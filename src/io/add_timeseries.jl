function add_timeseries_33bus!(data::Dict; resolution = 1)
    ts_gen = CSV.read(joinpath(BASE_DIR, "data/33Bus-Modified/Profiles/GenerationProfile.csv"), _DF.DataFrame, ntasks=1, header = 0) # unitless multipliers of rated generator size
    ts_dem = CSV.read(joinpath(BASE_DIR, "data/33Bus-Modified/Profiles/DemandProfiles.csv"), _DF.DataFrame, ntasks=1, header = 0)    # is in kW
    pf = CSV.read(joinpath(BASE_DIR, "data/33Bus-Modified/OpenDSS_Model/PowerFactors.csv"), _DF.DataFrame, ntasks=1, header = 0)     # power factors for the demand

    mn_data = Dict{String, Any}(
                "nw" => Dict{String, Any}(),
                "is_kron_reduced" => true,
                "conductor_ids" => [1, 2, 3],
                "name" => data["name"],
                "is_projected" => data["is_projected"],
                "per_unit" => data["per_unit"],
                "map" => data["map"],
                "data_model" => data["data_model"],
                "settings" => data["settings"],
                "bus_lookup" => data["bus_lookup"],
                "multinetwork" => true
            )

    n_timesteps = Int(size(ts_gen,1) / resolution)      
    for t in 1:n_timesteps
        t_idx = 1 + resolution * (t-1)
        mn_data["nw"]["$t"] = Dict{String, Any}()
        mn_data["nw"]["$t"] = deepcopy(data)
        for (l, load) in mn_data["nw"]["$t"]["load"]
            conns = load["connections"] # active load connections
            if haskey(load, "was_gen") # there is only one generation profile for all
                load["pd"] = fill(-ts_gen[t_idx, 1]*264.75/length(conns), length(conns)) ./ data["settings"]["sbase_default"] # generators all have size 264.75
                load["qd"] = fill(0., length(conns)) # generation always have PF = 1
            else
                original_load_id = parse(Int, load["name"]) # as in openDSS. PMD scrambles the ids when it builds the dict
                if original_load_id == 1
                    delete!(mn_data["nw"]["$t"]["load"], l) # in the .dss there is a load by the slackbus with always 0 power. confusing. let's just remove it
                else
                    load["pd"] = fill(ts_dem[t_idx, original_load_id]/length(conns), length(conns)) ./ data["settings"]["sbase_default"] 
                    load["qd"] = fill(ts_dem[t_idx, original_load_id]/length(conns), length(conns)) ./ data["settings"]["sbase_default"] * tan(acos(pf[original_load_id, 1])) 
                end
            end
        end
    end
    return mn_data
end

function add_timeseries_irish!(data::Dict; resolution = 1)
    ts_gen = CSV.read(joinpath(BASE_DIR, "data/IrishMVGrid/Profiles/GenerationProfileDingle.csv"), _DF.DataFrame, header = 0) # unitless multipliers of rated generator size
    ts_dem = CSV.read(joinpath(BASE_DIR, "data/IrishMVGrid/Profiles/DemandProfileDingle.csv"), _DF.DataFrame, header = 0)    # unitless multipliers of rated load size
    load_info = CSV.read(joinpath(BASE_DIR, "data/IrishMVGrid/OpenDSS_Model/PowerFactors.csv"), _DF.DataFrame, header = 1) # rated P and Q for loads (power factor not really used). header = 1 is deliberate

    mn_data = Dict{String, Any}(
                "nw" => Dict{String, Any}(),
                "is_kron_reduced" => true,
                "conductor_ids" => [1, 2, 3],
                "name" => data["name"],
                "is_projected" => data["is_projected"],
                "per_unit" => data["per_unit"],
                "map" => data["map"],
                "data_model" => data["data_model"],
                "settings" => data["settings"],
                "bus_lookup" => data["bus_lookup"]
            )

    n_timesteps = Int(size(ts_gen,1) / resolution)  
    for t in 1:n_time_steps
        t_idx = 1 + resolution * (t-1)
        mn_data["nw"]["$t"] = Dict{String, Any}()
        mn_data["nw"]["$t"] = deepcopy(data)
        for (_, load) in mn_data["nw"]["$t"]["load"]
            if haskey(load, "was_gen")
                load["pd"] = fill(-ts_gen[t_idx, 1]/length(conns), length(conns)) ./ data["settings"]["sbase_default"]
                load["qd"] = fill(0., length(conns)) # generation always have PF = 1
            else
                original_load_id = parse(Int, load["name"]) # as in openDSS. PMD scrambles the ids
                load["pd"] = fill(ts_dem[t_idx, original_load_id]/length(conns), length(conns)) ./ data["settings"]["sbase_default"] * load_info.kW[original_load_id]
                load["qd"] = fill(ts_dem[t_idx, original_load_id]/length(conns), length(conns)) ./ data["settings"]["sbase_default"] * load_info.kvar[original_load_id]
            end
        end
    end
    return mn_data
end