using GLMakie

function renderbox(
    scene, position, size, boxcolor;
    transparent=true, wire=true, boxwirecolor=RGBAf(0.2, 0.2, 0.2, 0.15)
)
    box = mesh!(
        scene,
        Rect3f(position, size),
        color=boxcolor,
        transparency=transparent,
        fxaa=true,
        ssao=false,
        shading=true
    )
    wire = wireframe!(
        scene,
        Rect3f(position, size),
        visible=wire,
        color=boxwirecolor,
        transparency=transparent,
        fxaa=true,
        ssao=true
    )
    box, wire
end

function rendersphere(
    scene, position, size, spherecolor;
    transparent=true, wire=true, spherewirecolor=RGBAf(0.2, 0.2, 0.2, 0.15)
)
    sphere = mesh!(
        scene,
        Sphere(position, size),
        color=spherecolor,
        transparency=transparent,
        fxaa=true,
        ssao=false,
        shading=true
    )
    wire = wireframe!(
        scene,
        Sphere(position, size),
        visible=wire,
        color=spherewirecolor,
        transparency=transparent,
        fxaa=true,
        ssao=true
    )
    sphere, wire
end

function renderconnectors(
    scene, elementposition, elementsize, boxcolor;
    scalefactor=0.2,
    transparent=true, wire=true, boxwirecolor=RGBAf(0.2, 0.2, 0.2, 0.15)
)
    commonsize = scalefactor * min(elementsize[1], elementsize[2])
    size = Point(commonsize, commonsize, 0.8 * elementsize[3])
    sizereversed = Point(commonsize, commonsize, 0.8 * elementsize[3])
    originlleft = Point(
        elementposition[1] - scalefactor * elementsize[2],
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
        elementposition[2] - scalefactor * elementsize[2],
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