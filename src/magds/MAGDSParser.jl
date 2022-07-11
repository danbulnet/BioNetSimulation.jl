module MAGDSParser

export db2magdrs, db2magdrs_old

using MySQL
using LibPQ
using Tables
import Dates
using DataFrames

using ..MAGDSSimple
using ..ASACGraph
using ..Common

include("query.jl")

const nullvalues = [nothing, ""]

function df2magds(dfs::Dict{Symbol, DataFrame}; rowlimit::Int=0)::MAGDSSimple.Graph
    graph = MAGDSSimple.Graph()

    for (dfname, df) in dfs
        rows = collect(eachrow(df))
        columntypes = eltype.(collect.(skipmissing.(eachcol(df))))
        columns = Symbol.(names(df))
    
        graph.neurons[dfname] = Set{NeuronSimple}()

        for (colindex, column) in enumerate(columns)
            if !(haskey(graph.sensors, column))
                coltype = columntypes[colindex]
                if coltype <: Number
                    datatype = numerical
                elseif coltype <: AbstractString
                    datatype = categorical
                    coltype = String
                elseif coltype <: <: Dates.DateTime 
                    datatype = ordinal
                end
                graph.sensors[column] = ASACGraph.Graph{coltype}(string(column), datatype)
            end
        end

        nrows = rowlimit > 0 ? min(rowlimit, length(rows)) : length(rows)
        for i = 1:nrows
            neuron = MAGDSSimple.NeuronSimple("$(dfname)_$i", string(dfname))
            push!(graph.neurons[Symbol(dfname)], neuron)
            for (colindex, column) in enumerate(columns)
                value = if columntypes[colindex] <: AbstractString 
                    string(rows[i][column])
                else 
                    rows[i][column]
                end
                if !ismissing(value)
                    sensor = insert!(graph.sensors[column], value)
                    MAGDSSimple.connect!(graph, :sensor_neuron, sensor, neuron)
                end
            end
        end
    end

    return graph
end

function mdb2magds(
    dbname::String,
    user::String,
    password::String;
    host::String = "localhost",
    port::Int = 3306,
    tablefilter::Vector{String} = String[],
    rowlimit::Int=0
)::MAGDSSimple.Graph
    conn = DBInterface.connect(
        MySQL.Connection, host, user, password; db=dbname, port=port
    )

    tables = columntable(DBInterface.execute(conn, "show tables;"))[1] .|> Symbol
    if !isempty(tablefilter)
        tablefilter = Symbol.(tablefilter)
        for table in tablefilter
            if !(table in tables)
                error("filter table $table desn't exists in database")
            end
        end
        tables = tablefilter
    end

    allfkeys = DBInterface.execute(conn, fkquerym) |> columntable
    fkeys = Dict{Symbol, Dict{Symbol, Symbol}}()
    for table in tables
        tablefkeys = Dict{Symbol, Symbol}()
        for i in 1:length(allfkeys.primary_table)
            if table == Symbol(allfkeys.foreign_table[i])
                tablefkeys[Symbol(allfkeys.fk_columns[i])] = Symbol(
                    allfkeys.primary_table[i]
                )
            end
        end
        fkeys[table] = tablefkeys
    end

    graph = tabs2magds(conn, tables, fkeys, rowlimit)
    close(conn)
    graph
end

function pgdb2magds(
    dbname::String,
    user::String,
    password::String;
    host::String = "localhost",
    port::String = "5432",
    tablefilter::Vector{String} = String[],
    rowlimit::Int=0
)::MAGDSSimple.Graph
    conn = LibPQ.Connection("host=$host port=$port dbname=$dbname user=$user password=$password")

    data = execute(conn, pkquerypg) |> columntable
    tables = filter(x -> !startswith(string(x), "pg_"), Symbol.(data.table_name))
    if !isempty(tablefilter) 
        tablefilter = Symbol.(tablefilter)
        for table in tablefilter
            if !(table in tables)
                error("filter table $table desn't exists in database")
            end
        end
        tables = tablefilter
    end

    allfkeys = execute(conn, fkquerypg) |> columntable
    fkeys = Dict{Symbol, Dict{Symbol, Symbol}}()
    for table in tables
        tablefkeys = Dict{Symbol, Symbol}()
        for i in 1:length(allfkeys.table_name)
            if table == Symbol(allfkeys.table_name[i])
                tablefkeys[Symbol(allfkeys.column_name[i])] = Symbol(
                    allfkeys.foreign_table_name[i]
                )
            end
        end
        fkeys[table] = tablefkeys
    end

    graph = tabs2magds(conn, tables, fkeys, rowlimit)
    close(conn)
    graph
end

