include("Element.jl")

const MIN_CHILDREN = (AVBTREE_ORDER + 1) ÷ 2
const MAX_CHILDREN = AVBTREE_ORDER + 1
const MIN_ELEMENTS = (AVBTREE_ORDER + 1) ÷ 2 - 1
const MAX_ELEMENTS = AVBTREE_ORDER
const MIN_KEYS = MIN_ELEMENTS
const MAX_KEYS = MAX_ELEMENTS
const T_OFFSET = (AVBTREE_ORDER + 1) ÷ 2
const MID_INDEX = (AVBTREE_ORDER + 1) ÷ 2

mutable struct Node{Key}
    size::Int
    isleaf::Bool
    parent::Opt{Node{Key}}
    keys::Vector{Opt{Key}}
    elements::Vector{Opt{Element{Key}}}
    children::Vector{Opt{Node{Key}}}

    function Node{Key}(leaf::Bool = false) where Key
        new(0,
            leaf,
            nothing,
            Vector{Opt{Key}}(nothing, MAX_KEYS),
            Vector{Opt{Element{Key}}}(nothing, MAX_ELEMENTS),
            Vector{Opt{Node{Key}}}(nothing, MAX_CHILDREN)
        )
    end
end

keytype(::Node{Key}) where Key = Key

function splitchild!(node::Node{Key}, childindex::Int) where Key
    rightnode = Node{Key}()
    leftnode = node.children[childindex]

    leftnode.parent = node
    rightnode.parent = node

    rightnode.isleaf = leftnode.isleaf
    rightnode.size = MIN_ELEMENTS
    leftnode.size = MIN_ELEMENTS
    rightsum = 0
    for j = 1:MIN_ELEMENTS
        rightnode.keys[j] = leftnode.keys[j + T_OFFSET]
        rightnode.elements[j] = leftnode.elements[j + T_OFFSET]
        rightsum += rightnode.elements[j].counter
    end
    if !leftnode.isleaf
        for j = 1:MIN_CHILDREN
            rightnode.children[j] = leftnode.children[j + T_OFFSET]
            rightnode.children[j].parent = rightnode
        end
    end


    for j = node.size+1:-1:childindex
        node.children[j + 1] = node.children[j]
    end
    node.children[childindex + 1] = rightnode

    for j = node.size:-1:childindex
        node.keys[j + 1] = node.keys[j]
        node.elements[j + 1] = node.elements[j]
    end

    node.keys[childindex] = leftnode.keys[MID_INDEX]
    node.elements[childindex] = leftnode.elements[MID_INDEX]
    node.size += 1
end

function findchildindex(parent::Node{Key}, child::Node{Key})::Int where Key
    for i = 1:(parent.size + 1)
        if parent.children[i] == child
            return i
        end
    end
    return 0
end