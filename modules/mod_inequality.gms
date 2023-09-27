# mod_inequality
*
* Short description
*activate with --mod_inequality=1
*integrate with utility function with --welfare_inequality=1
#____________
# REFERENCES
* -
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

# --welfare_inequality=1 activates internal inequality integration in the utility function
# --transfer=="OPTION" activates redistribution of carbon tax
# OPTIONS =   
#   - endo = endogenous redistribution of the carbon tax
#   - scheme = exogenous redistribution of the carbon tax, governed by el_redist
# --neg_redist=y/n requires transfer=="endo" or "epc" (ie gov_redist_ctax activated) and allows for "negative redistribution" for net negative emissions
# TO CALIBRATE damage elasticity:
# STEP 1: run --calib_damages=1, without policy specification, with the parameters you want to run (xi, omega, impact fun, quantiles time dependency)
# STEP 2: run the policy you wish, with the same specifications and --use_calib=1

# inequality parameters are declared x*10 for readibility of the result .gdx 
# write a zero before the number for decimals <1
# eg. xi 05 == 0.5

##  CONF
#_________________________________________________________________________
* Definition of the global flags and settings specific to the module
$ifthen.ph %phase%=='conf'

$If not exist "%datapath%data_mod_inequality_converted.gdx" $abort "Please run the translate_rice50x_data.R script again, uncommenting the last line ["source('input/convert_mod_inequality.R')]""

* Omega: takes values between 0 and 2
* 1 is the neutral value
$setglobal omega 05

* Elasticity to damages across quantiles: takes values between [-1;+1]
* 1 is the neutral value
$setglobal xi 85

* Elasticity of redistribution across quantiles for exogenous transfer schemes
$setglobal el_redist 0

* Internal inequality aversion
* Range: [0,1.5]; good options: | 0 | 0.5 | 1.45
$setglobal gammaint 50

* calibrate omega from Budolfson 2021
$setglobal omegacalib

* cap MIU to one
$setglobal max_miuup 1


$if not set calib_damages $setglobal welfare_inequality
$if set calib_damages $setglobal policy "bau_impact"
$if set calib_damages $setglobal transfer "neutral"

#policy flag
$if not set transfer  $setglobal transfer "neutral"
$if %transfer%=="epc" $setglobal el_redist 0

$if set calib_damages $setglobal nameout "calib_%baseline%_IMP%impact%_XI%xi%_Q%quant%"

*activate alternative utility function argument if active
$if set welfare_inequality $setglobal alternative_utility

## SETS
#_________________________________________________________________________
* In the phase SETS you should declare all your sets, or add to the existing
* sets the element that you need.
$elseif.ph %phase%=='sets'

set dist / D1*D10/;
alias(dist,ddist);

set ineq_elast / 'damages',
                 'abatement',
                 'redist'/; 

## INCLUDE DATA
#_________________________________________________________________________
* In the phase INCLUDE_DATA you should declare and include all exogenous parameters.
* You can also modify the data loaded in data.gms
* Best practice : - create a .gdx containing those and to loading it
*                 - this is the only phase where we should have numbers...
$elseif.ph %phase%=='include_data'

Scalar deltain /1e-3/;

Scalar gammaint;
gammaint = %gammaint%/100; 

Parameters quantiles_ref(t,n,dist);
Parameters inequality_parameters(t,n,*);

*to allow for quantiles of different sizes (eg deciles together with percentiles)
Parameter quant_share(dist); 
quant_share(dist) = 1/card(dist);

Parameter subsistance_level / 273.3 / ; # half of 1.9USDpc/day in 2005 US$/yr 
Parameter y_dist_min(t,n,dist); 

* Inequality data

$ifthen.cd set use_calib
Parameter ineq_weights_calib(t,n,dist)
$gdxin 'results_calib_%baseline%_IMP%impact%_XI%xi%_Q%quant%'
$load ineq_weights_calib = ineq_calib # inequality_parameters
$gdxin
$endif.cd 

