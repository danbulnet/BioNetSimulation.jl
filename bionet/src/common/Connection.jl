export ConnectionDirection, oneway, bidirectional, ConnectionType
export activation, inhibitory, Connection, ConnectionSimple, counterdown!, counterup!

include("types.jl")
include("parameters.jl")
include("paths.jl")
include("distances.jl")

@enum ConnectionDirection begin
    oneway = 1
    bidirectional = 2
end

@enum ConnectionType begin
    activation = 1
    inhibitory = 2
end

mutable struct Connection
    from::AbstractNeuron
    to::AbstractNeuron

    type::ConnectionType

    weight::Float64

    counter::Int

    function Connection(from::AbstractNeuron, to::AbstractNeuron, weight::Float64 = 1.0)
        new(from, to, activation, weight, 1)
    end
end

mutable struct ConnectionSimple
    from::AbstractNeuron
    to::AbstractNeuron

    function ConnectionSimple(from::AbstractNeuron, to::AbstractNeuron)
        new(from, to)
    end
end

function counterup!(conn::Connection, amount::Int64 = 1)::Connection
    conn.counter += amount
    conn
end

function counterdown!(conn::Connection, amount::Int64 = 1)::Connection
    conn.counter -= amount
    if conn.counter < 0
        conn.counter = 0
    end
    conn
end

name(neuron::AbstractNeuron) = "unknown neuron"

# function Base.show(io::IO, conn::Connection)
#     println(name(conn.from), " => ", name(conn.to), " weight: ", round.(conn.weight; digits=5))
# end
