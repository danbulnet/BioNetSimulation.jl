using Dates
using ..Common
using ..Common: AbstractSensor, AbstractNeuron
import BioNet.SimpleNeuron: activate!
import Base.keytype

export treename, name, datatype, activate!, activatesimple!, deactivate!

mutable struct Element{Key} <: AbstractSensor
    key::Key
    counter::Int
    parent::Opt{AbstractSensoryField}

    state::NeuronState
    activation::Float64

    in::Vector{Connection}
    out::Vector{Connection}

    next::Opt{
        NamedTuple{
            (:element, :weight), 
            Tuple{Element{Key}, Float64}
        }
    }
    prev::Opt{
        NamedTuple{
            (:element, :weight), 
            Tuple{Element{Key}, Float64}
        }
    }

    function Element{Key}(
        key::Key, 
        parent::Opt{AbstractSensoryField}
    ) where Key
        new(key,
            1,
            parent,
            active,
            0.0,
            Vector{Connection}(),
            Vector{Connection}(),
            nothing,
            nothing
        )
    end
end

Base.show(io::IO, el::Element) = print("$(name(el)): $(el.activation)")

keytype(::Element{Key}) where Key = Key

name(element::Element) = string("[sensor: ", element.key, "(", element.counter, ")]")

id(element::Element) = (Symbol(element.parent.name), Symbol(element.key))

treename(el::Element)::String = el.parent.name

datatype(el::Element)::DataScale = el.parent.datatype

function setconnections!(
    element::Element{Key},
    next::Opt{Element{Key}},
    prev::Opt{Element{Key}},
    range::Float64
)::Nothing where Key
    if isnothing(element)
        throw(DomainError("element must not be nothing"))
    end

    if !isnothing(prev)
        weightprev = 1 - abs(prev.key - element.key) / range
        element.prev = (
            element = prev,
            weight = weightprev
        )

        prev.next = (
            element = element,
            weight = weightprev
        )
    else
        element.prev = nothing
    end

    if !isnothing(next)
        weightnext = 1 - abs(element.key - next.key) / range
        element.next = (
            element = next,
            weight = weightnext
        )

        next.prev = (
            element = element,
            weight = weightnext
        )
    else
        element.next = nothing
    end

    nothing
end

function activatesimple!(element::Element, signal::Float64 = 1.0)::Nothing
    elactivationold = copy(element.activation)
    element.activation += signal

    for connection in element.out
        connection.to.activation += signal
    end

    element.activation = elactivationold

    nothing
end

function activate!(
    element::Element, 
    signal::Float64 = 1.0, 
    forward::Bool = true, 
    neuronmode::Bool = false
)::Set{AbstractNeuron}
    element.activation += signal
    if element.activation >= Common.NEURON_ACTIVATION_THRESHOLD
        element.state = active
    else
        element.state = inactive
    end

    outconns = Set{Connection}()
    outconns = union(outconns, element.out)

    if (datatype(element) == numerical || datatype(element) == ordinal) && !neuronmode
        el = element
        while !isnothing(el.next) && el.activation > Common.INTERELEMENT_ACTIVATION_THRESHOLD
            el.next.element.activation += el.next.weight * el.activation
            # if (treename(element) != "price")
            #     println("next", el.next, " ", el.activation)
            # end
            el = el.next.element
            if el.activation >= Common.NEURON_ACTIVATION_THRESHOLD
                el.state = active
            else
                el.state = inactive
            end
            outconns = union(outconns, el.out)
        end

        el = element
        while !isnothing(el.prev) && el.activation > Common.INTERELEMENT_ACTIVATION_THRESHOLD
            el.prev.element.activation += el.prev.weight * el.activation
            # if (treename(element) != "price")
            #     println("prev", el.prev, " ", el.activation)
            # end
            el = el.prev.element
            if el.activation >= Common.NEURON_ACTIVATION_THRESHOLD
                el.state = active
            else
                el.state = inactive
            end
            outconns = union(outconns, el.out)
        end
    end

    outneurons = Set{AbstractNeuron}()

    if forward
        divisor = 1 / (1 - Common.INTERELEMENT_ACTIVATION_THRESHOLD)
        for connection in outconns
            if !neuronmode
                sign = connection.type == activation ? 1 : -1
                signal = sign * connection.from.activation * connection.weight / divisor
            end

            activate!(connection.to, signal, false)
            push!(outneurons, connection.to)
        end
    end

    outneurons
end

function deactivate!(el::Element{Key}) where Key
    el.state = Common.inactive
    el.activation = 0.0
end