*-------------------------------------------------------------------------------
* Stochastic tree
* Usage: --stochastic=s2branch --calibration=1
* where you want to consider an uncertain parameter, assign values
* like this: param(t)$branch_node(t, 'branch_1') = ...
*-------------------------------------------------------------------------------

## CONF
*-------------------------------------------------------------------
* Definition of the global flags and settings specific to the module
$ifthen.ph %phase%=='conf'

* Use endogenous probabilities
*$setglobal prob_endo

* Disentangled risk aversion
$setglobal rra '10'
parameter rra    'parameter of relative risk aversion'  /%rra%/;

* Different welfare orderings for disentangled preferences (else, default is 'tn' with uncertainty at global t level)
$setglobal swf stochastic

* Value in a specific year (use tt instead of t, not working in equations) here return AVERAGE value
$macro valuein(takeyear, expr) (sum(tt$(year(tt) eq &takeyear), PROB.l(tt) * &expr))

## SETS
#_________________________________________________________________________
* In the phase SETS you should declare all your sets, or add to the existing
* sets the element that you need.
$elseif.ph %phase%=='sets'

* Setup of the Stochastic Tree
set branch 'total number of branches'/
branch_1*branch_3
/;
parameter probability(branch) 'probabilities of each branch'/
branch_1  0.333
branch_2  0.334
branch_3  0.333
/;
scalar num_branches_one 'Number of branches after first resolution'    / 3 /;
scalar t_resolution_one 'time of the first resolution of uncertainty'  / 8 /;
scalar t_resolution_two 'time of the second resolution of uncertainty' / 59 /;
* set the second t_resolution to 31 if only one resolution specified

* dynamic set of branches to allow assigning branch-specific values
set branch_node(t, branch) 'sets for each branch after the first resolution of uncertainty';
branch_node(t, branch)$((ORD(t) ge t_resolution_one) and ORD(t) le (t_resolution_one-1+num_branches_one*(t_resolution_two-t_resolution_one)) and (round(((ORD(t)-(t_resolution_one-1))/(t_resolution_two-t_resolution_one))+0.499) eq ord(branch)))=yes;
*for more than one branch opening (need to CHECK branch_node always to verify it matches t/node names!)
branch_node(t, branch)$((ORD(t) ge (t_resolution_one+num_branches_one*(t_resolution_two-t_resolution_one))) and
(round(((ORD(t)-(t_resolution_one+num_branches_one*(t_resolution_two-t_resolution_one)))/(smax(tt, ORD(tt)) - t_resolution_two))+0.499) eq (ord(branch)-num_branches_one)))=yes;

##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

Variable PROB(t) 'Probability of states';

##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

* Create probability space based on branches (as variable to allow for endogenous probabilities)
PROB.fx(t)$(tperiod(t) lt t_resolution_one)=1;

$ifthen.pe not set prob_endo
LOOP(branch,
PROB.fx(t)$branch_node(t, branch) = probability(branch);
);
$else.pe
LOOP(branch,
PROB.lo(t)$(tperiod(t) ge t_resolution_one) = 0.001;
PROB.up(t)$(tperiod(t) ge t_resolution_one) = 0.999;
PROB.l(t)$branch_node(t, branch)=probability(branch);
);
variable PROB_ENDO;
PROB_ENDO.lo=0.001;
PROB_ENDO.up=0.999;
PROB_ENDO.l=probability('branch_1');
Parameter prob_endo_iter(iter);
$endif.pe

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

$ifthen.pe set prob_endo
eq_prob_endo_function_%clt%
eq_prob_endo_p_%clt%
eq_prob_endo_1mp_%clt%
$endif.pe

##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'


$ifthen.pe set prob_endo
*Equation that determines the function of the probability depending on other variables
eq_prob_endo_function_%clt%..
    PROB_ENDO =e= 1 - exp( -0.277  * TATM(t)); # calibrated to a 50% probability at 2.5degC in 2045

*assigning this value to the probability of each t
eq_prob_endo_p_%clt%(t)$branch_node(t, 'branch_1')..
    PROB(t) =e= PROB_ENDO;

eq_prob_endo_1mp_%clt%(t)$branch_node(t, 'branch_2')..
    PROB(t) =e= 1 - PROB_ENDO;
$endif.pe

##  AFTER SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='before_solve'

$if set prob_endo prob_endo_iter(iter) = PROB_ENDO.l;

##  AFTER SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='after_solve'

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

PROB
branch_node
probability
rra
$if set prob_endo PROB_ENDO
$if set prob_endo prob_endo_iter


$endif.ph
