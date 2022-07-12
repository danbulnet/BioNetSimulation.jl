module Graph

import BioNet: ASACGraph, MAGDSParser, MAGDSSimple, Simulation

include("db2sensors.jl")
include("../data/questions.jl")

"""
    Runs app which visualize a given knowledge graph
"""
function show()
    BioNet.Simulation.graphsim(
        "homefyprod", "root", "szic8805", 3306;
        camera3d=true, rowlimit=5, sensorfilter=homefyall, tablefilter=homefytabs
    )
end

end