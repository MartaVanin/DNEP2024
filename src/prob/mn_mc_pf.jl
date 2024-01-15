
function solve_mc_mn_acr_pf(data::Union{Dict{String,<:Any},String}, solver; kwargs...)
    return _PMD.solve_mc_model(data, _PMD.ACRUPowerModel, solver, build_mc_mn_pf; multinetwork=true, kwargs...)
end

"Constructor for multiperiod Power Flow Problem"
function build_mc_mn_pf(pm::_PMD.AbstractUnbalancedPowerModel)

    for (t, timestep) in _PMD.nws(pm)
        _PMD.variable_mc_bus_voltage(pm; nw = t, bounded = false)
        _PMD.variable_mc_branch_power(pm; nw = t, bounded = false)
        _PMD.variable_mc_generator_power(pm; nw = t, bounded = false)
        _PMD.variable_mc_load_power(pm; nw=t, bounded=false)

        _PMD.constraint_mc_model_voltage(pm, nw = t)

        for (i,bus) in _PMD.ref(pm, t, :ref_buses)
            @assert bus["bus_type"] == 3

            _PMD.constraint_mc_theta_ref(pm, i, nw = t)
            _PMD.constraint_mc_voltage_magnitude_only(pm, i, nw = t)
        end

        for id in _PMD.ids(pm, t, :gen)
            _PMD.constraint_mc_generator_power(pm, id, nw = t)
        end

        for id in _PMD.ids(pm, t, :load)
            _PMD.constraint_mc_load_power(pm, id, nw = t)
        end

        for (i,bus) in _PMD.ref(pm, t, :bus)
            _PMD.constraint_mc_power_balance(pm, i, nw = t)
        end

        for i in _PMD.ids(pm, t, :branch)
            _PMD.constraint_mc_ohms_yt_from(pm, i, nw = t)
            _PMD.constraint_mc_ohms_yt_to(pm, i, nw = t)
        end
    end

end

function build_mn_mc_pf(pm::AbstractUBFModels)

    # Variables
    for n in _PMD.nws(pm)
        _PMD.variable_mc_bus_voltage(pm; bounded=false)
        _PMD.variable_mc_branch_current(pm)
        _PMD.variable_mc_branch_power(pm)
        _PMD.variable_mc_switch_power(pm)
        # _PMD.variable_mc_transformer_power(pm; bounded=false)
        _PMD.variable_mc_generator_power(pm; bounded=false)
        _PMD.variable_mc_load_power(pm)
        _PMD.variable_mc_storage_power(pm; bounded=false)
    end

    # Constraints
    for n in _PMD.nws(pm)
        _PMD.constraint_mc_model_current(pm)

        for (i,bus) in _PMD.ref(pm, :ref_buses)
            if !(typeof(pm)<:_PMD.LPUBFDiagPowerModel)
                _PMD.constraint_mc_theta_ref(pm, i)
            end

            @assert bus["bus_type"] == 3
            _PMD.constraint_mc_voltage_magnitude_only(pm, i)
        end

        for id in _PMD.ids(pm, :gen)
            _PMD.constraint_mc_generator_power(pm, id)
        end

        for id in _PMD.ids(pm, :load)
            _PMD.constraint_mc_load_power(pm, id)
        end

        for (i,bus) in _PMD.ref(pm, :bus)
            _PMD.constraint_mc_power_balance(pm, i)
        end

        for i in _PMD.ids(pm, :storage)
            _PMD.constraint_storage_state(pm, i)
            _PMD.constraint_storage_complementarity_nl(pm, i)
            _PMD.constraint_mc_storage_losses(pm, i)
            _PMD.constraint_mc_storage_thermal_limit(pm, i)
        end

        for i in _PMD.ids(pm, :branch)
            _PMD.constraint_mc_power_losses(pm, i)
            _PMD.constraint_mc_model_voltage_magnitude_difference(pm, i)
            _PMD.constraint_mc_voltage_angle_difference(pm, i)
        end

        for i in _PMD.ids(pm, :switch)
            _PMD.constraint_mc_switch_state(pm, i)
        end

        for i in _PMD.ids(pm, :transformer)
            _PMD.constraint_mc_transformer_power(pm, i)
        end
    end

end