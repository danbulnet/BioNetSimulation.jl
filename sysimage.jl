using PackageCompiler
using Pkg

rootpath = @__DIR__

Pkg.activate(rootpath)
Pkg.instantiate()
Pkg.precompile()

rootdir = @__DIR__

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