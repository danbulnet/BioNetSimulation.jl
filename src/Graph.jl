module Graph

import BioNet: ASACGraph, MAGDSParser, MAGDSSimple, Simulation
import BioNet.ASACGraph.DataScale
import BioNet.MAGDSSimple.NeuronSimple
import Base.Threads.SpinLock

include("db2sensors.jl")
include("../data/questions.jl")

graph = nothing
graphlock = SpinLock();

estateneurons_name = :estates

function safeexecute(f::Function)
    lock(graphlock)
    try
        f()
    catch

    end
end

function creategraph()
    lock(graphlock)
    try
        global graph = MAGDSSimple.Graph()
        graph.neurons[estateneurons_name] = Set{NeuronSimple}()
    catch
        @error "error creating graph with lock"
    finally
        unlock(graphlock)
    end
    nothing
end

function addsensin(name::Symbol, ketype::DataType)
    lock(graphlock)
    try
        if haskey(graph.sensors, name)
            @warn "addsensin: sensor $name already exists"
            return
        end
        
        keytype_infered, datatype = MAGDSParser.infertype(ketype)
        graph.sensors[name] = ASACGraph.Graph{keytype_infered}(string(name), datatype)    
    catch
        @error "error creating graph with lock"
    finally
        unlock(graphlock)
    end
    nothing
end

function addestate(name::String, sensors::Dict{Symbol, Any}) where T
    lock(graphlock)
    try
        if !isnothing(MAGDSParser.findbyname(graph.neurons[estateneurons_name], name))
            @warn "addestate: estate $name already exists"
            return
        end
    
        neuron = MAGDSSimple.NeuronSimple(string(name), string(estateneurons_name))
        push!(graph.neurons[estateneurons_name], neuron)
        for (sensorname, sensorvalue) in sensors
            asac = graph.sensors[sensorname]
            asac_keytype = ASACGraph.keytype(asac)
            sensor = ASACGraph.insert!(asac, asac_keytype(sensorvalue))
            MAGDSSimple.connect!(graph, :sensor_neuron, sensor, neuron)
        end
    catch
        @error "error creating graph with lock"
    finally
        unlock(graphlock)
    end
    nothing
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