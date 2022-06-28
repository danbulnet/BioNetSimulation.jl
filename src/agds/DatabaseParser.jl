module DatabaseParser

export db2magdrs, db2magdrs_old

using LibPQ, Tables
using ..AGDSSimple
using ..ASACGraph
using ..Common

const pkquery = """
    SELECT tc.table_name, kc.column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kc
    ON kc.table_name = tc.table_name and kc.constraint_name = tc.constraint_name
    WHERE tc.constraint_type = 'PRIMARY KEY'
    AND kc.ordinal_position is not null
    ORDER BY tc.table_name, kc.position_in_unique_constraint;
"""

const fkquery = """
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

macro colsquery(table)
    :(string("SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_NAME = '",  $(esc(table)), "';"))
end

macro rowsquery(table)
    :(string("SELECT * FROM ",  $(esc(table)), ";"))
end

function db2magdrs(
    dbname::String,
    user::String,
    password::String;
    host::String = "localhost",
    port::String = "5432",
    tablefilter::Vector{String} = String[],
    rowlimit::Int=0
)::AGDSSimple.Graph
    conn = LibPQ.Connection("host=$host port=$port dbname=$dbname user=$user password=$password")

    result = execute(conn, fkquery)
    allfkeys = columntable(result)

    result = execute(conn, pkquery)
    data = columntable(result)
    
    tables = if isempty(tablefilter) 
        filter(x -> !startswith(string(x), "pg_"), map(Symbol, data.table_name))
    else
        map(Symbol, tablefilter)
    end

    graph = AGDSSimple.Graph()
  
    tabsfkeys = Dict{Symbol, Set{Symbol}}()
    tabsfkeystabs = Dict{Symbol, Dict{Symbol, Symbol}}()
    for table in tables
        tablefkeys = Set{Symbol}()
        tablefkeystabs = Dict{Symbol, Symbol}()
        for i in 1:length(allfkeys.table_name)
            if table == Symbol(allfkeys.table_name[i])
                push!(tablefkeys, Symbol(allfkeys.column_name[i]))
                tablefkeystabs[Symbol(allfkeys.column_name[i])] = Symbol(allfkeys.foreign_table_name[i])
            end
        end
        tabsfkeys[table] = tablefkeys
        tabsfkeystabs[table] = tablefkeystabs
    end

    tablestodo = Set(tables)
    tablesprim = filter(x -> isempty(tabsfkeys[x]), tables)

    for table in tablesprim
        addsensins!(graph, conn, table)
    end
    tablesprim = Set(tablesprim)
    tablestodo = setdiff(tablestodo, tablesprim)
    tablesdone = copy(tablesprim)

    while !isempty(tablestodo)
       for table in tablestodo
            ftables = tabsfkeystabs[table]
            todo = true
            for (_, ftable) in ftables
                if !(ftable in tablesdone) && ftable in tables
                    todo = false
                    break
                end
            end
            if todo
                addsensins!(graph, conn, table)
                # if length(tablefilter) > 1
                    # addneurons!(graph, conn, table, tabsfkeystabs[table])
                # end
                addneurons!(graph, conn, table, tabsfkeystabs[table]; rowlimit)
                pop!(tablestodo, table)
                push!(tablesdone, table)
            end
       end
    end

    close(conn)

    return graph
end

function addsensins!(graph::AGDSSimple.Graph, conn, table::Symbol)
    println("adding sensins for ", table)
    result = execute(conn, @rowsquery(table))
    rows = columntable(result)
    columntypes = LibPQ.column_types(result)
    columns = LibPQ.column_names(result)

    graph.neurons[Symbol(table)] = Set{NeuronSimple}()

    for (colindex, column) in enumerate(columns)
        column = Symbol(column)
        if !(haskey(graph.sensors, column))
            graph.sensors[column] = ASACGraph.Graph{columntypes[colindex]}(string(column), ordinal) # TODO: datatype
        end
    end

    for i = 1:length(rows[1])
        neuron = AGDSSimple.NeuronSimple("$(table)_$(rows[Symbol(columns[1])][i])", string(table))
        push!(graph.neurons[Symbol(table)], neuron)
        for column in columns
            value = rows[Symbol(column)][i]
            if typeof(value) != Missing
                sensor = insert!(graph.sensors[Symbol(column)], rows[Symbol(column)][i])
                AGDSSimple.connect!(graph, :sensor_neuron, sensor, neuron)
            end
        end
    end
end

function addneurons!(graph::AGDSSimple.Graph, conn, table::Symbol, fkeys; rowlimit::Int=0)
    println("adding neurons for ", table)
    result = execute(conn, @rowsquery(table))
    rows = columntable(result)
    columns = LibPQ.column_names(result)

    nrows = rowlimit > 0 ? min(rowlimit, length(rows[1])) : length(rows[1])
    for i = 1:nrows
        # if i == 1 || i % 1000 == 0 || i == length(rows[1])
        #     print(i, " ")
        # end
        nname = "$(table)_$(rows[Symbol(columns[1])][i])"
        neuron = findbyname(graph.neurons[Symbol(table)], nname)
        for column in columns
            column = Symbol(column)
            if haskey(fkeys, column)
                ftable = fkeys[column]
                fnname = "$(ftable)_$(rows[Symbol(column)][i])"
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
    # println()
end

function db2magdrs_old(
    dbname::String,
    user::String,
    password::String;
    host::String = "localhost",
    port::String = "5432",
    tablefilter::Vector{String} = String[],
)::AGDSSimple.Graph
    conn = LibPQ.Connection("host=$host port=$port dbname=$dbname user=$user password=$password")

    result = execute(conn, fkquery)
    allfkeys = columntable(result)

    result = execute(conn, pkquery)
    data = columntable(result)
    
    if isempty(tablefilter) 
        tables = data.table_name
    else
        tables = tablefilter
    end

    graph = AGDSSimple.Graph()
    # graph.connections[:sensor_neuron] = Set{Connection}()
    # graph.connections[:neuron_neuron] = Set{Connection}()

    for table in tables
        println("table ", table, ": ")
        fkeys = Dict{String, NamedTuple{(:table, :column),Tuple{Symbol, String}}}()
        for i in 1:length(allfkeys.table_name)
            if table == allfkeys.table_name[i]
                fkeys[allfkeys.column_name[i]] =
                    (table = Symbol(allfkeys.foreign_table_name[i]),
                     column = allfkeys.foreign_column_name[i])
            end
        end

        println(fkeys)

        # result = execute(conn, @colsquery(table))
        # data = columntable(result)
        # columns = data.column_name

        result = execute(conn, @rowsquery(table))
        rows = columntable(result)
        columntypes = LibPQ.column_types(result)
        columns = LibPQ.column_names(result)
        print(columns)

        graph.neurons[Symbol(table)] = Set{NeuronSimple}()

        for (colindex, column) in enumerate(columns)
            column = Symbol(column)
            if !(haskey(graph.sensors, column)) && !(haskey(fkeys, column))
                graph.sensors[column] = ASACGraph.Graph{columntypes[colindex]}(string(column), ordinal) # TODO: datatype
            end
        end

        for i = 1:length(rows[1])
            if i == 1 || i % 100 == 0
                print(i, " ")
            end
            neuron = AGDSSimple.NeuronSimple("$(table)_$(rows[Symbol(columns[1])][i])", string(table))
            push!(graph.neurons[Symbol(table)], neuron)
            for (colindex, column) in enumerate(columns)
                value = rows[Symbol(column)][i]
                if typeof(value) != Missing && !(haskey(fkeys, column))
                    treekeystype = ASACGraph.keytype(graph.sensors[Symbol(column)])
                    # value = if treekeystype == String
                    #     string(treekeystype, rows[Symbol(column)][i])
                    # else
                    #     convert(treekeystype, rows[Symbol(column)][i])
                    # end
                    sensor = insert!(graph.sensors[Symbol(column)], rows[Symbol(column)][i])

                    # s2nweight = 1 / (length(sensor.out) + 1)
                    # for connout in sensor.out
                    #     connout.weight = s2nweight
                    # end

                    # AGDSSimple.connect!(
                    #     graph,
                    #     :sensor_neuron,
                    #     sensor,
                    #     neuron,
                    #     bidirectional,
                    #     s2nweight,
                    #     1.0
                    # )
                    AGDSSimple.connect!(graph, :sensor_neuron, sensor, neuron)
                end
            end
        end
        println()
    end

    for table in tables
        println("table ", table, ": ")
        fkeys = Dict{String, NamedTuple{(:table, :column),Tuple{Symbol, String}}}()
        for i in 1:length(allfkeys.table_name)
            if table == allfkeys.table_name[i]
                fkeys[allfkeys.column_name[i]] =
                    (table = Symbol(allfkeys.foreign_table_name[i]),
                     column = allfkeys.foreign_column_name[i])
            end
        end

        # result = execute(conn, @colsquery(table))
        # data = columntable(result)
        # columns = data.column_name

        # result = execute(conn, @rowsquery(table))
        # rows = columntable(result)

        result = execute(conn, @rowsquery(table))
        rows = columntable(result)
        columns = LibPQ.column_names(result)
        print(columns)

        for i = 1:length(rows[1])
            if i == 1 || i % 100 == 0
                print(i, " ")
            end
            nname = "$table $(rows[Symbol(columns[1])][i])"
            neuron = findbyname(graph.neurons[Symbol(table)], nname)
            for column in columns
                if haskey(fkeys, column)
                    ftable = fkeys[column].table
                    fnname = "$ftable $(rows[Symbol(column)][i])"
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
                    # else
                    #     println("failed to find neuron $fnname in $ftable for $(neuron.name)")
                    end

                    # outobjs = sum(typeof(out.to) === Neuron for out in fneuron.out)
                    # n2nweight = 1 / (outobjs + 1)
                    # for connout in fneuron.out
                    #     connout.weight = n2nweight
                    # end

                    # AGDSSimple.connect!(
                    #     graph,
                    #     :neuron_neuron,
                    #     fneuron,
                    #     neuron,
                    #     bidirectional,
                    #     n2nweight,
                    #     1.0
                    # )
                end
            end
        end
        println()
    end

    close(conn)

    return graph
end

end # module