function get_33bus_network()::Dict
    data = _PMD.parse_file(joinpath(BASE_DIR, "data/33Bus-Modified/OpenDSS_Model/Master33bus.dss"), data_model = _PMD.MATHEMATICAL)
    slackbus = [bus["index"] for (_, bus) in data["bus"] if bus["bus_type"] == 3][1]
    make_gens_negative_loads!(data, slackbus)
    return add_line_power_rating!(data, joinpath(BASE_DIR, "data/33Bus-Modified/OpenDSS_Model/LineLimits.csv"))
end

function get_irish_network()::Dict
    data = _PMD.parse_file(joinpath(BASE_DIR, "data/IrishMVGrid/OpenDSS_Model/master_file.dss"), data_model = _PMD.MATHEMATICAL)
    slackbus = [bus["index"] for (_, bus) in data["bus"] if bus["bus_type"] == 3][1]
    make_gens_negative_loads!(data, slackbus)
    return add_line_power_rating!(data, joinpath(BASE_DIR, "data/IrishMVGrid/OpenDSS_Model/LineLimits.csv"))
end

"""
This function:
    1) replaces generators (except the power supply at the slackbus) with "negative loads"
    2) changes the bus type of generators from 2 (PV bus) to 1 (PQ bus)
"""
function make_gens_negative_loads!(data::Dict, slackbus::Int)::Dict
    load_id = maximum([load["index"] for (_,load) in data["load"]]) 
    for (_, gen) in data["gen"]
        if gen["gen_bus"] != slackbus

            data["bus"]["$(gen["gen_bus"])"]["bus_type"] = 1 # instead of 2 : these are PQ buses, not PV buses as the dss parser says
            
            load_id+=1
            data["load"]["$load_id"] = Dict{String, Any}()
            data["load"]["$load_id"] = Dict(
                "pmax" => -gen["pmax"],
                "pmin" => -gen["pmin"],
                "qmax" => -gen["qmax"],
                "qmin" => -gen["qmin"],
                "pd" => -gen["pg"],
                "qd" => -gen["qg"],
                "connections" => gen["connections"],
                "load_bus" => gen["gen_bus"],
                "source_id" => gen["source_id"],
                "name" => gen["name"],
                "vbase" => gen["vbase"],
                "configuration" => _PMD.WYE,
                "was_gen" => true,
                "index" => load_id,
                "model" => _PMD.POWER
            )
            delete!(data["gen"], "$(gen["index"])")
        end
    end
    return data
end
"""
These are needed for the thermal limits
"""
function add_line_power_rating!(data::Dict, path_to_csv::String)::Dict
    r = CSV.read(path_to_csv, _DF.DataFrame, header = 0)
    rate_per_unit = data["settings"]["sbase"]
    for row in 1:size(r)[1]
        for (_, branch) in data["branch"]
            if branch["name"] == "$row"
                branch["rate_a"] = fill(r[row, 1]/rate_per_unit, 3)
            end
        end
    end
    return data
end