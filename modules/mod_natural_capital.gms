# MODULE NATURAL CAPITAL
*
* Introduced Natural Capital in the model with impacts and productin function adjustment
#____________
# REFERENCES
* - Bastien-Olvera, Bernardo A., and Frances C. Moore. ‘Use and Non-Use Value of Nature and the Social Cost of Carbon’.
*   Nature Sustainability, 28 September 2020, 1–8. https://doi.org/10.1038/s41893-020-00615-0.
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
* Definition of the global flags and settings specific to the module
$ifthen.ph %phase%=='conf'


*$setglobal nat_cap_production_function
*$setglobal welfare_nature
*$setglobal nat_cap_damages

$setglobal nat_cap_market_dam medium  #low, high
$setglobal nat_cap_nonmarket_dam medium  #low, high
$setglobal nat_cap_damfun lin # sq, log
$setglobal nat_cap_dgvm lpj # all, lpj, car, orc

*activate alternative utility function argument if active
$if set welfare_nature $setglobal alternative_utility

## SETS
#_________________________________________________________________________
* In the phase SETS you should declare all your sets, or add to the existing
* sets the element that you need.
$elseif.ph %phase%=='sets'

set type / market, nonmarket/; #types of natural capital

set prodfact /nature/; #add nature as production factor

set factor /H, K, mN, nN/;

set dgvm /all, car, lpj, orc/;
set formula /lin, log, sq/;
set damfuncoef /coeff, coeff_ub, coeff_lb/;

## INCLUDE DATA
#_________________________________________________________________________
* In the phase INCLUDE_DATA you should declare and include all exogenous parameters.
* You can also modify the data loaded in data.gms
* Best practice : - create a .gdx containing those and to loading it
*                 - this is the only phase where we should have numbers...
$elseif.ph %phase%=='include_data'

Scalar dknat 'depreciation rate of natural capital';

Parameter tfp_orig(t,n);

Parameters natural_capital_aggregate(n,factor), 
           natural_capital_elasticity(n, factor), 
           natural_capital_damfun(type, dgvm, formula, n, damfuncoef);

Parameter theta(n), nat_cap_utility_share(n);

Parameter nat_omega(type,t, n);
Parameter nat_cap_dam_pc(type,t, n);

Parameter natural_capital_global_elasticity(n);
Scalar gnn 'Global sum of nonmarket natural capital [Trillion 2005 USD]';

$gdxin '%datapath%data_mod_natural_capital.gdx'
$load natural_capital_aggregate natural_capital_elasticity natural_capital_global_elasticity
$load natural_capital_damfun
$gdxin

