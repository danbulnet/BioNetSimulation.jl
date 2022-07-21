module Structures

export Option, Address, Investment, Estate, Prediction
export Client, ClientProfilingData, Developer

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
    created_at::UInt64
    updated_at::UInt64
    post_code::String
end

mutable struct Developer
    id::UInt64
    name::String
    email::String
    email_verified_at::Option{UInt64}
    webpage::Option{String}
    desctiption::Option{String}
    info::Option{String}
    contact_email::Option{String}
    phone::Option{String}
    address::Option{Address}
    is_agency::Bool
    created_at::UInt64
    updated_at::UInt64
end

mutable struct Investment
    id::UInt64
    name::String
    presentation::Option{Vector{String}}
    webpage::Option{String}
    desctiption::Option{String}
    developer::Developer
    address::Option{Address}
    created_at::UInt64
    updated_at::UInt64
    active::UInt8
end

mutable struct Prediction
    key::String
    value::String
end

mutable struct Estate
    id::UInt64
    name::String
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
    created_at::UInt64
    updated_at::UInt64
    government_program_1::UInt8
end

mutable struct ClientProfilingData
    answers::Option{Dict{String, String}} # odpowiedzi na pytania asystenta
    profiling::Option{Dict{String, String}} # twoje dodatkowe dane
    filters::Option{Dict{String, Option{String}}} # wybrane filtry
end

mutable struct Client
    id::UInt64
    browser_user_agent::Option{String}
    browser_language::Option{String}
    browser_platform::Option{String}
    browser_name::Option{String}
    profiling_data::Option{ClientProfilingData}
    email::Option{String}
end

end