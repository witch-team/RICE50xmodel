# MODULE TEMPLATE
*
* Short description 
#____________
# REFERENCES
* - 
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================


* activate with --dac=1

##  CONF
#_________________________________________________________________________
* Definition of the global flags and settings specific to the module 
$ifthen.ph %phase%=='conf'

*by default, DAC are the only source of negative emissions if activated
$setglobal noneg

*source https://iopscience.iop.org/article/10.1088/1748-9326/ac2db0#erlac2db0s2
$if %baseline%=='ssp1' $setglobal costdac 'low'
$if %baseline%=='ssp2' $setglobal costdac 'best'
$if %baseline%=='ssp3' $setglobal costdac 'high'
$if %baseline%=='ssp4' $setglobal costdac 'best'
$if %baseline%=='ssp5' $setglobal costdac 'low'

$if %baseline%=='ssp1' $setglobal residual_emissions 'low'
$if %baseline%=='ssp2' $setglobal residual_emissions 'medium'
$if %baseline%=='ssp3' $setglobal residual_emissions 'high'
$if %baseline%=='ssp4' $setglobal residual_emissions 'low'
$if %baseline%=='ssp5' $setglobal residual_emissions 'high'

$setglobal burden_share 'geo'

$setglobal max_cdr 40

## SETS
#_________________________________________________________________________
* In the phase SETS you should declare all your sets, or add to the existing 
* sets the element that you need.
$elseif.ph %phase%=='sets'

set v /'E_NEG'/; 
vcheck('E_NEG') = yes;

## INCLUDE DATA
#_________________________________________________________________________
* In the phase INCLUDE_DATA you should declare and include all exogenous parameters. 
* You can also modify the data loaded in data.gms
* Best practice : - create a .gdx containing those and to loading it 
*                 - this is the only phase where we should have numbers...
$elseif.ph %phase%=='include_data'

Scalar twh2ej / 0.0036 /;

Scalar c2co2;
c2co2 = 44/12;

scalar dac_tot0 'Initial tot costs of dac [T$/GtonCO2]';

scalar dac_totfloor 'Floor total costs  [T$/GtonCO2]';

Parameter dac_totcost(t,n) 'LCOD [T$/GtonCO2]';

scalar capex 'fraction of LCOD due to investments' /0.4/;

scalar lifetime /20/; 

scalar dac_delta_en; #constant as in transport
dac_delta_en = 1 - exp( 1 / ( - lifetime + (0.01/2) * lifetime**2) ); #20: DAC lifetime

parameter capstorreg(n);
parameter totcapstor;

parameter mkt_growth_rate_dac(t,n);

Parameter mkt_growth_free_dac(t,n);
mkt_growth_free_dac(t,n) = 0.001/5; 

Parameter dac_learn(t,n);

Parameter wcum_dac(t);
wcum_dac(t)$(year(t) le 2015) = 0.001 * 5;

##  COMPUTE DATA
#_________________________________________________________________________
* In the phase COMPUTE_DATA you should declare and compute all the parameters 
* that depend on the data loaded in the previous phase. 
$elseif.ph %phase%=='compute_data'

dac_tot0 = 453 * 1e-3; # Source: RFF expert elicitation (Soheil Shayegh, 2020)
* DAC expansion constraint

$ifthen.cd %mkt_growth_dac%=='high'
mkt_growth_rate_dac(t,n) = 0.1; # of additionnal capacities

$elseif.cd %mkt_growth_dac%=='low'
mkt_growth_rate_dac(t,n) = 0.03; # of additionnal capacities

$else.cd 
mkt_growth_rate_dac(t,n)= 0.06; # of additionnal capacities
$endif.cd


$ifthen.cd %costdac%=='high'
dac_learn(t,n)= 0.06; # to reproduce 440 $/tonCO2 in 2050 with 2.2 GtCO2 of capacity, source: RFF expert elicitation (Soheil Shayegh, 2020)

