using GLMakie

# using WGLMakie
# using JSServe

# Page(exportable=true, offline=true)

Base.@kwdef mutable struct Lorenz
    dt::Float64 = 0.01
    σ::Float64 = 10
    ρ::Float64 = 28
    β::Float64 = 8/3
    x::Float64 = 1
    y::Float64 = 1
    z::Float64 = 1
end

function step!(l::Lorenz)
    dx = l.σ * (l.y - l.x)
    dy = l.x * (l.ρ - l.z) - l.y
    dz = l.x * l.y - l.β * l.z
    l.x += l.dt * dx
    l.y += l.dt * dy
    l.z += l.dt * dz
    Point3f(l.x, l.y, l.z)
end

function draw()
    attractor = Lorenz()

    points = Observable(Point3f[])
    colors = Observable(Int[])

    set_theme!(theme_black())

    fig, ax, l = lines(points, color = colors,
        colormap = :inferno, transparency = true,
        axis = (; type = Axis3, protrusions = (0, 0, 0, 0),
            viewmode = :fit, limits = (-30, 30, -30, 30, 0, 50)))

    record(fig, "lorenz.mp4", 1:120) do frame
        for i in 1:50
            push!(points[], step!(attractor))
            push!(colors[], frame)
        end
        ax.azimuth[] = 1.7pi + 0.3 * sin(2pi * frame / 120)
        notify.((points, colors))
        l.colorrange = (0, frame)
    end
end
    
function map3dv1()
    x = 1:10
    y = 1:10
    z = 1:10
    f(x,y,z) = x^2 + y^2 + z^2
    vol = [f(ix,iy,iz) for ix in x, iy in y, iz in z]
    fig, ax, _ = volume(
        x, y, z, 
        vol, 
        colormap = :plasma, colorrange = (minimum(vol), maximum(vol)),
        figure = (; resolution = (3000, 2000)),  
        axis=(;
            type=Axis3, 
            perspectiveness = 0.5, 
            azimuth = 7.19, 
            elevation = 0.57,  
            aspect = (1,1,1)
        )
    )
    fig
end

function map3dv2()
    xs = -10:0.1:10
    ys = -10:0.1:10
    zs = [2 * (cos(x) * cos(y)) * (.1 + exp(-(x^2 + y^2 + 1) / 25)) - 0.01x^2 - 0.008y^2 - 0.1x - 0.08y for x in xs, y in ys]
    zsn = [0.3 * (sin(x*y) + 2cos(y) + sin(x) - 0.01x^2 - 0.008y^2 - 0.3x - 0.2y) for x in xs, y in ys]

    fig, ax, pl = surface(
        xs, ys, zsn, 
        colormap = [:black, :white],
        # Light comes from (0, 0, 15), i.e the sphere
        axis = (
            scenekw = (
                # Light comes from (0, 0, 15), i.e the sphere
                lightposition = Vec3f(0, 0, 15),
                # base light of the plot only illuminates red colors
                ambient = RGBf(0.58, 0.58, 0.18)
            ),
        ),
        # light from source (sphere) illuminates yellow colors
        diffuse = Vec3f(0.4, 0.4, 0),
        # reflections illuminate blue colors
        specular = Vec3f(0, 0, 1.0),
        # Reflections are sharp
        shininess = 128f0,
        figure = (resolution=(3000, 2000),)
    )
    surface!(xs, ys, zs .+ 10, colormap = [:green, :yellow],)
    mesh!(ax, Sphere(Point3f(0, 0, 15), 1f0), color=RGBf(1, 0.7, 0.3))

    fig
    # app = JSServe.App() do session
    #     light_rotation = JSServe.Slider(1:360)
    #     shininess = JSServe.Slider(1:128)

    #     pointlight = ax.scene.lights[1]
    #     ambient = ax.scene.lights[2]
    #     on(shininess) do value
    #         pl.shininess = value
    #     end
    #     on(light_rotation) do degree
    #         r = deg2rad(degree)
    #         pointlight.position[] = Vec3f(sin(r)*10, cos(r)*10, 15)
    #     end
    #     JSServe.record_states(session, DOM.div(light_rotation, shininess, fig))
    # end
    # app
end

function map3dv3()
    fig = Figure(resolution = (3000, 2000))
    ax1 = LScene(fig[1, 1], show_axis=false)
    p1 = mesh!(ax1, Rect2f(-2, -2, 4, 4), color = :red, shading = false, transparency = true)
    p2 = mesh!(ax1, Rect2f(-2, -2, 4, 4), color = :blue, shading = false, transparency = true)
    p3 = mesh!(ax1, Rect2f(-2, -2, 4, 4), color = :red, shading = false, transparency = true)
    for (dz, p) in zip((-1, 0, 1), (p1, p2, p3))
        translate!(p, 0, 0, dz)
    end

    ax2 = LScene(fig[1, 2], show_axis=false)
    p1 = mesh!(ax2, Rect2f(-1.5, -1, 3, 3), color = (:red, 0.5), shading = false, transparency=true)
    p2 = mesh!(ax2, Rect2f(-1.5, -2, 3, 3), color = (:blue, 0.5), shading = false, transparency=true)
    rotate!(p1, Vec3f(0, 1, 0), 0.1)
    rotate!(p2, Vec3f(0, 1, 0), -0.1)
    fig
end

