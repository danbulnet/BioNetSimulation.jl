using GLMakie
using Colors
using DataStructures

import Makie.Mesh

using BioNet.Simulation

function renderneuron(
    scene, position, neuroncolor, activation;
    transparent=false,
    size=Point(1.0, 0.7, 0.1),
    text=nothing, textcolor=:grey8,
    wire=false, neuronwirecolor=RGBAf(0.2, 0.2, 0.2, 0.15)
)
    neuron, wire = renderbox(
        scene, position, size, neuroncolor;
        transparent=transparent, wire=wire, boxwirecolor=neuronwirecolor
    )

    connectors = renderconnectors(
        scene, position, size, RGBAf(1.0, 0.97, 0.86, 0.2);
        scalefactor=0.18,
        transparent=false, wire=false, boxwirecolor=neuronwirecolor
    )

    text = if !isnothing(text)
        textlen = max(length(string(text)), 3)
        flextextsize = 0.88 * size[2] / (textlen / 2.5)
        activationsize = 0.78 * flextextsize
        renderneurontext(
            scene, position, size, text, textcolor, flextextsize, activation, activationsize
        )
    else
        nothing
    end
    Dict(
        :neuron => neuron, 
        :wire => wire, 
        :text => text, 
        :connectors => connectors
    )
end

function renderneurontext(
    scene, position, size, text, textcolor, textsize, activation, activationsize;
    activationcolor=:gray25
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
        string(activation),
        position=Point(
            position[1] + size[1] / 2,
            position[2] + size[2] / 5,
            position[3] + 1.1 * size[3],
        ),
        color=activationcolor,
        fxaa=true,
        font="Consolas",
        align=(:center, :center),
        textsize=activationsize,
        markerspace=:data
    )
end

function neuronposition(
    origin::Point3, n::Integer, neuronsize=Point3(1.0, 0.7, 0.1), gap=2.0
)
    n == 0 && return Point3[], 0
    
    points = Point3[origin]
    n == 1 && return points, 0

    distance = max(neuronsize[1], neuronsize[2]) + gap
    r = distance
    
    currentposition = 2
    while currentposition <= n
        ltotal = circler2l(r)
        circlecount = min(ltotal ÷ distance, n - currentposition + 1)
        for i in 1:circlecount
            lcurrent = (i - 1) * ltotal / circlecount
            x, y, α = circlegeometry(lcurrent, ltotal)
            push!(points, Point3(x + origin[1], y + origin[2], origin[3]))
            # push!(points, origin)
            currentposition += 1
        end
        r += distance
    end

    points, r
end