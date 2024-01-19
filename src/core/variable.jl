"""
The load is variable in the sense that it is the "wished" 
demand/generation +/- the battery contribution
"""
function variable_mc_load(pm::_PMD.AbstractUnbalancedPowerModel; nw::Int=_IM.nw_id_default)
    variable_mc_load_active(pm, nw = nw)
    variable_mc_load_reactive(pm, nw = nw)
end

function variable_mc_load_active(pm::_PMD.AbstractUnbalancedPowerModel;
                                 nw::Int=_IM.nw_id_default)

    connections = Dict(i => load["connections"] for (i,load) in _PMD.ref(pm, nw, :load))

    pd = _PMD.var(pm, nw)[:pd] = Dict(i => JuMP.@variable(pm.model,
            [c in connections[i]], base_name="$(nw)_pd_$(i)",
            start = _PMD.comp_start_value(_PMD.ref(pm, nw, :load, i), "pd", c, 0.0) 
        ) for i in _PMD.ids(pm, nw, :load)
    )

    _IM.sol_component_value(pm, _PMD.pmd_it_sym, nw, :load, :pd, _PMD.ids(pm, nw, :load), pd)
end

function variable_mc_load_reactive(pm::_PMD.AbstractUnbalancedPowerModel;
                                 nw::Int=_IM.nw_id_default)

    connections = Dict(i => load["connections"] for (i,load) in _PMD.ref(pm, nw, :load))

    qd = _PMD.var(pm, nw)[:qd] = Dict(i => JuMP.@variable(pm.model,
            [c in connections[i]], base_name="$(nw)_qd_$(i)",
            start = _PMD.comp_start_value(_PMD.ref(pm, nw, :load, i), "qd", c, 0.0) 
        ) for i in _PMD.ids(pm, nw, :load)
    )

    _IM.sol_component_value(pm, _PMD.pmd_it_sym, nw, :load, :qd, _PMD.ids(pm, nw, :load), qd)
end
"""
Time-invariant investment variables
"""
function variable_all_investments(pm::_PMD.AbstractUnbalancedPowerModel)
    variable_regulator(pm)
    variable_auxiliary_battery_cap_cost(pm)
    variable_auxiliary_battery_rat_cost(pm)
    variable_infra_upgrade_fix(pm)
    variable_infra_upgrade_var(pm)
end
"""
Time-varying battery variables
"""
function variable_battery(pm::_PMD.AbstractUnbalancedPowerModel; nw::Int=_IM.nw_id_default)
    variable_battery_soc(pm, nw = nw)
    variable_battery_use(pm, nw = nw)
end

function variable_regulator(pm::_PMD.AbstractUnbalancedPowerModel)
    # all buses can have one (except the slack and a virtual bus), variable is binary
    nw = 1 # investment is for all timeserie
    excluded = [i for i in _PMD.ids(pm, nw, :bus) if _PMD.ref(pm, nw, :bus, i, "bus_type") == 3 || occursin("virtual", _PMD.ref(pm, nw, :bus, i, "name"))] # rules out slack + an artificial bus
    z_reg = _PMD.var(pm, nw)[:z_reg] = Dict(i => JuMP.@variable(pm.model,
            base_name="z_reg_$i",
            start = 0,
            binary = true
            ) 
            for i in _PMD.ids(pm, 1, :bus) if i ∉ excluded
        )
    _IM.sol_component_value(pm, _PMD.pmd_it_sym, nw, :bus, :z_reg, [i for i in _PMD.ids(pm, nw, :bus) if i ∉ excluded], z_reg) 
end
"""
Charging or discharging
"""
function variable_battery_use(pm::_PMD.AbstractUnbalancedPowerModel; nw::Int=_IM.nw_id_default)
    z_bat_r = _PMD.var(pm, nw)[:z_bat_r] = Dict(i => JuMP.@variable(pm.model,
            base_name="$(nw)_z_bat_r_$i",
            start = 0,
            lower_bound = 0.,
            upper_bound = 100., # could be "anything" though
            ) 
            for i in _PMD.ids(pm, nw, :load)
        )
    _IM.sol_component_value(pm, _PMD.pmd_it_sym, nw, :load, :z_bat_r, _PMD.ids(pm, nw, :load), z_bat_r) # this is to include the variable values in the solution dictionary
