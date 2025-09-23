# MODULE OCEAN
*
* Module for representing ocean capital, ecosystem services, and damages
#____________
# REFERENCES
* Bastien-Olvera B. A., Aburto-Oropeza O., Brander L., Cheung W. W. L., Emmerling J., Free C. M., Granella F., Tavoni M., Verschuur J., Ricke K. (2025): Social Cost of Carbon for the Oceans, preliminary draft
* How to run:
* First create baseline with impact run:         --n=maxiso3 --mod_ocean=1 --nameout=ocean_damage
* Second, run th ereference run without damages: --n=maxiso3 --mod_ocean=1 --nameout=ocean_today --policy=simulation_tatm_exogen --climate_of_today=1
* Third, run with emission pulse:                --n=maxiso3 --mod_ocean=1 --mod_emission_pulse=ocean_damage --reference_marg_util=ocean_today
* SCC is stored in the file results_ocean_damage_emission_pulse.gdx asunder the parameter "scc_pulse_ramsey_global"
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
* Definition of the global flags and settings specific to the module
$ifthen.ph %phase%=='conf'

$setglobal welfare_ocean
$if set welfare_ocean $setglobal alternative_utility

## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

* Define ocean capital types
set oc_capital              / coral, mangrove, ports, fisheries /;   # Types of ocean capital
set oc_mkt_capital(oc_capital) / ports, fisheries /;                # Market capital
set oc_nonmkt_capital(oc_capital) / coral, mangrove, fisheries /;   # Non-market capital
set oc_nonuse_capital(oc_capital) / coral, mangrove /;              # Non-use capital

* Country-ocean capital mapping set (TRUE if country has the specified ocean capital)
set map_n_oc(n,oc_capital) 'Map of countries with specific ocean capital';

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

* Damage coefficients
Parameter ocean_area_damage_coef(oc_capital,n)      'Linear damage coefficient to ocean area';
Parameter ocean_area_damage_coef_sq(oc_capital,n)   'Quadratic damage coefficient to ocean area';
Parameter ocean_area_start(oc_capital,n)            'Initial area in KM2';
Parameter ocean_consump_damage_coef(oc_capital,n)   'Linear damage coefficient to consumption';
Parameter ocean_consump_damage_coef_sq(oc_capital,n) 'Quadratic damage coefficient to consumption';

* Health impacts parameters
Parameter ocean_health_tame(oc_capital,n)           'Health impacts coefficient';
Parameter ocean_health_beta(oc_capital,n)           'Health impacts temperature coefficient';
Parameter ocean_health_mu(oc_capital,n)             'Health impacts coefficient';

* Initial values of ocean capital
Parameter ocean_unm_start(oc_capital,n)             'Starting use values per area [Trillion 2005 USD]';
Parameter ocean_nu_start(oc_capital,n)              'Starting nonuse values per area [Trillion 2005 USD]';

* Value function parameters
Parameter ocean_value_intercept_unm(oc_capital,n)   'Intercept for nonmarket use values';
Parameter ocean_value_intercept_nu(oc_capital,n)    'Intercept for nonuse values';
Parameter ocean_value_exp_um(oc_capital,n)          'Exponent for market use values';
Parameter ocean_value_exp_unm(oc_capital,n)         'Exponent for nonmarket use values';
Parameter ocean_value_exp_nu(oc_capital,n)          'Exponent for nonuse values';

* Utility function parameters
Scalar ocean_s1_1                                   'Weight of consumption' / 1 /;
Scalar ocean_s1_2                                   'Weight of use value' / 1 /;
Scalar ocean_s2_1                                   'Weight of consumption and use value' / 1 /;
Scalar ocean_s2_2                                   'Weight of nonuse value' / 1 /;
Scalar ocean_theta_1                                'Substitutability parameter 1' / 0.21 /;
Scalar ocean_theta_2                                'Substitutability parameter 2' / 0.21 /;
Scalar ocean_income_elasticity_usenm                'Income elasticity for use values' / 0.222 /;
Scalar ocean_income_elasticity_nonuse               'Income elasticity for nonuse values' / 0.243 /;
Scalar vsl_start                                    'Value of a Statistical Life [Million US-$[2006] per capita]' / 7.4 /;
Scalar ocean_health_eta                             'Health impact scaling factor' / 0.05 /;

* Load data from GDX
$gdxin '%datapath%data_mod_ocean.gdx'
$load ocean_area_damage_coef ocean_area_damage_coef_sq ocean_area_start 
$load ocean_nu_start ocean_unm_start 
$load ocean_value_intercept_nu ocean_value_exp_nu ocean_value_exp_um 
$load ocean_value_intercept_unm ocean_value_exp_unm 
$load ocean_consump_damage_coef ocean_consump_damage_coef_sq
$load ocean_health_tame ocean_health_mu ocean_health_beta
$gdxin

