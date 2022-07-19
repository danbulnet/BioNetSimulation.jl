module Graph

import BioNet: ASACGraph, MAGDSParser, MAGDSSimple, Simulation

include("db2sensors.jl")
include("../data/questions.jl")

"""
    Runs app which visualize a given knowledge graph
"""
function show()
    Simulation.graphsim(
        ["/mnt/d/BioNetLabs/GrapeUp/Toyota/KnowledgeModels/repo/knowledge-models-toyota/data/carscom_prepared_04_06_2022.csv"];
        camera3d=true, 
        rowlimit=10, sensorfilter=Set(Symbol[])
    )
end

end