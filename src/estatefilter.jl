export homefydevelopers, homefyclients, homefyinvestment, homefyaddresses, homefyestates

tabsfilter = [
    :homefy_addresses, 
    :homefy_clients, 
    :homefy_developers, 
    :homefy_estates, 
    :homefy_estates_predictions, 
    :homefy_investments
]

developerfilter = [:name, :isagency]

clientfilter = [
    :email,
    :browser_language,
    :browser_name,
    :browser_platform,
    :profiling_data
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

investmentfilter = [:name, :presentation, :views, :active]

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
    :views,
    :created_at,
    :updated_at,
    :government_program_1
]