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
if !isfile(precompilationsfile)
    precompilationsfile = nothing
end

create_sysimage(
    ["HomefyAI", "BioNet"];
    sysimage_path=joinpath(rootdir, "sysimage/HomefyAI.so"),
    incremental=true, 
    precompile_execution_file=precompilationsfile,
    # filter_stdlibs=true,
    # include_transitive_dependencies=true
)

exit()