Parameter quantiles_ref_ssp(ssp,t,n,dist);

$gdxin '%datapath%data_mod_inequality_converted'
$load quantiles_ref_ssp = quantiles # inequality_parameters
$gdxin

* for regiond where no within-country inequality data is available, assume perfect equality
quantiles_ref_ssp('%baseline%',t,n,dist)$(not quantiles_ref_ssp('%baseline%',t,n,dist)) = 0.1;

Parameter ineq_weights(t,n,dist,ineq_elast); 
Parameter el_coeff(ineq_elast); 

el_coeff('damages') = %xi%/100; # elasticity of damage costs distribution among quantiles
el_coeff('redist') = %el_redist%/10; #elasticity of carbon tax redistribution scheme
el_coeff('abatement') = %omega%/10; # elasticity of abatement costs distribution among quantiles

##  COMPUTE DATA
#_________________________________________________________________________
* In the phase COMPUTE_DATA you should declare and compute all the parameters
* that depend on the data loaded in the previous phase.
$elseif.ph %phase%=='compute_data'

*minumum subsistance level 
y_dist_min(t,n,dist) = subsistance_level * quant_share(dist) * pop(t,n) * 1e-6;

quantiles_ref(t,n,dist) = quantiles_ref_ssp('%baseline%',t,n,dist); 
#constant after 2100
quantiles_ref(t,n,dist)$(ord(t) gt 18) = quantiles_ref_ssp('%baseline%','18',n,dist); 

#compute weights of the burden share per quantile of damages and abatement
ineq_weights(t,n,dist,ineq_elast) = ( quantiles_ref(t,n,dist) ** el_coeff(ineq_elast) ) / sum(ddist, quantiles_ref(t,n,ddist) ** el_coeff(ineq_elast) ) ;

#calibrated xi to avoid negative decile incomes in worst case scenario
$if set use_calib ineq_weights(t,n,dist,'damages') = ineq_weights_calib(t,n,dist);

#calibrated omega elasticities from Budolfson 2021
$if set omegacalib ineq_weights(t,n,dist,'abatement') = ( quantiles_ref(t,n,dist) ** ( 3.3219 - 0.2334 * log(1e6 * ykali(t,n)/pop(t,n) ) ) ) / sum(ddist, quantiles_ref(t,n,ddist) ** (3.3219 - 0.2334 * log(1e6 * ykali(t,n)/pop(t,n))) )  ;

$if %transfer%=="neutral" ineq_weights(t,n,dist,'redist') = ineq_weights(t,n,dist,'abatement');

##  DECLARE VARIABLES
#_________________________________________________________________________
* In the phase DECLARE VARS, you can DECLARE new variables for your module.
* Remember that by modifying sets, you already have some variables for free.
$elseif.ph %phase%=='declare_vars'

Variable YGROSS_DIST(t,n,dist);
Variable YNET_DIST(t,n,dist);
Variable Y_DIST_PRE(t,n,dist)  'GDP per quantile NET of Abatement Costs and Damages, pre-taxes (%exchange_rate%) [Trill 2005 USD / year]';
Variable Y_DIST(t,n,dist)            'GDP per quantile NET of Abatement Costs, Damages and taxes (%exchange_rate%) [Trill 2005 USD / year]';
Variable CPC_DIST(t,n,dist)          'Per capita quantile consumption (%exchange_rate%) [2005 USD per year per capita]'; 
Variable TRANSFER(t,n,dist);

