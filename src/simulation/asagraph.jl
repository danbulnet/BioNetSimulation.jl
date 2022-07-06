using GLMakie
using Colors
using DataStructures
using Decimals: Decimal
import Makie.Mesh

using BioNet.Simulation
import BioNet.ASACGraph: nodelevels as asanodelevels, elements as asaelements

function renderasagraph!(
    scene, origin, asagraph;
    elementsize=Point(0.58, 0.7, 0.1), elementstep=0.92, nodestep=0.35,
    wirecolor=RGBAf(0.2, 0.2, 0.2, 0.15),
    elementtextcolor=:grey8, nodetextcolor=:cornsilk2,
    nodetextsize=0.15,
    elementwire=false, nodewire=false,
    nodecolorstart=RGB(0.1, 0.1, 0.58), nodecolorend=RGB(0.05, 0.05, 0.38),
    elementcolorstart=colorant"royalblue1", elementcolorend=colorant"lightblue1",
    connectorcolorstart=colorant"cornsilk4", connectorcolorend=colorant"cornsilk2",
    labelcolor=:sienna, labeltextcolor=:cornsilk2, labeltextsize=0.38
)
    nodelevels = asanodelevels(asagraph)
    orderedelements = asaelements(asagraph)
    labeltext = string(asagraph.name)
    noelements = length(orderedelements)

    nodecolors = Colors.range(
        nodecolorstart, stop=nodecolorend, length=length(nodelevels) + 1
    )
    elementcolors = Colors.range(
        elementcolorstart, stop=elementcolorend, length=noelements + 1
    )
    elementcolorsdict = Dict(
        map(x -> Symbol(x[2].key) => elementcolors[x[1]], enumerate(orderedelements))
    )
    
    elementgap = elementstep - elementsize[1]
    currentorigin = origin
    
    renderednodes = OrderedDict{Symbol, Any}()
    renderedelements = SortedDict{Symbol, Any}()
    origins = SortedDict{Int, Vector{Point}}()
    _, nodesize = nodegeometry(origin, [origin], elementgap, elementsize)
    _, nodeheight, nodethick = nodesize
    
    for (ilevel, (level, nodes)) in enumerate(reverse(collect(nodelevels)))
        origins[ilevel] = Vector()
        lastnodeposition = 0
        for (inode, node) in enumerate(nodes)
            if ilevel == 1
                currentorigin = Point(
                    currentorigin[1] + nodesize[1] + nodestep,
                    currentorigin[2], 
                    currentorigin[3]
                )
            else
                lastnodeposition += 1
                firstorigin = origins[ilevel - 1][lastnodeposition]
                lastnodeposition += node.size
                lastorigin = origins[ilevel - 1][lastnodeposition]

                currentorigin = Point(
                    firstorigin[1] + (lastorigin[1] - firstorigin[1]) / 2,
                    (ilevel - 1) * (nodeheight + 1.5nodestep), 
                    origin[3]
                )
            end
            push!(origins[ilevel], currentorigin)

            elements = asaelements(node)
            elementpoints = elementpositions(
                length(elements); stepfactor=elementstep, origin=currentorigin
            )
            nodeorigin, nodesize = nodegeometry(
                currentorigin, elementpoints, elementgap, elementsize
            )
            
            renderednodes[Symbol("n$(level)p$inode")] = rendernode(
                scene, nodeorigin, nodesize, nodecolors[level], elementgap;
                transparent=false,
                text="$(node.subtreesize)", textcolor=nodetextcolor, textsize=nodetextsize,
                wire=nodewire, nodewirecolor=wirecolor
            )

            for (ielement, pos) in enumerate(elementpoints)
                elementcounter = elements[ielement].counter
                renderedelements[Symbol(elements[ielement].key)] = renderelement(
                    scene, pos, elementsize, 
                    elementcolorsdict[Symbol(elements[ielement].key)], elementcounter;
                    text=string(elements[ielement].key), textcolor=elementtextcolor,
                    transparent=false,
                    wire=elementwire, elementwirecolor=wirecolor
                )
            end
        end
    end

    topnodegeomentry = meshgeometry(renderednodes[:n1p1][:node])
    labelwidth = 0.5 + labeltextsize * elementsize[1] * length(labeltext)
    labelsize = Point(labelwidth, elementsize[2], nodethick)
    labelorigin = Point(
        topnodegeomentry[:center][1] - labelsize[1] / 2, 
        topnodegeomentry[:origin][2] + nodeheight + 2nodestep, 
        topnodegeomentry[:origin][3]
    )
    label = renderlabel(
        scene, labelorigin, labelsize, labelcolor, labeltext;
        textcolor=labeltextcolor, textsize=labeltextsize
    )

    elementconnections = connectelements!(
        scene, orderedelements, renderedelements;
        colorstart=connectorcolorstart, colorend=connectorcolorend
    )

    nodeconnections = connectnodes!(
        scene, nodelevels, renderednodes, label[:node];
    )

    lastlevel = length(nodelevels)
    firstnode = renderednodes[Symbol("n$(lastlevel)p1")]
    lastnode = renderednodes[Symbol("n$(lastlevel)p$(length(nodelevels[lastlevel]))")]
    firstnodegeometry = meshgeometry(firstnode[:node])
    lastnodegeometry = meshgeometry(lastnode[:node])
    Dict(
        :nodes => renderednodes, 
        :elements => renderedelements, 
        :elementconnections => elementconnections, 
        :nodeconnections => nodeconnections, 
        :label => label,
        :origin => origin,
        :size => Point(
            lastnodegeometry[:origin][1] + lastnodegeometry[:widths][1] - firstnodegeometry[:origin][1],
            labelorigin[2] + labelsize[2] - origin[2],
            origin[3] + 1.1 * elementsize[3] - origin[3]
        )
    )
