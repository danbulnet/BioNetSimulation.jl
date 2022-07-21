module HomefyAI

push!(LOAD_PATH, "bionet")

include("Structures.jl")
include("Graph.jl")

export Graph, BioNet, Structures

end
