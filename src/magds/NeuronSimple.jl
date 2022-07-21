using ..Common

export NeuronSimple

mutable struct NeuronSimple <: AbstractNeuron
    name::String
    parent::String

    activation::Float64

    in::Vector{ConnectionSimple}
    out::Vector{ConnectionSimple}

    function NeuronSimple(name::String, parent::String)
        new(
            name,
            parent,
            0.0,
            Vector{ConnectionSimple}(),
            Vector{ConnectionSimple}()
        )
    end
end

Base.show(io::IO, neuron::NeuronSimple) = print(name(neuron))

setname!(neuron::AbstractNeuron, name::String) = neuron.name = name

nameact(neuron::NeuronSimple) = "[neuron: $(neuron.name)]: $(neuron.activation)"

name(neuron::NeuronSimple) = "[neuron: $(neuron.name)]"

id(neuron::NeuronSimple) = (Symbol(neuron.parent), Symbol(neuron.name))

function activate!(neuron::NeuronSimple, signal::Float64 = 1.0, forward::Bool = true)::Set{AbstractNeuron}
    neuron.activation += signal

    outneurons = Set{AbstractNeuron}()

    if forward
        for connection in neuron.out
            sign = connection.type == activation ? 1 : -1
            signal = sign * neuron.activation
            if isa(connection.to, AbstractSensor)
                activate!(connection.to, signal, false)
            else
                activate!(connection.to, signal, true)
            end
            push!(outneurons, connection.to)
        end
    end
    return outneurons
end

function deactivate!(neuron::AbstractNeuron)
    neuron.activation = 0.0
end

function addconn!(neuron::AbstractNeuron, connection::ConnectionSimple, type::Symbol)
    if type == :in
        push!(neuron.in, connection)
    elseif type == :out
        push!(neuron.out, connection)
    end
end
