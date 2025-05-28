*------------------------------------------------------------------------
* Module Geoengineering by SRM via SO2 injection
* If run as g6 sulfur experiment should be run with maxiso3sai
* lower regional aggregations will work but lose precision for emulator
*-------------------------------------------------------------------------

$ifthen.ph %phase%=='conf'

$setglobal can_deploy "no" #all, wp, no, coal, region_name
$setglobal sai "free" # free, max_efficiency, sovereign, tropics, equator
$setglobal sai_experiment "g6" # options: g0 (uniform reduction of solar constant) | emulator
$if %cooperation%=="coalitions" $setglobal sel_coalition "sai"
$if %cooperation%=="coalitions" $setglobal can_deploy "coal" 

*Period in which SRM becomes available
$setglobal geoeng_start 2050
$setglobal geoeng_end 2200
$setglobal safe_temp 0.3 #deg per decade of maximum temperature increase/decrease

*For serial solving
$setglobal reordering_rule "descending"     #ascending | descending | random
$setglobal reordering_indicator "srm"     #srm | power (i.e. fraction of global GDP) | emissions 

*------------------------------------------------------------------------
$elseif.ph %phase%=='sets'

set inj 'possible injection points for SAI' / 15S, 30S, 45S, 60S, 0, 15N, 30N, 45N, 60N/;
alias(inj,injj);

set can_inject(n) 'Subset indicating wheter a region is allowed to inject'; 
can_inject(n)=no;

$ifthen.rt %can_deploy%=="all"
can_inject(n)=yes; 

$elseif.rt %can_deploy%=="no"
can_inject(n)=no; 

$elseif.rt %can_deploy%=="coal"
can_inject(n) =  yes$(coalitions("%sai_coalition%",n)); 

$else.rt 
can_inject("%can_deploy%")=yes;

$endif.rt

set belong_inj(n,inj) 'Subset indicating whether a region can inject at a certain latitude';

set v /'SAI'/;
vcheck('SAI') = yes;

*------------------------------------------------------------------------
$elseif.ph %phase%=='include_data'

* In the phase INCLUDE_DATA you should declare and include all your exogenous parameters.
* You can also modify the data loaded in data.gms
* Best practice : - create a .gdx containing those and to loading it
*                 - this is the only phase where we should have numbers...

