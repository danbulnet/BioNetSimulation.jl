using Pkg

rootpath = @__DIR__

Pkg.activate(rootpath)
Pkg.instantiate()
Pkg.precompile()

using PackageCompiler

rootdir = @__DIR__

precompilationsfile = joinpath(rootdir, "sysimage/precompilations.jl")
if !isfile(precompilationsfile)
    precompilationsfile = nothing
end

create_sysimage(
    ["BioNet"];
    sysimage_path=joinpath(rootdir, "sysimage/BioNet.so"),
    incremental=true, 
    precompile_execution_file=precompilationsfile,
    # filter_stdlibs=true,
    # include_transitive_dependencies=true
)

exit()