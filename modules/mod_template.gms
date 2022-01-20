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


##  FIX VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='fix_variables'
* This phase is done after the phase POLICY.
* You should fix all your new variables.



##  BEFORE SOLVE
#_________________________________________________________________________
* In the phase BEFORE_SOLVE, you can update parameters (fixed
* variables, ...) inside the nash loop and right before solving the
* model. This is typically done for externalities, spillovers, ...
$elseif.ph %phase%=='before_solve'


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


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  REPORT
#_________________________________________________________________________
* Post-solve evaluate report measures
$elseif.ph %phase%=='report'


##  GDX ITEMS
#_________________________________________________________________________
* List the items to be kept in the final gdx
$elseif.ph %phase%=='gdx_items'


$endif.ph
