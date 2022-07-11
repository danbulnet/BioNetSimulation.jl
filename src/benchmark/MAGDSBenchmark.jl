module MAGDSBenchmark

using BioNet.MAGDSSimple
using BioNet.ASAGraph
using BioNet.ASAGraph: Element
using BioNet.Common
using Dates

export experiment1, experiment2, experiment3, experiment4, experiment5, experiment6, experiment7
export e1tabs, e2tabs, e3tabs

e1tabs = ["gxd_specimen", "gxd_genotype", "prb_strain"]
e2tabs = ["prb_probe"]
e3tabs = ["map_coord_feature"]

function experiment1(
    graph::MAGDSSimple.Graph, 
    tablename::Symbol = :gxd_specimen, 
    fk::Symbol = :age, 
    limit::Int64 = 100
)
    ret = Vector{String}(undef, limit)
    i = 1
    for neuron in graph.neurons[tablename]
        for out in neuron.out
            someneuron = out.to
            if someneuron isa AbstractSensor && ASAGraph.treename(someneuron) == fk
                ret[i] = string(someneuron.key)
                i += 1
            end
        end
        if i > limit
            break
        end
    end
    return ret
end

function experiment2(graph::MAGDSSimple.Graph)
    agemin = graph.sensors[:agemin]
    agemin_minkey = agemin.minkey
    if isnothing(agemin_minkey)
        error("failed to find agemin_minkey")
    end
    agemin_minel = ASAGraph.search(agemin, agemin_minkey)
    ASAGraph.activatesimple!(agemin_minel, 1.01)

    agemin_maxkey = agemin.maxkey
    if isnothing(agemin_maxkey)
        error("failed to find agemin_maxkey")
    end
    agemin_maxel = ASAGraph.search(agemin, agemin_maxkey)
    ASAGraph.activatesimple!(agemin_maxel, 1.01)

    agemax = graph.sensors[:agemax]
    agemax_minkey = agemax.minkey
    if isnothing(agemax_minkey)
        error("failed to find agemax_minkey")
    end
    agemax_minel = ASAGraph.search(agemax, agemax_minkey)
    ASAGraph.activatesimple!(agemax_minel, 1.01)

    agemax_maxkey = agemax.maxkey
    if isnothing(agemax_maxkey)
        error("failed to find agemax_maxkey")
    end
    agemax_maxel = ASAGraph.search(agemax, agemax_maxkey)
    ASAGraph.activatesimple!(agemax_maxel, 1.01)

    isconditional = graph.sensors[:isconditional]
    isconditional_zero = ASAGraph.search(isconditional, Int16(0))
    if isnothing(isconditional_zero)
        error("failed to find isconditional_zero")
    end
    ASAGraph.activatesimple!(isconditional_zero, 1.01)

    standard = graph.sensors[:standard]
    standard_one = ASAGraph.search(standard, Int16(1))
    if isnothing(standard_one)
        error("failed to find standard_one")
    end
    ASAGraph.activatesimple!(standard_one, 1.01)

    private = graph.sensors[:private]
    private_zero = ASAGraph.search(private, Int16(0))
    if isnothing(private_zero)
        error("failed to find private_zero")
    end
    ASAGraph.activatesimple!(private_zero, 1.01)

    # creation_date = graph.sensors[:creation_date]
    # start_creation_date = ASAGraph.searchnear(creation_date, Dates.DateTime("2010-05-03"))

    # if isnothing(start_creation_date)
    #     error("failed to find start_creation_date")
    # end

    ret = Vector{String}()

    for neuron in graph.neurons[:gxd_specimen]
        if neuron.activation > 7.0
            for out in neuron.out
                someneuron = out.to
                if someneuron isa AbstractSensor && ASAGraph.treename(someneuron) == :specimenlabel
                    someneuron.activation = 1.01
                end
            end
        end
    end

    specimenlabel = graph.sensors[:specimenlabel]
    specimenlabel_minkey = specimenlabel.minkey
    if isnothing(specimenlabel_minkey)
        error("failed to find specimenlabel_minkey")
    end
    specimenlabelel = ASAGraph.search(specimenlabel, specimenlabel_minkey)
    while !isnothing(specimenlabelel)
        if specimenlabelel.activation >= 1.0
            push!(ret, string(specimenlabelel.key))
        end
        specimenlabelel = if isnothing(specimenlabelel.next)
            nothing
        else
            specimenlabelel.next
        end
    end

    ret
end

