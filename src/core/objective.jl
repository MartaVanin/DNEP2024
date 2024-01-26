function objective_minimize_cost_lowcost_proj(pm::_PMD.AbstractUnbalancedPowerModel)
    nw = 1 # all investments are time-indep
    return JuMP.@objective(pm.model, Min,
          sum(_PMD.var(pm, nw, :z_reg, i)*300000 for i in _PMD.ids(pm, nw, :bus) if _PMD.ref(pm, nw, :bus, i, "bus_type") != 3 && !occursin("virtual", _PMD.ref(pm, nw, :bus, i, "name")))  # cost regulators
         +sum(_PMD.var(pm, nw, :c_bat_r, i)*160+_PMD.var(pm, nw, :c_bat_c, i)*120 for i in _PMD.ids(pm, nw, :load)) # cost batteries
         +sum(_PMD.var(pm, nw, :z_upg_fix, i)*150000+_PMD.var(pm, nw, :z_upg_var, i)*15000 for i in _PMD.ids(pm, nw, :branch) if !occursin("virtual", _PMD.ref(pm, nw, :branch, i, "name"))) # cost upgrades
    )
end

function objective_minimize_cost_midcost_proj(pm::_PMD.AbstractUnbalancedPowerModel)
    nw = 1 # all investments are time-indep
    return JuMP.@objective(pm.model, Min,
          sum(_PMD.var(pm, nw, :z_reg, i)*300000 for i in _PMD.ids(pm, nw, :bus) if _PMD.ref(pm, nw, :bus, i, "bus_type") != 3 && !occursin("virtual", _PMD.ref(pm, nw, :bus, i, "name")))  # cost regulators
         +sum(_PMD.var(pm, nw, :c_bat_r, i)*200+_PMD.var(pm, nw, :c_bat_c, i)*150 for i in _PMD.ids(pm, nw, :load)) # cost batteries
         +sum(_PMD.var(pm, nw, :z_upg_fix, i)*150000+_PMD.var(pm, nw, :z_upg_var, i)*15000 for i in _PMD.ids(pm, nw, :branch) if !occursin("virtual", _PMD.ref(pm, nw, :branch, i, "name"))) # cost upgrades
    )
end

function objective_minimize_cost_highcost_proj(pm::_PMD.AbstractUnbalancedPowerModel)
    nw = 1 # all investments are time-indep
    return JuMP.@objective(pm.model, Min,
          sum(_PMD.var(pm, nw, :z_reg, i)*300000 for i in _PMD.ids(pm, nw, :bus) if _PMD.ref(pm, nw, :bus, i, "bus_type") != 3 && !occursin("virtual", _PMD.ref(pm, nw, :bus, i, "name")) )  # cost regulators
         +sum(_PMD.var(pm, nw, :c_bat_r, i)*210*_PMD.ref(pm, 1, "settings")["sbase_default"]                                   # cost battery rating
             +_PMD.var(pm, nw, :c_bat_c, i)*195*_PMD.ref(pm, 1, "settings")["sbase_default"] for i in _PMD.ids(pm, nw, :load)) # cost battery capacity
         +sum(_PMD.var(pm, nw, :z_upg_fix, i)*_PMD.ref(pm, nw, :branch, i, "fixed_upgrade_cost") 
             +_PMD.var(pm, nw, :z_upg_var, i)*_PMD.ref(pm, nw, :branch, i, "variable_upgrade_cost_per_pu")*_PMD.ref(pm, 1, "settings")["sbase_default"] for i in _PMD.ids(pm, nw, :branch) if !occursin("virtual", _PMD.ref(pm, nw, :branch, i, "name"))) # cost upgrades
    )
end