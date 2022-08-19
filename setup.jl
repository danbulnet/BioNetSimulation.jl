using Pkg

rootpath = @__DIR__
bionetpath = joinpath(rootpath, "bionet")

push!(LOAD_PATH, bionetpath)

Pkg.activate(bionetpath)
Pkg.instantiate()
Pkg.precompile()

Pkg.activate(rootpath)
Pkg.develop(path=bionetpath)
Pkg.instantiate()
Pkg.precompile()

exit()