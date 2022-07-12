module MAGDSSimple

export addneuron!, connect!, deactivate!, findbyname, Neuron

import ..Common: Opt, ConnectionSimple
import ..ASAGraph
include("NeuronSimple.jl")

struct Graph <: Common.AbstractGraph
    sensors::Dict{Symbol, AbstractSensoryField}
    neurons::Dict{Symbol, Set{NeuronSimple}}
    connections::Dict{Symbol, Set{Common.ConnectionSimple}}

    function Graph()
        new(
            Dict{Symbol, AbstractSensoryField}(),
            Dict{Symbol, Set{NeuronSimple}}(),
            Dict{Symbol, Set{Common.ConnectionSimple}}()
        )
    end
end

sensorweights(sensor::Common.AbstractSensor) = 1 / (length(sensor.out) + 1)

function addneuron!(graph::Graph, name::String, type::Symbol)::NeuronSimple
    if !haskey(graph.neurons, type)
        graph.neurons[type] = Set{NeuronSimple}()
    end
    
    neuron = NeuronSimple(name)
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
        graph.connections[type] = Set{Common.ConnectionSimple}()
    end

    first2second = Common.ConnectionSimple(first, second)
    push!(graph.connections[type], first2second)
    addconn!(first, first2second, :out)
    addconn!(second, first2second, :in)

    second2first = Common.ConnectionSimple(second, first)
    push!(graph.connections[type], second2first)
    addconn!(second, second2first, :out)
    addconn!(first, second2first, :in)
end

function connect1d!(
    graph::Graph,
    type::Symbol,
    first::Common.AbstractNeuron,
    second::Common.AbstractNeuron
)
    if !haskey(graph.connections, type)
        graph.connections[type] = Set{Common.ConnectionSimple}()
    end
        
    first2second = areconnected(graph, type, first, second)
    if isnothing(first2second)
        first2second = Common.ConnectionSimple(first, second)
        push!(graph.connections[type], first2second)
        addconn!(first, first2second, :out)
        addconn!(second, first2second, :in)
    end
end

function areconnected(graph, type, first, second)::Union{ConnectionSimple, Nothing}
    for conn in graph.connections[type]
        if first == conn.from && second == conn.to
            return conn
        end            
    end
    return nothing
end

function findbyname(neurons::Set{NeuronSimple}, name::String)::Opt{NeuronSimple}
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

function Base.show(io::IO, conn::ConnectionSimple)
    fromname = isa(conn.from, ASAGraph.Element) ? ASAGraph.name(conn.from) : name(conn.from)
    toname = isa(conn.to, ASAGraph.Element) ? ASAGraph.name(conn.to) : name(conn.to)
    println(fromname, " => ", toname)
end

end # module