module ASACGraph

using DataStructures
import Base: keytype, insert!, range

include("Node.jl")

export range, search, insert!, printgraph, listelements, deactivate!, winner, weightedmean, test

mutable struct Graph{Key} <: AbstractSensoryField
    name::String
    root::Node{Key}
    datatype::DataScale
    
    height::Int
    elements::Int
    maxkey::Opt{Key}
    minkey::Opt{Key}

    function Graph{Key}(name::String, datatype::DataScale) where Key
        new(name,
            Node{Key}(true),
            datatype,
            0,
            0,
            nothing,
            nothing
        )
    end
end

keytype(::Graph{Key}) where Key = Key

function range(graph::Graph{Key})::Float64 where Key <: Number
    if !isnothing(graph.minkey) && !isnothing(graph.maxkey)
        return graph.maxkey - graph.minkey
    end
    0
end

function range(graph::Graph{Key})::Float64 where Key <: String 
    graph.elements
end

function range(graph::Graph{Key})::Float64 where Key <: Dates.DateTime 
    if !isnothing(graph.minkey) && !isnothing(graph.maxkey)
        return Dates.value(graph.maxkey) - Dates.value(graph.minkey)
    end
    0
end

function search(graph::Graph{Key}, key::Key)::Opt{Element{Key}} where Key
    node = graph.root

    if node.size == 0
        return nothing
    end

    if (graph.maxkey - key > key - graph.minkey)
        while !isnothing(node)
            index = 1
            while index <= node.size && key > node.keys[index]
                index += 1
            end
            if index <= node.size && key == node.keys[index]
                return node.elements[index]
            elseif node.isleaf
                return nothing
            else
                node = node.children[index]
            end
        end
    else
        while !isnothing(node)
            index = node.size
            while index > 1 && key < node.keys[index]
                index -= 1
            end
            if key > node.keys[index]
                node = node.children[index+1]
            elseif key == node.keys[index]
                return node.elements[index]
            elseif node.isleaf
                return nothing
            else
                node = node.children[index]
            end
        end
    end
end

function insert!(graph::Graph{Key}, key::Key)::Element{Key} where Key
    node = graph.root

    if graph.root.size == MAX_ELEMENTS
        oldroot = graph.root
        graph.root = Node{Key}()
        graph.height += 1
        graph.root.children[1] = oldroot
        splitchild!(graph.root, 1)
    end

    node = graph.root

    left = true
    if !isnothing(graph.maxkey) && !isnothing(graph.minkey)
        left = graph.maxkey - key > key - graph.minkey
    end
    while true
        if left
            # left search
            index = 1
            while index <= node.size && key > node.keys[index]
                index += 1
            end
            if index <= node.size && key == node.keys[index]
                node.elements[index].counter += 1
                node.subtreesize += 1
                return node.elements[index]
            end
        else
            # right search
            index = node.size
            while index > 1 && key < node.keys[index]
                index -= 1
            end
            if key > node.keys[index]
                index += 1
            elseif key == node.keys[index]
                node.elements[index].counter += 1
                node.subtreesize += 1
                return node.elements[index]
            end
        end

        if node.isleaf
            index = node.size
            while index >= 1 && key < node.keys[index]
                node.keys[index + 1] = node.keys[index]
                node.elements[index + 1] = node.elements[index]
                index -= 1
            end
            index += 1

            node.keys[index] = key
            node.elements[index] = Element{Key}(key, graph)
            graph.elements += 1
            ret = node.elements[index]

            if isnothing(graph.minkey)
                graph.minkey = graph.maxkey = key
            elseif key < graph.minkey
                graph.minkey = key
            elseif key > graph.maxkey
                graph.maxkey = key
            end

            next::Opt{Element{Key}} = nothing
            prev::Opt{Element{Key}} = nothing
            if node.size >= 1
                if index == 1
                    next = node.elements[2]
                    prev = isnothing(next.prev) ? nothing : next.prev.element
                elseif index > 1
                    prev = node.elements[index - 1]
                    next = isnothing(prev.next) ? nothing : prev.next.element
                end
            end

            node.size += 1
            node.subtreesize += 1

            setconnections!(node.elements[index], next, prev, range(graph))

            while node.size == MAX_ELEMENTS
                parent = node.parent
                if isnothing(parent)
                    oldroot = graph.root
                    graph.root = Node{Key}()
                    graph.height += 1
                    graph.root.children[1] = oldroot
                    splitchild!(graph.root, 1)
                    return ret
                else
                    splitchild!(parent, findchildindex(parent, node))
                    node = parent
                end
            end

            return ret
        else
            node.subtreesize += 1
            node = node.children[index]
        end
    end
end

function printgraph(graph::Graph{Key}) where Key
    levels = nodelevels(graph)
    
    elementscount = 0
    uniqueelementscount = 0
    for (level, nodes) in levels
        print("$level: ")
        for node in nodes
            print("|-")
            for i = 1:node.size
                print(
                    node.keys[i], 
                    ":", 
                    node.elements[i].counter, 
                    "-"
                )
                uniqueelementscount += 1
                elementscount += node.elements[i].counter 
            end
            print("| ")
        end
        println("\n")
    end
    println("number of unique elements: $uniqueelementscount")
    println("total number of elements: $elementscount")