* Parameters of the utility function
ocean_theta_1 = 0.21; #0.21 #1.00
ocean_theta_2 = 0.21; #0.21 #1.00
# ocean_income_elasticity = 0.79; #updated from https://arxiv.org/pdf/2308.04400.pdf
ocean_income_elasticity_usenm = 0.222; #updated form Brander et al (2024)
ocean_income_elasticity_nonuse = 0.243; #updated form Brander et al (2024)
ocean_s1_1 = 1;  # Weight of consumption in utility function                 #0.9
ocean_s1_2 = 1;  # Weight of use value in utility function                   #0.1
ocean_s2_1 = 1;  # Weight of consumption and usevalue in utility function    #0.9
ocean_s2_2 = 1;  # Weight of nonuse value in utility function                #0.1 
vsl_start = 7.4; # VSL for the U.S. in Million USD per capita
ocean_health_eta = 0.05;


############################### SENSITIVITY ANALYSIS [Files by Francesco Granella ###########################
$if set ocean_sensitivity $batinclude tools/mod_ocean_sensitivity.inc

* Ensure damage coefficients stay within feasible bounds
ocean_area_damage_coef(oc_capital,n) = max(ocean_area_damage_coef(oc_capital,n), -0.10);
ocean_area_damage_coef('mangrove',n) = max(ocean_area_damage_coef('mangrove',n), -0.05);
ocean_area_damage_coef_sq('mangrove',n) = max(ocean_area_damage_coef_sq('mangrove',n), -0.005);
ocean_consump_damage_coef_sq('mangrove',n) = min(ocean_consump_damage_coef_sq('mangrove',n) , 0);
ocean_health_tame('fisheries', n) = max(ocean_health_tame('fisheries', n), -0.01);
$if %n%==maxiso3 ocean_health_beta('fisheries', n) = min(ocean_health_beta('fisheries', n), -0.03);

* Initialize country-ocean capital mapping (TRUE if country has this capital)
map_n_oc(n,oc_capital) = ocean_consump_damage_coef(oc_capital,n) <> 0 or ocean_area_start(oc_capital,n) <> 0 or ocean_health_beta(oc_capital,n) <> 0 or ocean_consump_damage_coef(oc_capital,n) <> 0;

##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

POSITIVE VARIABLE CPC_OCEAN_DAM(t,n)                        'Consumption per capita after damages [$ per capita]'; 
POSITIVE VARIABLE OCEAN_AREA(oc_capital,t,n)                'Area of ocean services [KM2]';
POSITIVE VARIABLE OCEAN_USENM_VALUE(oc_capital,t,n)         'Use value of ocean services [Million USD]';
POSITIVE VARIABLE OCEAN_USENM_VALUE_PERKM2(oc_capital,t,n)  'Use value per KM2 [Million USD per KM2]';
POSITIVE VARIABLE OCEAN_NONUSE_VALUE(oc_capital,t,n)        'Nonuse value of ocean services [Million USD]';
POSITIVE VARIABLE OCEAN_NONUSE_VALUE_PERKM2(oc_capital,t,n) 'Nonuse value per KM2 [Million USD per KM2]';
POSITIVE VARIABLE VSL(t,n)                                  'Value of a Statistical Life [Million USD per capita]';

##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

* Initialize values for first time period
OCEAN_USENM_VALUE_PERKM2.fx('coral', '1', n)$map_n_oc(n,'coral') = ocean_unm_start('coral', n) * 1e6;
OCEAN_NONUSE_VALUE_PERKM2.fx('coral', '1', n)$map_n_oc(n,'coral') = ocean_nu_start('coral', n) * 1e6;

* Starting values
OCEAN_NONUSE_VALUE.l(oc_capital,t,n)$map_n_oc(n,oc_capital) = 1;
OCEAN_USENM_VALUE.l(oc_capital,t,n)$map_n_oc(n,oc_capital) = 1;

TATM.lo(t) = TATM.l('1');

#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

eq_ocean_area
eq_ocean_cpc
eq_ocean_nmuse_value_perkm2_coral
eq_ocean_nmuse_value_coral
eq_ocean_nmuse_value_mangrove
eq_ocean_nonuse_value_perkm2_coral
eq_ocean_nonuse_value_coral
eq_ocean_nonuse_value_mangrove
eq_ocean_nmuse_value_fisheries
eq_ocean_vsl

##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

