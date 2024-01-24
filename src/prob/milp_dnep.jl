"solve the DNEP problem"
function solve_milp_dnep(data::Union{Dict{String,<:Any},String}, model_type::Type, solver; kwargs...)
    return _PMD.solve_mc_model(data, model_type, solver, build_mc_dnep; kwargs...)
end

"Constructor for DNEP optim. problem"
function build_mc_dnep(pm::_PMD.AbstractUBFModels)

    # Variables
    for (t, timestep) in _PMD.nws(pm)
        _PMD.variable_mc_bus_voltage(pm; nw = t, bounded=false) # not bounded here, because bounds are variable if there is a regulator
        _PMD.variable_mc_branch_power(pm; nw = t, bounded=false) # not bounded here, see ``constraint_dnep_line_power_rating``
        _PMD.variable_mc_generator_power(pm; nw = t, bounded=true) # bounded here, only bus with gen is slackbus: other gens are negative loads!
        variable_mc_load(pm; nw = t)                             # not bounded here, depends on battery presence
        variable_battery(pm; nw = t)
    end

    variable_all_investments(pm) # investment variables are time-independent

    # Constraints
    for (t, timestep) in _PMD.nws(pm)
        _PMD.constraint_mc_model_current(pm; nw = t)

        for (i,bus) in _PMD.ref(pm, t, :ref_buses) # this fixes voltage at slackbus
            if !(typeof(pm)<:_PMD.LPUBFDiagPowerModel)
                _PMD.constraint_mc_theta_ref(pm, i, nw = t)
            end
            @assert bus["bus_type"] == 3
            _PMD.constraint_mc_voltage_magnitude_only(pm, i, nw = t)
        end

        # ASSUMPTION: infrastructure reinforcement increases branch rating, but impedances are invariate
        # so no modification required here with respect to PMD
        for i in _PMD.ids(pm, t, :branch)
            _PMD.constraint_mc_power_losses(pm, i, nw = t)
            _PMD.constraint_mc_model_voltage_magnitude_difference(pm, i, nw = t)
            _PMD.constraint_mc_voltage_angle_difference(pm, i, nw = t)
        end

        ####### CONSTRAINTS SPECIFIC TO DNEP2024
        for (i,bus) in _PMD.ref(pm, t, :bus)
            constraint_dnep_voltage_magnitude(pm, i, nw = t) 
        end

        for (i,branch) in _PMD.ref(pm, t, :branch)
            constraint_line_power_rating(pm, i, nw = t)
            # constraint_line_power_rating_brutal_linearization(pm, i, nw = t)
        end

        for (i,bus) in _PMD.ref(pm, t, :bus)
            constraint_mc_power_balance(pm, i, nw = t) # we use our, not PMD! because PMD's does not have demand vars
        end

        # ASSUMPTION: batteries have no losses
        for i in _PMD.ids(pm, t, :load)
            constraint_load_battery_injection(pm, i, nw = t)
            constraint_battery_capacity(pm, i, nw = t)
            constraint_auxiliary_battery_cost(pm, i, nw = t)
        end

    end
    objective_minimize_cost_lowcost_proj(pm)
end