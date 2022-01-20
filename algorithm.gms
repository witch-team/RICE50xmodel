#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================
* launch optimization logic, passing full sequence of coalition-changing-times
* This will result in a sequence of progressive optimizations, 
* one for each %coalitions_t_sequence% time passed
$batinclude "algorithm/optimization_loop" %coalitions_t_sequence%


