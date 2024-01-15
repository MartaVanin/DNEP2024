function constraint_dnep_voltage_magnitude(pm::_PMD.AbstractUnbalancedPowerModel, i::Int; nw::Int=_IM.nw_id_default)
    w = _PMD.var(pm, nw, :w, i)
    terminals = _PMD.ref(pm, nw, :bus, i)["terminals"]
    grounded = _PMD.ref(pm, nw, :bus, i)["grounded"]

    wmax = [1.06, 1.06, 1.06].^2 # standard limits
    wmin = [0.94, 0.94, 0.94].^2 # standard limits
    extra_upper = 0.09 # extra range thanks to regulator
    extra_lower = 0.09 # extra range thanks to regulator

    z_reg = _PMD.var(pm, 0, :z_reg, i) # is there a regulator (z=1) or not (z=0)

    for (idx, t) in [(idx,t) for (idx,t) in enumerate(terminals) if !grounded[idx]]
        JuMP.@constraint(pm.model, w[t] <= wmax[idx]+extra_upper*z_reg)
        JuMP.@constraint(pm.model, w[t] >= wmin[idx]-extra_lower*z_reg)
    end
end
"""
THIS CONSTRAINT IS NOT LINEAR!
"""
function constraint_line_power_rating(pm::_PMD.AbstractUnbalancedPowerModel, i::Int; nw::Int=_IM.nw_id_default) 
    
    # get upgrade variables
    z_upg_var = _PMD.var(pm, 0, :z_upg_var, i)
    z_upg_fix = _PMD.var(pm, 0, :z_upg_fix, i) 

    # get branch indices
    branch = _PMD.ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)
    f_conn = branch["f_connections"]
    t_conn = branch["t_connections"]

    # the apparent power must be below the new rating:
    p_fr = [_PMD.var(pm, nw, :p, f_idx)[idx] for (idx,c) in enumerate(f_conn)] # c indicates the conductor
    q_fr = [_PMD.var(pm, nw, :q, f_idx)[idx] for (idx,c) in enumerate(f_conn)] # c indicates the conductor

    p_to = [_PMD.var(pm, nw, :p, t_idx)[idx] for (idx,c) in enumerate(t_conn)] # c indicates the conductor
    q_to = [_PMD.var(pm, nw, :q, t_idx)[idx] for (idx,c) in enumerate(t_conn)] # c indicates the conductor

    rate_per_unit = 100000.0

    for (idx,c) in enumerate(f_conn)
        JuMP.@constraint(pm.model, p_fr[idx]^2 + q_fr[idx]^2 <= rate_a[idx]^2+(z_upg_var/rate_per_unit)^2) # this is ugly...??
    end
    for (idx,c) in enumerate(t_conn)
        JuMP.@constraint(pm.model, p_to[idx]^2 + q_to[idx]^2 <= rate_a[idx]^2+(z_upg_var/rate_per_unit)^2) # this is ugly...??
    end

    # furthermore, there can only be an upgrade if the z_upg_fix is nonzero
    bigM = 6808 / rate_per_unit
    JuMP.@constraint(pm.model, z_upg_var <= z_upg_fix*bigM) # z_upg_var >= 0 is already enforced as bound in its definition

end

function constraint_load_battery_injection(pm::_PMD.AbstractUnbalancedPowerModel, i::Int; nw::Int=_IM.nw_id_default)
    z_bat_r = _PMD.var(pm, nw = nw, :z_bat_r, i)
    pd = _PMD.var(pm, nw=nw, :pd)
    qd = _PMD.var(pm, nw=nw, :qd)

    # TODO enumerate terminals!!!
    for (idx,c) in enumerate(t_conn)
        JuMP.@constraint(pm.model, pd[idx] == _PMD.ref(pm, :load, i, "pd")[idx]-z_bat_r)
        JuMP.@constraint(pm.model, qd[idx] == _PMD.ref(pm, :load, i, "qd")[idx]-z_bat_r)
    end
end

function constraint_battery_capacity(pm::_PMD.AbstractUnbalancedPowerModel, i::Int; nw::Int=_IM.nw_id_default)
    if nw == 1

    end
end

