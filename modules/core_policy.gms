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
$setglobal impact "kalkuhl"

$elseif.pol '%policy%'=='simulation'
* Simulation mode, fixed saving rates and no mitigation, but possibly with impacts
$setglobal savings 'fixed'

$elseif.pol '%policy%'=='simulation_fixed_miu'
* Simulation mode, fixed saving rates and no mitigation, but possibly with impacts
$setglobal savings 'fixed'
$setglobal results_for_fixed_miu results_cba_burke

$elseif.pol '%policy%'=='simulation_tatm_exogen'
* Simulation mode, fixed saving rates and no mitigation, and given TATM temperature trajectory (emissions don't match!)
* define trajectory in mod_climate_tatm_exogen.gms
$setglobal savings 'fixed'

$elseif.pol '%policy%'=='simulation_climate_regional_exogen'
* Simulation mode, fixed saving rates and no mitigation, and given TATM temperature trajectory (emissions don't match!)
* Set to import regions temperatures to RCP for CMIP5 data (26, 45, 60, 85) or scenario for CMIP6 data (ssp126, ssp245, ss370, ssp585)
$if %downscaling%=="cmip5_pop" $setglobal temp_region_exogen 45
$if %downscaling%=="cmip6_pop" $setglobal temp_region_exogen "ssp245"
$if %downscaling%=="cmip6_area" $setglobal temp_region_exogen "ssp245"
$setglobal savings 'fixed'
#$setglobal damages_postprocessed

$elseif.pol '%policy%'=='cbudget'
* CUMULATED CO2 LIMIT from 2019 until 2100 in GtCO2 (as in ENGAGE) TOTAL CO2
$if not %cooperation% == 'coop' $abort 'USER ERROR: cbudget option requires cooperative mode.'
* For noncooperative runs, use policy=cbudget_regional with burden=cost_efficiency
$setglobal cbudget 1150
$setglobal impact "off"
$setglobal tax_oghg_as_co2

$elseif.pol '%policy%'=='cba'
$setglobal impact "kalkuhl"

$elseif.pol '%policy%'=='cea_tatm'
* limit GMT to %tatm_limit% degrees above preindustrial
$setglobal tatm_limit 2
* Enable/disable overshoot option
$setglobal overshoot "yes"
$setglobal damages_postprocessed

$elseif.pol '%policy%'=='cea_rcp'
* limit total radiative forcing to %forc_limit% W/m2
$setglobal forc_limit 4.5
* Enable/disable overshoot option
$setglobal overshoot "yes"
$setglobal damages_postprocessed

$elseif.pol '%policy%'=='ctax'
*by defaults, no impacts
$setglobal impact "off"
*Tax in 2015 in USD/tCO2 (by default increasing by 5% p.a.), constant after 2100
$setglobal ctax_initial 5
*Starting year of the carbon tax
$setglobal ctax_start 2025
$setglobal growth_rate 'uniform'
$setglobal ctax_shape 'exponential'
$setglobal ctax_slope 0.05
$setglobal tax_oghg_as_co2

*this flag fixes the MAC to equal exaclty the carbon tax (NB this FIXES CPRICE and may cause infeasibilities combined with other policies)
* for now deactivated in 2.5.0
*$setglobal ctax_marginal


$elseif.pol '%policy%'=='dice'
*$setglobal cooperation 'coop'
$setglobal climate 'dice2016'
$setglobal impact 'dice'
$setglobal macc 'dice2016'

$elseif.pol '%policy%'=='cbudget_regional'
*relax inertia by a factor of 2 from 0.034
$setglobal miuinertia 0.068 # no inertia: 0.24 , implying 1.2 per 5 years (=no inertia), or 0.034

* run carbon budget (also non cooperatively) with a pre-defined budget sharing formula
$setglobal cbudget 1150
$setglobal impact "off"
* some burden sharing formulas may not solve for low budgets: equal_per_capita, historical_responsability, grandfathering, cost_efficiency
$setglobal burden "cost_efficiency"

$ifthen.bgr %burden%=='cost_efficiency'
* Tolerance error for budget (in GtCO2) for noncooperative budgets
$setglobal conv_budget 1
*this flag fixes the MAC to equal exaclty the carbon tax  (NB this FIXES CPRICE and may cause infeasibilities combined with other policies)
*$setglobal ctax_marginal
$setglobal ctax_start 2025
$setglobal growth_rate 'uniform'
$setglobal ctax_shape 'exponential'
$setglobal ctax_slope 0.05

$else.bgr 

** this taxes non co2 as co2 by default (even for co2 only policies)
$setglobal tax_oghg_as_co2

$endif.bgr

$elseif.pol '%policy%'=='global_netzero'
$if not %cooperation%=="coop" $abort 'USER ERROR: global_netzero requires cooperative mode.'
$setglobal nzyear 2050
$setglobal impact "off"

$elseif.pol '%policy%'=='long_term_pledges'
$setglobal impact "off"
* activate NDCs for countries without long term pledges
$setglobal pol_ndc 1
$setglobal ndcs_bound ".lo"

*relax inertia by a factor of 2 from 0.034
$setglobal miuinertia 0.068 # no inertia: 0.24 , implying 1.2 per 5 years (=no inertia), or 0.034

$else.pol
$abort 'Please specify a valid policy via --policy=='
$endif.pol

* NDCs type: | cond | uncond |
* Conditional or unconditional (less stringent) Nationally Determined Contributions (NDCs
$setglobal ndcs_type "cond"

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
*$if not %impact%=="off" $abort 'USER ERROR: impact=off possibly intended for using a cbudget? Else comment in core_policy.gms.'
$elseif.pol '%policy%'=='cea_tatm'
$if not %cooperation%=="coop" $abort 'USER ERROR: cooperation required with < cea_tatm >  policy!'
$elseif.pol '%policy%'=='cea_rcp'
$if not %cooperation%=="coop" $abort 'USER ERROR: cooperation required with < cea_rcp >  policy!'
$elseif.pol '%policy%'=='ctax'
$elseif.pol '%policy%'=='cbudget_regional'
$elseif.pol '%policy%'=='global_netzero'
$if not %cooperation%=="coop" $abort 'USER ERROR: cooperation required with < global_netzero >  policy!'
$elseif.pol '%policy%'=='long_term_pledges'
$elseif.pol '%policy%'=='dice'
$if %cooperation% == 'coop' $if not %swf% == 'dice' $abort 'USER ERROR: $setglobal swf dice for DICE replication'
$if %cooperation% == 'coop' $if not %region_weights% == 'negishi' $abort 'USER ERROR: $setglobal region_weights negishi for DICE replication'
$endif.pol

set years_budget(t);
years_budget(t)$(year(t) ge 2100) = yes; 
$if %overshoot%=="no" years_budget(t)$(year(t) gt 2020) = yes; 

# by default fix until 2020
Set tmiufix(t) 'Time periods of fixed mitigation levels' /1,2/; 

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

Parameter ctax(t,n);
ctax(t,n) = 0;

Parameter ctax_corrected(t,n,ghg);
ctax_corrected(t,n,ghg) = 0;

#load MIUs from NDCs to fix policy levels before 2020
Parameter miu_ndcs_2030(n) "Mitigation levels in 2030 according to countries NDCs";
$gdxin  '%datapath%data_pol_ndc.gdx'
$load    miu_ndcs_2030 = pbl_%ndcs_type%_2030
$gdxin
Parameter miu_fixed(t,n,ghg) "Mitigation levels fixed to meet 2030 %ndcs_type% NDCs";
miu_fixed('1',n,'co2') = 0;
miu_fixed('2',n,'co2') = 0;
miu_fixed('4',n,'co2') = miu_ndcs_2030(n);
# intermediate values
miu_fixed('3',n,'co2') = miu_fixed('2',n,'co2') + (1/2) * miu_fixed('4',n,'co2');

Scalar cbudget_2020_2100 /0/;

$ifthen.pol '%policy%'=='simulation_fixed_miu'
Variable MIU_loaded(t,n);
$gdxin %results_for_fixed_miu%
$loaddc MIU_loaded=MIU
$gdxin

$elseif.pol '%policy%'=='ctax'

scalar ctax_var;
ctax_var = %ctax_initial%;

$elseif.pol '%policy%'=='cbudget_regional'
$ifthen.bgr  %burden%=="cost_efficiency"

scalar ctax_var;
scalar ctax_target_rhs /%cbudget%/;
ctax_var = max(581.12 -74.3*log(%cbudget%),1);

$endif.bgr

parameter burden_share(n), carbon_carbon_debt(n);

$elseif.pol '%policy%'=='long_term_pledges'
parameter long_term_pledges_year(n,*);
parameter long_term_pledges_year_co2(n), long_term_pledges_year_ghg(n);

$gdxin "%datapath%data_long_term_pledges.gdx"
$loaddc long_term_pledges_year=nzpl
$gdxin

long_term_pledges_year_co2(n) = 2310;

long_term_pledges_year_ghg(n) = 2310;

long_term_pledges_year_co2(n) = long_term_pledges_year(n,"Net zero");
*long_term_pledges_year_ghg(n) = long_term_pledges_year(n,"Carbon neutral");

$endif.pol

##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

#burden sharing formulas follow https://link.springer.com/article/10.1007/s10584-019-02368-y#Sec2 

$ifthen.share %burden%=="equal_per_capita"

burden_share(n) = sum(t$(year(t) le 2100),pop(t,n))/sum((t,nn)$(year(t) le 2100),pop(t,nn));

$elseif.share %burden%=="historical_responsability"

parameter l_valid_wdi(yearlu,n);
$gdxin 'data_%n%/data_historical_values'
$load l_valid_wdi
$gdxin

carbon_carbon_debt(n) = sum(yearlu$(yearlu.val ge 1960 and yearlu.val le 2010), (l_valid_wdi(yearlu,n) * sum(nn,q_emi_valid_primap('co2ffi',yearlu,nn)/l_valid_wdi(yearlu,nn)) -  q_emi_valid_primap('co2ffi',yearlu,n) ) );
burden_share(n) = (sum(t$(year(t) le 2100),pop(t,n))/sum((t,nn)$(year(t) le 2100),pop(t,nn)) + carbon_carbon_debt(n)/ sum(nn,carbon_carbon_debt(nn)) ) / 2 ;

$elseif.share %burden%=="grandfathering"

burden_share(n) = emi_bau('1',n,'co2')/sum(nn,emi_bau('1',nn,'co2'));

$elseif.share %burden%=="cost_efficiency"

* very large number, make eq_carbon_budget_reg useless
burden_share(n) = 1e4; 

$else.share 
$if %policy%=="cbudget_regional" $abort "USER ERROR: please choose a valid effort sharing formula!"
$endif.share 

$ifthen.pol '%policy%'=='ctax'

* compute full tax schedule
ctax(t,n) = 1e-8;
ctax(t,n)$(year(t) eq %ctax_start%) = max(ctax_var/1000,1e-8);

$ifthen.grt %growth_rate%=="uniform"

$ifthen.ctx %ctax_shape%=="constant"
ctax(t,n)$(year(t) gt %ctax_start%) =   ctax_var/1000; #convert from USD/tCO2 to T$/GtCO2
$elseif.ctx %ctax_shape%=="linear"
ctax(t,n)$(year(t) gt %ctax_start%) =  ctax_var/1000 * (1 + %ctax_slope%) * (year(t)-%ctax_start%); #convert from USD/tCO2 to T$/GtCO2
$elseif.ctx %ctax_shape%=="exponential"
ctax(t,n)$(year(t) gt %ctax_start%) =   ctax_var/1000 * (1 + %ctax_slope%)**(year(t)-%ctax_start%); #convert from USD/tCO2 to T$/GtCO2
$endif.ctx

$elseif.grt %growth_rate%=="hotelling"
ctax(t,n)$(year(t) gt %ctax_start%) = (ctax_var/1000) * (1 + sum(nn,RI.l(t,nn)*pop(t,nn)/sum(nnn,pop(t,nnn))))**(year(t)-%ctax_start%);
$elseif.grt %growth_rate%=="diff"
ctax(t,n)$(year(t) eq %ctax_start%) = max(ctax_var/1000,1e-8);
ctax(t,n)$(year(t) gt %ctax_start%) = (ctax_var/1000) * (1 + RI.l(t,n))**(year(t)-%ctax_start%);
$endif.grt

ctax(t,n)$(year(t) gt 2100) = valuein(2100, ctax(tt,n));

$endif.pol

##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'



##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

MIU.fx(t,n,ghg)$tmiufix(t) = miu_fixed(t,n,ghg);

$if '%policy%'=='bau' MIU.l(t,n,ghg) = 0; MIU.fx(t,n,ghg) = 0; MIULAND.l(t,n) = 0; MIULAND.fx(t,n) = 0;

$if '%policy%'=='bau_impact' MIU.l(t,n,ghg) = 0; MIU.fx(t,n,ghg) = 0; MIULAND.l(t,n) = 0; MIULAND.fx(t,n) = 0;

$if '%policy%'=='simulation' MIU.l(t,n,ghg) = 0; MIU.fx(t,n,ghg) = 0;

$if '%policy%'=='simulation_fixed_miu' MIU.l(t,n,ghg) = MIU_loaded.l(t,n,ghg); MIU.fx(t,n,ghg) = MIU_loaded.l(t,n,ghg);

$if '%policy%'=='simulation_tatm_exogen' MIU.l(t,n,ghg) = 0; MIU.fx(t,n,ghg) = 0; MIULAND.l(t,n) = 0; MIULAND.fx(t,n) = 0;

$if '%policy%'=='simulation_climate_regional_exogen' MIU.l(t,n,ghg) = 0; MIU.fx(t,n,ghg) = 0; MIULAND.l(t,n) = 0; MIULAND.fx(t,n) = 0;

$ifthen.fixmiu set load_miu_from
parameter miufixed(t,n,ghg);
$gdxin "%load_miu_from%"
$load miufixed=MIU.l
MIU.fx(t,n,ghg) = miufixed(t,n,ghg);
$endif.fixmiu 

#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================
##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

$if '%policy%'=='cea_rcp' eq_forc_limit
$if '%policy%'=='cea_tatm' eq_tatm_limit
$if '%policy%'=='cbudget' eq_carbon_budget
$if '%policy%'=='cbudget_regional' eq_carbon_budget_reg
$if '%policy%'=='global_netzero' eq_global_netzero
$if '%policy%'=='long_term_pledges' eq_long_term_pledges_co2
$if '%policy%'=='long_term_pledges' eq_long_term_pledges_ghg
$if set ctax_marginal eq_ctax

##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

$ifthen.cb '%policy%'=='cbudget'


eq_carbon_budget(tt)$years_budget(tt).. 
                        sum((t,n)$(year(t) gt 2020 and year(t) lt (tperiod(tt)*5 + 2010) ), E(t,n,'co2')) * tstep 
                        + 3.5 * sum(n,E('2',n,'co2')) # 2020-2022.5
                        + 2.5 * sum(n,E(tt,n,'co2')) # final year
                        =L=  %cbudget%; 

$endif.cb

$ifthen.cbr '%policy%'=='cbudget_regional' 

eq_carbon_budget_reg(n,tt)$(reg(n) and years_budget(tt)).. 
                        sum(t$(year(t) gt 2020 and year(t) lt (tperiod(tt)*5 + 2010) ), E(t,n,'co2')) * tstep
                        + 3.5 * E('2',n,'co2') # 2020-2022.5
                        + 2.5 * E(tt,n,'co2') # final year
                        =L=  %cbudget% * burden_share(n); 

$endif.cbr

$ifthen.nz '%policy%'=='global_netzero'
eq_global_netzero(t)$(year(t) ge %nzyear%).. 
                        sum(n, E(t,n,'co2')) =E= EPS; 
$endif.nz

$ifthen.nz '%policy%'=='long_term_pledges'
eq_long_term_pledges_co2(t,n)$(reg(n) and not sameas(n,"rcam") and year(t) ge long_term_pledges_year_co2(n)).. 
                        E(t,n,'co2') - ELAND(t,n) =L= EPS; 
                        
eq_long_term_pledges_ghg(t,n)$(reg(n) and year(t) ge long_term_pledges_year_ghg(n)).. 
                        sum(ghg,EIND(t,n,ghg)*emi_gwp(ghg)) - ELAND(t,n) =L= EPS;  
$endif.nz

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
eq_ctax(t,n,ghg)$(year(t) ge %ctax_start% and reg(n)).. MAC(t,n,ghg) =E= ctax_corrected(t,n,ghg);
$endif.ctx

##  FIX VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='fix_variables'

##  BEFORE SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='before_solve'

* CO2 carbon budget 2020-2100
cbudget_2020_2100  =  sum((t,n)$(year(t) gt 2020 and year(t) le 2095), E.l(t,n,'co2')) * tstep
                + 3.5 * sum(n,valuein(2020, E.l(tt,n,'co2'))) # 2020-2022.5
                + 2.5 * sum(n,valuein(2100, E.l(tt,n,'co2'))) # 2100
;

$ifthen.pol '%policy%'=='cbudget_regional'
$ifthen.bgr %burden%=="cost_efficiency"

if((ord(iter) gt 1) and (ctax_target_rhs>0) and abs(cbudget_2020_2100-ctax_target_rhs) gt %conv_budget%,
    ctax_var = ctax_var * ( min((6000 - ctax_target_rhs) / max((6000 - cbudget_2020_2100), 1), 3) )**2.2 );

abort$(ctax_var>10000) 'Stop because ctax is too high';

abort$(ctax_var<1e-8) 'Budget is higher than bau emissions';


* compute full tax schedule
ctax(t,n) = 1e-8;
ctax(t,n)$(year(t) eq %ctax_start%) = max(ctax_var/1000,1e-8);

$ifthen.grt %growth_rate%=="uniform"

$ifthen.ctx %ctax_shape%=="constant"
ctax(t,n)$(year(t) gt %ctax_start%) =   ctax_var/1000; #convert from USD/tCO2 to T$/GtCO2
$elseif.ctx %ctax_shape%=="linear"
ctax(t,n)$(year(t) gt %ctax_start%) =  ctax_var/1000 * (1 + %ctax_slope%) * (year(t)-%ctax_start%); #convert from USD/tCO2 to T$/GtCO2
$elseif.ctx %ctax_shape%=="exponential"
ctax(t,n)$(year(t) gt %ctax_start%) =   ctax_var/1000 * (1 + %ctax_slope%)**(year(t)-%ctax_start%); #convert from USD/tCO2 to T$/GtCO2
$endif.ctx

$elseif.grt %growth_rate%=="hotelling"
ctax(t,n)$(year(t) gt %ctax_start%) = (ctax_var/1000) * (1 + sum(nn,RI.l(t,nn)*pop(t,nn)/sum(nnn,pop(t,nnn))))**(year(t)-%ctax_start%);
$elseif.grt %growth_rate%=="diff"
ctax(t,n)$(year(t) eq %ctax_start%) = max(ctax_var/1000,1e-8);
ctax(t,n)$(year(t) gt %ctax_start%) = (ctax_var/1000) * (1 + RI.l(t,n))**(year(t)-%ctax_start%);
$endif.grt

ctax(t,n)$(year(t) gt 2100) = valuein(2100, ctax(tt,n));

$endif.bgr
$endif.pol

$ifthen.dctx set differentiated_ctax
*from world bank classification https://blogs.worldbank.org/opendata/new-world-bank-country-classifications-income-level-2022-2023 
ctax(t,n)$(year(t) ge %ctax_start% and tperiod(t) le 10 and (ykali('2',n)/pop('2',n)*1e6*113.647/104.691) gt 0 and (ykali('2',n)/pop('2',n)*1e6*113.647/104.691) le 4125) = ctax(t,n) * (0.25*(2050-year(t))/(2050-%ctax_start%) + 0.5*(year(t)-%ctax_start%)/(2050-%ctax_start%)); 
ctax(t,n)$(year(t) ge %ctax_start% and tperiod(t) gt 10 and (ykali('2',n)/pop('2',n)*1e6*113.647/104.691) gt 0 and (ykali('2',n)/pop('2',n)*1e6*113.647/104.691) le 4125) = 0.5*ctax(t,n); 
ctax(t,n)$(year(t) ge %ctax_start% and tperiod(t) le 10 and (ykali('2',n)/pop('2',n)*1e6*113.647/104.691) gt 4125 and (ykali('2',n)/pop('2',n)*1e6*113.647/104.691) le 13205) = ctax(t,n) * (0.5*(2050-year(t))/(2050-%ctax_start%) + 0.75*(year(t)-%ctax_start%)/(2050-%ctax_start%)); 
ctax(t,n)$(year(t) ge %ctax_start% and tperiod(t) gt 10 and (ykali('2',n)/pop('2',n)*1e6*113.647/104.691) gt 4125 and (ykali('2',n)/pop('2',n)*1e6*113.647/104.691) le 13205) = 0.75*ctax(t,n); 
ctax(t,n)$(year(t) ge %ctax_start% and tperiod(t) le 10 and (ykali('2',n)/pop('2',n)*1e6*113.647/104.691) gt 13205) = ctax(t,n); 
$endif.dctx 

$ifthen.rctx set smooth_ctax
* ramp-up before reaching the exponential
ctax(t,n)$(year(t) eq (%ctax_start% + 0)) = ctax(t,n) * (1-(0.5));
ctax(t,n)$(year(t) eq (%ctax_start% + 1*tstep)) = ctax(t,n) * (1-(0.5*0.5));
ctax(t,n)$(year(t) eq (%ctax_start% + 2*tstep)) = ctax(t,n) * (1-(0.5*0.5*0.5));
ctax(t,n)$(year(t) eq (%ctax_start% + 3*tstep)) = ctax(t,n) * (1-(0.5*0.5*0.5*0.5));
$endif.rctx 

ctax_corrected(t,n,ghg) = min( ctax(t,n)*1e3 * emi_gwp(ghg),  cprice_max(t,n,ghg) );
$if set tax_oghg_as_co2 ctax_corrected(t,n,ghg)$(not sameas(ghg,'co2')) = min( MAC.l(t,n,'co2') * emi_gwp(ghg),  cprice_max(t,n,ghg) );

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

* CO2 carbon budget 2019-2100
cbudget_2020_2100  =  sum((t,n)$(year(t) gt 2020 and year(t) le 2095), E.l(t,n,'co2')) * tstep
                + 3.5 * sum(n,valuein(2020, E.l(tt,n,'co2'))) # 2020-2022.5
                + 2.5 * sum(n,valuein(2100, E.l(tt,n,'co2'))) # 2100
;

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

ctax
ctax_corrected
cbudget_2020_2100
$if '%policy%'=='cbudget'  eq_carbon_budget
$if '%policy%'=='cea_rcp'  eq_forc_limit
$if '%policy%'=='cbudget_regional' burden_share carbon_carbon_debt
$if '%policy%'=='long_term_pledges' long_term_pledges_year_co2 long_term_pledges_year_ghg
$endif.ph
