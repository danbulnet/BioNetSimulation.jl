using Test
using BioNetSimulation
import BioNet: MAGDSSimple, ASACGraph

@testset "BioNetSimulation graph tests" begin
    asagcraph = ASACGraph.asacgraphsample(100)
    @test asacgraph.elements == 100
end