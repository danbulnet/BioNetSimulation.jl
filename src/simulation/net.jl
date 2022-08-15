using GLMakie
using FileIO
using Colors
using GeometryBasics
using DataStructures
using Rotations
using LinearAlgebra: norm
using DataFrames
using CSV
# using WGLMakie
# using JSServe

import BioNet: ASACGraph, MAGDSParser, MAGDSSimple, Simulation
import BioNet.ASAGraph
import BioNet.ASACGraph: AbstractSensor, id

function graphsim(
    magds::MAGDSSimple.Graph;
    resolution=(3700, 2000),
    camera3d=true, ssao=false,
    neuronsize=Point3(1.0, 0.7, 0.1), neurongap=2.0,
    neuroncolorstart=HSV(70, 0.38, 1), neuroncolorstop=HSV(-180, 0.38, 1),
    toggleheight=25, paddingcoeff=1.28, 
    connectorcolorstart=colorant"honeydew4", connectorcolorend=colorant"honeydew2",
    sensorfilter::Set{Symbol}=Set{Symbol}(),
)
    set_theme!(theme_black(), resolution=resolution)
    GLMakie.enable_SSAO[] = ssao

    figure, parentscene, scenes, camera = createscenes(resolution, camera3d)

    sensorsnames = sort(map(first, collect(magds.sensors)))
    sensors, totalwidth = rendersensors(magds, sensorfilter, parentscene, scenes)

    r, neurons = renderneurons(
        magds, parentscene, scenes, neuronsize, neurongap, paddingcoeff,
        neuroncolorstart, neuroncolorstop
    )

    r2l = circler2l(r * √paddingcoeff)
    maxwidth = max(totalwidth, r2l)
    rdiff = r2l - totalwidth
    sensorpadding = rdiff > 0 ? rdiff / length(sensors) : 0
    transformsensors(sensors, sensorpadding, maxwidth, scenes)

    conncections = connecgraph(
        magds, scenes, neurons, sensors, sensorfilter, connectorcolorstart, connectorcolorend
    )

    toggles = sensortoggles(figure, resolution, sensorsnames, sensorfilter, toggleheight)
    rerenderbutton = toggles[:rerenderbutton]
    restorebutton = toggles[:restorebutton]
    on(rerenderbutton.clicks) do _
        selectedtoggles = activetoggles(toggles)
    end
    on(restorebutton.clicks; update=true) do _
        println("restorebutton.clicks")
        # delete!(first(toggles[:toggles]))
        # for sensorname in keys(sensors)
        #     delete!(figure, sensors[sensorname][:label][:node])
        # end
        restoretoggles(toggles, sensorfilter)
        # display(figure)
    end

    println(activetoggles(toggles))

    center!(parentscene.scene)
    
    figure
end

function graphsim(
    dffiles::Vector{String};
    resolution=(3700, 2000),
    camera3d=true, ssao=false,
    neuronsize=Point3(1.0, 0.7, 0.1), neurongap=2.0,
    neuroncolorstart=HSV(70, 0.38, 1), neuroncolorstop=HSV(-180, 0.38, 1),
    toggleheight=25, paddingcoeff=1.28, 
    connectorcolorstart=colorant"honeydew4", connectorcolorend=colorant"honeydew2",
    rowlimit::Int=0,
    sensorfilter::Set{Symbol}=Set(),
)
    set_theme!(theme_black(), resolution=resolution)
    GLMakie.enable_SSAO[] = ssao

    figure, parentscene, scenes, camera = createscenes(resolution, camera3d)
    
    dfs = Dict{Symbol, DataFrame}()
    for filename in dffiles
        systemseparator = Base.Filesystem.path_separator
        separator = if occursin(systemseparator, filename)
            systemseparator
        else
            "/"
        end
        name = Symbol(split(split(filename, separator)[end], ".")[1])
        dfs[name] = CSV.File(filename) |> DataFrame
    end

    magds = MAGDSParser.df2magds(dfs; rowlimit=rowlimit)

    sensorsnames = sort(map(first, collect(magds.sensors)))
    sensors, totalwidth = rendersensors(magds, sensorfilter, parentscene, scenes)

    r, neurons = renderneurons(
        magds, parentscene, scenes, neuronsize, neurongap, paddingcoeff,
        neuroncolorstart, neuroncolorstop
    )

    r2l = circler2l(r * √paddingcoeff)
    maxwidth = max(totalwidth, r2l)
    rdiff = r2l - totalwidth
    sensorpadding = rdiff > 0 ? rdiff / length(sensors) : 0
    transformsensors(sensors, sensorpadding, maxwidth, scenes)

    conncections = connecgraph(
        magds, scenes, neurons, sensors, sensorfilter, connectorcolorstart, connectorcolorend
    )

    toggles = sensortoggles(figure, resolution, sensorsnames, sensorfilter, toggleheight)
    rerenderbutton = toggles[:rerenderbutton]
    restorebutton = toggles[:restorebutton]
    on(rerenderbutton.clicks) do _
        selectedtoggles = activetoggles(toggles)
    end
    on(restorebutton.clicks; update=true) do _
        println("restorebutton.clicks")
        # delete!(first(toggles[:toggles]))
        # for sensorname in keys(sensors)
        #     delete!(figure, sensors[sensorname][:label][:node])
        # end
        restoretoggles(toggles, sensorfilter)
        # display(figure)
    end

    println(activetoggles(toggles))

    center!(parentscene.scene)
    
    figure