* Ocean area (currently fix to initial values)
eq_ocean_area(oc_capital,t,n)$(reg(n) and ocean_area_start(oc_capital, n)).. 
    OCEAN_AREA(oc_capital,t,n) =E= ocean_area_start(oc_capital, n) * (1 + ocean_area_damage_coef(oc_capital,n) * (TATM.l(t) - TATM.l('1')) + ocean_area_damage_coef_sq(oc_capital,n) * (TATM.l(t) - TATM.l('1'))**2);

* Consumption per capita with ocean damages
eq_ocean_cpc(t,n)$reg(n)..
    CPC_OCEAN_DAM(t,n) =E= CPC(t,n) * (1 +
        sum(oc_capital$map_n_oc(n,oc_capital), ocean_consump_damage_coef(oc_capital,n)) * (TATM(t) - TATM.l('1')) + 
        sum(oc_capital$(map_n_oc(n,oc_capital) and ocean_consump_damage_coef_sq(oc_capital,n)), ocean_consump_damage_coef_sq(oc_capital,n)) * (TATM(t) - TATM.l('1'))**2
    );

* Value of Statistical Life - scales with global average GDP
eq_ocean_vsl(t,n)$reg(n)..
VSL(t,n) =E= vsl_start *
(sum(nn, YNET.l('1',nn)) / sum(nn, pop('1',nn)))/ (YNET.l('1','usa') / pop('1','usa')) *          # rescaled to global GDP per capita from U.S.
(sum(nn, YNET.l(t,nn)) / sum(nn, pop(t,nn))) / (sum(nn, YNET.l('1',nn)) / sum(nn, pop('1',nn)))   # growing at global per capita growth rate
;

* CORAL REEFS ---------------------------------------------------------------
* Use value per km2 (scales with income elasticity)
eq_ocean_nmuse_value_perkm2_coral(t,tm1,n)$(reg(n) and pre(tm1,t) and map_n_oc(n,'coral'))..
    OCEAN_USENM_VALUE_PERKM2('coral', t, n) =E= 
        OCEAN_USENM_VALUE_PERKM2('coral', tm1, n) * 
        [1 + (gdppc_kali(t,n) / gdppc_kali(tm1,n) - 1) * ocean_income_elasticity_usenm];

* Total use value = per km2 value * area
eq_ocean_nmuse_value_coral(t,n)$(reg(n) and map_n_oc(n,'coral'))..
    OCEAN_USENM_VALUE('coral', t, n) =E= 
        OCEAN_USENM_VALUE_PERKM2('coral', t, n) * OCEAN_AREA('coral', t, n);

* Nonuse value per km2 (scales with income elasticity)
eq_ocean_nonuse_value_perkm2_coral(t,tm1,n)$(reg(n) and pre(tm1,t) and map_n_oc(n,'coral'))..
    OCEAN_NONUSE_VALUE_PERKM2('coral', t, n) =E= 
        OCEAN_NONUSE_VALUE_PERKM2('coral', tm1, n) * 
        [1 + (gdppc_kali(t,n) / gdppc_kali(tm1,n) - 1) * ocean_income_elasticity_nonuse];

* Total nonuse value = per km2 value * area
eq_ocean_nonuse_value_coral(t,n)$(reg(n) and map_n_oc(n,'coral'))..
    OCEAN_NONUSE_VALUE('coral', t, n) =E= 
        OCEAN_NONUSE_VALUE_PERKM2('coral', t, n) * OCEAN_AREA('coral', t, n);

* MANGROVES ----------------------------------------------------------------
* Use value (based on power function of per capita income)
eq_ocean_nmuse_value_mangrove(t,n)$(reg(n) and map_n_oc(n,'mangrove'))..
    OCEAN_USENM_VALUE('mangrove', t, n) =E= 
        exp(ocean_value_intercept_unm('mangrove', n)) * 
        (YNET.l(t,n)/pop(t,n)*1e6)**ocean_value_exp_unm('mangrove', n) * 
        OCEAN_AREA('mangrove', t, n) * 1e6;

* Nonuse value (based on power function of per capita income)
eq_ocean_nonuse_value_mangrove(t,n)$(reg(n) and map_n_oc(n,'mangrove'))..
    OCEAN_NONUSE_VALUE('mangrove', t, n) =E= 
        exp(ocean_value_intercept_nu('mangrove', n)) * 
        (YNET.l(t,n)/pop(t,n)*1e6)**ocean_value_exp_nu('mangrove', n) * 
        OCEAN_AREA('mangrove', t, n) * 1e6;

