using ..Common

export treename, name, keytype, datatype, activate!, deactivate!

mutable struct Element{Key} <: AbstractSensor
    key::Key
    counter::Int

    next::Opt{Element{Key}}
    prev::Opt{Element{Key}}

    function Element{Key}(key::Key) where Key
        new(key,
            1,
            nothing,
            nothing
        )
    end
end

Base.show(io::IO, el::Element) = print("$(name(el)): $(el.counter)")

keytype(::Element{Key}) where Key = Key

name(element::Element) = string("[sensor: ", element.key, "(", element.counter, ")]")

treename(el::Element)::Symbol = el.parent.name

datatype(el::Element)::DataScale = el.parent.datatype

function setconnections!(
    element::Element{Key},
    next::Opt{Element{Key}},
    prev::Opt{Element{Key}}
)::Nothing where Key
    if isnothing(element)
        throw(DomainError("element must not be nothing"))
    end

    if !isnothing(prev)
        element.prev = prev
        prev.next = element
    else
        element.prev = nothing
    end

    if !isnothing(next)
        element.next = next
        next.prev = element
    else
        element.next = nothing
    end

    nothing
end