* Costs: 5 (Robock 2009) - 25 (Cruzen 2006) billion US/TgS
* Forcing: -0.5 (Cruzen 2006) up to -2.5 (Rasch 2008) W/m^2/TgS (see also Gramstad and Tjotta (2010)
* Atmospheric residence time: not relevant for dynamics due to 5 year time step, but lowers cost!
* 1Tg = 1MT. 1gr S = 2gr SO2
Parameters
        sai_cost_tgs              'costs in billion USD per TgS'          / 10 /
        geoeng_forcing          'negative forcing per TgS'          / -1.75 /
        geoeng_residence_in_atm   'atmospheric residence time in yrs' / 2  /;

* compute actual cost per year taking into account the atmospheric residence time, disregarding initialisation.
* convert billions into T$ (trillions USD) by dividing by 1000.
*SRM_COST_tgs=(SRM_COST_tgs/geoeng_residence_in_atm)/1000 ;

Parameter sai_only_region(t,n,inj) 'maximum SAI deployed by each region if (a) only option (b) only injector';

Parameter sai_temp(n,inj) 'Efficiency of SAI per region and injection latitude'
          num_to_inj(inj) 'Numeric value of injection latitude'
          sai_precip(n,inj) 'SAI precipitation response per region and injection latitude';

Scalar delta_sai 'delta for smooth approximation' / 1e-3 /;

Scalar max_warming_projected 'Max warming per period' /0.2/; #this works for SSP2, might infes in others

Parameter start_geo(n); 
start_geo(n) = %geoeng_start%;

parameter damage_geoeng_amount(n);
damage_geoeng_amount(n) = 0.03;

** global temperature change from 12tGS/yr SAI single-point injection 
parameter sai_temp_global(inj) /"60S" 0.95,
                                "45S" 1.2,
                                "30S" 1.3,
                                "15S" 1.12,
                                "0" 0.93,
                                "15N" 1.09,
                                "30N" 1.28,
                                "45N" 1.22,
                                "60N" 1.06 /;

*------------------------------------------------------------------------
$elseif.ph %phase%=='compute_data'
 
sai_only_region(t,n,inj) = 0;
sai_temp(n,inj) = 0;
sai_precip(n,inj) = 0;

num_to_inj("60S") = -60;
num_to_inj("45S") = -45; 
num_to_inj("30S") = -30;
num_to_inj("15S") = -15;
num_to_inj("0") = 0;
num_to_inj("60N") = 60;
num_to_inj("45N") = 45; 
num_to_inj("30N") = 30;
num_to_inj("15N") = 15;

Parameter loadtemp(*,*);
$gdxin '%datapath%data_mod_sai'
$load loadtemp=srm_temperature_response
$gdxin
sai_temp(n,inj) = loadtemp(n,inj);

Parameter loadprec(*,*);
$gdxin '%datapath%data_mod_sai'
$loaddc loadprec=srm_precip_response
$gdxin
sai_precip(n,inj) = loadprec(n,inj);

* set allowed injection latitudes
$ifthen.ss %sai% == "sovereign" 
parameter injection_points(n,inj);
$gdxin '%datapath%data_mod_sai'
$loaddc injection_points
$gdxin
belong_inj(n,inj) = yes$(injection_points(n,inj) eq 1);

$elseif.ss %sai% == "max_efficiency"
belong_inj(n,inj)$( sai_temp(inj,n) eq smax(injj,sai_temp(injj,n)) ) = yes; 

$elseif.ss %sai% == "free"
belong_inj(n,inj) = yes;

$elseif.ss %sai% == "equator"
belong_inj(n,"0") = yes;

$elseif.ss %sai% == "tropics"
belong_inj(n,"15N") = yes;
belong_inj(n,"15S") = yes;

$elseif.ss %sai% == "symmetric"
belong_inj(n,"15N") = yes;
belong_inj(n,"15S") = yes;
belong_inj(n,"30N") = yes;
belong_inj(n,"30S") = yes;

$else.ss 
belong_inj(n,inj) = no;
$endif.ss

belong_inj(n,inj)$(not can_inject(n)) = no;

* geoengineering starting year
start_geo(n) = 2035;

$ifthen.n %n%=="maxiso3_sai"
set security_council(n) /usa,rus,chn,fra,gbr/;
set brics(n) /rus,chn,ind,bra,zaf/;

start_geo(security_council) = 2035;
start_geo(n)$(not security_council(n) and brics(n)) = 2035+15;
start_geo(n)$(not security_council(n) and not brics(n)) = 2035+35;
$endif.n 

*------------------------------------------------------------------------
$elseif.ph %phase%=='declare_vars'

Variable SAI(t,n,inj)             'TgS injected into the atmosphere';
Variable COST_SAI(t,n)            'Costs of Geoengineering in trillion USD';
Variable N_SAI(t,n)               'Regional SAI deployment'; 
Variable Z_SAI(t,inj)             'Zonal SAI deployment'; 
Variable W_SAI(t)                 'Global SAI deployment';
Variable DTEMP_REGION_SAI(t,n)    'Decrease in local temperature due to SAI (positive for reductions) [deg.C]';
Variable DPRECIP_REGION_SAI(t,n)  'Variation in local precipitation due to SAI (positive for increase) [mm/yr]';

SAI.l(t,n,inj)=0;
N_SAI.l(t,n)=0;

*------------------------------------------------------------------------
$elseif.ph %phase%=='compute_vars'
* The phase BEFORE_NASHLOOP is situated just before the loop solving an equilibrium

SAI.lo(t,n,inj) = 0;
Z_SAI.lo(t,inj) = 0;
N_SAI.lo(t,n) = 0;
N_SAI.up(t,n) = 100;
W_SAI.lo(t) = 0;

* To start with, no Geoengineering possible
SAI.fx(t,n,inj)$(not (year(t) ge start_geo(n) and year(t) le %geoeng_end% and belong_inj(n,inj)))=0;
SAI.l(t,n,inj)$(not (year(t) ge start_geo(n) and year(t) le %geoeng_end% and belong_inj(n,inj)) )=0;
N_SAI.fx(t,n)$(not (year(t) ge start_geo(n) and year(t) le %geoeng_end% and can_inject(n)) )=0; # necessary for g0

*------------------------------------------------------------------------------
$elseif.ph %phase%=='eql'

* List of equations
eq_sai_cost
eqw_sai
eq_tempconstup
eq_tempconstdo
$ifthen.exp "%sai_experiment%"=="g6" 
eqz_sai
eqn_sai
$if "%sai%"=="symmetric"  eqsym_sai
eq_temp_region_sai
eq_precip_region_sai
$endif.exp

*------------------------------------------------------------------------------
$elseif.ph %phase%=='eqs'

$ifthen.exp "%sai_experiment%"=="g6" 

eqz_sai(t,inj)..                     Z_SAI(t,inj) =e= sum(n$reg(n), SAI(t,n,inj)) + sum(n$(not reg(n)), SAI.l(t,n,inj));

$if "%sai%"=="symmetric" eqsym_sai(t,inj,injj)$(num_to_inj(inj) eq -num_to_inj(injj) and not sameas(inj,"0"))..        Z_SAI(t,inj) =e= Z_SAI(t,injj);

eqn_sai(t,n)$reg(n)..                N_SAI(t,n) =e= sum(inj, SAI(t,n,inj));

eqw_sai(t)..                         W_SAI(t) =e= sum(inj, Z_SAI(t,inj));

eq_temp_region_sai(t,n)$reg_all(n)..    DTEMP_REGION_SAI(t,n) =E= sum(inj, Z_SAI(t,inj) * sai_temp(n,inj) / 12 );

eq_precip_region_sai(t,n)$reg_all(n)..  DPRECIP_REGION_SAI(t,n) =E= sum(inj, Z_SAI(t,inj) * sai_precip(n,inj) / 12 );
 
eq_tempconstup(tp1,t,n)$(reg_all(n) and pre(t,tp1)
$if not %cooperation%=="coop"  and can_inject(n)
 )..   TEMP_REGION(tp1,n) =g= TEMP_REGION(t,n) - %safe_temp%*tstep/10; 

eq_tempconstdo(tp1,t,n)$(reg_all(n) and pre(t,tp1)
$if not %cooperation%=="coop"  and can_inject(n)
)..   TEMP_REGION(tp1,n) =l= TEMP_REGION(t,n) + max_warming_projected*climate_region_coef("beta_temp",n); #max warming needs to avoid infeasibilities with BAU temp increase

$elseif.exp "%sai_experiment%"=="g0" 

eqw_sai(t)..                         W_SAI(t) =e=  sum(n$reg(n), N_SAI(t,n)) + sum(n$(not reg(n)), N_SAI.l(t,n));

eq_tempconstup(tp1,t)$pre(t,tp1)..   
        TATM(tp1) =g= TATM(t) - %safe_temp%*tstep/10; 

eq_tempconstdo(tp1,t)$pre(t,tp1)..   
        TATM(tp1) =l= TATM(t) + max_warming_projected; #max warming needs to avoid infeasibilities with BAU temp increase

$else.exp
$abort "Unknown SAI experiment type. Please set %sai_experiment% to either g0 (solar constant reduction) or g6 (sulfur)."
$endif.exp

eq_sai_cost(t,n)$reg(n)..            COST_SAI(t,n) =e= ((sai_cost_tgs/geoeng_residence_in_atm)/1000) * N_SAI(t,n);

*------------------------------------------------------------------------
$elseif.ph %phase%=='before_solve'

$ifthen.ss set serial_solving
if(ord(iter) eq 2, 
SAI.up(t,n,inj)$(not (year(t) ge start_geo(n) and year(t) le %geoeng_end% and belong_inj(n,inj)) ) =sai_only_region(t,n,inj);
SAI.l(t,n,inj)=sai_only_region(t,n,inj);
);
$endif.ss

*------------------------------------------------------------------------
$elseif.ph %phase%=='before_serial_solve'

*run the first iteration as if only one region can do geoengineering
if (ord(iter) eq 1, 
* deactivate SAI for the regions that are not solving
SAI.fx(t,n,inj)$(not reg(n)) = 0;
SAI.l(t,n,inj)$(not reg(n)) = 0; 

* deactivate MIU for the regions that are not solving
MIU.fx(t,n,ghg)$(not reg(n)) = 0;
MIU.l(t,n,ghg)$(not reg(n)) = 0; 
MIULAND.fx(t,n)$(not reg(n)) = 0;
MIULAND.l(t,n)$(not reg(n)) = 0; 

* activate SAI only the regions that are currently solving, with a ruleset consistent with the scenario
SAI.up(t,n,inj)$(reg(n) and not (year(t) ge start_geo(n) and year(t) le %geoeng_end% and belong_inj(n,inj)) ) = +inf;

* activate all other decision variables for the solving region
##  CO2 MITIGATION UPPER BOUND SHAPE ----------
MIU.up(t,n,ghg)$(reg(n) and not tmiufix(t) ) = 1;
MIU.up(t,n,ghg)$(reg(n) and not tmiufix(t) and not sameas(ghg,'co2')) = maxmiu_pbl(t,n,ghg);
MIULAND.up(t,n)$(reg(n)) = 1;

** now reinitialize state variables relevant to global variables
E.l(t,n,ghg) = sigma(t,n,ghg)*ykali(t,n) + eland_bau(t,n,'%luscenario%');

);

*------------------------------------------------------------------------
$elseif.ph %phase%=='after_serial_solve'

*save the value 
if(ord(iter) eq 1, sai_only_region(t,reg,inj) = SAI.l(t,reg,inj); );

*------------------------------------------------------------------------
$elseif.ph %phase%=='after_solve'

viter(iter,'SAI',t,n)$nsolve(n) = N_SAI.l(t,n)/100;    # Keep track of last srm values (over maximum allowed)

$ifthen.ss set serial_solving
if (ord(iter) eq 1, 

put_utility 'gdxout' / 'srm_upper_bounds.gdx' ; execute_unload '%datapath%srm_upper_bounds_%nameout%.gdx' sai_only_region, map_clt_n, n, cltsolve, ykali, ppp2mer, emi_bau;
execute 'Rscript "tools/reorder_regions.R" -d "%datapath%" -i "%datapath%srm_upper_bounds_%nameout%.gdx" -o "%datapath%regions_reordered_%nameout%.gdx" -m "%reordering_rule%" -s "%reordering_indicator%" ';
put_utility 'gdxin' / execute_load '%datapath%regions_reordered_%nameout%.gdx' reorder_clt=rank; 
order_clt(nregs,clt) = yes$(nregs.val eq reorder_clt(clt)); # specify the imported order of solution
nactive(nregs) = no; # reset the number of solving coalitions
loop(clt, nactive(nregs)$order_clt(nregs,clt) = yes; ); #update the number of solving coalitions

);

$endif.ss

*------------------------------------------------------------------------
$elseif.ph %phase%=='report'

* report (approximate) global temperature change due to SAI for g6 experiments
$if %sai_experiment%=="g6" TATM.l(t) = TATM.l(t) - sum(inj, Z_SAI.l(t,inj) * sai_temp_global(inj) / 12); 

*------------------------------------------------------------------------
$elseif.ph %phase%=='gdx_items'
* List the items to be kept in the final gdx
SAI
W_SAI
N_SAI
Z_SAI
DTEMP_REGION_SAI
DPRECIP_REGION_SAI
COST_SAI

sai_temp
sai_precip
belong_inj
can_inject
start_geo
sai_only_region
$ifthen.ss set serial_solving
reorder_clt
order_clt
$endif.ss

$endif.ph
