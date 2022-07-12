using ..Common

mutable struct Neuron <: AbstractNeuron
    name::String
    parent::String

    state::NeuronState
    activation::Float64
    counter::Int

    in::Vector{Connection}
    out::Vector{Connection}

    function Neuron(name::String, parent::String)
        new(name,
            parent,
            inactive,
            0.0,
            1,
            Vector{Connection}(),
            Vector{Connection}())
    end
end

Base.show(io::IO, neuron::Neuron) = print(name(neuron))

counterup!(neuron::AbstractNeuron) = neuron.counter += 1

counterdown!(neuron::AbstractNeuron) = neuron.counter > 0 ? neuron.counter -= 1 : 0

setname!(neuron::AbstractNeuron, name::String) = neuron.name = name

nameact(neuron::Neuron) = "[neuron: $(neuron.name)($(neuron.counter))]: $(neuron.activation)"
name(neuron::Neuron) = "[neuron: $(neuron.name)($(neuron.counter))]"

function activate!(neuron::Neuron, signal::Float64 = 1.0, forward::Bool = true)::Set{AbstractNeuron}
    neuron.activation += signal
    if neuron.activation >= Common.NEURON_ACTIVATION_THRESHOLD
        neuron.state = active
    else
        neuron.state = inactive
    end

    outneurons = Set{AbstractNeuron}()

    if forward
        for connection in neuron.out
            sign = connection.type == activation ? 1 : -1
            signal = sign * neuron.activation * connection.weight
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
    neuron.state = inactive
    neuron.activation = 0.0
end

function addconn!(neuron::AbstractNeuron, connection::Connection, type::Symbol)
    if type == :in
        push!(neuron.in, connection)
    elseif type == :out
        push!(neuron.out, connection)
    end
end

function addconn!(neuron::AbstractNeuron, connection::ConnectionSimple, type::Symbol)
    if type == :in
        push!(neuron.in, connection)
    elseif type == :out
        push!(neuron.out, connection)
    end
end