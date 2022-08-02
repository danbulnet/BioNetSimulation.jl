module Algorithms

using DataFrames

using ..MAGDSSimple
import ..MAGDSParser: infertype
import ..ASACGraph
import ..SimpleNeuron: AbstractNeuron

function predict(magds::MAGDSSimple.Graph, sample::DataFrameRow, target::Symbol; validcols=[])
	MAGDSSimple.deactivate!(magds)

    colnames = Symbol.(names(sample))
	validcols = if isempty(validcols)
        Set(colnames)
    else
        Set(validcols)
    end
	if target in validcols
		pop!(validcols, target)
	end
    validcols = collect(intersect(validcols, colnames))
	sample = select!(DataFrame(sample), validcols)

	outneurons = Set{AbstractNeuron}()
	for featurename in colnames
		value = sample[1, featurename]
		if !ismissing(value)
			coltype, _ = infertype(typeof(value))
			if typeof(value) <: AbstractArray
				for el in value
					if !ismissing(el)
						sensor = ASACGraph.search(magds.sensors[featurename], coltype(el))
						if isnothing(sensor)
							sensor = ASACGraph.insert!(magds.sensors[featurename], coltype(el)) #TODO: remove tmp sensor
						end
						neurons = ASACGraph.activate!(sensor, 1.0, true, false)
						outneurons = union(outneurons, neurons)
					end
				end
			else
				sensor = ASACGraph.search(magds.sensors[featurename], coltype(value))
				if isnothing(sensor)
					sensor = ASACGraph.insert!(magds.sensors[featurename], coltype(value)) #TODO: remove tmp sensor
				end
				neurons = ASACGraph.activate!(sensor, 1.0, true, false)
				outneurons = union(outneurons, neurons)
			end
		end
	end
	sortedneurons = sort(collect(outneurons), by=x -> x.activation, rev=true)
	# winner takes all strategy
	for conn in sortedneurons[1].out
		if conn.to.parent.name == string(target)
			return conn.to.key
		end
	end
end

function predictions(magds::MAGDSSimple.Graph, Xtest::DataFrame, target::Symbol)::Vector
	ypred = []
	for (i, sample) in enumerate(eachrow(Xtest))
		i % 100 == 0 && println(i)
        push!(ypred, Float64(predict(magds, sample, target)))
	end
    ypred
end

end