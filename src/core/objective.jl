function objective_minimize_cost_lowcost_proj(pm::_PMD.AbstractUnbalancedPowerModel)
    return JuMP.@objective(pm.model, Min,
          sum(_PMD.var(pm, 0, :z_reg, i)*300000 for i in _PMD.ids(pm, 0, :bus))  # cost regulators
         +sum(_PMD.var(pm, 0, :c_bat_r, i)*160+_PMD.var(pm, 0, :c_bat_c, i)*120 for i in _PMD.ids(pm, 0, :load)) # cost batteries
         +sum(_PMD.var(pm, 0, :z_upg_fix, i)*150000+_PMD.var(pm, 0, :z_upg_var, i)*15000 for i in _PMD.ids(pm, 0, :branch)) # cost upgrades
    )
end

function objective_minimize_cost_midcost_proj(pm::_PMD.AbstractUnbalancedPowerModel)
    return JuMP.@objective(pm.model, Min,
          sum(_PMD.var(pm, 0, :z_reg, i)*300000 for i in _PMD.ids(pm, 0, :bus))  # cost regulators
         +sum(_PMD.var(pm, 0, :c_bat_r, i)*200+_PMD.var(pm, 0, :c_bat_c, i)*150 for i in _PMD.ids(pm, 0, :load)) # cost batteries
         +sum(_PMD.var(pm, 0, :z_upg_fix, i)*150000+_PMD.var(pm, 0, :z_upg_var, i)*15000 for i in _PMD.ids(pm, 0, :branch)) # cost upgrades
    )
end

function objective_minimize_cost_highcost_proj(pm::_PMD.AbstractUnbalancedPowerModel)
    return JuMP.@objective(pm.model, Min,
          sum(_PMD.var(pm, 0, :z_reg, i)*300000 for i in _PMD.ids(pm, 0, :bus))  # cost regulators
         +sum(_PMD.var(pm, 0, :c_bat_r, i)*210+_PMD.var(pm, 0, :c_bat_c, i)*195 for i in _PMD.ids(pm, 0, :load)) # cost batteries
         +sum(_PMD.var(pm, 0, :z_upg_fix, i)*150000+_PMD.var(pm, 0, :z_upg_var, i)*15000 for i in _PMD.ids(pm, 0, :branch)) # cost upgrades
    )
end