#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================
$ifthen.opt %run_mode% == 'optimization'
* launch optimization logic, passing full sequence of coalition-changing-times
* This will result in a sequence of progressive optimizations, 
* one for each %coalitions_t_sequence% time passed
$batinclude "algorithm/optimization_loop" %coalitions_t_sequence%
$endif.opt


#=========================================================================
*   ///////////////////////     SIMULATION    ///////////////////////
#=========================================================================
$ifthen.sim %run_mode% == 'simulation'
* Starting setup
$batinclude "modules" "set_simulation"
* Main simulation (lloping over t) subdivided in 2 main phases
loop(t,
$batinclude "modules" "simulate_1"
$batinclude "modules" "simulate_2"
);
* After simulation
$batinclude "modules" "after_simulation"
* Convergence is straightforward
converged = 1;
$endif.sim

