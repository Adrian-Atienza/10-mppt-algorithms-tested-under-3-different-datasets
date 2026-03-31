# 10-mppt-algorithms-tested-under-3-different-datasets
This is a Matlab/Simulink simulation of 10 algorithms (P&O, IncCond, SMC, RCC, FSB, FLC, ANN, PSO, GA, GWO) under 3 datasets: Mid-Latitude, Cloud Transient, and Tropical.

# How to use it:
1. Open all 10 MPPT algorithm matlab files, build_scenarios, analyze_all_results, run_all, metrics_engine, and compute_algorithm_rank_stability. Open pv_environment.slx as well.
2. Run build_scenarios to establish the 3 datasets to create 4 scenarios (clear, ramp, step, and mixed)
3. Run run_all and this will run 120 simulations (10 algorithms x 3 datasets x 4 scenarios). If any existing simulation is done, it will skip to next simulation. This allows users to delete any simulation file they wish to redo and re-simulate only specific simulations.
4. To view results, run metrics_engine and this will visualize the data and also create .csv files of the results.
5. This thesis used a new entropy-weighted metric called algorithm rank stability (ARS) which determines which metric holds more weight in deciding which MPPT algorithsm to use. Run compute_algorithm_rank_stability to visualize the results and also create .csv files of results.

Simulation files are stored in results folder while the results for metrics are in the analysis_results folder.
To delete and re-simulate specific simulations (scenario x algorithm x dataset), go to results folder and delete the simulation files you wish to re-simulate.

A .zip file is in the repository which shows a version of the file with completed results. 
