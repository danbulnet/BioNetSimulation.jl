(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using HomefyAI
push!(Base.modules_warned_for, Base.PkgId(HomefyAI))
HomefyAI.main()