* FISHERIES ----------------------------------------------------------------
* Non-market use value of fisheries from health benefits
eq_ocean_nmuse_value_fisheries(t,n)$(reg(n) and map_n_oc(n,'fisheries') and ocean_health_beta('fisheries',n))..
    OCEAN_USENM_VALUE('fisheries', t, n) =E= (1 + ocean_health_beta('fisheries',n) * (TATM(t) - TATM.l('1'))) * 
    ocean_health_tame('fisheries',n) * pop(t,n) * 1e6 * 
    ocean_health_mu('fisheries',n) * ocean_health_eta * VSL(t,n)
    ;

* UTILITY FUNCTION ---------------------------------------------------------
$ifthen.ut set welfare_ocean
eq_utility_arg(t,n)$reg(n).. 
    UTARG(t,n) =E= (
        (
            ocean_s2_1 * (
                ocean_s1_1 * CPC_OCEAN_DAM(t,n)**ocean_theta_1 +
                ocean_s1_2 * (
                    sum(oc_capital$(oc_nonmkt_capital(oc_capital) and map_n_oc(n,oc_capital)), 
                        OCEAN_USENM_VALUE(oc_capital,t,n)
                    ) / pop(t,n)
                )**ocean_theta_1
            )**(ocean_theta_2/ocean_theta_1)
            +
            ocean_s2_2 * (
                (sum(oc_capital$(oc_nonuse_capital(oc_capital) and map_n_oc(n,oc_capital)), 
                    OCEAN_NONUSE_VALUE(oc_capital,t,n)
                ) / pop(t,n))**ocean_theta_2
            )
        )**(1/ocean_theta_2)
    ); 
$endif.ut

##  FIX VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='fix_variables'

##  BEFORE SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='before_solve'

##  AFTER SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='after_solve'

## REPORTING
#_________________________________________________________________________
$elseif.ph %phase%=='report'

Parameter marg_util_cons(t,n);

 marg_util_cons(t,n) = (1/(1-elasmu)) * (
        (
            ocean_s2_1 * (
                ocean_s1_1 * CPC_OCEAN_DAM.l(t,n)**ocean_theta_1 +
                ocean_s1_2 * (
                    sum(oc_capital$(oc_nonmkt_capital(oc_capital) and map_n_oc(n,oc_capital)), 
                        OCEAN_USENM_VALUE.l(oc_capital,t,n)
                    ) / pop(t,n)
                )**ocean_theta_1
            )**(ocean_theta_2/ocean_theta_1)
            +
            ocean_s2_2 * (
                (sum(oc_capital$(oc_nonuse_capital(oc_capital) and map_n_oc(n,oc_capital)), 
                    OCEAN_NONUSE_VALUE.l(oc_capital,t,n)
                ) / pop(t,n))**ocean_theta_2
            )
        )**(((1-elasmu)/ocean_theta_2)-1)
 )
 * ((1-elasmu)/ocean_theta_2)
 * ocean_s2_1 * (
                ocean_s1_1 * CPC_OCEAN_DAM.l(t,n)**ocean_theta_1 +
                ocean_s1_2 * (
                    sum(oc_capital$(oc_nonmkt_capital(oc_capital) and map_n_oc(n,oc_capital)), 
                        OCEAN_USENM_VALUE.l(oc_capital,t,n)
                    ) / pop(t,n)
                )**ocean_theta_1
            )**((ocean_theta_2/ocean_theta_1)-1)
 * (ocean_theta_2/ocean_theta_1)
 * ocean_s1_1 * CPC_OCEAN_DAM.l(t,n)**(ocean_theta_1-1)
 * ocean_theta_1
 ;




##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

* Sets
map_n_oc

* Parameters
ocean_area_damage_coef
ocean_area_damage_coef_sq
ocean_consump_damage_coef
ocean_consump_damage_coef_sq
ocean_health_tame
ocean_area_start
ocean_theta_1
ocean_theta_2
ocean_income_elasticity_usenm
ocean_income_elasticity_nonuse
ocean_s1_1
ocean_s1_2
ocean_s2_1
ocean_s2_2
ocean_value_intercept_unm
ocean_value_exp_unm
ocean_value_intercept_nu
ocean_value_exp_nu
ocean_health_beta
ocean_health_mu
ocean_health_eta
$ifthen.fair %climate%=='fair'
* Symbols do not exist if --policy=simulation_tatm_exogen
Ttcr
Tecs
$endif.fair

* Variables
CPC_OCEAN_DAM
OCEAN_USENM_VALUE
OCEAN_NONUSE_VALUE
OCEAN_USENM_VALUE_PERKM2
OCEAN_NONUSE_VALUE_PERKM2
OCEAN_AREA
UTARG
VSL

$endif.ph