end

function graphsim(
    database::String, host::String, username::String, password::String, port::Int;
    resolution=(3700, 2000),
    camera3d=true, ssao=false,
    neuronsize=Point3(1.0, 0.7, 0.1), neurongap=2.0,
    neuroncolorstart=HSV(70, 0.38, 1), neuroncolorstop=HSV(-180, 0.38, 1),
    toggleheight=25, paddingcoeff=1.28, 
    connectorcolorstart=colorant"honeydew4", connectorcolorend=colorant"honeydew2",
    tablefilter=String[], rowlimit::Int=0,
    sensorfilter::Set{Symbol}=Set{Symbol}(),
    dbtype=:mariadb
)
    set_theme!(theme_black(), resolution=resolution)
    GLMakie.enable_SSAO[] = ssao

    figure, parentscene, scenes, camera = createscenes(resolution, camera3d)
    
    magdsparser = if dbtype == :mariadb
        MAGDSParser.mdb2magds
    elseif dbtype == :postgres
        MAGDSParser.pgdb2magds
    end

    magds = magdsparser(
        database, username, password;
        host=host,port=port, tablefilter=tablefilter, rowlimit=rowlimit
    )
    sensorsnames = sort(map(first, collect(magds.sensors)))
    sensors, totalwidth = rendersensors(magds, sensorfilter, parentscene, scenes)

    r, neurons = renderneurons(
        magds, parentscene, scenes, neuronsize, neurongap, paddingcoeff,
        neuroncolorstart, neuroncolorstop
    )

    r2l = circler2l(r * √paddingcoeff)
    maxwidth = max(totalwidth, r2l)
    rdiff = r2l - totalwidth
    sensorpadding = rdiff > 0 ? rdiff / length(sensors) : 0
    transformsensors(sensors, sensorpadding, maxwidth, scenes)

    conncections = connecgraph(
        magds, scenes, neurons, sensors, sensorfilter, connectorcolorstart, connectorcolorend
    )

    toggles = sensortoggles(figure, resolution, sensorsnames, sensorfilter, toggleheight)
    rerenderbutton = toggles[:rerenderbutton]
    restorebutton = toggles[:restorebutton]
    on(rerenderbutton.clicks) do _
        selectedtoggles = activetoggles(toggles)
    end
    on(restorebutton.clicks; update=true) do _
        println("restorebutton.clicks")
        # delete!(first(toggles[:toggles]))
        # for sensorname in keys(sensors)
        #     delete!(figure, sensors[sensorname][:label][:node])
        # end
        restoretoggles(toggles, sensorfilter)
        # display(figure)
    end

    println(activetoggles(toggles))

    center!(parentscene.scene)
    
    figure
end

function rendersensors(magds, sensorfilter, parentscene, scenes)
    sensors = OrderedDict{Symbol, Dict}()
    totalwidth = 0.0
    for (name, graph) in magds.sensors
        if isnothing(graph.minkey)
            println("$name is empty, skipping")
            continue
        end
        scenes[name] = Scene(parentscene.scene, camera=parentscene.scene.camera)
        if !isempty(sensorfilter) && !(name in sensorfilter)
            println("sensor $name is not included in sensorfilter, skipping")
            continue
        else
            sensors[name] = renderasagraph!(scenes[name], Point(0, 0, 0), graph)
        end
        graphwidth = sensors[name][:size][1] + 1.25
        totalwidth += graphwidth
    end
    sensors, totalwidth
end

function transformsensors(sensors, sensorpadding, maxwidth, scenes)
    originx = 0
    for (name, sensor) in sensors
        graphwidth = sensor[:size][1]
        originx += graphwidth + sensorpadding
        x, y, α = circlegeometry(2originx, 2maxwidth)
        angle = α - π / (2 - 2(graphwidth / maxwidth)) - 2(graphwidth / maxwidth)
        rotate!(scenes[name], Vec3f(0, 0, 1), angle)
        translate!(scenes[name], Vec3f(x, y, 0))
        originx += 1.25
    end
end