end

"render node and elements belonging to it"
function renderunit()

end

function renderelement(
    scene, position, size, elementcolor, counter;
    transparent=false,
    text=nothing, textcolor=:grey8,
    wire=false, elementwirecolor=RGBAf(0.2, 0.2, 0.2, 0.15)
)
    element, wire = renderbox(
        scene, position, size, elementcolor;
        transparent=transparent, wire=wire, boxwirecolor=elementwirecolor
    )

    connectors = renderelementconnectors(
        scene, position, size, RGBAf(1.0, 0.97, 0.86, 0.2);
        scalefactor=0.18,
        transparent=false, wire=false, boxwirecolor=elementwirecolor
    )

    text = if !isnothing(text)
        textlen = max(length(string(text)), 3)
        flextextsize = 0.5 * size[2] / (textlen / 2.5)
        countersize = 0.3 * size[2]
        renderelementtext(
            scene, position, size, text, textcolor, flextextsize, counter, countersize
        )
    else
        nothing
    end
    Dict(
        :element => element, 
        :wire => wire, 
        :text => text, 
        :connectors => connectors
    )
end

function renderlabel(
    scene, position, size, nodecolor, text::String;
    transparent=false,
    textcolor=:grey8, textsize=0.35,
    wire=false, nodewirecolor=RGBAf(0.2, 0.2, 0.2, 0.15)
)
    node, wire = renderbox(
        scene, position, size, nodecolor;
        transparent=transparent, wire=wire, boxwirecolor=nodewirecolor
    )

    text = text!(
        scene,
        text,
        position=Point(
            position[1] + size[1] / 2,
            position[2] + size[2] / 2,
            position[3] + 1.1 * size[3],
        ),
        color=textcolor,
        fxaa=true,
        font="Consolas",
        align=(:center, :center),
        textsize=textsize,
        markerspace=:data
    )

    Dict(:node => node, :wire => wire, :text => text)
end

function rendernode(
    scene, position, size, nodecolor, elementgap;
    transparent=false,
    text=nothing, textcolor=:grey8, textsize=0.05,
    wire=false, nodewirecolor=RGBAf(0.2, 0.2, 0.2, 0.15)
)
    node, wire = renderbox(
        scene, position, size, nodecolor;
        transparent=transparent, wire=wire, boxwirecolor=nodewirecolor
    )

    text = if !isnothing(text)
        rendernodetext(
            scene, position, size, text, textcolor, textsize, elementgap
        )
    else
        nothing
    end

    Dict(:node => node, :wire => wire, :text => text)