function tabs2magds(
    conn, 
    tables::Vector{Symbol},
    fkeys::Dict{Symbol, Dict{Symbol, Symbol}},
    rowlimit::Int
)
    graph = MAGDSSimple.Graph()
    
    tablestodo = Set(tables)
    tablesprim = Set(filter(x -> isempty(keys(fkeys[x])), tables))

    for table in tablesprim
        tabledata = fetchtable(conn, table)
        addsensins!(graph, table, tabledata; rowlimit=rowlimit)
    end
    tablesprim = Set(tablesprim)
    tablestodo = setdiff(tablestodo, tablesprim)
    tablesdone = copy(tablesprim)

    while !isempty(tablestodo)
       for table in tablestodo
            ftables = fkeys[table]
            todo = true
            for (_, ftable) in ftables
                if !(ftable in tablesdone) && ftable in tables
                    todo = false
                    break
                end
            end
            if todo
                tabledata = fetchtable(conn, table)
                addsensins!(graph, table, tabledata; rowlimit=rowlimit)
                addneurons!(
                    graph, table, tabledata, fkeys[table]; rowlimit=rowlimit
                )
                pop!(tablestodo, table)
                push!(tablesdone, table)
            end
       end
    end

    graph
end

function addsensins!(
    graph::MAGDSSimple.Graph, table::Symbol, tabledata::Dict; rowlimit::Int=0
)
    println("adding sensin for ", table)

    columns = tabledata[:columns]
    columntypes = tabledata[:columntypes]
    datatypes = tabledata[:datatypes]
    rows = tabledata[:rows]

    graph.neurons[table] = Set{NeuronSimple}()

    for (colindex, column) in enumerate(columns)
        if !(haskey(graph.sensors, column))
            coltype, datatype = infertype(columntypes[colindex])
            graph.sensors[column] = ASACGraph.Graph{coltype}(
                string(column), datatype
            )
        end
    end

    tablelen = length(first(rows))
    nrows = rowlimit > 0 ? min(rowlimit, tablelen) : tablelen
    for i = 1:nrows
        neuron = MAGDSSimple.NeuronSimple(
            "$(table)_$(rows[columns[1]][i])", string(table)
        )
        push!(graph.neurons[table], neuron)
        for (colindex, column) in enumerate(columns)
            datatype = datatypes[column]
            value = rows[column][i]
            if !ismissing(value) && !(value in nullvalues)
                coltype, _ = infertype(columntypes[colindex])
                if typeof(value) <: AbstractArray
                    for el in value
                        sensor = insert!(graph.sensors[column], coltype(el))
                        MAGDSSimple.connect!(graph, :sensor_neuron, sensor, neuron)
                    end
                elseif datatype == :set
                    parser = el -> (coltype <: Number) ? parse(coltype, el) : coltype(el)
                    for el in split(string(value), ",")
                        sensor = insert!(graph.sensors[column], parser(el))
                        MAGDSSimple.connect!(graph, :sensor_neuron, sensor, neuron)
                    end
                else
                    sensor = insert!(graph.sensors[column], coltype(value))
                    MAGDSSimple.connect!(graph, :sensor_neuron, sensor, neuron)
                end
            end
        end
    end
end

function addneurons!(
    graph::MAGDSSimple.Graph, table::Symbol, tabledata::Dict, fkeys; rowlimit::Int=0
)
    println("adding neurons for ", table)

    columns = tabledata[:columns]
    rows = tabledata[:rows]

    tablelen = length(first(rows))
    nrows = rowlimit > 0 ? min(rowlimit, tablelen) : tablelen
    for i = 1:nrows
        nname = "$(table)_$(rows[columns[1]][i])"
        neuron = findbyname(graph.neurons[table], nname)
        for column in columns
            if haskey(fkeys, column)
                ftable = fkeys[column]
                fnname = "$(ftable)_$(rows[column][i])"
                neuronsgroup = if haskey(graph.neurons, ftable)
                    graph.neurons[ftable]
                else
                    nothing
                end
                fneuron = if !isnothing(neuronsgroup) 
                    findbyname(graph.neurons[ftable], fnname)
                else 
                    nothing
                end
                if !isnothing(fneuron)
                    MAGDSSimple.connect!(graph, :neuron_neuron, fneuron, neuron)
                end
            end
        end
    end
end

function infertype(coltype::DataType)
    if coltype <: AbstractArray
        coltype = eltype(coltype)
    end
    if coltype <: Integer
        coltype = Int
    end

    datatype = if coltype <: Number
        numerical
    elseif coltype <: AbstractString
        coltype = String
        categorical
    elseif coltype <: Dates.DateTime 
        ordinal
    else
        error("unknown data type for $coltype")
    end
    coltype, datatype
end

function fetchtable(conn, table::Symbol)
    lib = nothing
    if typeof(conn) == MySQL.Connection
        lib = DBInterface
    elseif typeof(conn) == LibPQ.Connection
        lib = LibPQ
    else
        error("unsupported connection type, supported types are: MySQL, LibPQ")
    end 
    rows = lib.execute(conn, @rowsquery(table)) |> columntable
    dt = Symbol.(columntable(lib.execute(conn, typesquery(table))).DATA_TYPE)
    dtnames = Symbol.(columntable(lib.execute(conn, typesquery(table))).COLUMN_NAME)
    datatypes = Dict{Symbol, Symbol}()
    for i in 1:length(dt)
        datatypes[dtnames[i]] = dt[i]
    end

    columntypes = eltype.(collect.(skipmissing.(values(rows)))) 
    columns = rows |> keys
    
    Dict(
        :columns => columns, 
        :columntypes => columntypes,
        :datatypes => datatypes,
        :rows => rows
    )
end

end # module