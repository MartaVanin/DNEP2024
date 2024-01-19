##
## You need to activate the environment in `path_to/DNEP2024` before you can run the below
## dependencies are installed automatically the first time you do so.
##

import DNEP2024 as _DNEP
import PowerModelsDistribution as _PMD
using Gurobi
using Cbc

data = _DNEP.get_33bus_network()
mn_data = _DNEP.add_timeseries_33bus!(data; n_timesteps = 30)
solver = _PMD.optimizer_with_attributes(Cbc.Optimizer, "seconds" => 60)#, "TimeLimit" => 60)

res = _DNEP.solve_milp_dnep(mn_data, _PMD.LinDist3FlowPowerModel, solver, multinetwork=true)