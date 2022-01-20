# IMPACT MODULE
* This module gathers all main impact parameters, variables and sets.
* Those will be mapped with specific impact submodules varibles.
*
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

# DAMAGE CAP
* GDP baseline multiplier (i.e., max_gain=2 -> maximum gains are 2x GDPbase)
*$setglobal damage_cap
$setglobal max_gain    2
$setglobal max_damage  1e-4

* for threshold/catastrophic damage
*$setglobal threshold_damage
$setglobal threshold_d 0.20  # (% of GDP)
$setglobal threshold_temp 3.0
$setglobal threshold_sigma 0.05

* gradient damage from fast temperature changes (based on Lempert et al 2000)
*$setglobal gradient_damage
$setglobal gradient_d 0.01 # (% of GDP)
$if set gradient_damage $setglobal solvermode dnlp

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

$ifthen.dc set damage_cap
PARAMETERS
* Calibrated safety bounds of climate change effect
    ynet_maximum(t,n)       'Maximum allowed gains from climate change'
    ynet_minimum(t,n)       'Maximum allowed damages from climate change'
;
# DAMAGES CAP LEVELS -----------------------------------
* Maximum and minimum reachable values (compared to baseline SSP GDP level)
 ynet_maximum(t,n) =   %max_gain%   * ykali(t,n) ;
 ynet_minimum(t,n) =   %max_damage% * ykali(t,n) ;
$endif.dc

##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'



##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
    OMEGA(t,n)               'Economic impact from the impact function from Climate Change [% of GDP]'
    DAMAGES(t,n)             'Damages [Trill 2005 USD / year]'
    DAMFRAC(t,n)             'Damages as GDP Gross fraction [%GDPgross]: (-) damages (+) gains'
    YNET_ESTIMATED(t,n)      'Potential GDP net of damages [Trill 2005 USD / year]'
    DAMFRAC_UNBOUNDED(t,n)   'Potential unbounded damages, as GDP Gross fraction [%GDPgross]: (+) damages (-) gains '
    YNET_UNBOUNDED(t,n)      'Potential unbounded GDP, net of damages [Trill 2005 USD / year]'
    YNET_UPBOUND(t,n)        'Potential GDP, net of damages, bounded in maximum gains [Trill 2005 USD / year]'

;
YNET_ESTIMATED.lo(t,n) = 0;

# VARIABLES STARTING LEVELS ----------------------------
OMEGA.l(t,n) = 0 ;
DAMAGES.l(t,n) = 0 ;
DAMFRAC.l(t,n) = 0 ;
YNET_ESTIMATED.l(t,n) = ykali(t,n) ;
DAMFRAC_UNBOUNDED.l(t,n) = 0 ;
YNET_UNBOUNDED.l(t,n) = ykali(t,n) ;
YNET_UPBOUND.l(t,n) = ykali(t,n)  ;

##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

* Tolerance for min/max nlp smooting
SCALAR   delta  /1e-2/ ; #-14 more than 1e-8 get solver stucked

##  STABILITY CONSTRAINTS ------------------------------
* to avoid errors/help the solver to converge
OMEGA.lo(t,n) = (-1 + 1e-5) ; # needed because of eq_komega 

##  CONTROL RATE LIMITS --------------------------------
OMEGA.fx(tfirst,n)  = 0 ;

#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'
    eq_damages        # Damages equation
    eq_damfrac        # Equation for Damages as GDP fraction
    eq_damfrac_nobnd
    eq_ynet_nobnd
$if set damage_cap   eq_ynet_upbnd
$if set damage_cap   eq_ynet_estim


##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

##  ESTIMATED YNET AND DAMAGES -------------------------
* Unbounded Damfrac
 eq_damfrac_nobnd(t,n)$(reg(n)).. DAMFRAC_UNBOUNDED(t,n)  =E=   1 - ( 1/(1+ (OMEGA(t,n)) ) )
$if set threshold_damage              + %threshold_d% * errorf( (TATM(t) - %threshold_temp%)/%threshold_sigma%)
$if set gradient_damage               + (%gradient_d% * power( (abs((TATM(t+1) - TATM(t))) / 0.35) , 4))$(not tlast(t))
$if set mod_srm $if set damage_geoeng + damage_geoeng_amount(n) * (-geoeng_forcing*W_SRM(t,n) / 3.5)**%impsrm_exponent%
;

* Unbounded YNET esteem
 eq_ynet_nobnd(t,n)$(reg(n))..   YNET_UNBOUNDED(t,n)  =E=  YGROSS(t,n) * (1 - DAMFRAC_UNBOUNDED(t,n))  ;

$ifthen.dc set damage_cap
* Gains upperbound 
 eq_ynet_upbnd(t,n)$(reg(n))..   
   YNET_UPBOUND(t,n)  =E=  ( YNET_UNBOUNDED(t,n) + ynet_maximum(t,n) - Sqrt( Sqr(YNET_UNBOUNDED(t,n)-ynet_maximum(t,n)) + Sqr(delta) ) )/2  ;
* Damages lowerbound and final YNET esteem
 eq_ynet_estim(t,n)$(reg(n))..  
   YNET_ESTIMATED(t,n)  =E=  ( YNET_UPBOUND(t,n) + ynet_minimum(t,n) + Sqrt( Sqr(YNET_UPBOUND(t,n)-ynet_minimum(t,n)) + Sqr(delta) ) )/2  ;

##  EFFECTIVE DAMAGES --------
* Effective net Damages
 eq_damages(t,n)$(reg(n))..   DAMAGES(t,n)  =E=  (YGROSS(t,n) - YNET_ESTIMATED(t,n));

* Effective Damages as fraction of YGROSS
 eq_damfrac(t,n)$(reg(n))..   DAMFRAC(t,n)  =E= (-1) * ( DAMAGES(t,n) / YGROSS(t,n) );

$else.dc

* Effective net Damages
 eq_damages(t,n)$(reg(n))..   DAMAGES(t,n)  =E=  (YGROSS(t,n) - YNET_UNBOUNDED(t,n));

* Effective Damages as fraction of YGROSS
 eq_damfrac(t,n)$(reg(n))..   DAMFRAC(t,n)  =E= DAMFRAC_UNBOUNDED(t,n);

$endif.dc

#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================
##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# Variables --------------------------------------------
OMEGA
DAMAGES
DAMFRAC


$endif.ph


#===============================================================================
*     /////////////////    SUBMODULE SELECTION   ////////////////////
#===============================================================================

* Include the impact full logic (selected as global option)
* Alternatives: | off | dice | burke | dell | kahn |
$batinclude 'modules/mod_impact_%impact%'  %1
