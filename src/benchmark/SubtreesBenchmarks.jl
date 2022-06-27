module SubtreesBenchmarks

export insertrand, medianrand

using ..Common
# using ..AvbTreeCounting
# using ..AvbTree
# using ..AvbTreeRaw
using ..ASAGraph
using ..ASAGraphSimple
using ..ASACGraph
using ..ASACGraphSimple

using DataStructures
using DataFrames
using GLMakie
using LinearAlgebra

function memclean()
    GC.enable(true)
    GC.gc()
    GC.enable(false)
end

function dumbtest()
    GC.enable(false)
    print("asagraphs ")
    @time begin
        tree = AvbTree.Tree{Int}(:test, numerical)
        for i = 1:1_000_000
            AvbTree.insert!(tree, rand(1:1_000_000))
        end
    end
    memclean()
end

function oneinsert(
    name::String,
    creation::Function, 
    insertion::Function,
    repeats::UInt8,
    nlimit::UInt64,
    range::Int64
)
    print(name, " ")
    time = @elapsed begin
        for i in 1:repeats
            tree = creation()
            for i = 1:nlimit
                insertion(tree, rand(1:range))
            end
        end
    end
    memclean()
    time
end

function insertrand(;nlimit::UInt64 = UInt64(1_000_000), repeats::UInt8 = UInt8(1))
    GC.enable(false)
    
    # percents = collect(0.0:10.0:90.0)
    percents = Float64[]
    push!(percents, [90, 99, 99.9, 99.99, 99.999]...)

    times = zeros(7, length(percents))

    for (index, p) in enumerate(percents)
        range = r  = round(Int64, nlimit * (100 - p) / 100 )

        print("$p% of duplicates: ")

        times[1, index] = oneinsert(
            "asagraph",
            () -> ASAGraph.Graph{Int}(:test, numerical), 
            (graph, range) -> ASAGraph.insert!(graph, rand(1:range)),
            repeats,
            nlimit,
            range
        )

        times[2, index] = oneinsert(
            "asacgraph",
            () -> ASACGraph.Graph{Int}(:test, numerical), 
            (graph, range) -> ASACGraph.insert!(graph, rand(1:range)),
            repeats,
            nlimit,
            range
        )

        times[3, index] = oneinsert(
            "asagraphsimple",
            () -> ASAGraphSimple.Graph{Int}(:test, numerical), 
            (graph, range) -> ASAGraphSimple.insert!(graph, rand(1:range)),
            repeats,
            nlimit,
            range
        )

        times[4, index] = oneinsert(
            "asacgraphsimple",
            () -> ASACGraphSimple.Graph{Int}(:test, numerical), 
            (graph, range) -> ASACGraphSimple.insert!(graph, rand(1:range)),
            repeats,
            nlimit,
            range
        )

        times[5, index] = oneinsert(
            "rbtree",
            () -> RBTree{Int}(), 
            (tree, range) -> push!(tree, rand(1:range)),
            repeats,
            nlimit,
            range
        )

        times[6, index] = oneinsert(
            "avltree",
            () -> AVLTree{Int}(), 
            (tree, range) -> push!(tree, rand(1:range)),
            repeats,
            nlimit,
            range
        )

        times[7, index] = oneinsert(
            "splaytree",
            () -> SplayTree{Int}(), 
            (tree, range) -> push!(tree, rand(1:range)),
            repeats,
            nlimit,
            range
        )

        println()
    end

    GC.enable(true)
    
    timesdf = DataFrame([
        "percents" => percents,
        "asagraph" => times[1, :],
        "asacgraph" => times[2, :],
        "asagraphsimple" => times[3, :],
        "asacgraphsimple" => times[4, :],
        "rbtree" => times[5, :],
        "avltree" => times[6, :],
        "splaytree" => times[7, :],
    ]...)

    println("$(typeof(vec(times[1, :]))) $(vec(times[1, :]))")

    f = Figure()
    ax = f[1, 1] = Axis(f)

    labels = names(timesdf)[2:end]
    percentno = 1:length(percents)
    dsno = 1:length(labels)

    for i in dsno
        lines!(
            percentno,
            times[i, :],
            label = labels[i],
            linestyle = [0.5, 1.0, 1.5, 2.5], 
            linewidth = 3
        )
    end

    f[1, 2] = Legend(f, ax, framevisible = false)

    f

    (timesdf, times)
end

function medianrand(;nlimit::Int = 1_000_000, repeats::Int = 10)
    GC.enable(false)

    percents = collect(0.0:10.0:90.0)
    push!(percents, [95, 99, 99.9, 99.99, 99.999]...)

    times = zeros(2, length(percents))

    for (index, p) in enumerate(percents)
        r  = round(Int64, nlimit * (100 - p) / 100 )

        print("$p% of duplicates: ")

        print("asagraphs ")
        let
            tree = AvbTree.Tree{Int}(:test, numerical)
            for i = 1:nlimit
                AvbTree.insert!(tree, rand(1:r))
            end

            times[1, index] = @elapsed begin
                for i in 1:repeats
                    median = AvbTree.medianel(tree)
                end
            end
        end
        memclean()

        print("asacgraphs ")
        let
            tree = AvbTreeCounting.Tree{Int}(:test, numerical)
            for i = 1:nlimit
                AvbTreeCounting.insert!(tree, rand(1:r))
            end
            times[2, index] = @elapsed begin
                for i in 1:repeats
                    median = AvbTreeCounting.mediansub(tree)
                end
            end
        end
        memclean()

        println()
    end

    GC.enable(true)
    
    timesdf = DataFrame(
        "percents" => percents,
        "asagraphs" => times[1, :],
        "asacgraphs" => times[2, :]
    )

    (timesdf, times)
end

end # module