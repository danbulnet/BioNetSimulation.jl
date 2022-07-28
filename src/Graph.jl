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

function safeexecute(f::Function)::Bool
    result = true
    try
        lock(graphlock)
        lock(graphlock_backup)
        fret = f()
        if fret isa Bool
            result = fret
        end
        global graph_backup = deepcopy(graph)
    catch e
        @error(
            "error processing safe function execution on graph with lock",
            exception=(e, catch_backtrace())
        )
        global graph = deepcopy(graph_backup)
        result = false
    finally
        unlock(graphlock)
        unlock(graphlock_backup)
    end
    result
end

function creategraph()::Nothing
    safeexecute() do 
        global graph = MAGDSSimple.Graph()
        graph.neurons[estateneurons_name] = Set{NeuronSimple}()
    end
    
    estate = estatesample()
    for (fieldname, value) in describe(estate)
        if fieldname in fieldfilter
            @info "sensor $fieldname has been added"
            addsensin(fieldname, typeof(value))
        end
    end
    nothing
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
    nothing
end

function addneuron(
    name::String, parent::Symbol, sensors::Dict{Symbol, Any}
)::Bool
    safeexecute() do
        if !isnothing(MAGDSParser.findbyname(graph.neurons[parent], name))
            @warn "addneuron: neuron $name already exists, skipping"
            return false
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
        true
    end
end

function addestate(estate::Estate)::Nothing
    estatename = "$(estate.id): $(estate.investment.name) => $(estate.name)"
    features = describe(estate)
    if addneuron(estatename, :estates, features)
        @info "\"$estatename\" has been added to the graph"
    end
end

function addestate(;kwargs...)::Nothing
    id = kwargs[:id]
    name = kwargs[:name]
    investmentname = kwargs[:investment_name]
    estatename = "$id: $investmentname => $name"

    allnothing = true
    features = Dict{Symbol, Any}()
    for (key, value) in kwargs
        if !isnothing(value) && key in fieldfilter
            features[key] = value
            allnothing = false
        end
    end

    if !allnothing 
        if addneuron(estatename, :estates, features)
            @info "\"$estatename\" has been added to the graph"
        end
    else
        @warn "\"$estatename\" has all sensors == nothing, skipping"
    end
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