function sensortoggles(fig, resolution, sensornames, sensorfilter, toggleheight)
    featuretoggles = []
    featurelabels = []
    for name in sensornames
        active = name in sensorfilter
        push!(featuretoggles, Toggle(
            fig, active=active, height=toggleheight, width=2toggleheight
        ))
        push!(featurelabels, Label(
            fig, string(name), height=toggleheight, textsize=(0.8toggleheight - 2)
        ))
    end
    rerenderbutton = Button(
        fig, strokewidth=3,
        label="rerender", textsize=0.8toggleheight, 
        labelcolor=:grey12, labelcolor_hover=:grey12, labelcolor_active=:grey20,
        buttoncolor=:springgreen3, buttoncolor_hover=:springgreen2, 
        buttoncolor_active=:springgreen1,
        cornerradius=8, font="Consolas"
    )
    push!(featuretoggles, rerenderbutton)

    restorebutton = Button(
        fig, strokewidth=3, 
        label="restore", textsize=0.8toggleheight, 
        labelcolor=:grey12, labelcolor_hover=:grey12, labelcolor_active=:grey20,
        buttoncolor=:ivory3, buttoncolor_hover=:ivory2, buttoncolor_active=:ivory1,
        cornerradius=8, font="Consolas"
    )
    push!(featurelabels, restorebutton)

    togglelen = length(featuretoggles)
    toggles4row = resolution[2] ÷ (2 * first(featuretoggles).height.val) - 2
    rows4toggle = ceil(Int, togglelen / toggles4row)

    for colindex in 1:(rows4toggle)
        startindex = 1 + toggles4row * (colindex - 1)
        endindex = min(startindex + toggles4row - 1, togglelen)
        fig[1, colindex + 1] = grid!(hcat(
            featuretoggles[startindex:endindex], featurelabels[startindex:endindex]
        ), tellheight = false)
    end

    return Dict(
        :toggles => featuretoggles[1:end - 1],
        :labels => featurelabels[1: end - 1],
        :rerenderbutton => rerenderbutton,
        :restorebutton => restorebutton,
    )
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

function renderneurons(
    magds, parentscene, scenes, neuronsize, neurongap, paddingcoeff,
    neuroncolorstart, neuroncolorstop
)
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
        scenes[cname] = Scene(parentscene.scene, camera=parentscene.scene.camera)
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

    r, neurons
end

function createscenes(resolution, camera3d)
    figure = Figure()
    rowsize!(figure.layout, 1, Fixed(resolution[2]))

    # pl = PointLight(Point3f(0, 0, 15), RGBf(1.0, 0.98, 0.94))
    al = AmbientLight(RGBf(0.58, 0.58, 0.58))

    parentscene = LScene(
        figure[:, 1],
        show_axis=false,
        scenekw = (
            clear=true,
            lights=[al],
            backgroundcolor=:black,
            # ssao = Makie.SSAO(radius=250.0, blur=2, bias=1),
            # lightposition = Vec3f(0, 0, 15),
            shininess=256f0
        )
    )
    scenes = Dict{Symbol, Scene}()

    camera = if camera3d 
        camera = cam3d!(parentscene.scene)
        camera.attributes.reset[] = Keyboard.m
        camera
    else 
        cam2d!(parentscene.scene)
    end
    # camc = cameracontrols(parentscene.scene)
    # update_cam!(parentscene.scene, camc, Vec3f(0, 5, 5), Vec3f(0.0, 0, 0))

    figure, parentscene, scenes, camera
end

function connecgraph(
    magds, scenes, neurons, sensors, sensorfilter, 
    connectorcolorstart, connectorcolorend;
    linewidth=0.38
)
    conncections = Dict{Symbol, Dict}()
    for (cname, currentneurons) in magds.neurons
        for neuron in currentneurons
            _sourcecluster, sourceid = MAGDSSimple.id(neuron)
            sourceneuron = neurons[cname][sourceid]
            sourceneurongeometry = meshgeometry(sourceneuron[:neuron])
            sourceneuroncenter = sourceneurongeometry[:center]
            for connection in neuron.out
                to = connection.to
                if to isa AbstractSensor
                    asagraph, targetvalue = id(to)
                    if !isempty(sensorfilter) && !(asagraph in sensorfilter)
                        continue
                    end
                    element = sensors[Symbol(asagraph)][:elements][Symbol(targetvalue)]
                    secondconnector = element[:connectors][:bottom][1]
                    firstconnector = determineconnector(
                        sourceneuron, sourceneuroncenter,
                        meshgeometry(secondconnector)[:center]
                    )
                    line, texts = connectneuronelement!(
                        scenes[cname], firstconnector,
                        scenes[asagraph], secondconnector, 1.0;
                        colorstart=connectorcolorstart, colorend=connectorcolorend,
                        linewidth=linewidth
                    )
                    connectionname = Symbol("$(sourceid)_$(asagraph)_$targetvalue")
                    conncections[connectionname] = Dict(:line => line, :texts => texts)
                elseif to isa MAGDSSimple.AbstractNeuron
                    targetcluster, targetneuronid = MAGDSSimple.id(to)
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
                        linewidth=linewidth
                    )
                    connectionname = Symbol("$(sourceid)_$(targetneuronid)")
                    conncections[connectionname] = Dict(:line => line, :texts => texts)
                end
            end
        end
    end
    conncections
end

function activetoggles(toggles)
    ret = Symbol[]
    labels = toggles[:labels]
    for (i, toggle) in enumerate(toggles[:toggles])
        if toggle.active.val
            push!(ret, Symbol(labels[i].text.val))
        end
    end
    ret
end

function restoretoggles(toggles, sensorfilter)
    labels = toggles[:labels]
    for (i, toggle) in enumerate(toggles[:toggles])
        toggle.active[] = labels[i] in sensorfilter
    end
end