end

function renderelementconnectors(
    scene, elementposition, elementsize, boxcolor;
    scalefactor=0.2,
    transparent=true, wire=true, boxwirecolor=RGBAf(0.2, 0.2, 0.2, 0.15)
)
    size = Point(
        scalefactor * elementsize[1], 
        scalefactor * elementsize[2], 
        0.8 * elementsize[3]
    )
    sizereversed = Point(
        scalefactor * elementsize[2], 
        scalefactor * elementsize[1], 
        0.8 * elementsize[3]
    )
    originlleft = Point(
        elementposition[1] - scalefactor * elementsize[1],
        elementposition[2] + (0.5 - scalefactor / 2) * elementsize[2],
        elementposition[3] + (scalefactor / 2) * elementsize[3]
    )
    origintop = Point(
        elementposition[1] + (0.5 - scalefactor / 2) * elementsize[1],
        elementposition[2] + elementsize[2],
        elementposition[3] + (scalefactor / 2) * elementsize[3]
    )
    originright = Point(
        elementposition[1] + elementsize[1],
        elementposition[2] + (0.5 - scalefactor / 2) * elementsize[2],
        elementposition[3] + (scalefactor / 2) * elementsize[3]
    )
    originbottom = Point(
        elementposition[1] + (0.5 - scalefactor / 2) * elementsize[1],
        elementposition[2] - scalefactor * elementsize[1],
        elementposition[3] + (scalefactor / 2) * elementsize[3]
    )

    ret = Dict()
    labels = [:left, :top, :right, :bottom]
    origins = [originlleft, origintop, originright, originbottom]
    sizes = [size, sizereversed, size, sizereversed]
    for (label, origin, size) in zip(labels, origins, sizes)
        ret[label] = renderbox(
            scene, origin, size, boxcolor;
            transparent=transparent, wire=wire, boxwirecolor=boxwirecolor
        )
    end
    ret
end

function renderelementtext(
    scene, position, size, text, textcolor, textsize, counter, countersize;
    countercolor=:gray25
)
    text!(
        scene,
        text,
        position=Point(
            position[1] + size[1] / 2,
            position[2] + size[2] / 2,
            position[3] + 1.1 * size[3],
        ),
        color=textcolor,
        fxaa=true,
        font="Consolas",
        align=(:center, :center),
        textsize=textsize,
        markerspace=:data
    )

    text!(
        scene,
        string(counter),
        position=Point(
            position[1] + size[1] / 2,
            position[2] + size[2] / 5,
            position[3] + 1.1 * size[3],
        ),
        color=countercolor,
        fxaa=true,
        font="Consolas",
        align=(:center, :center),
        textsize=countersize,
        markerspace=:data
    )
end

function rendernodetext(
    scene, position, size, text, textcolor, textsize, elementgap
)
    text!(
        scene,
        text,
        position=Point(
            position[1] + size[1] / 2,
            position[2] + size[2] - elementgap / 3,
            position[3] + 1.1 * size[3],
        ),
        color=textcolor,
        fxaa=true,
        font="Consolas",
        align=(:center, :center),
        textsize=textsize,
        markerspace=:data
    )
end

function elementpositions(n::Integer; stepfactor=0.85, origin=Point(0, 0, 0))
    positions = Point{3, Float64}[]
    for i in 0:1:(n - 1)
        push!(positions, Point(i * stepfactor + origin[1], origin[2], origin[3]))
    end
    positions
end

function nodegeometry(origin, elementpoints, elementgap, elementsize)
    nodeorigin = Point(
        origin[1] - elementgap / 2, 
        origin[2] - elementgap / 2, 
        origin[3] - elementsize[3] / 5
    )

    nodesize = Point(
        elementpoints[end][1] + elementsize[1] - elementpoints[1][1] + elementgap,
        elementgap + elementsize[2] + elementsize[2] / 4, 
        elementsize[3] / 5
    )

    nodeorigin, nodesize
end