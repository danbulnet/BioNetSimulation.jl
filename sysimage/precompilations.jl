using HomefyAI
using BioNet
using HomefyAI.Graph

Simulation.graphsim(
    ["/mnt/d/BioNetLabs/GrapeUp/Toyota/KnowledgeModels/repo/knowledge-models-toyota/data/carscom_prepared_04_06_2022.csv"];
    camera3d=true, 
    rowlimit=10, sensorfilter=Set(Symbol[])
)

homefyclients = Set([                                                                              
    :email,                                                                                        
    :browser_language,                                                                             
    :browser_name,                                                                                 
    :browser_platform,                                                                             
    :profiling_data                                                                                
])

Simulation.graphsim(
    "homefyprod",
    "host", 
    "root", 
    "szic8805", 
    3306; 
    camera3d=true, 
    rowlimit=1,
    tablefilter=String["homefy_clients"], 
    sensorfilter=homefyclients, 
    dbtype=:mariadb
)

Simulation.graphsim(
    "homefyprod",
    "host",
    "postgres",
    "szic8805",
    5433; camera3d=true,
    rowlimit=1,
    tablefilter=String["homefy_clients"],
    sensorfilter=homefyclients,
    dbtype=:postgres
)

Graph.show()