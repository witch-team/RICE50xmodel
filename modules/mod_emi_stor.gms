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

* Assumption for leakage in % per year --leak_input=0.0001
$setglobal leak_input 0

* Value estimates to consider (low,best,high)
$if %baseline%=='ssp1' $setglobal ccs_stor_cost 'low'
$if %baseline%=='ssp2' $setglobal ccs_stor_cost 'best'
$if %baseline%=='ssp3' $setglobal ccs_stor_cost 'high'
$if %baseline%=='ssp4' $setglobal ccs_stor_cost 'best'
$if %baseline%=='ssp5' $setglobal ccs_stor_cost 'low'

$if %baseline%=='ssp1' $setglobal ccs_stor_cap_max 'low'
$if %baseline%=='ssp2' $setglobal ccs_stor_cap_max 'best'
$if %baseline%=='ssp3' $setglobal ccs_stor_cap_max 'high'
$if %baseline%=='ssp4' $setglobal ccs_stor_cap_max 'high'
$if %baseline%=='ssp5' $setglobal ccs_stor_cap_max 'high'

## SETS
#_________________________________________________________________________
* In the phase SETS you should declare all your sets, or add to the existing 
* sets the element that you need.
$elseif.ph %phase%=='sets'

* -- Storage -- *
set ccs_stor   'different storage technologies' /
    aqui_on
    aqui_off
    oil_gas_no_eor_on
    oil_gas_no_eor_off
    eor_on
    eor_off
    ecbm
/;

set ccs_stor_aqui(ccs_stor) 'aquifer storage ON and OFF'/
    aqui_on
    aqui_off
/;

set ccs_stor_og_eor 'oil and gas storage ON and OFF, including eor'/
    oil_gas_on
    oil_gas_off
/;

set ccs_stor_og(ccs_stor) 'oil and gas storage ON and OFF, excluding eor'/
    oil_gas_no_eor_on
    oil_gas_no_eor_off
/;

set ccs_stor_eor(ccs_stor) ' eor'/
    eor_on
    eor_off
/;

set ccs_stor_estim 'low, best, high case of storage capacity'/
    low
    best
    high
/;

set ccs_stor_dist_cat 'how distances are referred to in the make data file' /
    aquif
    oil_gas_onshore
    oil_gas_offshore
    coal_beds
/;

set map_ccs_stor_og(ccs_stor_og,ccs_stor_og_eor,ccs_stor_eor) /
 oil_gas_no_eor_on.oil_gas_on.eor_on
 oil_gas_no_eor_off.oil_gas_off.eor_off
/
;

set map_ccs_stor_eor(ccs_stor_eor,ccs_stor_og_eor) /
eor_on.oil_gas_on
eor_off.oil_gas_off
/
;

set map_ccs_stor_dist_cat(ccs_stor_dist_cat,ccs_stor) /
    aquif.(aqui_on,aqui_off)
    oil_gas_onshore.(oil_gas_no_eor_on,eor_on)
    oil_gas_offshore.(oil_gas_no_eor_off,eor_off)
    coal_beds.ecbm
/;



## INCLUDE DATA
#_________________________________________________________________________
* In the phase INCLUDE_DATA you should declare and include all exogenous parameters. 
* You can also modify the data loaded in data.gms
* Best practice : - create a .gdx containing those and to loading it 
*                 - this is the only phase where we should have numbers...
$elseif.ph %phase%=='include_data'


Parameter ccs_leak_rate(ccs_stor,t,n);

Parameter ccs_stor_cap_max(n,ccs_stor_estim,ccs_stor); 

$gdxin '%datapath%data_mod_emi_stor'

parameter ccs_stor_cap_aqui(n,*) 'Storage capacity for aquifers storage';
$loaddc ccs_stor_cap_aqui

parameter ccs_stor_cap_ecbm(n,*) 'Storage capacity for coal bed storage';
$loaddc ccs_stor_cap_ecbm

parameter ccs_stor_cap_og(n,*) 'Storage capacity for oil and gas fields storage';
$loaddc ccs_stor_cap_og

parameter ccs_stor_cap_eor(n) 'Storage capacity for eor storage';
$loaddc ccs_stor_cap_eor

parameter ccs_stor_share_onoff(n,*) 'Share of storage capacity ONshore and OFFshore';
$loaddc ccs_stor_share_onoff

parameter ccs_stor_dist(n,*) 'average distance in the country for different storage types in [km]';
$loaddc ccs_stor_dist

parameter ccs_stor_cost_estim(ccs_stor,ccs_stor_estim) 'storage cost, [T$/GtonCO2]';
$loaddc ccs_stor_cost_estim
$gdxin

parameter ccs_stor_cost(ccs_stor,n) 'storage cost, [T$/GtonCO2]';
ccs_stor_cost(ccs_stor,n) = ccs_stor_cost_estim(ccs_stor,'%ccs_stor_cost%');

parameter ccs_stor_cap_og_onoff(n,ccs_stor_estim,ccs_stor_og_eor) 'storage capacity of oil and gas fields divided into ONshore and OFFshore GtCO2';
parameter ccs_stor_cap_max(n,ccs_stor_estim,ccs_stor)             'storage capacity of each storage type GtCO2';
parameter ccs_leak_rate(ccs_stor,t,n)                             '%/yr of cumulated stored CO2 leakages';

