export homefydevelopers, homefyclients, homefyinvestment, homefyaddresses, homefyestates, fieldfilter

tabsfilter = [
    :homefy_addresses, 
    :homefy_clients, 
    :homefy_developers, 
    :homefy_estates, 
    :homefy_estates_predictions, 
    :homefy_investments
]

clientfilter = [
    :email,
    :browserlanguage,
    :browsername,
    :browserplatform,
    :profilingdata
]

addressfilter = [
    :country,
    :voivodeship,
    :district,
    :town,
    :street,
    :buildingnumber,
    :buildingletter,
    :flatnumber,
    :lat,
    :long
]

developerfilter = [:name, :isagency]
developerfilter_prefix = Symbol.(map(x -> "developer_$x", developerfilter))

investmentfilter = [:name, :presentation, :active]
investmentfilter_prefix = Symbol.(map(x -> "investment_$x", investmentfilter))

estatefilter = [
    :name, 
    :availability, 
    :estatetype, 
    :buildingtype, 
    :localtype,
    :buildingphase,
    :deliverydeadline,
    :standard,
    :material,
    :heating,
    :canalization,
    :price,
    :aream2,
    :storeys,
    :floor,
    :rooms,
    :bathrooms,
    :additionalarea,
    :facilities,
    :functionalities,
    :presentation,
    :builtyear,
    :createdat,
    :updatedat,
    :governmentprogram_1
]


fieldfilter = union(
    Set(estatefilter), 
    Set(addressfilter), 
    Set(developerfilter_prefix), 
    Set(investmentfilter_prefix)
) |> collect