#INITIALIZE VARIABLES
YGROSS_DIST.l(t,n,dist) = YGROSS.l(t,n)*quantiles_ref(t,n,dist);
YNET_DIST.l(t,n,dist) = YGROSS_DIST.l(t,n,dist);
Y_DIST_PRE.l(t,n,dist) = YGROSS_DIST.l(t,n,dist);
Y_DIST.l(t,n,dist) = YGROSS_DIST.l(t,n,dist);
CPC_DIST.l(t,n,dist) = 1e6 * Y_DIST.l(t,n,dist) * ( 1 - S.l(t,n) ) / ( pop(t,n) * quant_share(dist) );
TRANSFER.l(t,n,dist) = 0;
CTX.l(t,n) = EIND.l(t,n)*CPRICE.l(t,n)*1e-3;

##  COMPUTE VARIABLES
#_________________________________________________________________________
* In the phase COMPUTE_VARS, you fix starting points and bounds.
* DO NOT put VAR.l here! (use the declare_vars phase)
$elseif.ph %phase%=='compute_vars'

TRANSFER.lo(t,n,dist) = 0; #positive transfers only
YGROSS_DIST.lo(t,n,dist) = 0;

##  STABILITY CONSTRAINTS ------------------------------
* to avoid errors/help the solver to converge
$if set welfare_inequality Y_DIST.lo(t,n,dist) = 0; #y_dist_min(t,n,dist); #grant substistance levels to all quantiles 
$if set welfare_inequality CPC_DIST.lo(t,n,dist) = 1e-3; #needed for equation eq_welfare

#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
* List of equations
* One per line.
$elseif.ph %phase%=='eql'

    eq_ygrossdist
    eq_ynetdist_unbnd
    eq_ydist_unbnd
    eq_ydist
    eq_cpcdist
    eq_transfer
    eq_ctx        # total cost of carbon tax
    
##  EQUATIONS
#_________________________________________________________________________
* In the phase EQS, you can include new equations to the model.
* The equations are always included.
* Best practice : - condition your equation to be able to do a run with tfix(t)
$elseif.ph %phase%=='eqs'

* computes income w/o climate damages and abatement costs. 
eq_ygrossdist(t,n,dist)$reg(n)..    YGROSS_DIST(t,n,dist) =E= 
                                        quantiles_ref(t,n,dist) * YGROSS(t,n); 

* computes
eq_ynetdist_unbnd(t,n,dist)$reg(n).. 
                                    YNET_DIST(t,n,dist) =E=
                                        YGROSS_DIST(t,n,dist)                                         
                                        - DAMAGES(t,n) * ineq_weights(t,n,dist,'damages'); 

eq_ydist_unbnd(t,n,dist)$reg(n)..   Y_DIST_PRE(t,n,dist) =E=
                                        YNET_DIST(t,n,dist) -
$if not set ctax_marginal               ctax_corrected(t,n) * 1e-3 * (E(t,n) - E.l(t,n)) * quantiles_ref(t,n,dist) -
                                        ( ABATECOST(t,n) + CTX(t,n) ) * ineq_weights(t,n,dist,'abatement')
;                                         

eq_ydist(t,n,dist)$reg(n)..         Y_DIST(t,n,dist) =E=
                                        Y_DIST_PRE(t,n,dist) 
                                        + TRANSFER(t,n,dist);

eq_ctx(t,n)$reg(n)..                CTX(t,n) =E= CPRICE(t,n) * EIND(t,n) * 1e-3;

*computes consumption per capita per quantile
eq_cpcdist(t,n,dist)$reg(n)..       CPC_DIST(t,n,dist) =E= 
                                        1e6 * Y_DIST(t,n,dist)     
                                        * ( 1 - S(t,n) ) / ( pop(t,n) * quant_share(dist) );

*fix transfer to an exogenous shape
$ifthen.redist %transfer%=="opt"
eq_transfer(t,n)$reg(n)..            CTX(t,n)  =E= sum(dist, TRANSFER(t,n,dist));
$else.redist
eq_transfer(t,n,dist)$reg(n)..       TRANSFER(t,n,dist) =E= CTX(t,n) * ineq_weights(t,n,dist,'redist'); 
$endif.redist

