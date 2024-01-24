##
## You need to activate the environment in `path_to/DNEP2024` before you can run the below
## dependencies are installed automatically the first time you do so.
##

import DNEP2024 as _DNEP
import PowerModelsDistribution as _PMD
using Gurobi
using Cbc

data = _DNEP.get_33bus_network()
mn_data = _DNEP.add_timeseries_33bus!(data; n_timesteps = 1000)
solver = _PMD.optimizer_with_attributes(Gurobi.Optimizer, "TimeLimit" => 300) #"seconds" => 60)#, "TimeLimit" => 60)
res = _DNEP.solve_milp_dnep(mn_data, _PMD.LinDist3FlowPowerModel, solver, multinetwork = true)

data_ir = _DNEP.get_irish_network()