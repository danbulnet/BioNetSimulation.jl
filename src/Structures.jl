module Structures

export Option, Address, Investment, Estate, Prediction
export Client, ClientProfilingData, Developer
export listfields, estatesample, describe

include("estatefilter.jl")

Option{T} = Union{T, Nothing}

mutable struct Address
    id::UInt64
    country::String
    voivodeship::Option{String}
    district::Option{String}
    town::String
    street::Option{String}
    buildingnumber::UInt16
    buildingletter::Option{String}
    flatnumber::Option{UInt16}
    flatletter::Option{String}
    lat::Option{Float32}
    long::Option{Float32}
    createdat::UInt64
    updatedat::UInt64
    postcode::String
end

mutable struct Developer
    id::UInt64
    name::String
    email::String
    email_verifiedat::Option{UInt64}
    webpage::Option{String}
    desctiption::Option{String}
    info::Option{String}
    contactemail::Option{String}
    phone::Option{String}
    address::Option{Address}
    isagency::Bool
    createdat::UInt64
    updatedat::UInt64
end

mutable struct Investment
    id::UInt64
    name::String
    presentation::Option{Vector{String}}
    webpage::Option{String}
    desctiption::Option{String}
    developer::Developer
    address::Option{Address}
    createdat::UInt64
    updatedat::UInt64
    active::UInt8
end

mutable struct Prediction
    key::String
    value::String
end

mutable struct Estate
    id::UInt64
    name::String
    presentation::Option{Vector{String}}
    desctiption::Option{String}
    availability::Option{String}
    estatetype::Option{String}
    buildingtype::Option{String}
    localtype::Option{String}
    builtyear::Option{UInt16}
    buildingphase::Option{String}
    deliverydeadline::Option{String}
    standard::Option{String}
    material::Option{String}
    heating::Option{String}
    canalization::Option{String}
    price::Option{UInt32}
    aream2::Float32
    storeys::Option{UInt8}
    floor::Option{Int16}
    rooms::Option{UInt16}
    bathrooms::Option{UInt16}
    additionalarea::Option{Vector{String}}
    facilities::Option{Vector{String}}
    functionalities::Option{Vector{String}}
    webpage::Option{String}
    investment::Investment
    address::Option{Address}
    predictions::Option{Vector{Prediction}}
    createdat::UInt64
    updatedat::UInt64
    governmentprogram_1::UInt8
end

mutable struct ClientProfilingData
    answers::Option{Dict{String, String}} # odpowiedzi na pytania asystenta
    profiling::Option{Dict{String, String}} # twoje dodatkowe dane
    filters::Option{Dict{String, Option{String}}} # wybrane filtry
end

mutable struct Client
    id::UInt64
    browser_useragent::Option{String}
    browserlanguage::Option{String}
    browserplatform::Option{String}
    browsername::Option{String}
    profilingdata::Option{ClientProfilingData}
    email::Option{String}
end

function estatesample(id::Int=1)::Estate
    address = Address(
        1,
        "PL",
        "małopolska",
        "krakowski",
        "Kraków",
        "Cieszyńska",
        6,
        "",
        23,
        "",
        50.075275,
        19.930216,
        1658379570,
        1658379580,
        "30-015"
    )

    developer = Developer(
        1,
        "Murapol",
        "info@murapol.pl",
        0,
        "",
        "",
        "",
        "",
        "",
        address,
        false,
        1658379570,
        1658379580
    )

    investment = Investment(
        1,
        "Apartamenty Cieszyńska",
        String["gallery", "interactivemap"],
        "",
        "",
        developer,
        address,
        1658379570,
        1658379580,
        true
    )

    estate = Estate(
        id,
        "6/23",
        String["gallery", "interactivemap"],
        "",
        "free",
        "luxuryapartment",
        "terraced",
        "",
        2012,
        "finished",
        "inuse",
        "readytolive",
        "brick",
        "centralcity",
        "urban",
        1_150_000,
        66.4,
        5,
        4,
        3,
        1,
        String["balcony", "loggia", "spaceingarage"],
        String["airconditioning", "internetwifi", "cabletv", "lift"],
        String["kitchenette", "functionallayout",],
        "",
        investment,
        address,
        Prediction[],
        1658379570,
        1658379580,
        0
    )

    estate
end

function listfields(object)::Dict{Symbol, Any}
    names = collect(fieldnames(typeof(object)))
    values = []
    for name in names
        value = :($object.$name) |> eval
        push!(values, value)
    end
    Dict{Symbol, Any}(zip(names, values))
end

function nonemptyfields(object)::Dict{Symbol, Any}
    Dict{Symbol, Any}(filter(x -> !isnothing(last(x)), listfields(object)))
end

function describe(estate::Estate)::Dict{Symbol, Any}
    estatefields = nonemptyfields(estate)
    estatefields = filter(x -> first(x) in estatefilter, estatefields)
    
    investmentfields = nonemptyfields(estate.investment)
    investmentfields = filter(x -> first(x) in investmentfilter, investmentfields)
    investmentfields = Dict{Symbol, Any}(map(
        x -> (Symbol("investment_$(first(x))") => last(x)), collect(investmentfields))
    )
    
    addressfields = if isnothing(estate.address)
        if isnothing(estate.investment.address)
            Dict{Symbol, Any}()
        else
            nonemptyfields(estate.investment.address)
        end
    else
        nonemptyfields(estate.address)
    end
    addressfields = filter(x -> first(x) in addressfilter, addressfields)

    developerfields = if isnothing(estate.investment.developer)
        Dict{Symbol, Any}()
    else
        nonemptyfields(estate.investment.developer)
    end
    developerfields = filter(x -> first(x) in developerfilter, developerfields)
    developerfields = Dict{Symbol, Any}(map(
        x -> (Symbol("developer_$(first(x))") => last(x)), collect(developerfields))
    )

    merge(estatefields, investmentfields, addressfields, developerfields)
end

end