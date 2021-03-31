# MODULE TEMPLATE
*
* Short description 
#____________
# REFERENCES
* - 
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
* Definition of the global flags and settings specific to the module 
$ifthen.ph %phase%=='conf'


##  SETTING CONF ---------------------------------------
* These can be changed by the user to explore alternative scenarios
$setglobal xxx "value"


##  CALIBRATED CONF ------------------------------------
* These settings shouldn't be changed
$setglobal xxx "value"

$ifi not %conf%=='VALUE' $abort 'USER ERROR:' 




## SETS
#_________________________________________________________________________
* In the phase SETS you should declare all your sets, or add to the existing 
* sets the element that you need.
$elseif.ph %phase%=='sets'




## INCLUDE DATA
#_________________________________________________________________________
* In the phase INCLUDE_DATA you should declare and include all exogenous parameters. 
* You can also modify the data loaded in data.gms
* Best practice : - create a .gdx containing those and to loading it 
*                 - this is the only phase where we should have numbers...
$elseif.ph %phase%=='include_data'

##  PARAMETERS HARDCODED OR ASSIGNED ------------------- 

##  PARAMETERS LOADED ----------------------------------

##  PARAMETERS EVALUATED -------------------------------




##  COMPUTE DATA
#_________________________________________________________________________
* In the phase COMPUTE_DATA you should declare and compute all the parameters 
* that depend on the data loaded in the previous phase. 
$elseif.ph %phase%=='compute_data'



##  DECLARE VARIABLES
#_________________________________________________________________________
* In the phase DECLARE VARS, you can DECLARE new variables for your module. 
* Remember that by modifying sets, you already have some variables for free.
$elseif.ph %phase%=='declare_vars'



##  COMPUTE VARIABLES
#_________________________________________________________________________
* In the phase COMPUTE_VARS, you fix starting points and bounds.
* DO NOT put VAR.l here! (use the declare_vars phase) 
$elseif.ph %phase%=='compute_vars'


##  STABILITY CONSTRAINTS ------------------------------
* to avoid errors/help the solver to converge



#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
* List of equations
* One per line.
$elseif.ph %phase%=='eql'


##  EQUATIONS
#_________________________________________________________________________
* In the phase EQS, you can include new equations to the model.
* The equations are always included.
* Best practice : - condition your equation to be able to do a run with tfix(t) 
$elseif.ph %phase%=='eqs'

eq_linear(t)$(not tfix(t))..   X(t)  =E=  alpha * Y(t) + Z(t) ;



##  FIX VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='fix_variables'
* This phase is done after the phase POLICY.
* You should fix all your new variables.
* Remember, quantities are fixed up to the last tfix, while investment only 
* up to tfix-1
* Best practices : 
* - Use the provided macro in policy_fix
* - Your module should be able to do a tfix run

* fix variable MY_VAR(t,n) in tfix
#tfixvar(MY_VAR,'(t,n)')

* fix variable MY_VAR_INVEST(t,n) in tfix
tfix1var(MY_VAR_INVEST,'(t,n)')







##  BEFORE SOLVE
#_________________________________________________________________________
* In the phase BEFORE_SOLVE, you can update parameters (fixed
* variables, ...) inside the nash loop and right before solving the
* model. This is typically done for externalities, spillovers, ...
* Best practice: record the variable that you update across iterations.
* Remember that you are inside the nash loop, so you cannot declare
* parameters, ...
$elseif.ph %phase%=='before_solve'


alpha = log(X.l(t)/Y.l(t));
alpha_iter(siter)=alpha;









##  PROBLEMATIC REGIONS
#_________________________________________________________________________
* You enter this phase if any region is having difficulties in finding a solution.
* Before running it serially, you may have provide some ad-hoc help. 
$elseif.ph %phase%=='problematic_regions'



##  AFTER SOLVE
#_________________________________________________________________________
* In the phase AFTER_SOLVE, you compute what must be propagated across the 
* regions after one bunch of parallel solving.
$elseif.ph %phase%=='after_solve'


#=========================================================================
*   ///////////////////////     SIMULATION    ///////////////////////
#=========================================================================

##  SIMULATION SETUP
#_________________________________________________________________________
* In this phase you have either to fix free variables or to declare useful
* parameters for the simulation loop.
* You are NOT inside a loop(t,..) at this stage.
$elseif.ph %phase%=='set_simulation'



##  SIMULATION HALFLOOP 1
#_________________________________________________________________________
* In the phase SIM1, you have to replicate all equations but keeping VAR.l instead
* of the pure variable and '=' instead =E=.
* Consider that you ARE inside a loop(t, ..),therefore NOTHING can be declared as new
$elseif.ph %phase%=='simulate_1'



##  SIMULATION HALFLOOP 2
#_________________________________________________________________________
* In the phase SIM2, you have to replicate all equations but keeping VAR.l instead
* of the pure variable and '=' instead =E=.
* Everything declared at halfloop1 has already been executed.
* Consider that you ARE inside a loop(t, ..),therefore NOTHING can be declared as new
$elseif.ph %phase%=='simulate_2'



##  AFTER SIMULATION
#_________________________________________________________________________
* In this phase you are OUTSIDE the loop(t,..), at the end of the simulation process.
$elseif.ph %phase%=='after_simulation'



#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  REPORT
#_________________________________________________________________________
* Post-solve evaluate report measures
$elseif.ph %phase%=='report'


##  LEGACY ITEMS ---------------------------------------
* Backward compatibility in outpunt naming
* These items will be soon removed in future model updates #TODO#


##  GDX ITEMS
#_________________________________________________________________________
* List the items to be kept in the final gdx
$elseif.ph %phase%=='gdx_items'


# Sets (excl. aliases) ---------------------------------

# Parameters -------------------------------------------

# Variables --------------------------------------------

# Equations (only for OPT. run_mode) -------------------


$endif.ph
