function objective_minimize_cost_with_candidates(pm::_PMD.AbstractUnbalancedPowerModel)
    return JuMP.@objective(pm.model, Min,
          sum(_PMD.var(pm, 0, :z_reg, i)*300000 for i in _PMD.ids(pm, 0, :bus))  # cost regulators
        + sum(_PMD.var(pm, 0, :z_upg_2500, i)*(150000 + 15000*2500/1000) for i in _PMD.ids(pm, 0, :branch)) # cost 2500 kVA upgrades
        + sum(_PMD.var(pm, 0, :z_upg_5000, i)*(150000 + 15000*5000/1000) for i in _PMD.ids(pm, 0, :branch)) # cost 5000 kVA upgrades
        + sum(_PMD.var(pm, 0, :z_upg_7500, i)*(150000 + 15000*7500/1000) for i in _PMD.ids(pm, 0, :branch)) # cost 7500 kVA upgrades
        + sum(_PMD.var(pm, 0, :z_bat, i)*300000 for i in _PMD.ids(pm, 0, :load)) # cost batteries
    )
end