# function add_regulators!(data::Dict)
#     # every bus can have a regulator. cost is fixed. not sure about the margins
#     # the margins are hard-coded in /src/core/constraint.jl, line 8-9
#     # the cost is hard-coded in the objective function
#     # here they are reported just for bookkeeping 
#     if !haskey(data, "candidates") data["candidates"] = Dict{String, Any}() end
#     data["candidates"]["regulators"] = Dict(
#         "cost" => "300000",
#         "extra_range_square_volts" => 0.09
#     )
# end

# function add_infrastructure_upgrades!(data::Dict)
#     if !haskey(data, "candidates") data["candidates"] = Dict{String, Any}() end
#     data["candidates"]["upgrades"] = Dict(
#         "cost_overhead" => "150000 + 15000 x MVArating" #EUR per km
#         "cost_undergrn" => "300000 + 30000 x MVArating" #EUR per km
#     )
# end

# function add_batteries!(data::Dict; cost_projection::String = "mid")
#     costs = Dict{String, String}("cost_high" => "210*(rating_kW)+195*(capacity_kWh)",
#                                  "cost_mid"  => "200*(rating_kW)+150*(capacity_kWh)",
#                                  "cost_low"  => "160*(rating_kW)+120*(capacity_kWh)")
#     if !haskey(data, "candidates") data["candidates"] = Dict{String, Any}() end
#     data["candidates"]["batteries"] = Dict("cost" => costs["cost_"*"$(cost_projection)"])
# end
