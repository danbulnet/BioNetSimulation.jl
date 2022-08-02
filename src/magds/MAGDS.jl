module MAGDS

export addneuron!, connect!, deactivate!, findbyname, Neuron

import ..Common: Opt, Connection
import ..ASAGraph
include("Neuron.jl")

struct Graph <: Common.AbstractGraph
    sensors::Dict{Symbol, Common.AbstractSensoryField}
    neurons::Dict{Symbol, Set{Common.AbstractNeuron}}
    connections::Dict{Symbol, Set{Common.Connection}}

    function Graph()
        new(
            Dict{Symbol, Common.AbstractSensoryField}(),
            Dict{Symbol, Set{Common.AbstractNeuron}}(),
            Dict{Symbol, Set{Common.Connection}}()
        )
    end
end

sensorweights(sensor::Common.AbstractSensor) = 1 / (length(sensor.out) + 1)

function countedsensorweights(sensor::Common.AbstractSensor)
    totalcount = 0
    for connout in sensor.out
        totalcount += connout.counter
    end
    for connout in sensor.out
        connout.weight = connout.counter / totalcount
    end
end

function addneuron!(graph::Graph, name::String, type::Symbol)::Neuron
    if !haskey(graph.neurons, type)
        graph.neurons[type] = Set{Common.AbstractNeuron}()
    end
    
    neuron = Neuron(name)
    push!(graph.neurons[type], neuron)
    neuron
end

function connect!( # LEGACY !
    graph::Graph,
    type::Symbol,
    first::Common.AbstractNeuron,
    second::Common.AbstractNeuron
)
    if !haskey(graph.connections, type)
        graph.connections[type] = Set{Common.Connection}()
    end

    first2second = Common.Connection(first, second, 1.0)
    push!(graph.connections[type], first2second)
    addconn!(first, first2second, :out)
    addconn!(second, first2second, :in)

    second2first = Common.Connection(second, first, 1.0)
    push!(graph.connections[type], second2first)
    addconn!(second, second2first, :out)
    addconn!(first, second2first, :in)

    if isa(first, Common.AbstractSensor)
        outweight = sensorweights(first)
        for connout in first.out
            connout.weight = outweight
        end
    elseif isa(second, Common.AbstractSensor)
        outweight = sensorweights(second)
        for connout in second.out
            connout.weight = outweight
        end
    end
end

function connect1d!(
    graph::Graph,
    type::Symbol,
    first::Common.AbstractNeuron,
    second::Common.AbstractNeuron
)
    if !haskey(graph.connections, type)
        graph.connections[type] = Set{Common.Connection}()
    end
        
    first2second = areconnected(graph, type, first, second)
    if isnothing(first2second)
        first2second = Common.Connection(first, second, 1.0)
        push!(graph.connections[type], first2second)
        addconn!(first, first2second, :out)
        addconn!(second, first2second, :in)
    else
        Common.counterup!(first2second)
    end

    if isa(first, Common.AbstractSensor)
        countedsensorweights(first)
    end
end

function areconnected(graph, type, first, second)::Union{Connection, Nothing}
    for conn in graph.connections[type]
        if first == conn.from && second == conn.to
            return conn
        end            
    end
    return nothing
end

function findbyname(neurons::Set{Common.AbstractNeuron}, name::String)::Opt{Common.AbstractNeuron}
    for neuron in neurons
        if neuron.name == name
            return neuron
        end
    end
    return nothing
end

function deactivate!(graph::Graph, neurons::Bool = true, sensors::Bool = true)::Nothing
    if neurons
        for neurontype in graph.neurons
            for neuron in graph.neurons[neurontype.first]
                deactivate!(neuron)
            end
        end
    end

    if sensors
        for sensortype in graph.sensors
            deactivate!(graph.sensors[sensortype.first])
        end
    end
    nothing
end

function show(io::IO, graph::Graph)
    println("sensors", " => ", graph.sensors)
    println("neurons", " => ", graph.neurons)
    println("connections", " => ", graph.connections)
end

# function Base.show(io::IO, conn::Connection)
#     fromname = isa(conn.from, ASAGraph.Element) ? ASAGraph.name(conn.from) : name(conn.from)
#     toname = isa(conn.to, ASAGraph.Element) ? ASAGraph.name(conn.to) : name(conn.to)
#     println(fromname, " => ", toname, " weight: ", round.(conn.weight; digits=5))
# end

end # module