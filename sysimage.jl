using Pkg

rootdir = @__DIR__

bionetpath = joinpath(rootdir, "bionet")
push!(LOAD_PATH, bionetpath)

Pkg.activate(bionetpath)
Pkg.instantiate()
Pkg.precompile()

Pkg.activate(rootdir)
Pkg.develop(path=bionetpath)
Pkg.instantiate()
Pkg.precompile()

using PackageCompiler

precompilationsfile = joinpath(rootdir, "sysimage/precompilations.jl")
if isfile(precompilationsfile)
    create_sysimage(
        ["BioNetSimulation", "BioNet"];
        sysimage_path=joinpath(rootdir, "sysimage/BioNetSimulation.so"),
        incremental=true, 
        precompile_execution_file=precompilationsfile
    )
else
    create_sysimage(
        ["BioNetSimulation", "BioNet"];
        sysimage_path=joinpath(rootdir, "sysimage/BioNetSimulation.so"),
        incremental=true
    )
end

exit()