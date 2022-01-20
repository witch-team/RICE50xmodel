# POLICY Module
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'


$ifthen.pol '%policy%'=='bau'
* Noncoop is faster but also coop would be ok
$setglobal impact "off"

$elseif.pol '%policy%'=='bau_impact'
* BAU with impacts
*$setglobal impact "burke"

$elseif.pol '%policy%'=='simulation'
* Simulation mode, fixed saving rates and no mitigation, but possibly with impacts
$setglobal savings 'fixed'

$elseif.pol '%policy%'=='simulation_fixed_miu'
* Simulation mode, fixed saving rates and no mitigation, but possibly with impacts
$setglobal savings 'fixed'
$setglobal results_for_fixed_miu results_cba_burke

$elseif.pol '%policy%'=='simulation_tatm_exogen'
* Simulation mode, fixed saving rates and no mitigation, and given TATM temperature trajectory (emissions don't match!)
* define trajectory in mo_climate_tatm_exogen.gms
$setglobal savings 'fixed'

$elseif.pol '%policy%'=='simulation_climate_regional_exogen'
* Simulation mode, fixed saving rates and no mitigation, and given TATM temperature trajectory (emissions don't match!)
* Set to import regions temperatures to RCP (26, 45, 60, 85)
$setglobal temp_region_exogen 26
$setglobal savings 'fixed'
$setglobal damages_postprocessed

$elseif.pol '%policy%'=='cbudget'
* CUMULATED CO2 LIMIT from 2019 until 2100 in GtCO2 (as in ENGAGE) TOTAL CO2
* For noncooperative runs, the budget is iteratively reached via a global uniform carbon tax
$setglobal cbudget 1000
$setglobal impact "off"
* Tolerance error for budget (in GtCO2) for noncooperative budgets
$setglobal conv_budget 10
*this flag fixes the MAC to equal exaclty the carbon tax  (NB this FIXES CPRICE and may cause infeasibilities combined with other policies)
$if '%cooperation%'=='noncoop' $setglobal ctax_marginal
$if '%cooperation%'=='noncoop' $setglobal ctax_start 2020

$elseif.pol '%policy%'=='cba'

$elseif.pol '%policy%'=='cea_tatm'
* limit GMT to %tatm_limit% degrees above preindustrial
$setglobal tatm_limit 2
* Enable/disable overshoot option
$setglobal overshoot "yes"
$setglobal damages_postprocessed

$elseif.pol '%policy%'=='cea_rcp'
* limit total radiative forcing to %forc_limit% W/m2
$setglobal forc_limit 2.6
* Enable/disable overshoot option
$setglobal overshoot "yes"
$setglobal damages_postprocessed

$elseif.pol '%policy%'=='ctax'
*Tax in 2015 in USD/tCO2 (by default increasing by 5% p.a.), constant after 2100
$setglobal ctax_initial 5
*Starting year of the carbon tax
$setglobal ctax_start 2020
*this flag fixes the MAC to equal exaclty the carbon tax (NB this FIXES CPRICE and may cause infeasibilities combined with other policies)
$setglobal ctax_marginal

$elseif.pol '%policy%'=='dice'
*$setglobal cooperation 'coop'
$setglobal climate 'dice2016'
$setglobal impact 'dice'
$setglobal macc_shape 'dice2016'

$else.pol
$abort 'Please specify a valid policy via --policy=='
$endif.pol

## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

#verify conf phase set all flags correctly
$ifthen.pol '%policy%'=='bau'
$if not %impact%=="off" $abort 'USER ERROR: impact=off must be used for BAU policy!'
$elseif.pol '%policy%'=='simulation'
$if not %savings%=="fixed" $abort 'USER ERROR: no_mitigation simulation mode requires fixedconf savings!'
*$if not %cooperation%=="noncoop" $abort 'USER ERROR: noncooperation required with any < simulation >  policy!'
$elseif.pol '%policy%'=='simulation_tatm_exogen'
$if not %savings%=="fixed" $abort 'USER ERROR: no_mitigation simulation mode requires fixedconf savings!'
$if not %cooperation%=="noncoop" $abort 'USER ERROR: noncooperation required with any < simulation >  policy!'
$elseif.pol '%policy%'=='simulation_climate_regional_exogen'
$if not %savings%=="fixed" $abort 'USER ERROR: no_mitigation simulation mode requires fixedconf savings!'
$if not %cooperation%=="noncoop" $abort 'USER ERROR: noncooperation required with any < simulation >  policy!'
$elseif.pol '%policy%'=='cbudget'
$if not %impact%=="off" $abort 'USER ERROR: impact=off possibly intended for using a cbudget? Else comment in core_policy.gms.'
$elseif.pol '%policy%'=='cea_tatm'
$if not %cooperation%=="coop" $abort 'USER ERROR: cooperation required with < cea_tatm >  policy!'
$elseif.pol '%policy%'=='cea_rcp'
$if not %cooperation%=="coop" $abort 'USER ERROR: cooperation required with < cea_rcp >  policy!'
$elseif.pol '%policy%'=='ctax'
$elseif.pol '%policy%'=='dice'
$if %cooperation% == 'coop' $if not %swf% == 'dice' $abort 'USER ERROR: $setglobal swf dice for DICE replication'
$if %cooperation% == 'coop' $if not %region_weights% == 'negishi' $abort 'USER ERROR: $setglobal region_weights negishi for DICE replication'
$endif.pol
$if set ctax_marginal $if not %macc_shape%=='enerdata' $abort "fixed ctax requires MACC enerdata curves to run"
$if set pol_ndc $if not %macc_shape%=='enerdata' $abort "ndc extrapolation requires MACC enerdata curves to run"

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

Parameter ctax(t,n);
ctax(t,n) = 0;

Parameter ctax_corrected(t,n);
ctax_corrected(t,n) = 0;

$ifthen.pol '%policy%'=='ctax'
ctax(t,n)$(year(t) ge %ctax_start%) =  (%ctax_initial%/1000) * (1 + 0.05)**(year(t)-%ctax_start%); #convert from USD/tCO2 to T$/GtCO2
ctax(t,n)$(year(t) gt 2100) = ctax('18',n);
$endif.pol

$ifthen.pol '%policy%'=='simulation_fixed_miu'
Variable MIU_loaded(t,n);
$gdxin %results_for_fixed_miu%
$loaddc MIU_loaded=MIU
$gdxin
$endif.pol

Scalar cbudget_2019_2100 /0/;

$ifthen.pol '%policy%'=='cbudget'
$ifthen.coop  '%cooperation%'=='noncoop'

Scalar ctax_var;
Scalar ctax_target_rhs /%cbudget%/;
ctax_var = max(581.12 -74.3*log(%cbudget%),1);

$endif.coop
$endif.pol

##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'



##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

$if '%policy%'=='bau' MIU.l(t,n) = 0; MIU.fx(t,n) = 0; 

$if '%policy%'=='bau_impact' MIU.l(t,n) = 0; MIU.fx(t,n) = 0;

$if '%policy%'=='simulation' MIU.l(t,n) = 0; MIU.fx(t,n) = 0;

$if '%policy%'=='simulation_fixed_miu' MIU.l(t,n) = MIU_loaded.l(t,n); MIU.fx(t,n) = MIU_loaded.l(t,n);

$if '%policy%'=='simulation_tatm_exogen' MIU.l(t,n) = 0; MIU.fx(t,n) = 0;

$if '%policy%'=='simulation_climate_regional_exogen' MIU.l(t,n) = 0; MIU.fx(t,n) = 0;

#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================
##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

$if '%policy%'=='cea_rcp' eq_forc_limit
$if '%policy%'=='cea_tatm' eq_tatm_limit
$if '%policy%'=='cbudget' $if '%cooperation%'=='coop' eq_carbon_budget
$if '%policy%'=='cbudget' $if '%cooperation%'=='coop' eq_carbon_budget_tatm
$if set ctax_marginal eq_ctax

##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

$ifthen.cb '%policy%'=='cbudget'

$ifthen.coop '%cooperation%'=='coop'
    eq_carbon_budget..   sum((t,n)$(year(t) ge 2020 and year(t) le 2095), E(t,n)) * tstep
                + 41 * 0.5 # 2018
                + 3.5 * sum(n,E('1',n)) # 2019-2022.5
                + 3 * sum(n,E('18',n)) # 2100
                =L=  %cbudget%+1;

#terminal conditions for budget after 2100
    eq_carbon_budget_tatm(t)$(year(t) gt 2100)..   TATM(t)  =L= TATM('18');
$endif.coop

$endif.cb

$ifthen.cea '%policy%'=='cea_tatm'
$ifthen.over %overshoot%=="yes"
* limit GMT only from 2100 an beyond
 eq_tatm_limit(t)$(year(t) ge 2100)..   TATM(t)  =L=  %tatm_limit% ;
$else.over
* No overshoot, always below limit
 eq_tatm_limit(t)..   TATM(t)  =L=  %tatm_limit% ;
$endif.over
$endif.cea

$ifthen.cea '%policy%'=='cea_rcp'
$ifthen.over %overshoot%=="yes"
* limit FORC only from 2100 an beyond
 eq_forc_limit(t)$(year(t) ge 2100)..   FORC(t)  =L=  %forc_limit% ;
$else.over
* No overshoot, always below limit
 eq_forc_limit(t)..   FORC(t)  =L=  %forc_limit% ;
$endif.over
$endif.cea

$ifthen.ctx set ctax_marginal
eq_ctax(t,n)$(year(t) ge %ctax_start%).. CPRICE_ED(t,n) =E= ctax_corrected(t,n);
$endif.ctx

##  FIX VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='fix_variables'

##  BEFORE SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='before_solve'

* CO2 carbon budget 2019-2100
cbudget_2019_2100  =  sum((t,n)$(year(t) ge 2020 and year(t) le 2095), E.l(t,n)) * tstep
                + 41 * 0.5 # 2018
                + 3.5 * sum(n,E.l('2',n)) # 2020
                + 3 * sum(n,E.l('18',n)); # 2100



$ifthen.pol '%policy%'=='cbudget'
$ifthen.coop '%cooperation%'=='noncoop'

if((ord(iter) gt 1) and (ctax_target_rhs>0),
if((mod(ord(iter),2)=0),
    if(((abs(cbudget_2019_2100-ctax_target_rhs) gt %conv_budget%) or (ord(iter) lt 10)),
    ctax_var = ctax_var * ( min((6000 - ctax_target_rhs) / max((6000 - cbudget_2019_2100), 1), 3) )**2.2;
))
);

abort$(ctax_var>10000) 'Stop because ctax is too high';

abort$(ctax_var<1e-8) 'Budget is higher than bau emissions';

* compute full tax schedule
ctax(t,n) = 1e-8;
ctax(t,n)$(year(t) eq %ctax_start%) = max(ctax_var/1000,1e-8);
ctax(t,n)$(year(t) gt %ctax_start%) = (ctax_var/1000) * (1 + 0.05)**(year(t)-%ctax_start%);
ctax(t,n)$(year(t) gt 2100) = ctax('18',n);

$endif.coop
$endif.pol

ctax_corrected(t,n) = min(ctax(t,n)*1e3,
                            mx(t,n)* ((ax_co2('%maccfit%','Total_CO2',t,n)*MIU.up(t,n)) + (bx_co2('%maccfit%','Total_CO2',t,n)*power(MIU.up(t,n),4))) );


##  PROBLEMATIC REGIONS
#_________________________________________________________________________
$elseif.ph %phase%=='problematic_regions'



##  AFTER SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='after_solve'

#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================
##  REPORT
#_________________________________________________________________________
$elseif.ph %phase%=='report'

$if '%policy%'=='simulation_climate_regional_exogen' TATM.l(t) = NA; #since TATM not correct in this case

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

ctax
ctax_corrected
$if '%policy%'=='cbudget' $if '%cooperation%'=='noncoop' ctax_var
$if '%policy%'=='cbudget' $if '%cooperation%'=='noncoop' ctax_target_rhs
cbudget_2019_2100
$if '%policy%'=='cbudget' $if '%cooperation%'=='coop'  eq_carbon_budget
$if '%policy%'=='cea_rcp'  eq_forc_limit

$endif.ph