$elseif.cd %costdac%=='low'
dac_learn(t,n)= 0.22; # to reproduce 124 $/tonCO2 in 2050 with 2.2 GtCO2 of capacity, source: RFF expert elicitation (Soheil Shayegh, 2020)

$else.cd 
dac_learn(t,n)= 0.136; # to reproduce 214 $/tonCO2 in 2050 with 2.2 GtCO2 of capacity, source: RFF expert elicitation (Soheil Shayegh, 2020)
$endif.cd

dac_totfloor = 100 * 1e-3; # long term floor cost
dac_totcost(t,n) = dac_tot0;

capstorreg(n) = sum(ccs_stor, ccs_stor_cap_max(n,'%ccs_stor_cap_max%',ccs_stor)) / c2co2;
totcapstor = sum(n, capstorreg(n));


##  DECLARE VARIABLES
#_________________________________________________________________________
* In the phase DECLARE VARS, you can DECLARE new variables for your module. 
* Remember that by modifying sets, you already have some variables for free.
$elseif.ph %phase%=='declare_vars'

Positive variable E_NEG(t,n)         'Installed capacity of DAC [GtCO2/yr]';
Positive variable I_CDR(t,n)         'Yearly investment of DAC [T$/yr]';
Positive variable COST_CDR(t,n)      'Yearly total cost of DAC [T$/yr]';

# VARIABLES STARTING LEVELS
* to help convergence
E_NEG.l(t,n) = 0;

##  COMPUTE VARIABLES
#_________________________________________________________________________
* In the phase COMPUTE_VARS, you fix starting points and bounds.
* DO NOT put VAR.l here! (use the declare_vars phase) 
$elseif.ph %phase%=='compute_vars'

##  STABILITY CONSTRAINTS --------
* to avoid errors/help the solver to converge
E_NEG.lo(t,n) = 1e-15; #such that E_NEG(tfirst)*depr^(tmax*tstep) > E_NEG.lo
COST_CDR.up(t,n) = 0.25*ykali(t,n); #max dac costs 25% of gross gdp, for stability
I_CDR.up(t,n) = 30/c2co2;

$ifthen.bs %burden_share%=="geo"

E_NEG.up(t,n) = capstorreg(n)/5697* %max_cdr%; 
* modify maximum capacity installed as a f of budget to mimic response of the energy system (calibrated from cumulative DAC in WITCH engage runs)
$if set cbudget E_NEG.up(t,n) = capstorreg(n)/5697* %max_cdr% / ( 1 + exp( 0.00631*(%cbudget%-1069) ) );

$elseif.bs %burden_share%=="epc"

E_NEG.up(t,n) = pop('2',n)/sum(nn,pop('2',nn)) * totcapstor/5697 * %max_cdr%; 
* modify maximum capacity installed as a f of budget to mimic response of the energy system (calibrated from cumulative DAC in WITCH engage runs)
$if set cbudget E_NEG.up(t,n) = pop('2',n) / sum(nn,pop('2',nn)) * totcapstor/5697 * %max_cdr% / ( 1 + exp( 0.00631*(%cbudget%-1069) ) );

$elseif.bs %burden_share%=="hist_resp"

$gdxin 'data_%n%/data_historical_values'
$load q_emi_valid_primap
$gdxin

E_NEG.up(t,n) = sum(yearlu,q_emi_valid_primap('co2ffi',yearlu,n)) / sum( (yearlu,nn),q_emi_valid_primap('co2ffi',yearlu,nn) ) * totcapstor/5697 * %max_cdr%; 
* modify maximum capacity installed as a f of budget to mimic response of the energy system (calibrated from cumulative DAC in WITCH engage runs)
$if set cbudget E_NEG.up(t,n) = sum(yearlu,q_emi_valid_primap('co2ffi',yearlu,n)) / sum( (yearlu,nn),q_emi_valid_primap('co2ffi',yearlu,nn) ) * totcapstor/5697 * %max_cdr% / ( 1 + exp( 0.00631*(%cbudget%-1069) ) );

$endif.bs 

I_CDR.up(t,n)$(year(t) gt 2100) = 0; #to avoid errors in the climate module