function constraint_power_balance(pm::_PMD.AbstractUnbalancedPowerModel, i::Int; nw::Int=_IM.nw_id_default)

    bus = _PMD.ref(pm, nw, :bus, i)
    bus_arcs = _PMD.ref(pm, nw, :bus_arcs_conns_branch, i)
    bus_arcs_sw = _PMD.ref(pm, nw, :bus_arcs_conns_switch, i)
    bus_arcs_trans = _PMD.ref(pm, nw, :bus_arcs_conns_transformer, i)
    bus_gens = _PMD.ref(pm, nw, :bus_conns_gen, i)
    bus_storage = _PMD.ref(pm, nw, :bus_conns_storage, i)
    bus_loads = _PMD.ref(pm, nw, :bus_conns_load, i)
    bus_shunts = _PMD.ref(pm, nw, :bus_conns_shunt, i)
    terminals = bus["terminals"]

    w = _PMD.var(pm, nw, :w, i)
    p   = get(_PMD.var(pm, nw),      :p,   Dict()); _PMD._check_var_keys(p,   bus_arcs, "active power", "branch")
    q   = get(_PMD.var(pm, nw),      :q,   Dict()); _PMD._check_var_keys(q,   bus_arcs, "reactive power", "branch")
    psw = get(_PMD.var(pm, nw),    :psw, Dict()); _PMD._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    qsw = get(_PMD.var(pm, nw),    :qsw, Dict()); _PMD._check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    pt  = get(_PMD.var(pm, nw),     :pt,  Dict()); _PMD._check_var_keys(pt,  bus_arcs_trans, "active power", "transformer")
    qt  = get(_PMD.var(pm, nw),     :qt,  Dict()); _PMD._check_var_keys(qt,  bus_arcs_trans, "reactive power", "transformer")
    pg  = get(_PMD.var(pm, nw),     :pg,  Dict()); _PMD._check_var_keys(pg,  bus_gens, "active power", "generator")
    qg  = get(_PMD.var(pm, nw),     :qg,  Dict()); _PMD._check_var_keys(qg,  bus_gens, "reactive power", "generator")
    ps  = get(_PMD.var(pm, nw),     :ps,  Dict()); _PMD._check_var_keys(ps,  bus_storage, "active power", "storage")
    qs  = get(_PMD.var(pm, nw),     :qs,  Dict()); _PMD._check_var_keys(qs,  bus_storage, "reactive power", "storage")
    pd  = get(_PMD.var(pm, nw),     :pd,  Dict()); _PMD._check_var_keys(pd,  bus_loads, "active power", "load")
    qd  = get(_PMD.var(pm, nw),     :qd,  Dict()); _PMD._check_var_keys(qd,  bus_loads, "reactive power", "load")

    cstr_p = []
    cstr_q = []

    ungrounded_terminals = [(idx,t) for (idx,t) in enumerate(terminals) if !grounded[idx]]

    for (idx,t) in ungrounded_terminals
        cp = JuMP.@constraint(pm.model,
                sum(  p[a][t] for (a, conns) in bus_arcs if t in conns)
            + sum(psw[a][t] for (a, conns) in bus_arcs_sw if t in conns)
            + sum( pt[a][t] for (a, conns) in bus_arcs_trans if t in conns)
            - sum( pg[g][t] for (g, conns) in bus_gens if t in conns)
            + sum( ps[s][t] for (s, conns) in bus_storage if t in conns)
            + sum( pd[d][t] for (d, conns) in bus_loads if t in conns)
            + sum(diag(_PMD.ref(pm, nw, :shunt, sh, "gs"))[findfirst(isequal(t), conns)]*w[t] for (sh, conns) in bus_shunts if t in conns)
            ==
            0.0
        )
        push!(cstr_p, cp)

        cq = JuMP.@constraint(pm.model,
                sum(  q[a][t] for (a, conns) in bus_arcs if t in conns)
            + sum(qsw[a][t] for (a, conns) in bus_arcs_sw if t in conns)
            + sum( qt[a][t] for (a, conns) in bus_arcs_trans if t in conns)
            - sum( qg[g][t] for (g, conns) in bus_gens if t in conns)
            + sum( qs[s][t] for (s, conns) in bus_storage if t in conns)
            + sum( qd[d][t] for (d, conns) in bus_loads if t in conns)
            - sum(diag(_PMD.ref(pm, nw, :shunt, sh, "bs"))[findfirst(isequal(t), conns)]*w[t] for (sh, conns) in bus_shunts if t in conns)
            ==
            0.0
        )
        push!(cstr_q, cq)
    end
end

"""
These auxiliary constraints are to incorporate the ``maximum" in the objective function
"""
function constraint_auxiliary_battery_cost(pm::_PMD.AbstractUnbalancedPowerModel, i::Int; nw::Int=_IM.nw_id_default)
    constraint_battery_cap(pm, i, nw = nw)
    constraint_battery_rat(pm, i, nw = nw)
end

function constraint_battery_cap(pm::_PMD.AbstractUnbalancedPowerModel, i::Int; nw::Int=_IM.nw_id_default)
    # to put the maximum in the objective, we 
    # want the auxiliary variable for the cost to have a greater value
    # than all calculated capacities at each timestep (nw)
    z_bat_c_nw = _PMD.var(pm, nw, :z_bat_c, i)
    c_bat_c = _PMD.var(pm, 0, :c_bat_c, i)
    JuMP.@constraint(pm.model, z_bat_c_nw <= c_bat_c)
end

function constraint_battery_rat(pm::_PMD.AbstractUnbalancedPowerModel, i::Int; nw::Int=_IM.nw_id_default)
    # to put the maximum in the objective, we 
    # want the auxiliary variable for the cost to have a greater value
    # than all calculated ratings at each timestep (nw)
    z_bat_r_nw = _PMD.var(pm, nw, :z_bat_r, i)
    c_bat_r = _PMD.var(pm, 0, :c_bat_r, i)
    JuMP.@constraint(pm.model, z_bat_r_nw <= c_bat_r)
end