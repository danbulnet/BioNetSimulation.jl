module BioNet

export AGDS, AGDSSimple, DatabaseParser, ASAGraph, ASACGraph, ASAGraphSimple, ASACGraphSimple
export Simulation, SubtreesBenchmarks, ECG, AssociativeSequentialMemory

include("common/Common.jl")
include("magds/SimpleNeuron.jl")
include("asagraph/ASAGraph.jl")
include("asagraphsimple/ASAGraphSimple.jl")
include("asacgraph/ASACGraph.jl")
include("asacgraphsimple/ASACGraphSimple.jl")
include("magds/MAGDS.jl")
include("magds/MAGDSSimple.jl")
include("magds/MAGDSParser.jl")
include("magds/Algorithms.jl")
include("benchmark/SubtreesBenchmarks.jl")
include("benchmark/MAGDSBenchmark.jl")
include("simulation/Simulation.jl")

greet() = println("Hello BioNet!")

end # module