*NOAP region missing for now (# Algeria and Libya)
natural_capital_aggregate('noap',factor) = natural_capital_aggregate('noan',factor);
natural_capital_elasticity('noap',factor) = natural_capital_elasticity('noan',factor);
natural_capital_damfun(type,dgvm, formula,'noap','coeff') = natural_capital_damfun(type, dgvm, formula,'noan','coeff');

$if '%nat_cap_market_dam%'=='upperbound'     natural_capital_damfun('market', '%nat_cap_dgvm%', '%nat_cap_damfun%', n,'coeff') = natural_capital_damfun('market', '%nat_cap_dgvm%', '%nat_cap_damfun%', n,'coeff_ub');
$if '%nat_cap_market_dam%'=='lowerbound'      natural_capital_damfun('market', '%nat_cap_dgvm%', '%nat_cap_damfun%', n,'coeff') = natural_capital_damfun('market', '%nat_cap_dgvm%', '%nat_cap_damfun%', n,'coeff_lb');
$if '%nat_cap_nonmarket_dam%'=='upperbound'  natural_capital_damfun('nonmarket', '%nat_cap_dgvm%', '%nat_cap_damfun%', n,'coeff') = natural_capital_damfun('nonmarket', '%nat_cap_dgvm%', '%nat_cap_damfun%', n,'coeff_ub');
$if '%nat_cap_nonmarket_dam%'=='lowerbound'   natural_capital_damfun('nonmarket', '%nat_cap_dgvm%', '%nat_cap_damfun%', n,'coeff') = natural_capital_damfun('nonmarket', '%nat_cap_dgvm%', '%nat_cap_damfun%', n,'coeff_lb');

#damage function over -0.02 are not feasible
$if '%nat_cap_damfun%'=='lin' natural_capital_damfun(type,'%nat_cap_dgvm%', '%nat_cap_damfun%',n,damfuncoef) = max(-0.16, natural_capital_damfun(type,'%nat_cap_dgvm%','%nat_cap_damfun%',n,damfuncoef));
$if '%nat_cap_damfun%'=='sq' natural_capital_damfun(type,'%nat_cap_dgvm%', '%nat_cap_damfun%',n,damfuncoef) = max(-0.02, natural_capital_damfun(type,'%nat_cap_dgvm%','%nat_cap_damfun%',n,damfuncoef));


#standard DICE
prodshare('labour', n) = 0.7;
prodshare('capital', n) = 0.3;
prodshare('nature', n) = 0.0;

# now based on new estimateion of Bernie and Fran
prodshare('labour', n) = natural_capital_elasticity(n, 'H');
prodshare('capital', n) = natural_capital_elasticity(n, 'K');
prodshare('nature', n) = natural_capital_elasticity(n, 'mN');

$ifthen.prod not set nat_cap_production_function
prodshare('labour', n) = prodshare('labour', n) + prodshare('nature', n);
prodshare('nature', n) = 0;
$endif.prod

#parameters for utility from natural capital (amenity value)
#Source: average of estimates compiled by Drupp (2018) and GreenDICE
theta(n) = .58;
$setglobal nat_cap_utility_share 10   #s=0.1 following Hoel and Sterner (2007) and GreenDICE
nat_cap_utility_share(n) = %nat_cap_utility_share%/100;

gnn = sum(n, natural_capital_aggregate(n,'nN'));

##  COMPUTE DATA
#_________________________________________________________________________
* In the phase COMPUTE_DATA you should declare and compute all the parameters
* that depend on the data loaded in the previous phase.
$elseif.ph %phase%=='compute_data'

* retrieve tfp from reverting Y-I-L process now getting TFP from standard RICE
loop(t,
   # Investments
   i_tfp(t,n)  =  fixed_savings(t,n)  * ykali(t,n)   ;
   # Capital
   k_tfp(t+1,n)  =  ((1-dk)**tstep) * k_tfp(t,n)  +  tstep * i_tfp(t,n)  ;
   # TFP of current scenario (explicited from Cobb-Douglas prod. function)
   tfp_orig(t,n)  =  ykali(t,n) / ( ( (
$if set mod_government         (working_hours('1',n)/5278 * (employment_rate('1',n)/100))*
                               pop(t,n)/1000)**prodshare('labour', n) )*(k_tfp(t,n)**prodshare('capital', n) ) )
                               ;
);
*Now match initial period GDP basd on natural capital, and keep from then growth rate from original TFP
*tfp(t,n) = tfp_orig(t,n) * (tfp(t,n) / tfp_orig(t,n));


##  DECLARE VARIABLES
#_________________________________________________________________________
* In the phase DECLARE VARS, you can DECLARE new variables for your module.
* Remember that by modifying sets, you already have some variables for free.
$elseif.ph %phase%=='declare_vars'

POSITIVE VARIABLE NAT_CAP(type,t,n) 'Natural Capital [Trill 2005 USD]';
POSITIVE VARIABLE NAT_CAP_DAM(type,t,n) 'Natural Capital after damages [Trill 2005 USD]';
POSITIVE VARIABLE NAT_INV(type,t,n) 'Investment in Natural Capital';
POSITIVE VARIABLE NAT_CAP_BASE(type,t,n) 'Natural Capital';
POSITIVE VARIABLE GLOBAL_NN(t,n)  'Sum of nonmarket natural capital, global [Trill 2005 USD]';
*POSITIVE VARIABLE GLOBAL_NN(t)  'Sum of nonmarket natural capital global [Trill 2005 USD]';
##  COMPUTE VARIABLES
#_________________________________________________________________________
* In the phase COMPUTE_VARS, you fix starting points and bounds.
* DO NOT put VAR.l here! (use the declare_vars phase)
$elseif.ph %phase%=='compute_vars'

NAT_CAP.fx('market','1',n) = natural_capital_aggregate(n,'mN');

*for now keep non market at same initial value than market
NAT_CAP.fx('nonmarket','1',n) = natural_capital_aggregate(n,'nN');
NAT_CAP_DAM.fx('nonmarket','1',n) = NAT_CAP.l('nonmarket','1',n);

*NAT_OMEGA.lo(type,t,n) = 1-0.1;
*NAT_OMEGA.up(type,t,n) = 1+0.1;

*NAT_OMEGA.fx('nonmarket',t,n) = 1;

#for now zero investment
NAT_INV.fx(type,t,n) = 0;

#depreciation 
dknat = 0.0;

TATM.lo(t) = TATM.l('1');

GLOBAL_NN.l(t,n) = gnn;

#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
* List of equations
* One per line.
$elseif.ph %phase%=='eql'

eq_nat_cap
eq_nat_cap_dam
eq_es_prodfun_nN
eq_es_prodfun_mN
eq_gnn


##  EQUATIONS
#_________________________________________________________________________
* In the phase EQS, you can include new equations to the model.
* The equations are always included.
* Best practice : - condition your equation to be able to do a run with tfix(t)
$elseif.ph %phase%=='eqs'

* Capital according to depreciation and investments
eq_NAT_CAP(type,t+1,n)$reg(n).. NAT_CAP(type, t+1,n)  =E=  ((1-dknat)**tstep * NAT_CAP(type,t,n) ) + tstep * NAT_INV(type,t,n);

$ifthen.es set es_prodfun
eq_es_prodfun_mN('market',t,n)$reg(n).. NAT_CAP_BASE('market',t,n) =E= NAT_CAP('market',t,n);
eq_es_prodfun_nN('nonmarket',t,n)$reg(n).. NAT_CAP_BASE('nonmarket',t,n) =E= 
      NAT_CAP.l('nonmarket','1',n) * ((prod(tt,RI.l(tt,n)+1))**(1/card(t))-1) *
      (pop(t,n)/1000)**prodshare('labour',n) * K.l(t,n)**prodshare('capital',n) * NAT_CAP.l('nonmarket',t,n)**prodshare('nature',n) /
      [(pop('1',n)/1000)**prodshare('labour',n) * K.l('1',n)**prodshare('capital',n) * NAT_CAP.l('nonmarket','1',n)**prodshare('nature',n)];
$else.es
eq_es_prodfun_mN('market',t,n)$reg(n).. NAT_CAP_BASE('market',t,n) =E= NAT_CAP.l('market',t,n);
eq_es_prodfun_nN('nonmarket',t,n)$reg(n).. NAT_CAP_BASE('nonmarket',t,n) =E= NAT_CAP.l('nonmarket',t,n);
$endif.es



eq_nat_cap_dam(type,t,n)$reg(n).. NAT_CAP_DAM(type,t,n) =E= NAT_CAP_BASE(type,t,n) * (
$ifthen.damfun set nat_cap_damages
   1 + natural_capital_damfun(type, '%nat_cap_dgvm%', '%nat_cap_damfun%',n,'coeff') * 
$ifthen.damfuntwo '%nat_cap_damfun%'=='lin'   
      (TATM(t) - TATM.l('1'))
$elseif.damfuntwo '%nat_cap_damfun%'=='log'   
      log(1 + TATM(t) - TATM.l('1'))
$elseif.damfuntwo '%nat_cap_damfun%'=='sq'    
      (TATM(t) - TATM.l('1'))**2
$endif.damfuntwo
$else.damfun
   1
$endif.damfun
);

$ifthen.ut set welfare_nature
   eq_utility_arg(t,n)$reg(n).. UTARG(t,n) =E= [
                                                (1-nat_cap_utility_share(n)) * ( CPC(t,n)**theta(n) ) +
                                                nat_cap_utility_share(n) * ( (NAT_CAP_DAM('nonmarket',t,n) / pop(t,n)*1e6)**theta(n) )
                                                ]**(1/theta(n)) ;
$endif.ut

eq_gnn(t,n)$reg(n).. GLOBAL_NN(t,n) =E= NAT_CAP_DAM('nonmarket',t,n) + sum( nn$(not reg(nn)),  NAT_CAP_DAM.l('nonmarket',t,nn));

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
* Best practice: record the variable that you update across iterations.
* Remember that you are inside the nash loop, so you cannot declare
* parameters, ...
$elseif.ph %phase%=='before_solve'

##  AFTER SOLVE
#_________________________________________________________________________
* In the phase AFTER_SOLVE, you compute what must be propagated across the
* regions after one bunch of parallel solving.
$elseif.ph %phase%=='after_solve'

nat_omega(type,t,n) = 1 * (
$ifthen.damfun set nat_cap_damages
   1 + natural_capital_damfun(type, '%nat_cap_dgvm%', '%nat_cap_damfun%',n,'coeff') * 
$ifthen.damfuntwo '%nat_cap_damfun%'=='lin'   
      (TATM.l(t) - TATM.l('1'))
$elseif.damfuntwo '%nat_cap_damfun%'=='log'   
      log(1 + TATM.l(t) - TATM.l('1'))
$elseif.damfuntwo '%nat_cap_damfun%'=='sq'    
      (TATM.l(t) - TATM.l('1'))**2
$endif.damfuntwo
$else.damfun
   1
$endif.damfun
);
nat_cap_dam_pc(type,t,n) = 1000 * NAT_CAP_DAM.l(type,t,n) / pop(t,n);

GLOBAL_NN.l(t,n) = sum(nn,NAT_CAP_DAM.l('nonmarket',t,nn));

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

NAT_CAP
NAT_CAP_DAM
NAT_INV
GLOBAL_NN

natural_capital_aggregate 
natural_capital_damfun 
natural_capital_elasticity
theta
nat_cap_utility_share
nat_omega
nat_cap_dam_pc
nat_cap_base
gnn

$endif.ph
