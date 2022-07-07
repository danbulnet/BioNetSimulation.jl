module BioNet

export AGDS, AGDSSimple, ASAGraph, ASACGraph, ASAGraphSimple, ASACGraphSimple
export Simulation, SubtreesBenchmarks, ECG, AssociativeSequentialMemory

include("common/Common.jl")
include("asagraph/ASAGraph.jl")
include("asagraphsimple/ASAGraphSimple.jl")
include("asacgraph/ASACGraph.jl")
include("asacgraphsimple/ASACGraphSimple.jl")
include("agds/AGDS.jl")
include("agds/AGDSSimple.jl")
include("agds/DatabaseParser.jl")
include("benchmark/SubtreesBenchmarks.jl")
include("benchmark/MAGDSBenchmark.jl")
include("simulation/Simulation.jl")

greet() = print("Hello BioNet!")

end # module
