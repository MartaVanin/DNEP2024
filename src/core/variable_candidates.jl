#########################################
### THIS IN PRINCIPLE IS NOT USED ATM ###
#########################################

function variable_all_candidates(pm::_PMD.AbstractUnbalancedPowerModel)
    variable_upgrade_infra_2500(pm)
    variable_upgrade_infra_5000(pm)
    variable_upgrade_infra_7500(pm)
    variable_regulator(pm)
    variable_battery(pm)
end

function variable_upgrade_infra_2500(pm::_PMD.AbstractUnbalancedPowerModel)
    # all branches upgradeable, variable is binary
    nw = 0 # investment is for all timeserie
    z_upg_2500 = _PMD.var(pm)[:z_upg_2500] = Dict(i => JuMP.@variable(pm.model,
            base_name="z_upg_2500_$i",
            start = 0,
            binary = true,
            ) 
            for i in _PMD.ids(pm, 0, :branch) if !occursin("virtual", _PMD.ref(pm, 0, :branch, i, "name")) # excludes virtual branche (transfo)
        )
    _IM.sol_component_value(pm, _PMD.pmd_it_sym, nw, :branch, :z_upg_2500, _PMD.ids(pm, nw, :branch), z_upg_2500) # this is to include the variable values in the solution dictionary
end

function variable_upgrade_infra_5000(pm::_PMD.AbstractUnbalancedPowerModel)
    # all branches upgradeable, variable is binary
    nw = 0 # investment is for all timeserie
    z_upg_5000 = _PMD.var(pm)[:z_upg_5000] = Dict(i => JuMP.@variable(pm.model,
            base_name="z_upg_5000_$i",
            start = 0,
            binary = true,
            ) 
            for i in _PMD.ids(pm, 0, :branch) if !occursin("virtual", _PMD.ref(pm, 0, :branch, i, "name")) # excludes virtual branche (transfo)
        )
    _IM.sol_component_value(pm, _PMD.pmd_it_sym, nw, :branch, :z_upg_5000, _PMD.ids(pm, nw, :branch), z_upg_5000) # this is to include the variable values in the solution dictionary
end

function variable_upgrade_infra_7500(pm::_PMD.AbstractUnbalancedPowerModel)
    # all branches upgradeable, variable is binary
    nw = 0 # investment is for all timeserie
    z_upg_7500 = _PMD.var(pm)[:z_upg_7500] = Dict(i => JuMP.@variable(pm.model,
            base_name="z_upg_7500_$i",
            start = 0,
            binary = true,
            ) 
            for i in _PMD.ids(pm, 0, :branch) if !occursin("virtual", _PMD.ref(pm, 0, :branch, i, "name")) # excludes virtual branche (transfo)
        )
    _IM.sol_component_value(pm, _PMD.pmd_it_sym, nw, :branch, :z_upg_7500, _PMD.ids(pm, nw, :branch), z_upg_7500) # this is to include the variable values in the solution dictionary
end
