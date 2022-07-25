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

    Graph.creategraph()
    @test length(Graph.graph.neurons[:estates]) == 0

    Graph.addestate(;
        id=1,
        estatetype="luxuryapartment",
        bathrooms=0x0001,
        updated_at=0x0000000062d8dd3c,
        street="Cieszyńska",
        country="PL",
        price=0x00118c30,
        created_at=0x0000000062d8dd32,
        builtyear=0x07dc,
        deliverydeadline="inuse",
        government_program_1=0x00,
        voivodeship="małopolska",
        investment_active=0x01,
        standard="readytolive",
        availability="free",
        canalization="urban",
        town="Kraków",
        floor=4,
        investment_name="Apartamenty Cieszyńska",
        rooms=0x0003,
        investment_presentation=["gallery", "interactivemap"],
        long=19.9302,
        storeys=0x05,
        developer_name="Murapol",
        name="6/23",
        flatnumber=0x0017,
        buildingphase="finished",
        additionalarea=["balcony", "loggia", "spaceingarage"],
        buildingnumber=0x0006,
        aream2=66.4,
        material="brick",
        facilities=["airconditioning", "internetwifi", "cabletv", "lift"],
        lat=50.0753,
        functionalities=["kitchenette", "functionallayout"],
        heating="centralcity",
        buildingtype="terraced"
    )
    @test length(Graph.graph.neurons[:estates]) == 1
end