*integrates mod inequality with the utility function
$ifthen.ut set welfare_inequality 
eq_utility_arg(t,n)$reg(n).. UTARG(t,n) =E= [( sum(dist, quant_share(dist) * CPC_DIST(t,n,dist) ** (1-gammaint)  ) **(1/(1-gammaint)) ) ];
$endif.ut                

##  FIX VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='fix_variables'

##  BEFORE SOLVE
#_________________________________________________________________________
* In the phase BEFORE_SOLVE, you can update parameters (fixed
* variables, ...) inside the nash loop and right before solving the
* model. This is typically done for externalities, spillovers, ...
* Best practice: record the variable that you update across iterations.
* Remember that you are inside the nash loop, so you cannot declare
* parameters, ...
$elseif.ph %phase%=='before_solve'

##  AFTER SOLVE
#_________________________________________________________________________
* In the phase AFTER_SOLVE, you compute what must be propagated across the
* regions after one bunch of parallel solving.
$elseif.ph %phase%=='after_solve'

*for SCC etc. recompute consumption marginal values to approximate from median
eq_cc.m(t,n) = eq_cpcdist.m(t,n,"D5")*1e6;

#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================
##  REPORT
#_________________________________________________________________________
* Post-solve evaluate report measures
$elseif.ph %phase%=='report'

* report consumption per capita w/o climate change damages and abatement costs
Parameter cpcgross_dist(t,n,dist);
cpcgross_dist(t,n,dist) = 1000 * YGROSS_DIST.l(t,n,dist) * (1 - S.l(t,n)) / ( pop(t,n) * quant_share(dist) );

Parameter quantiles(t,n,dist);
quantiles(t,n,dist) = ( CPC_DIST.l(t,n,dist) * quant_share(dist) ) / ( CPC.l(t,n) );

Parameter abatecost_dist(t,n,dist);
abatecost_dist(t,n,dist) = ABATECOST.l(t,n) * ineq_weights(t,n,dist,'abatement'); 

$ifthen.cd set calib_damages
#needed for calib_damages
Parameter itermax /1e3/;
Parameter tol /1e-5/;
Parameters err,it;

Parameter y_dist_last(t,n,dist); 
Parameter y_dist_bounded(t,n,dist);
Parameter y_dist_red(t,n,dist); 
Parameter ineq_calib(t,n,dist);

* entry conditions into the while loop
y_dist_red(t,n,dist) = Y_DIST.l(t,n,dist);
it = 0;
err = 1;

* grant that climate change damages in a bau_impact cause at most y_dist to go to 0
while ( it < itermax and err > tol,
y_dist_last(t,n,dist) =  y_dist_red(t,n,dist);
y_dist_bounded(t,n,dist) = max(y_dist_min(t,n,dist), y_dist_last(t,n,dist));
y_dist_red(t,n,dist) = y_dist_bounded(t,n,dist) - sum(ddist,y_dist_bounded(t,n,ddist) - y_dist_last(t,n,ddist) ) * quant_share(dist) ;
err = smax( (t,n,dist), abs( ( y_dist_red(t,n,dist) - y_dist_last(t,n,dist) ) / y_dist_last(t,n,dist) ) );
it = it + 1;
);

ineq_calib(t,n,dist)$(year(t) le 2020) = ineq_weights(t,n,dist,'damages');
ineq_calib(t,n,dist)$(year(t) gt 2020) = (YGROSS_DIST.l(t,n,dist) - y_dist_red(t,n,dist)) / DAMAGES.l(t,n);
$endif.cd

##  GDX ITEMS
#_________________________________________________________________________
* List the items to be kept in the final gdx
$elseif.ph %phase%=='gdx_items'

quantiles_ref
quantiles
inequality_parameters
YGROSS_DIST
Y_DIST
CPC_DIST
TRANSFER
cpcgross_dist
ineq_weights
abatecost_dist
el_coeff
y_dist_min
gammaint

$if set calib_damages ineq_calib 
eq_cpcdist

$endif.ph
