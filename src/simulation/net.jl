using GLMakie
using FileIO
using Colors
using GeometryBasics
using DataStructures
using Rotations
using LinearAlgebra: norm
# using WGLMakie
# using JSServe

import BioNet: ASACGraph, DatabaseParser, AGDSSimple, Simulation
import BioNet.ASAGraph
import BioNet.ASACGraph: AbstractSensor, id

function graphsim(
    database, username, password, port="5432";
    camera3d=true, ssao=false,
    neuronsize=Point3(1.0, 0.7, 0.1), neurongap=2.0,
    neuroncolorstart=HSV(70, 0.38, 1), neuroncolorstop=HSV(-180, 0.38, 1),
    paddingcoeff=1.0,
    connectorcolorstart=colorant"honeydew4", connectorcolorend=colorant"honeydew2",
    tablefilter=String[]
)
    # set_theme!(resolution=(2500, 1500))
    # set_theme!(theme_black(), resolution=(3840, 2160))
    set_theme!(theme_black(), resolution=(3500, 2000))
    GLMakie.enable_SSAO[] = ssao

    pl = PointLight(Point3f(0, 0, 15), RGBf(1.0, 0.98, 0.94))
    al = AmbientLight(RGBf(0.58, 0.58, 0.58))

    # screen = GLMakie.global_gl_screen()

    parentscene = Scene(
        clear=true,
        lights=[al],
        backgroundcolor=:black,
        # ssao = Makie.SSAO(radius=250.0, blur=2, bias=1),
        # lightposition = Vec3f(0, 0, 15),
        shininess=256f0,
    )
    scenes = Dict{Symbol, Scene}()
    
    sensins = OrderedDict{Symbol, Dict}()
    magds = DatabaseParser.db2magdrs(database, username, password; port=port, tablefilter=tablefilter)
    # origin = Point(0, 0, 0)
    totalwidth = 0.0
    for (i, (name, graph)) in enumerate(magds.sensors)
        if isnothing(graph.minkey)
            println("$name is empty, skipping")
            continue
        end
        scenes[name] = Scene(parentscene, camera=parentscene.camera)
        sensins[name] = renderasagraph!(scenes[name], Point(0, 0, 0), graph)
        graphwidth = sensins[name][:size][1] + 1.25
        totalwidth += graphwidth
    end

    rclusters = Float64[]
    neuronpositions = Vector{Vector{Point3}}()
    for neurons in values(magds.neurons)
        positions, rcluster = neuronposition(
            Point(0, 0, 0), length(neurons), neuronsize, neurongap
        )
        push!(rclusters, rcluster)
        push!(neuronpositions, positions)
    end
    
    r = paddingcoeff * maximum(rclusters)
    clusterorigins = clusterpositions(r, rclusters)
    clustercolors = Colors.range(
        neuroncolorstart, stop=neuroncolorstop, length=length(rclusters) + 1
    )
    neurons = Dict{Symbol, Dict{Symbol, Dict}}()
    for (i, (cname, currentneurons)) in magds.neurons |> enumerate
        scenes[cname] = Scene(parentscene, camera=parentscene.camera)
        neurons[cname] = Dict{Symbol, Dict}()
        sign = i % 2 == 0 ? 1 : -1
        clusterorigins[i] = Point(clusterorigins[i][1], clusterorigins[i][2], 1)
        for (j, neuron) in enumerate(currentneurons)
            neurons[cname][Symbol(neuron.name)] = renderneuron(
                scenes[cname], 
                clusterorigins[i] + neuronpositions[i][j], 
                clustercolors[i], 
                neuron.activation;
                text=neuron.name
            )
        end
    end

    originx = 0
    for (name, sensin) in sensins
        graphwidth = sensin[:size][1]
        originx += graphwidth
        x, y, α = circlegeometry(2originx, 2totalwidth)
        angle = α - π / (2 - 2(graphwidth / totalwidth)) - 2(graphwidth / totalwidth)
        rotate!(scenes[name], Vec3f(0, 0, 1), angle)
        translate!(scenes[name], Vec3f(x, y, 0))
        originx += 1.25
    end

    for (cname, currentneurons) in magds.neurons
        for neuron in currentneurons
            _sourcecluster, sourceid = AGDSSimple.id(neuron)
            sourceneuron = neurons[cname][sourceid]
            sourceneurongeometry = meshgeometry(sourceneuron[:neuron])
            sourceneuroncenter = sourceneurongeometry[:center]
            for connection in neuron.out
                to = connection.to
                if to isa AbstractSensor
                    asagraph, targetvalue = id(to)
                    element = sensins[Symbol(asagraph)][:elements][Symbol(targetvalue)]
                    secondconnector = element[:connectors][:bottom][1]
                    firstconnector = determineconnector(
                        sourceneuron, sourceneuroncenter,
                        meshgeometry(secondconnector)[:center]
                    )
                    line, texts = connectneuronelement!(
                        scenes[cname], firstconnector,
                        scenes[asagraph], secondconnector, 1.0;
                        colorstart=connectorcolorstart, colorend=connectorcolorend,
                        transparent=true
                    )
                elseif to isa AGDSSimple.AbstractNeuron
                    targetcluster, targetneuronid = AGDSSimple.id(to)
                    targetneuron = neurons[targetcluster][targetneuronid]
                    targetneurongeometry = meshgeometry(targetneuron[:neuron])
                    targetneuroncenter = targetneurongeometry[:center]
                    firstconnector = determineconnector(
                        sourceneuron, sourceneuroncenter, targetneuroncenter
                    )
                    secondconnector = determineconnector(
                        targetneuron, targetneuroncenter, sourceneuroncenter
                    )
                    line, texts = connect2elements!(
                        scenes[cname], firstconnector, secondconnector, 1.0;
                        colorstart=connectorcolorstart, colorend=connectorcolorend,
                        linewidth=0.38, transparent=true
                    )
                end
            end
        end
    end

    camera = if camera3d cam3d!(parentscene) else cam2d!(parentscene) end
    center!(parentscene)
    camera.attributes.reset[] = Keyboard.m
    # camc = cameracontrols(parentscene)
    # update_cam!(parentscene, camc, Vec3f(0, 5, 5), Vec3f(0.0, 0, 0))
    
    parentscene
end

function clusterpositions(r::Number, rclusters::Vector{Float64})
    noclusters = length(rclusters)
    if noclusters == 1
        return Point[Point(0, 0, 0)]
    end
    angle = Angle2d(2π / noclusters)
    points2d = Point[Point(r - rclusters[1] / 2, 0)]
    points3d = Point[Point(r - rclusters[1] / 2, 0, 0)]
    for i in 2:(noclusters)
        rposition = r - rclusters[i] / 2
        newvec = last(points2d) / norm(last(points2d)) * rposition
        push!(points2d, Point(round.(angle \ newvec; digits=5)))
        push!(points3d, Point(last(points2d)..., 0))
    end
    points3d
end