function map_v4()
    f = Figure()

    r = LinRange(-1, 1, 100)
    cube = [(x.^2 + y.^2 + z.^2) for x = r, y = r, z = r]
    cube_with_holes = cube .* (cube .> 1.4)

    viewmodes = [:fitzoom, :fit, :stretch]

    for (j, viewmode) in enumerate(viewmodes)
        for (i, azimuth) in enumerate([1.1, 1.275, 1.45] .* pi)
            ax = Axis3(f[i, j], aspect = :data,
                azimuth = azimuth,
                viewmode = viewmode, title = "$viewmode")
            hidedecorations!(ax)
            ax.protrusions = (0, 0, 0, 20)
            volume!(cube_with_holes, algorithm = :iso, isorange = 0.05, isovalue = 1.7)
        end
    end

    f
end


function menuexample()
    fig = Figure()

    menu = Menu(fig, options = ["viridis", "heat", "blues"])

    funcs = [sqrt, x->x^2, sin, cos]

    menu2 = Menu(fig, options = zip(["Square Root", "Square", "Sine", "Cosine"], funcs))

    fig[1, 1] = vgrid!(
        Label(fig, "Colormap", width = nothing),
        menu,
        Label(fig, "Function", width = nothing),
        menu2;
        tellheight = false, width = 200)

    ax = Axis(fig[1, 2])

    func = Observable{Any}(funcs[1])

    ys = lift(func) do f
        f.(0:0.3:10)
    end
    scat = scatter!(ax, ys, markersize = 10px, color = ys)

    cb = Colorbar(fig[1, 3], scat)

    on(menu.selection) do s
        scat.colormap = s
    end

    on(menu2.selection) do s
        func[] = s
        autolimits!(ax)
    end

    menu2.is_open = true

    fig
end

function modelviewer()
    set_theme!(theme_black())

    f = Figure()

    # neuronpath = joinpath(pwd(), "asset/stl/phix174surface25_fixed.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/westnile_fixed.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/DeathStar_I_-_Death_Star_I_-_Bottom-1.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/octahedron.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/2in_cube.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/cat_ball.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/CubitruncatedCuboctahedron-solid.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/dengue_fixed.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/dodecahedron_2in.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/Example_dodecahedron_Parametric_Lamp_Shade.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/Funky_Fyyran.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/PolyhedronCCsubdivisionDemoico.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/BiscribedDualSnubTruncatedIcosahedron-openface.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/OctagonalIrisToroid-solid.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/IsohedralToroid24-solid.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/BiscribedDualSnubTruncatedIcosahedron-solid.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/GuardiansGalaxyInfinityOrbInteriorSideB.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/1500_Megawatt_Aperture_Science_Heavy_Duty_Super-Colliding_Super_Button_BASE.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/The_HIVE_Custom_Fit_with_3_Holes.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/Tetrahemihexahedron-solid_1.stl")
    neuronpath = joinpath(pwd(), "asset/stl/stackable_hex.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/SmallHexagonalHexecontahedron-solid.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/GreatDodecacronicHexecontahedron-solid.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/RegularTetragonalToroid18B2-solid.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/GuardiansGalaxyInfinityOrbExteriorNEW.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/GuardiansGalaxyInfinityOrbInteriorSideA.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/Icosahedron_2in.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/nudo_chaser_tetraocta_24mm.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/nudo_tetraocta_estrella_24mm.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/OctagonalAntiprism-openface.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/OctagonalPrism-solid.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/RegularTetragonalToroid9-solid.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/SmallDodecahemidodecahedron-openface_1.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/TetragonalTrapezohedronAntiprismToroid-solid.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/triangular_pyramid_2in.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/adenovirussurface25_fixed.stl")
    # neuronpath = joinpath(pwd(), "asset/stl/Scroll_03_neuron.stl")
    brain = load(assetpath(neuronpath))

    aspects = [:data, (1, 1, 1), (1, 2, 3), (3, 2, 1)]

    for (i, aspect) in enumerate(aspects)
        ax = Axis3(f[fldmod1(i, 2)...], aspect = aspect, title = "$aspect")
        mesh!(brain, color = :bisque)
    end

    f
end

function antmodel()
    set_theme!(theme_black())

    f = Figure()

    neuronpath = joinpath(pwd(), "d:/Projekty/AntSim/assets/ant.stl")
    brain = load(assetpath(neuronpath))

    aspects = [:data, (1, 1, 1), (1, 2, 3), (3, 2, 1)]

    for (i, aspect) in enumerate(aspects)
        ax = Axis3(f[fldmod1(i, 2)...], aspect = aspect, title = "$aspect")
        mesh!(brain, color = :bisque)
    end

    f
end

function graph()
    g = smallgraph(:cubical)
    elabels_shift = [0.5 for i in 1:ne(g)]
    elabels_shift[[2,7,8,9]] .= 0.3
    elabels_shift[10] = 0.25
    graphplot(
        g; 
        layout=Spring(dim=3, seed=5),
        elabels="Edge ".*repr.(1:ne(g)),
        elabels_textsize=12,
        elabels_opposite=[3,5,7,8,12],
        elabels_shift,
        elabels_distance=3,
        arrow_show=true,
        arrow_shift=0.9,
        arrow_size=15,
        node_color=:blue
    )
end

function graph2()
    g = watts_strogatz(1000, 5, 0.03; seed=5)
    layout = Spectral(dim=3)
    f, ax, p = graphplot(g, layout=layout, node_size=0.0, edge_width=1.0)
end

function rotatedtext()
    f = Figure()
    LScene(f[1, 1])

    text!(
        fill("Makie", 7),
        rotation = [i / 7 * 1.5pi for i in 1:7],
        position = [Point3f(0, 0, i/2) for i in 1:7],
        color = [cgrad(:viridis)[x] for x in LinRange(0, 1, 7)],
        align = (:left, :baseline),
        textsize = 100,
        space = :data
    )

    f
end