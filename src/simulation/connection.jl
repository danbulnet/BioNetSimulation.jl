using GLMakie
using Colors
import Makie.Mesh

using BioNetSimulation.Simulation
import BioNet.ASAGraph
import BioNet.ASACGraph
import BioNet.ASACGraph: -

function connectelements!(
    scene, elements, renderedelements;
    colorstart=colorant"gray10", colorend=colorant"gray20"
)
    range = Float64(elements[end].key - elements[1].key)
    @assert(length(elements) == length(renderedelements))
    connections = Dict{Symbol,Dict{Symbol,Any}}()
    for i in length(elements):-1:2

        weight = if eltype(elements) <: ASAGraph.Element
            ASAGraph.weight(elements[i-1], elements[i], range)
        elseif eltype(elements) <: ASACGraph.Element
            elements[i-1].next.weight
        end
        keyleft = Symbol(elements[i-1].key)
        keyright = Symbol(elements[i].key)
        firstconnector = renderedelements[keyleft][:connectors][:right][1]
        secondconnector = renderedelements[keyright][:connectors][:left][1]
        line, texts = connect2elements!(
            scene, firstconnector, secondconnector, weight;
            colorstart=colorstart, colorend=colorend
        )
        connections[Symbol("$(keyleft)_$(keyright)")] = Dict()
        connections[Symbol("$(keyleft)_$(keyright)")][:line] = line
        connections[Symbol("$(keyleft)_$(keyright)")][:texts] = texts
    end
    connections
end

function connect2elements!(
    scene,
    connector1::Mesh, connector2::Mesh, weight::Float64;
    colorstart=colorant"gray10", colorend=colorant"gray20",
    transparent=true,
    linewidth=1.25,
    textcolor=:grey15, textsize=0.042
)
    ncolors = 100
    colors = Colors.range(colorstart, stop=colorend, length=ncolors)
    color = colors[max(round(Int, weight * ncolors), 1)]

    connector1.color = color
    connector2.color = color

    mesh1geometry = meshgeometry(connector1)
    mesh2geometry = meshgeometry(connector2)
    coords = hcat(mesh1geometry[:center], mesh2geometry[:center])'

    line = lines!(
        scene,
        collect(coords[:, 1]), collect(coords[:, 2]), collect(coords[:, 3]);
        linewidth=linewidth, color=color,
        transparent=transparent, fxaa=true
    )

    weighttext = string(round(weight, digits=2))
    texts = []
    for meshgeometry in [mesh1geometry, mesh2geometry]
        push!(texts, text!(
            scene,
            # "$weighttext\n\u21C4",
            "$weighttext",
            position=Point(
                meshgeometry[:center][1],
                meshgeometry[:center][2] - 2textsize * mesh1geometry[:widths][2],
                meshgeometry[:center][3] + 0.55 * mesh1geometry[:widths][3],
            ),
            color=textcolor,
            fxaa=true,
            font="Consolas",
            align=(:center, :center),
            fontsize=textsize,
            markerspace=:data
        ))
    end
    line, Tuple(texts)
end

function connectneuronelement!(
    neuronscene::Scene, neuronconnector::Mesh,
    elementscene::Scene, elementconnector::Mesh, weight::Float64;
    colorstart=colorant"gray10", colorend=colorant"gray20",
    transparent=true,
    linewidth=0.38,
    textcolor=:grey95, textsize=0.042
)
    ncolors = 100
    colors = Colors.range(colorstart, stop=colorend, length=ncolors)
    color = colors[max(round(Int, weight * ncolors), 1)]

    neuronconnector.color = color
    elementconnector.color = color

    neurongeometry = meshgeometry(neuronconnector)
    elementgeometry = meshgeometry(elementconnector)
    rawelementgeometry = meshgeometry(elementconnector; transformations=false)

    coords = hcat(neurongeometry[:center], elementgeometry[:center])'

    line = lines!(
        neuronscene, collect(coords[:, 1]), collect(coords[:, 2]), collect(coords[:, 3]);
        linewidth=linewidth, color=color,
        transparent=transparent, fxaa=true
    )

    weighttext = string(round(weight, digits=2))
    texts = []
    geoscenes = [(neuronscene, neurongeometry), (elementscene, rawelementgeometry)]
    for (scene, meshgeometry) in geoscenes
        push!(texts, text!(
            scene,
            # "$weighttext\n\u21C4",
            "$weighttext",
            position=Point(
                meshgeometry[:center][1],
                meshgeometry[:center][2] - 2textsize * meshgeometry[:widths][2],
                meshgeometry[:center][3] + 0.55 * meshgeometry[:widths][3],
            ),
            color=textcolor,
            fxaa=true,
            font="Consolas",
            align=(:center, :center),
            fontsize=textsize,
            markerspace=:data
        ))
    end
    line, Tuple(texts)
end

function connectnodes!(
    scene, nodelevels, renderednodes, labelmesh;
    transparent=true, color=:sienna, linewidth=2.8
)
    lines = []
    for (ilevel, (level, nodes)) in enumerate(reverse(collect(nodelevels)))
        childcounter = 1
        for (inode, node) in enumerate(nodes)
            nochildren = node.size + 1
            noelements = node.size
            renderednode = renderednodes[Symbol("n$(level)p$inode")][:node]
            nodegeomentry = meshgeometry(renderednode)
            nodewidth = nodegeomentry[:widths][1]

            if ilevel > 1
                for nochild in 0:(nochildren-1)
                    start = Point(
                        nodegeomentry[:origin][1] + (nodewidth / noelements) * nochild,
                        nodegeomentry[:origin][2],
                        nodegeomentry[:center][3]
                    )
                    stopnode = renderednodes[Symbol("n$(level + 1)p$childcounter")][:node]
                    stopnodegeometry = stopnode |> meshgeometry
                    stop = Point(
                        stopnodegeometry[:center][1],
                        stopnodegeometry[:origin][2] + stopnodegeometry[:widths][2],
                        stopnodegeometry[:center][3]
                    )

                    push!(lines, connect2nodes!(
                        scene, start, stop;
                        transparent=transparent, color=color, linewidth=linewidth
                    ))

                    childcounter += 1
                end
            end

            if level == 1
                labelgeometry = labelmesh |> meshgeometry
                start = Point(
                    labelgeometry[:center][1],
                    labelgeometry[:origin][2],
                    labelgeometry[:center][3],
                )
                stop = Point(
                    nodegeomentry[:origin][1] + nodewidth / 2,
                    nodegeomentry[:origin][2] + nodegeomentry[:widths][2],
                    nodegeomentry[:center][3]
                )
                push!(lines, connect2nodes!(
                    scene, start, stop;
                    transparent=transparent, color=color, linewidth=linewidth
                ))
            end
        end
    end
    lines
end

function connect2nodes!(
    scene, first::Point3, second::Point3;
    transparent=false, color=:tan4, linewidth=2.8
)
    coords = hcat(first, second)'
    line = lines!(
        scene,
        collect(coords[:, 1]), collect(coords[:, 2]), collect(coords[:, 3]);
        linewidth=linewidth, color=color,
        transparent=transparent, fxaa=true
    )
    line
end

function determineconnector(neuron, source::Point, target::Point)
    quarter = cartesianquarter45(source, target)
    connector = if quarter == :I
        neuron[:connectors][:top][1]
    elseif quarter == :II
        neuron[:connectors][:left][1]
    elseif quarter == :III
        neuron[:connectors][:bottom][1]
    elseif quarter == :IV
        neuron[:connectors][:right][1]
    end
    connector
end