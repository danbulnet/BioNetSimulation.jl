module DatabaseParser

export db2magdrs, db2magdrs_old

using MySQL
using LibPQ
using Tables
import Dates
using DataFrames

using ..AGDSSimple
using ..ASACGraph
using ..Common

const pkquerypg = """
    SELECT tc.table_name, kc.column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kc
    ON kc.table_name = tc.table_name and kc.constraint_name = tc.constraint_name
    WHERE tc.constraint_type = 'PRIMARY KEY'
    AND kc.ordinal_position is not null
    ORDER BY tc.table_name, kc.position_in_unique_constraint;
"""

const fkquerypg = """
    SELECT
        tc.table_name, kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name
    FROM
        information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage
    AS kcu ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage
    AS ccu ON ccu.constraint_name = tc.constraint_name
    WHERE constraint_type = 'FOREIGN KEY';
"""

const fkquerym = """
    select fks.table_name as foreign_table, '->' as rel,
    fks.referenced_table_name as primary_table,
    fks.constraint_name,
    group_concat(kcu.column_name
        order by position_in_unique_constraint separator ', ') 
        as fk_columns
    from information_schema.referential_constraints fks
    join information_schema.key_column_usage kcu
    on fks.constraint_schema = kcu.table_schema
    and fks.table_name = kcu.table_name
    and fks.constraint_name = kcu.constraint_name
    -- where fks.constraint_schema = 'database name'
    group by fks.constraint_schema,
    fks.table_name,
    fks.unique_constraint_schema,
    fks.referenced_table_name,
    fks.constraint_name
    order by fks.constraint_schema,
    fks.table_name;
"""

macro colsquery(table)
    :(string("SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_NAME = '",  $(esc(table)), "';"))
end

macro rowsquery(table)
    :(string("SELECT * FROM ",  $(esc(table)), ";"))
end

function df2magds(dfs::Dict{Symbol, DataFrame}; rowlimit::Int=0)::AGDSSimple.Graph
    graph = AGDSSimple.Graph()

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
            neuron = AGDSSimple.NeuronSimple("$(dfname)_$i", string(dfname))
            push!(graph.neurons[Symbol(dfname)], neuron)
            for (colindex, column) in enumerate(columns)
                value = if columntypes[colindex] <: AbstractString 
                    string(rows[i][column])
                else 
                    rows[i][column]
                end
                if !ismissing(value)
                    sensor = insert!(graph.sensors[column], value)
                    AGDSSimple.connect!(graph, :sensor_neuron, sensor, neuron)
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
)::AGDSSimple.Graph
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
)::AGDSSimple.Graph
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
    graph = AGDSSimple.Graph()
    
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
    graph::AGDSSimple.Graph, table::Symbol, tabledata::Dict; rowlimit::Int=0
)
    println("adding sensin for ", table)

    columns = tabledata[:columns]
    columntypes = tabledata[:columntypes]
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
        neuron = AGDSSimple.NeuronSimple(
            "$(table)_$(rows[columns[1]][i])", string(table)
        )
        push!(graph.neurons[table], neuron)
        for column in columns
            value = rows[column][i]
            if !ismissing(value)
                if typeof(value) <: AbstractArray
                    for el in value
                        sensor = insert!(graph.sensors[column], el)
                        AGDSSimple.connect!(graph, :sensor_neuron, sensor, neuron)
                    end
                else
                    sensor = insert!(graph.sensors[column], value)
                    AGDSSimple.connect!(graph, :sensor_neuron, sensor, neuron)
                end
            end
        end
    end
end

function addneurons!(
    graph::AGDSSimple.Graph, table::Symbol, tabledata::Dict, fkeys; rowlimit::Int=0
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
                    AGDSSimple.connect!(graph, :neuron_neuron, fneuron, neuron)
                end
            end
        end
    end
end

function infertype(coltype::DataType)
    if coltype <: AbstractArray
        coltype = eltype(coltype)
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
    rows = if typeof(conn) == MySQL.Connection
        DBInterface.execute(conn, @rowsquery(table))
    elseif typeof(conn) == LibPQ.Connection
        LibPQ.execute(conn, @rowsquery(table))
    else
        error("unsupported connection type, supported types are: MySQL, LibPQ")
    end |> columntable

    columntypes = eltype.(collect.(skipmissing.(values(rows))))
    columns = rows |> keys
    
    Dict(:columns => columns, :columntypes => columntypes, :rows => rows)
end

end # module