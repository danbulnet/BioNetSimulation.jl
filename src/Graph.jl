module Graph

import Base.Threads.SpinLock

import BioNet: ASACGraph, MAGDSParser, MAGDSSimple, Simulation
import BioNet.ASACGraph.DataScale
import BioNet.MAGDSSimple.NeuronSimple

using HomefyAI.Structures

include("../data/questions.jl")

graph = nothing
graph_backup = nothing
graphlock = SpinLock();
graphlock_backup = SpinLock();

estateneurons_name = :estates

function safeexecute(f::Function)::Nothing
    try
        lock(graphlock)
        lock(graphlock_backup)
        f()
        global graph_backup = deepcopy(graph)
    catch e
        @error(
            "error procession safe function execution on graph with lock",
            exception=(e, catch_backtrace())
        )
        global graph = deepcopy(graph_backup)
    finally
        unlock(graphlock)
        unlock(graphlock_backup)
    end
    nothing
end

function creategraph()::Nothing
    safeexecute() do 
        global graph = MAGDSSimple.Graph()
        graph.neurons[estateneurons_name] = Set{NeuronSimple}()
    end
    
    estate = estatesample()
    for (fieldname, value) in describe(estate)
        @info "sensor $fieldname has been added"
        addsensin(fieldname, typeof(value))
    end
end

function addsensin(name::Symbol, ketype::DataType)::Nothing
    safeexecute() do
        if haskey(graph.sensors, name)
            @warn "addsensin: sensor $name already exists"
            return
        end
        
        keytype_infered, datatype = MAGDSParser.infertype(ketype)
        graph.sensors[name] = ASACGraph.Graph{keytype_infered}(string(name), datatype) 
    end
end

function addneuron(
    name::String, parent::Symbol, sensors::Dict{Symbol, Any}
)::Nothing where T
    safeexecute() do
        if !isnothing(MAGDSParser.findbyname(graph.neurons[parent], name))
            @warn "addneuron: neuron $name already exists, skipping"
            return
        end
    
        neuron = MAGDSSimple.NeuronSimple(name, string(parent))
        push!(graph.neurons[parent], neuron)
        for (sensorname, sensorvalue) in sensors
            asac = graph.sensors[sensorname]
            asac_keytype = ASACGraph.keytype(asac)
            if typeof(sensorvalue) <: AbstractArray
                for el in sensorvalue
                    sensor = ASACGraph.insert!(asac, asac_keytype(el))
                    MAGDSSimple.connect!(graph, :sensor_neuron, sensor, neuron)
                end
            else
                sensor = ASACGraph.insert!(asac, asac_keytype(sensorvalue))
                MAGDSSimple.connect!(graph, :sensor_neuron, sensor, neuron)
            end
        end
    end
end

function addestate(estate::Estate)::Nothing
    estatename = "$(estate.id): $(estate.investment.name) => $(estate.name)"
    features = describe(estate)
    addneuron(estatename, :estates, features)
    @info "\"$estatename\" has been added to the graph"
end

function addestate(;kwargs...)::Nothing
    id = kwargs[:id]
    name = kwargs[:name]
    investmentname = kwargs[:investment_name]
    estatename = "$id: $investmentname => $name"

    features = Dict{Symbol, Any}()
    for (key, value) in kwargs
        if key in fieldfilter
            features[key] = value
        end
    end

    addneuron(estatename, :estates, features)
    @info "\"$estatename\" has been added to the graph"
end

"""
    Runs app which visualize a given knowledge graph
"""
function show()
    nothing
end

function addestates(estates::Vector{Estate})
    for estate in estates
        addestate(estate)
    end
    @info "$(length(estates)) estates have been added to the graph"
end

end