end

function nodelevels(graph::Graph{Key})::SortedDict{Int, Vector{Node{Key}}} where Key
    node = graph.root
    levels = SortedDict{Int, Vector{Node{Key}}}()
    level = 1
    levels[level] = Vector()
    push!(levels[level], node)
    while true
        first(levels[level]).isleaf && break
        levels[level + 1] = Vector()
        for node in levels[level]
            for i in 1:node.size + 1
                push!(levels[level + 1], node.children[i]) 
            end
        end
        level += 1
    end
    levels
end

function elements(graph::Graph{Key})::Vector{Element{Key}} where Key
    element = findminel(graph)
    elements = Vector{Element{Key}}()
    push!(elements, element)
    while !isnothing(element.next)
        element = element.next.element
        push!(elements, element)
    end
    elements
end

function elements(node::Node{Key})::Vector{Element{Key}} where Key
    ret = []
    for i = 1:node.size
        push!(ret, node.elements[i])
    end
    ret
end

function listelements(graph::Graph{Key})::Array{Pair{String,Int64},1} where Key
    node = graph.root
    queue = []
    push!(queue, Vector{Opt{Node{Key}}}())
    push!(queue[1], node)
    height = 1
    elements = Dict{String, Int64}()
    while true
        push!(queue, Vector{Opt{Node{Key}}}())
        for i = 1:(length(queue[height]))
            if !isnothing(queue[height][i])
                for j = 1:(queue[height][i].size)
                    if queue[height][i] != nothing
                        elements[string(queue[height][i].keys[j])] = 
                            queue[height][i].elements[j].counter
                    end
                    if !(queue[height][i].isleaf)
                        push!(
                            queue[height + 1], 
                            queue[height][i].children[j]
                        )
                    end
                end
                if !(queue[height][i].isleaf)
                    push!(
                        queue[height + 1], 
                        queue[height][i].children[queue[height][i].size + 1]
                    )
                end
            end
        end
        if length(queue[end]) > 0
            height += 1
        else
            return sort(collect(elements), by = x -> x[2], rev = true)
        end
    end

    sort(collect(elements), by = x -> x[2], rev = true)
end

function winner(graph::Graph{Key})::Opt{Element{Key}} where Key
    if isnothing(graph.minkey)
        return nothing
    end

    el = search(graph, graph.minkey)
    winner = el
    
    while !isnothing(el)
        el = el.next.element
        if el.activation > winner.activation
            winner = el
        end
    end
    
    winner
end

function weightedmean(graph::Graph{Key})::Opt{Int64} where Key <: Number
    sum::Float64 = 0.0
    weightsum::Float64 = 0.0

    if isnothing(graph.minkey)
        return nothing
    end
    el = search(graph, graph.minkey)

    if isnothing(el.next)
        return nothing
    end

    while !isnothing(el)
        activation = el.activation
        if !isnan(activation) && !isinf(activation)
            sum += el.key * activation
            weightsum += activation
        end
        el = el.next.element
    end

    round(Int64, sum / weightsum)
end

function deactivate!(graph::Graph{Key})::Nothing where Key
    if isnothing(graph.minkey)
        return
    end

    el = search(graph, graph.minkey)

    while !isnothing(el)
        deactivate!(el)
        el = el.next.element
    end
    
    nothing
end

function test()
    GC.enable(false)
    @time begin
        graph = graph{Int}(:test, numerical)
        for i = 1:1_000
            insert!(graph, rand(1:1_000))
        end
        printgraph(graph)
    end
    GC.enable(true)
    nothing
end

function asacgraphsample(n=50)
    graph = Graph{Int}("sample", numerical)
    for i = 1:n
        insert!(graph, rand(1:999))
    end
    graph
end

function mediansub(graph::Graph{Key})::Key where Key
    node = graph.root
    total = node.subtreesize
    median = total / 2;
    offset = 0

    while true
        total = offset

        for i in 1:(node.size + 1)
            if !node.isleaf
                total += node.children[i].subtreesize
            end

            if total >= median
                offset = total - node.children[i].subtreesize
                node = node.children[i]
                break
            end

            if i <= node.size
                total += node.elements[i].counter;
                if total >= median
                    return node.elements[i].key;
                end
            end
        end
    end
end

function findminel(graph::Graph{Key})::Element{Key} where Key
    node = graph.root
    while true 
        if node.isleaf
            return node.elements[1]
        else
            node = node.children[1];
        end
    end
end

function findmaxel(graph::Graph{Key})::Element{Key} where Key
    node = graph.root
    while true 
        if node.isleaf
            return node.elements[node.size]
        else
            node = node.children[node.size + 1];
        end
    end
end


function medianel(graph::Graph{Key})::Key where Key
    firstel = findminel(graph)
    secondel = findmaxel(graph)

    left = 0
    right = 0
    while true
        if firstel == secondel
            return firstel.key
        end
        if left <= right
            left += firstel.counter
            firstel = firstel.next.element
        else
            right += secondel.counter
            secondel = secondel.prev.element
        end
    end
end


end # module
