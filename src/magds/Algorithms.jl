module Algorithms

using DataFrames

import ..MAGDSParser: infertype
using ..MAGDSSimple
import ..ASACGraph
import ..SimpleNeuron: AbstractNeuron

validcols = [
    :exterior_color,
    :interior_color,
    :drivetrain,
    :fuel_type,
    :transmission,
    :engine,
    :mileage,
    :seller,
    :reviews_count,
    :seller_state,
    :new_used,
    :brand,
    :comfort,
    :interior_design,
    :performance,
    :value_for_the_money,
    :exterior_styling,
    :reliability,
    :price,
    :rating,
    :year,
    :model,
    :features
]

function predict(magds::MAGDSSimple.Graph, sample::DataFrameRow; validcols=validcols)
    MAGDSSimple.deactivate!(magds)

    validcols = Set(validcols)
    if :price in validcols
        pop!(validcols, :price)
    end
    colnames = Symbol.(names(sample))
    validcols = collect(intersect(validcols, colnames))
    sample = select!(DataFrame(sample), validcols)

    outneurons = Set{AbstractNeuron}()
    for featurename in colnames
        value = sample[1, featurename]
        println("featurename $featurename value $value")
        if !ismissing(value)
            coltype, _ = infertype(typeof(value))
            if typeof(value) <: AbstractArray
                for el in value
                    if !ismissing(el)
                        sensor = ASACGraph.search(magds.sensors[featurename], coltype(el))
                        if isnothing(sensor)
                            sensor = ASACGraph.insert!(graph.sensors[column], coltype(el)) #TODO: remove tmp sensor   
                        end
                        neurons = ASACGraph.activate!(sensor, 1.0, true, false)
                        outneurons = union(outneurons, neurons)
                    end
                end
            else
                sensor = ASACGraph.search(magds.sensors[featurename], coltype(value))
                if isnothing(sensor)
                    sensor = ASACGraph.insert!(graph.sensors[column], coltype(value)) #TODO: remove tmp sensor        
                end
                neurons = ASACGraph.activate!(sensor, 1.0, true, false)
                outneurons = union(outneurons, neurons)
            end
        end
    end
    outneurons
end

end