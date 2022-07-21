module HomefyAI

push!(LOAD_PATH, "bionet")

include("Graph.jl")
include("Structures.jl")

export Graph, BioNet, Structures

end
