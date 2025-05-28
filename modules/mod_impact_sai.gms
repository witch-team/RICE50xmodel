* IMPACT BURKE SUB-MODULE
*
* Burke's damage function implemented according to model regional detail
* REFERENCES
* - Burke et al. 2015
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

* Given the Burke extreme impact functions, use a damage cap by default
$setglobal timpact "bhm"
$setglobal pimpact "kotz"
$setglobal kotz_spec "sym" # original (org), symmetric (sym)
$setglobal t_srm 10 # divide by 10
$setglobal p_srm 10 # divide by 10
$setglobal damage_cap

** options for rescaling of damage functions 
$setglobal calibration_t "modified"
$setglobal calibration_p "original"
$setglobal modulate_temperatures_at 2
$setglobal maximum_temperature_spread 10 # divide by 10
$setglobal rescale_prec_at 3 #amount of standard deviations
$setglobal base_temperature "base_temp" #options: base_temp, today
$setglobal power_temperature_rescale 1 #power of the temperature rescaling

# DAMAGE CAP
* GDP baseline multiplier (i.e., max_gain=2 -> maximum gains are 2x GDPbase)
$setglobal max_gain    1
$setglobal max_loss  0.9

# following Kotz et al. 2024
$setglobal persistency_temp 15 #by default, 10 years persistency of temperature impacts
$setglobal persistency_prec 10 #by default, 5 years persistency of precipitation impacts

*------------------------------------------------------------------------
$elseif.ph %phase%=='sets'

set d 'type of damages' /'temp','prec'/;


## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

* Short run, BHM specification
PARAMETERS
    bhm_SR_T            'Short Run Temperature coeff'                      /  0.0127184 /
    bhm_SR_T2           'Short Run squared Temperature coeff'              / -0.0004871 /;

* Precipitation effects, from Damania et al. 2020
PARAMETERS 
    ddz_T    /0.00693/
    ddz_T2   /-0.00021/
    ddz_P  /0.01573/
    ddz_P2 /-0.00251/
    pnas_P / 0.0469 /
    pnas_P2 / -0.0168 /;

SCALAR    delta /1e-3/;

PARAMETER coeff_T(n,*), 
coeff_T_original(n,*),
coeff_P(n,*),
coeff_P_original(n,*),
persistency(d) "For growth impact, time of persistency [years]"; 



##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

$batinclude "tools/modify_impacts.gms"
persistency("temp") = %persistency_temp%;
persistency("prec") = %persistency_prec%;

##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'


VARIABLES
    DAMAGES(t,n)             'Damages [Trill 2005 USD / year] (negative values are gains)'
    DAMFRAC(t,n)             'Damages as GDP Gross fraction [%GDPgross]: (negative values are gains)'
    IMPACT(t,n,d)            'Impact per type of damage'
    YG(t,n)                  'Gross GDP with (all type of) damages, growth'    
    DAMFRAC_UNBOUNDED(t,n)   'Potential unbounded damages, as % of gross GDP (negative values are gains)'
    DAMFRAC_UPBOUND(t,n)     'Potential GDP, net of damages, bounded in maximum gains [Trill 2005 USD / year]'
;

# VARIABLES STARTING LEVELS ----------------------------
IMPACT.l(t,n,d) = 0 ;

##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

##  STABILITY CONSTRAINTS ------------------------------
* to avoid errors/help the solver to converge
IMPACT.lo(t,n,d) = -1;
IMPACT.up(t,n,d) = 2; 

IMPACT.fx(tfirst,n,d) = 0;
DAMFRAC_UNBOUNDED.fx(tfirst,n) = 0;
YG.fx(tfirst,n) = ykali(tfirst,n)/pop(tfirst,n);

#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

eq_impact   # BHM yearly impact equation
eq_pimpact
eq_yg
eq_damages
eq_damfrac
$if set damage_cap eq_damfrac_upbnd
eq_damfrac_unbounded

##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

##  BURKE'S IMPACT --------------------------------------
* BHM's yearly local impact
 eq_impact(t,n)$(reg_all(n) and not tfirst(t))..    IMPACT(t,n,'temp')  =E=  ( coeff_T(n,'a') + coeff_T(n,'b') * TEMP_REGION(t,n) + coeff_T(n,'c') * power(TEMP_REGION(t,n),2) ) * modulate_damages('temp',n) ;

 eq_pimpact(t,n)$(reg_all(n) and not tfirst(t))..   IMPACT(t,n,'prec') =E= ( coeff_P(n,'a') + coeff_P(n,'b') * PRECIP_REGION(t,n) * 1e-3 + coeff_P(n,'c') * power(PRECIP_REGION(t,n) * 1e-3,2) ) * modulate_damages('prec',n);

 eq_yg(t,n)$(reg_all(n))..                       YG(t,n) =E= ykali('1',n) / pop('1',n) * prod(tt$(tperiod(tt) lt tperiod(t)), 
                                                    (1 + basegrowthcap(tt,n) + sum(d, (
                                                    ( IMPACT(tt,n,d) - 0.4 + Sqrt( Sqr(IMPACT(tt,n,d) + 0.4) + Sqr(delta) )  )/2 
                                                    #IMPACT(tt,n,d)
                                                    ) $(tperiod(tt) gt (tperiod(t) - 1 - persistency(d)/tstep) ) ) )**tstep ); 

 eq_damfrac_unbounded(t,n)$(reg_all(n))..        DAMFRAC_UNBOUNDED(t,n) =E= ( ykali(t,n) - YG(t,n) * pop(t,n) ) / ykali(t,n);


$ifthen.dc set damage_cap
* Gains upperbound
 eq_damfrac_upbnd(t,n)$(reg_all(n))..
   DAMFRAC_UPBOUND(t,n)  =E=  ( DAMFRAC_UNBOUNDED(t,n) + %max_loss% - Sqrt( Sqr(DAMFRAC_UNBOUNDED(t,n) - %max_loss%) + Sqr(delta) )  )/2  ;
* Damages lowerbound and final YNET esteem
 eq_damfrac(t,n)$(reg_all(n))..
   DAMFRAC(t,n)  =E=  ( DAMFRAC_UPBOUND(t,n) - %max_gain% + Sqrt( Sqr(DAMFRAC_UPBOUND(t,n) + %max_gain%) + Sqr(delta) ) )/2  ;

$else.dc
 
 eq_damfrac(t,n)$(reg_all(n))..    DAMFRAC(t,n)  =E=  DAMFRAC_UNBOUNDED(t,n); 

$endif.dc

 eq_damages(t,n)$(reg_all(n))..   DAMAGES(t,n)  =E=  YGROSS(t,n) * DAMFRAC(t,n);


##  REPORT
#_________________________________________________________________________
$elseif.ph %phase%=='report'

### separate damage fraction by type of impact
parameter damfrac_type(t,n,d);
damfrac_type(t,n,d) =  (ykali(t,n) - pop(t,n) * ykali('1',n) / pop('1',n) * 
                                        prod(tt$(tt.val lt t.val), 
                                            (1 + basegrowthcap(tt,n) + ( ( IMPACT.l(tt,n,d) - 0.4 + Sqrt( Sqr(IMPACT.l(tt,n,d) + 0.4) + Sqr(delta) )  )/2 ) $(tt.val gt (t.val - 1 - persistency(d)/tstep) ) ) )**tstep 
                        ) / ykali(t,n);

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# Parameters -------------------------------------------
coeff_T
coeff_P
modulate_damages
persistency
precipitation_hist
sd_perc
damfrac_type

# Variables --------------------------------------------
IMPACT
YG
DAMFRAC
DAMAGES


$endif.ph
