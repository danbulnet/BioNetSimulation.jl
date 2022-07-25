using Test
using HomefyAI

@testset "homefy graph tests" begin
    nofneurons = 100
    
    Graph.creategraph()
    @test length(Graph.graph.neurons[:estates]) == 0

    for i in 1:nofneurons
        Graph.addestate(Structures.estatesample(i))
    end

    @test length(Graph.graph.neurons[:estates]) == nofneurons

    Graph.safeexecute() do 
        Graph.graph = MAGDSSimple.Graph()
        graph.neurons[estateneurons_name] = Set{NeuronSimple}()
        error("test error")
    end

    @test length(Graph.graph.neurons[:estates]) == nofneurons
end