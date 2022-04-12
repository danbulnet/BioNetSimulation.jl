(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using App
push!(Base.modules_warned_for, Base.PkgId(App))
App.main()