function experiment3(graph::MAGDSSimple.Graph)
    agemin = graph.sensors[:agemin]
    agemin_minkey = agemin.minkey
    if isnothing(agemin_minkey)
        error("failed to find agemin_minkey")
    end
    agemin_minel = ASAGraph.search(agemin, agemin_minkey)
    ASAGraph.activatesimple!(agemin_minel, 1.01)

    agemin_maxkey = agemin.maxkey
    if isnothing(agemin_maxkey)
        error("failed to find agemin_maxkey")
    end
    agemin_maxel = ASAGraph.search(agemin, agemin_maxkey)
    ASAGraph.activatesimple!(agemin_maxel, 1.01)

    agemax = graph.sensors[:agemax]
    agemax_minkey = agemax.minkey
    if isnothing(agemax_minkey)
        error("failed to find agemax_minkey")
    end
    agemax_minel = ASAGraph.search(agemax, agemax_minkey)
    ASAGraph.activatesimple!(agemax_minel, 1.01)

    agemax_maxkey = agemax.maxkey
    if isnothing(agemax_maxkey)
        error("failed to find agemax_maxkey")
    end
    agemax_maxel = ASAGraph.search(agemax, agemax_maxkey)
    ASAGraph.activatesimple!(agemax_maxel, 1.01)

    isconditional = graph.sensors[:isconditional]
    isconditional_zero = ASAGraph.search(isconditional, Int16(0))
    if isnothing(isconditional_zero)
        error("failed to find isconditional_zero")
    end
    ASAGraph.activatesimple!(isconditional_zero, 1.01)

    standard = graph.sensors[:standard]
    standard_one = ASAGraph.search(standard, Int16(1))
    if isnothing(standard_one)
        error("failed to find standard_one")
    end
    ASAGraph.activatesimple!(standard_one, 1.01)

    private = graph.sensors[:private]
    private_zero = ASAGraph.search(private, Int16(0))
    if isnothing(private_zero)
        error("failed to find private_zero")
    end
    ASAGraph.activatesimple!(private_zero, 1.01)

    # creation_date = graph.sensors[:creation_date]
    # start_creation_date = ASAGraph.searchnear(creation_date, Dates.DateTime("2010-05-03"))

    # if isnothing(start_creation_date)
    #     error("failed to find start_creation_date")
    # end

    sum = 0
    count = 0

    for neuron in graph.neurons[:gxd_specimen]
        if neuron.activation > 7.0
            for out in neuron.out
                someneuron = out.to
                if someneuron isa AbstractSensor && ASAGraph.treename(someneuron) == :specimenlabel
                    someneuron.activation = 1.01
                end
            end
        end
    end

    specimenlabel = graph.sensors[:sequencenum]
    specimenlabel_minkey = specimenlabel.minkey
    if isnothing(specimenlabel_minkey)
        error("failed to find specimenlabel_minkey")
    end
    specimenlabelel = ASAGraph.search(specimenlabel, specimenlabel_minkey)
    while !isnothing(specimenlabelel)
        if specimenlabelel.activation >= 1.0
            sum += specimenlabelel.key * specimenlabelel.counter
            count += specimenlabelel.counter
        end
        specimenlabelel = if isnothing(specimenlabelel.next)
            nothing
        else
            specimenlabelel.next
        end
    end

    sum / count
end

function experiment4(graph::MAGDSSimple.Graph, col::Symbol)
    ret = Vector{String}()
    
    asa = graph.sensors[col]
    min_minkey = asa.minkey
    if isnothing(min_minkey)
        error("failed to find min_minkey")
    end

    el = ASAGraph.search(asa, min_minkey)
    while !isnothing(el)
        push!(ret, string(el.key))
        el = if isnothing(el.next)
            nothing
        else
            el.next
        end
    end

    ret
end

function experiment5(graph::MAGDSSimple.Graph, col::Symbol)
    asa = graph.sensors[col]
    maxkey = asa.maxkey
    if isnothing(maxkey)
        error("failed to find maxkey")
    end

    maxkey
end

function experiment6(graph::MAGDSSimple.Graph, col::Symbol)::Float64
    sum::Int128 = 0
    count = 0
    
    asa = graph.sensors[col]
    min_minkey = asa.minkey
    if isnothing(min_minkey)
        error("failed to find min_minkey")
    end

    el = ASAGraph.search(asa, min_minkey)
    while !isnothing(el)
        sum += convert(Int128, el.key)
        count += 1
        el = if isnothing(el.next)
            nothing
        else
            el.next
        end
    end

    sum / count
end

function experiment7(graph::MAGDSSimple.Graph, tab::Symbol)
    length(graph.neurons[tab])
end

end # module