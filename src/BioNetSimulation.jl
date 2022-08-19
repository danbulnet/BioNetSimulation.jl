module BioNetSimulation


push!(LOAD_PATH, "bionet")

export BioNet
export Simulation, SubtreesBenchmarks

include("benchmark/SubtreesBenchmarks.jl")
include("benchmark/MAGDSBenchmark.jl")
include("simulation/Simulation.jl")

greet() = println("Hello BioNetSimulation")

end # module
