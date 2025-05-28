* MODULE WELFARE
*
* Welfare and utility function definitions
*____________
* REFERENCES
* Berger, Loic, and Johannes Emmerling (2020): Welfare as Equity Equivalents, Journal of Economic Surveys 34, no. 4 (26 August 2020): 727-752. https://doi.org/10.1111/joes.12368.
*
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

##  SETTING CONF ---------------------------------------
# These can be changed by the user to explore alternative scenarios

# Social Welfare Function:  dice | disentangled
$setglobal swf 'disentangled'

* Time Discount Rate (rho) of the Ramsey equation
* [0.001, 0.03] with default 0.015 in DICE2016
$setglobal prstp 0.015

* Elasticity of marginal utility of consumption in the Ramsey equation
* with default 1.45 in DICE2016
$setglobal elasmu 1.45

* Inequality aversion
* Range: [0,1.5]; good options: | 0 | 0.5 | 1.45 | 2 |
$setglobal gamma 0.5

# WELFARE GDP-ADJUSTMENT
* | PPP | MER |
$setglobal gdpadjust 'PPP'

# UTILITY SCALING COEFFICIENTS
* these are unnecessary for the calculations but help optimizer covergence.
$setglobal dice_scale1   1e-4   #DICE2013: 0.016408662    #DICE2016: 0.0302455265681763
$setglobal dice_scale2   0      #DICE2013: -3855.106895   #DICE2016: -10993.704

## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

$if %swf%=='disentangled' $if %region_weights%=='negishi' $abort 'Negishi weights require dice welfare function (--swf=dice)';


## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

PARAMETERS
* Preferences
    elasmu          'Elasticity of marginal utility of consumption'   /  %elasmu%  / # DICE16 1.45 (alpha)
    prstp           'Initial rate of social time preference per year' /  %prstp%   / # DICE16 .015 (ro-discount rate)
;


* Scaling options to help convergence
PARAMETERS
   dice_scale1  'Scaling factor'    / %dice_scale1% /
   dice_scale2  'Scaling factor'    / %dice_scale2% /

   gamma  'Inequality aversion' / %gamma% /
;

PARAMETERS
   nweights(t,n)         'Weights used in the welfare of the cooperative solution'
   rr(t)                 'Average utility Social Discount rate'
;

PARAMETERS
   welfare_bge(n)
   welfare_regional(n)
;

##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

# WEIGHTS ----------------------------------------------
* Initialized at 1,
* they change in the 'solve_region' file AFTER FIRST ITERATION
nweights(t,n) = 1;

* Discount factor
rr(t)  =  1 / ( (1+prstp)**(tstep*(tperiod(t)-1)) );


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
   PERIODU(t,n)      'One period utility function'
   CEMUTOTPER(t,n)   'Period utility'
   TUTILITY(t)       'Intra-region utility'
   UTILITY           'Welfare function'
   UTARG(t,n)        'Argument of the utility function'
;


##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

TUTILITY.lo(t) = 1e-3 ; # needed because of eq_utility (disentangled)


#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

eq_utility_arg       # Argument fo the instantanteous utility function
eq_util              # Objective function
$ifthen.wf '%swf%'=='dice'
   eq_cemutotper     # Period utility
   eq_periodu        # Instantaneous utility function equation           
$endif.wf


##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

$if not set alternative_utility eq_utility_arg(t,n)$(reg(n)).. UTARG(t,n) =E= CPC(t,n);

* Disentangled welfare function (within coalitions, using inequality aversion basd on gamma)
$ifthen.wf '%swf%'=='disentangled' #(DEFAULT)
eq_util.. UTILITY  =E=  sum(t, PROB.l(t) * ( ( ( (sum(n$reg(n),  pop(t,n)/sum(nn$reg(nn),pop(t,nn)) * ((UTARG(t,n))**(1-gamma))))**((1-elasmu)/(1-gamma))) / (1-elasmu) ) - 1 )  * rr(t) );

$elseif.wf '%swf%'=='stochastic'

eq_welfare(t).. TUTILITY(t)  =E=  sum(n$reg(n),  pop(t,n)/sum(nn$reg(nn),pop(t,nn))  *  ((UTARG(t,n))**(1-gamma))  );

eq_util.. UTILITY  =E=  ( (sum(t$((tperiod(t) lt t_resolution_one)), rr(t)/sum(ttt,rr(ttt)*PROB.l(ttt)) * TUTILITY(t)**((1-elasmu)/(1-gamma)))) +
          (sum(t$branch_node(t, 'branch_1'), rr(t)/sum(ttt,rr(ttt)*PROB.l(ttt)) * (sum(tt$(year(tt) eq year(t)), PROB.l(tt) * TUTILITY(tt)**((1-rra)/(1-gamma))) ) **((1-elasmu)/(1-rra))))
          ) **(1/(1-elasmu))  * 1e6;

$else.wf
* Original DICE welfare function adapted to multiregion
eq_cemutotper(t,n)$(reg(n))..  CEMUTOTPER(t,n)  =E=  PERIODU(t,n) * rr(t) * pop(t,n)  ;

eq_periodu(t,n)$(reg(n))..  PERIODU(t,n)  =E=  ( (UTARG(t,n))**(1-elasmu) - 1)/(1-elasmu) - 1  ;

eq_util..   UTILITY   =E=  (dice_scale1 * tstep * sum((t,n)$map_nt, nweights(t,n) * PROB.l(t) * CEMUTOTPER(t,n) )) + dice_scale2  ;
$endif.wf

##  AFTER SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='after_solve'

#reporting some welfare measures (for regions, abstracting from inequality aversion)
welfare_regional(n)$nsolve(n) = (sum(t, PROB.l(t) * ( ( pop(t,n) * (UTARG.l(t,n)**(1-elasmu)) / (1-elasmu) ) )  * rr(t) ));
welfare_bge(n)$nsolve(n) = ( welfare_regional(n) / (sum(t, PROB.l(t) * ( ( pop(t,n) / (1-elasmu) ) )  * rr(t) )) )**(1/(1-elasmu));

#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# Parameters -------------------------------------------
nweights
welfare_bge
welfare_regional

# Variables --------------------------------------------
UTILITY
UTARG

$endif.ph