#fix investments before 2020
E_NEG.up(t,n)$(year(t) le 2020) = 1e-3*capstorreg(n)/totcapstor;

#values at tfirst
I_CDR.fx(tfirst,n) = 0;
E_NEG.fx(tfirst,n) = 1e-8;

#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
* List of equations
* One per line.
$elseif.ph %phase%=='eql'

eq_depr_e_neg
eq_cost_cdr
eq_emi_stor_dac
eq_mkt_growth_dac

##  EQUATIONS
#_________________________________________________________________________
* In the phase EQS, you can include new equations to the model.
* The equations are always included.
* Best practice : - condition your equation to be able to do a run with tfix(t) 
$elseif.ph %phase%=='eqs'

* Compute the depreciation of DAC
eq_depr_E_NEG(t,tp1,n)$(reg(n) and pre(t,tp1))..
    E_NEG(tp1,n) =E= E_NEG(t,n) * (1 - dac_delta_en)**tlen(t) +
                     tlen(t) * I_CDR(t,n) / (capex * lifetime * dac_totcost(t,n));

* Compute the total cost of emissions
eq_COST_CDR(t,n)$(reg(n))..
    COST_CDR(t,n) =E= I_CDR(t,n) + E_NEG(t,n) * dac_totcost(t,n) * (1-capex)  +
                      sum(ccs_stor, E_STOR(ccs_stor,t,n) * ccs_stor_cost(ccs_stor,n) ) * CtoCO2;
 
eq_emi_stor_dac(t,n)$(reg(n))..
    E_NEG(t,n) =E= sum(ccs_stor, E_STOR(ccs_stor,t,n)) * CtoCO2;

* DAC growth constraint
eq_mkt_growth_dac(t,tp1,n)$(reg(n) and pre(t,tp1))..
    I_CDR(tp1,n) / (capex * lifetime * dac_totcost(tp1,n) ) =L= I_CDR(t,n) / (capex * lifetime * dac_totcost(t,n) ) *
                                            (1 + mkt_growth_rate_dac(t,n))**tlen(t) +
                                            tlen(tp1) * mkt_growth_free_dac(tp1,n);

##  BEFORE SOLVE
#_________________________________________________________________________
* In the phase BEFORE_SOLVE, you can update parameters (fixed
* variables, ...) inside the nash loop and right before solving the
* model. This is typically done for externalities, spillovers, ...
$elseif.ph %phase%=='before_solve'

* cumulative DAC capital installed over time
loop((t,tp1)$(pre(t,tp1) and year(t) ge 2015),
           wcum_dac(tp1) = tlen(t) * sum(n, E_NEG.l(t,n)) + wcum_dac(t)
);

dac_totcost(t,n) = max(dac_tot0 * (wcum_dac(t) / wcum_dac('1'))**(-dac_learn(t,n)),dac_totfloor);

*in SSP3 and SSP4, no spillover across countries
$if %baseline%=="ssp3" dac_totcost(t,n)$(not tfirst(t)) = max(dac_tot0 * ( (sum(tt$(preds(t,tt)),E_NEG.l(tt,n)*tlen(tt)) + wcum_dac('1') ) / wcum_dac('1'))**(-dac_learn(t,n)),dac_totfloor);
$if %baseline%=="ssp4" dac_totcost(t,n)$(not tfirst(t)) = max(dac_tot0 * ( (sum(tt$(preds(t,tt)),E_NEG.l(tt,n)*tlen(tt)) + wcum_dac('1') ) / wcum_dac('1'))**(-dac_learn(t,n)),dac_totfloor);

##  AFTER SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='after_solve'

viter(iter,'E_NEG',t,n)$nsolve(n) = E_NEG.l(t,n);# Keep track of last negative emission values

##  GDX ITEMS
#_________________________________________________________________________
* List the items to be kept in the final gdx
$elseif.ph %phase%=='gdx_items'


#variables
E_NEG
I_CDR
dac_totcost
COST_CDR

#
totcapstor
capstorreg

$endif.ph