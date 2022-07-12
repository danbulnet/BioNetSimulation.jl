import Base.-
using Dates

Base.:-(first::String, second::String) = first == second ? 0 : 1
Base.:-(first::Dates.DateTime, second::Dates.DateTime) = Dates.value(first) - Dates.value(second)
Base.:-(first::Dates.Date, second::Dates.Date) = Dates.value(first) - Dates.value(second)