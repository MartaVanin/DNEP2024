"solve the DNEP problem"
function solve_milp_dnep(data::Union{Dict{String,<:Any},String}, model_type::Type, solver; kwargs...)
    return solve_mc_model(data, model_type, solver, build_mc_dnep; kwargs...)
end

"Constructor for DNEP optim. problem"
function build_mc_dnep(pm::AbstractUBFModels)

    # Variables
    for (t, timestep) in _PMD.nws(pm)
        _PMD.variable_mc_bus_voltage(pm; nw = t, bounded=false) # not bounded here, because bounds are variable if there is a regulator
        _PMD.variable_mc_branch_power(pm; nw = t, bounded=false) # as above
        variable_mc_load(pm; nw = t)                             # not bounded here, depends on battery presence
        _PMD.variable_mc_generator_power(pm; nw = t, bounded=true) # bounded here, only bus with gen is slackbus: other gens are negative loads!
        # the ones below are standard in PMD but not needed here because we use simplified models
        # _PMD.variable_mc_switch_power(pm; nw = t, bounded=true)
        # variable_mc_transformer_power(pm; bounded=false)
        # _PMD.variable_mc_storage_power(pm; nw = t, bounded=true)
    end
    # investments are not time dependent
    variable_all_candidates(pm)

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

        for id in _PMD.ids(pm, t, :load)
            _PMD.constraint_mc_load_power(pm, id, nw = t)
        end

        for (i,bus) in _PMD.ref(pm, t, :bus)
            _PMD.constraint_mc_power_balance(pm, i, nw = t)
        end

        # ASSUMPTION: batteries have no losses, so this is not needed
        # for i in ids(pm, t, :storage)
        #     # _PMD.constraint_storage_state(pm, i, nw = t)
        #     _PMD.constraint_storage_complementarity_nl(pm, i, nw = t)
        #     # _PMD.constraint_mc_storage_losses(pm, i, nw = t)
        #     _PMD.constraint_mc_storage_thermal_limit(pm, i, nw = t)
        # end

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
            constraint_dnep_line_power_rating(pm, i, nw = t)
        end

        for (i,load) in _PMD.ref(pm, t, :load)
            constraint_dnep_battery(pm, i, nw = t)
        end

    end
    objective_minimize_cost(pm)
end