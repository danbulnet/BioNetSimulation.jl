export homefydevelopers, homefyclients, homefyinvestment, homefyaddresses, homefyestates

homefytabs = Set([
    :homefy_addresses, 
    :homefy_clients, 
    :homefy_developers, 
    :homefy_estates, 
    :homefy_estates_predictions, 
    :homefy_investments
])

homefydevelopers = Set([:name, :isagency])

homefyclients = Set([
    :email,
    :browser_language,
    :browser_name,
    :browser_platform,
    :profiling_data
])

homefyaddresses = Set([
    :country,
    :voivodeship,
    :district,
    :town,
    :street,
    :buildingnumber,
    :flatnumber,
    :lat,
    :long
])

homefyinvestment = Set([:name, :presentation, :views, :active])

homefyestates = Set([
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
    :views
])

homefysensors = union(
    homefydevelopers, homefyclients, homefyinvestment, homefyaddresses, homefyestates
)