##  COMPUTE DATA
#_________________________________________________________________________
* In the phase COMPUTE_DATA you should declare and compute all the parameters 
* that depend on the data loaded in the previous phase. 
$elseif.ph %phase%=='compute_data'

* Storage capacity: total of aquifer dividing into ON and OFF
ccs_stor_cap_max(n,ccs_stor_estim,ccs_stor_aqui) = ccs_stor_cap_aqui(n,ccs_stor_estim) * ccs_stor_share_onoff(n,ccs_stor_aqui);

* Storage capacity: total of og, eor included
ccs_stor_cap_og_onoff(n,ccs_stor_estim,ccs_stor_og_eor) = ccs_stor_cap_og(n,ccs_stor_estim) * ccs_stor_share_onoff(n,ccs_stor_og_eor);

* Storage capacity: total of ecbm which is ON only
ccs_stor_cap_max(n,ccs_stor_estim,'ecbm') = ccs_stor_cap_ecbm(n,ccs_stor_estim);

* Storage capacity: total of eor dividing into ON and OFF
loop((ccs_stor_eor,ccs_stor_og_eor)$(map_ccs_stor_eor(ccs_stor_eor,ccs_stor_og_eor)),
     ccs_stor_cap_max(n,ccs_stor_estim,ccs_stor_eor) = ccs_stor_cap_eor(n)*ccs_stor_share_onoff(n,ccs_stor_og_eor)
);

* Storage capacity: total of og, eor excluded
loop((ccs_stor_og,ccs_stor_og_eor,ccs_stor_eor)$(map_ccs_stor_og(ccs_stor_og,ccs_stor_og_eor,ccs_stor_eor)),
   ccs_stor_cap_max(n,ccs_stor_estim,ccs_stor_og) = max(ccs_stor_cap_og_onoff(n,ccs_stor_estim,ccs_stor_og_eor)-ccs_stor_cap_max(n,ccs_stor_estim,ccs_stor_eor),1e-7)
);

ccs_leak_rate(ccs_stor,t,n) = %leak_input%;

##  DECLARE VARIABLES
#_________________________________________________________________________
* In the phase DECLARE VARS, you can DECLARE new variables for your module. 
* Remember that by modifying sets, you already have some variables for free.
$elseif.ph %phase%=='declare_vars'

positive variable E_STOR(ccs_stor,t,n) 'quantity of co2 that is stored for each storage type [GtonC/yr]';

positive variable CUM_E_STOR(ccs_stor,t,n) 'cumulative quantity of co2 that is stored for each storage type [GtonC]';

Positive variable E_LEAK(t,n);


# VARIABLES STARTING LEVELS
* to help convergence
CUM_E_STOR.l(ccs_stor,t,n) =  1e-8;

##  COMPUTE VARIABLES
#_________________________________________________________________________
* In the phase COMPUTE_VARS, you fix starting points and bounds.
* DO NOT put VAR.l here! (use the declare_vars phase) 
$elseif.ph %phase%=='compute_vars'

CUM_E_STOR.fx(ccs_stor,tfirst,n) =  1e-8;
CUM_E_STOR.up(ccs_stor,t,n)$(not tfirst(t)) = max(ccs_stor_cap_max(n,'%ccs_stor_cap_max%',ccs_stor) / c2co2,1e-5);

##  STABILITY CONSTRAINTS --------
* to avoid errors/help the solver to converge

#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
* List of equations
* One per line.
$elseif.ph %phase%=='eql'

    eq_stor_cum
    eq_emi_leak


##  EQUATIONS
#_________________________________________________________________________
* In the phase EQS, you can include new equations to the model.
* The equations are always included.
* Best practice : - condition your equation to be able to do a run with tfix(t) 
$elseif.ph %phase%=='eqs'

eq_stor_cum(ccs_stor,tp1,t,n)$(reg(n) and not tfirst(t) and pre(t,tp1))..
                CUM_E_STOR(ccs_stor,tp1,n) =e= CUM_E_STOR(ccs_stor,t,n) * (1 - ccs_leak_rate(ccs_stor,t,n))**tlen(t) + tlen(t) * E_STOR(ccs_stor,t,n); 

eq_emi_leak(t,n)$(reg(n))..
                E_LEAK(t,n) =e= sum(ccs_stor, (1 - (1 - ccs_leak_rate(ccs_stor,t,n))**tlen(t)) * CUM_E_STOR(ccs_stor,t,n)) / tlen(t);


##  FIX VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='fix_variables'
* This phase is done after the phase POLICY.
* You should fix all your new variables.

tfixvar(E_STOR,'(t,n)')

##  BEFORE SOLVE
#_________________________________________________________________________
* In the phase BEFORE_SOLVE, you can update parameters (fixed
* variables, ...) inside the nash loop and right before solving the
* model. This is typically done for externalities, spillovers, ...
$elseif.ph %phase%=='before_solve'


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

#parameters
ccs_stor_cap_max

#variables
E_LEAK
E_STOR
CUM_E_STOR

$endif.ph