end

function variable_battery_soc(pm::_PMD.AbstractUnbalancedPowerModel; nw::Int=_IM.nw_id_default)

    z_bat_c = _PMD.var(pm, nw)[:z_bat_c] = Dict(i => JuMP.@variable(pm.model,
            base_name="$(nw)_z_bat_c_$i",
            start = 0,
            lower_bound = 0.,
            upper_bound = 100., # could be "anything" though
            ) 
            for i in _PMD.ids(pm, nw, :load)
        )
    _IM.sol_component_value(pm, _PMD.pmd_it_sym, nw, :load, :z_bat_c, _PMD.ids(pm, nw, :load), z_bat_c) # this is to include the variable values in the solution dictionary
end
"""
The auxiliary variables are needed to represent the maximum in the
objective function
"""
function variable_auxiliary_battery_rat_cost(pm::_PMD.AbstractUnbalancedPowerModel)
    nw = 1 # investment is for all timeserie
    # c_bat_r = # I decided not to report the value of the auxiliary variable, but can be changed ofc 
    _PMD.var(pm, nw)[:c_bat_r] = Dict(i => JuMP.@variable(pm.model,
            base_name="c_bat_r_$i",
            start = 0,
            lower_bound = 0.,
            upper_bound = 100., # could be "anything" though
            ) 
            for i in _PMD.ids(pm, nw, :load)
        )
end

function variable_auxiliary_battery_cap_cost(pm::_PMD.AbstractUnbalancedPowerModel)
    nw = 1 # investment is for all timeserie
    #c_bat_c = # I decided not to report the value of the auxiliary variable, but can be changed ofc
    _PMD.var(pm, nw)[:c_bat_c] = Dict(i => JuMP.@variable(pm.model,
            base_name="c_bat_c_$i",
            start = 0,
            lower_bound = 0.,
            upper_bound = 100., # could be "anything" though
            ) 
            for i in _PMD.ids(pm, nw, :load)
        )
end

function variable_infra_upgrade_fix(pm::_PMD.AbstractUnbalancedPowerModel)
    nw = 1 # investment is for all timeserie
    excluded =[i for i in _PMD.ids(pm, nw, :branch) if occursin("virtual", _PMD.ref(pm, nw, :branch, i, "name"))]
    z_upg_fix = _PMD.var(pm, nw)[:z_upg_fix] = Dict(i => JuMP.@variable(pm.model,
            base_name="z_upg_fix_$i",
            start = 0,
            binary = true
            ) 
            for i in _PMD.ids(pm, nw, :branch) if i ∉ excluded # excludes virtual branche (transfo)
        )
    _IM.sol_component_value(pm, _PMD.pmd_it_sym, nw, :branch, :z_upg_fix, [i for i in _PMD.ids(pm, nw, :branch) if i ∉ excluded], z_upg_fix) # this is to include the variable values in the solution dictionary
end

function variable_infra_upgrade_var(pm::_PMD.AbstractUnbalancedPowerModel)
    nw = 1 # investment is for all timeserie
    z_upg_var = _PMD.var(pm, nw)[:z_upg_var] = Dict(i => JuMP.@variable(pm.model,
            base_name="z_upg_var_$i",
            start = 0,
            lower_bound = 0.,
            upper_bound = 1e5
            ) 
            for i in _PMD.ids(pm, nw, :branch) if !occursin("virtual", _PMD.ref(pm, nw, :branch, i, "name")) # excludes virtual branche (transfo)
        )
    _IM.sol_component_value(pm, _PMD.pmd_it_sym, nw, :branch, :z_upg_var, [ i for i in _PMD.ids(pm, nw, :branch) if !occursin("virtual", _PMD.ref(pm, nw, :branch, i, "name"))], z_upg_var) # this is to include the variable values in the solution dictionary
end