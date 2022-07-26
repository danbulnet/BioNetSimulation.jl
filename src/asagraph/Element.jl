using ..Common

export treename, name, keytype, datatype, activate!, deactivate!, treename

mutable struct Element{Key} <: AbstractSensor
    key::Key
    counter::Int
    parent::Opt{AbstractSensoryField}

    activation::Float64

    in::Vector{ConnectionSimple}
    out::Vector{ConnectionSimple}

    next::Opt{Element{Key}}
    prev::Opt{Element{Key}}

    function Element{Key}(
        key::Key, 
        parent::Opt{AbstractSensoryField}
    ) where Key
        new(key,
            1,
            parent,
            0.0,
            Vector{ConnectionSimple}(),
            Vector{ConnectionSimple}(),
            nothing,
            nothing
        )
    end
end

Base.show(io::IO, el::Element) = print("$(name(el)): $(el.activation)")

keytype(::Element{Key}) where Key = Key

name(element::Element) = string("[sensor: ", element.key, "(", element.counter, ")]")

id(element::Element) = (Symbol(element.parent.name), Symbol(element.key))

treename(el::Element)::Symbol = el.parent.name

datatype(el::Element)::DataScale = el.parent.datatype

function weight(el1::Element{Key}, el2::Element{Key}, range::Float64) where Key
    Float64(1 - abs(el1.key - el2.key) / range)
end

function setconnections!(
    element::Element{Key},
    next::Opt{Element{Key}},
    prev::Opt{Element{Key}}
)::Nothing where Key
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

function activatesimple!(element::Element, signal::Float64 = 1.0)::Nothing
    elactivationold = element.activation
    element.activation += signal

    for connection in element.out
        connection.to.activation += signal
    end

    element.activation = elactivationold

    nothing
end

# function activate!(
#     element::Element{Key}, 
#     signal::Float64 = 1.0, 
#     forward::Bool = true, 
#     neuronmode::Bool = false
# )::Set{AbstractNeuron} where Key
#     element.activation += signal
#     if element.activation >= Common.NEURON_ACTIVATION_THRESHOLD
#         element.state = active
#     else
#         element.state = inactive
#     end

#     outconns = Set{Connection}()
#     outconns = union(outconns, element.out)

#     if (datatype(element) == numerical || datatype(element) == ordinal) && !neuronmode
#         el = element
#         while !isnothing(el.next) && el.activation > Common.INTERELEMENT_ACTIVATION_THRESHOLD
#             el.next.element.activation += el.next.weight ^ Common.INTERELEMENT_WEIGHT_POWER * el.activation
#             # if (treename(element) != :price)
#             #     println("next", el.next)
#             # end
#             el = el.next.element
#             if el.activation >= Common.NEURON_ACTIVATION_THRESHOLD
#                 el.state = active
#             else
#                 el.state = inactive
#             end
#             outconns = union(outconns, el.out)
#         end

#         el = element
#         while !isnothing(el.prev) && el.activation > Common.INTERELEMENT_ACTIVATION_THRESHOLD
#             el.prev.element.activation += el.prev.weight ^ Common.INTERELEMENT_WEIGHT_POWER * el.activation
#             # if (treename(element) != :price)
#             #     println("prev", el.prev)
#             # end
#             el = el.prev.element
#             if el.activation >= Common.NEURON_ACTIVATION_THRESHOLD
#                 el.state = active
#             else
#                 el.state = inactive
#             end
#             outconns = union(outconns, el.out)
#         end
#     end

#     outneurons = Set{AbstractNeuron}()

#     if forward
#         for connection in outconns
#             if !neuronmode
#                 sign = connection.type == activation ? 1 : -1
#                 signal = sign * connection.from.activation * connection.weight
#             end

#             activate!(connection.to, signal, forward)
#             push!(outneurons, connection.to)
#         end
#     end

#     outneurons
# end

function deactivate!(el::Element{Key}) where Key
    el.state = Common.inactive
    el.activation = 0.0
end