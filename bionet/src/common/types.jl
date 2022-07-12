export AbstractGraph, AbstractNeuron, AbstractSensor, AbstractSensoryField, Opt, NeuronState, active, inactive, DataScale, numerical, categorical, ordinal

#########################
# abstract types
#########################

abstract type AbstractGraph end
abstract type AbstractNeuron end
abstract type AbstractSensor <: AbstractNeuron end
abstract type AbstractSensoryField end

#########################
# aliases
#########################

Opt{T} = Union{T, Nothing}

#########################
# enums
#########################

@enum NeuronState begin
    active = 1
    inactive = 2
end

@enum DataScale begin
    numerical = 1
    categorical = 2
    ordinal = 3
end