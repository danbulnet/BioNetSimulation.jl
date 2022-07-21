module Graph

import BioNet: ASACGraph, MAGDSParser, MAGDSSimple, Simulation
import BioNet.ASACGraph.DataScale
import BioNet.MAGDSSimple.NeuronSimple
import Base.Threads.SpinLock

using HomefyAI.Structures

include("db2sensors.jl")
include("../data/questions.jl")

graph = nothing
graphlock = SpinLock();

estateneurons_name = :estates

function safeexecute(f::Function)::Nothing
    lock(graphlock)
    try
        f()
    catch e
        @error "error procession safe function execution on graph with lock"
        @error e
    finally
        unlock(graphlock)
    end
    nothing
end

function creategraph()::Nothing
    safeexecute() do 
        global graph = MAGDSSimple.Graph()
        graph.neurons[estateneurons_name] = Set{NeuronSimple}()
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
            sensor = ASACGraph.insert!(asac, asac_keytype(sensorvalue))
            MAGDSSimple.connect!(graph, :sensor_neuron, sensor, neuron)
        end
    end
end

function addestate(estate::Estate)::Nothing where T
    estatename = estate.id * ": " * estate.investment.name * " => " * estate.name
    for (fieldname, value) in listfields(estate)

    end

    addneuron(estatename, :estates, features)
end

"""
    Runs app which visualize a given knowledge graph
"""
function show()
    nothing
end

function addestates(graph::MAGDSSimple.Graph, estates)
    println(estates)
end

end