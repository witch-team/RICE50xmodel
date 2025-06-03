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
$setglobal max_gain    1
$setglobal max_damage  0.9

* for threshold/catastrophic damage
*$setglobal threshold_damage
$setglobal threshold_d 0.20  # (% of GDP)
$setglobal threshold_temp 3.0
$setglobal threshold_sigma 0.05

* gradient damage from fast temperature changes (based on Lempert et al 2000)
*$setglobal gradient_damage
$setglobal gradient_d 0.01 # (% of GDP)

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

$if set prec_impact a_prec=%prec_impact%;

##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
    OMEGA(t,n)               'Economic impact from the impact function from Climate Change [% of GDP]'
    DAMAGES(t,n)             'Damages [Trill 2005 USD / year] (negative values are gains)'
    DAMFRAC(t,n)             'Damages as GDP Gross fraction [%GDPgross]: (negative values are gains)'
    DAMFRAC_UNBOUNDED(t,n)   'Potential unbounded damages, as % of gross GDP (negative values are gains)'
    DAMFRAC_UPBOUND(t,n)     'Potential GDP, net of damages, bounded in maximum gains [Trill 2005 USD / year]'
;

# VARIABLES STARTING LEVELS ----------------------------
OMEGA.l(t,n) = 0 ;
DAMAGES.l(t,n) = 0 ;
DAMFRAC.l(t,n) = 0 ;
DAMFRAC_UPBOUND.l(t,n) = 0  ;

##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

* Tolerance for min/max nlp smooting
SCALAR   delta  /1e-2/ ; #-14 more than 1e-8 get solver stucked

##  STABILITY CONSTRAINTS ------------------------------
* to avoid errors/help the solver to converge
$if %omega_eq% == 'full' OMEGA.lo(t,n) = (-1 + 1e-5) ; # needed because of eq_komega

DAMFRAC.lo(t,n) = - %max_gain% - delta;
DAMFRAC.up(t,n) = %max_damage% + delta;

##  first period zero impacts --------------------------------
OMEGA.fx(tfirst,n)  = 0 ;
DAMFRAC_UNBOUNDED.fx(tfirst,n) = 0;

$if %impact%=="off" OMEGA.fx(t,n) = 0;

#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'
    eq_damages        # Damages equation
    eq_damfrac        # Equation for Damages as GDP fraction
    eq_damfrac_nobnd
$if set damage_cap   eq_damfrac_upbnd


##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

##  ESTIMATED YNET AND DAMAGES -------------------------
* Unbounded Damfrac
 eq_damfrac_nobnd(tm1,t,n)$(reg_all(n) and pre(tm1,t)).. DAMFRAC_UNBOUNDED(t,n)  =E=   1 - ( 1/(1+ (OMEGA(t,n)
$if set mod_adaptation             / ( 1 + (Q_ADA('ada',t,n)**ces_ada('exp',n))$(OMEGA.l(t,n) gt 0) )
) ) )
$if set threshold_damage              + %threshold_d% * errorf( (TATM(t) - %threshold_temp%)/%threshold_sigma%)
$if set gradient_damage               + (%gradient_d% * power( ( sqrt(sqr((TATM(t) - TATM(tm1))) + sqr(delta)) / 0.35) , 4))$(not tlast(t))
$if set mod_sai                       + damage_geoeng_amount(n) * power(W_SAI(t) / 12,2)
;

$ifthen.dc set damage_cap
* Gains upperbound
 eq_damfrac_upbnd(t,n)$(reg_all(n))..
   DAMFRAC_UPBOUND(t,n)  =E=  ( DAMFRAC_UNBOUNDED(t,n) + %max_damage% - Sqrt( Sqr(DAMFRAC_UNBOUNDED(t,n) - %max_damage%) + Sqr(delta) )  )/2  ;
* Damages lowerbound and final YNET esteem
 eq_damfrac(t,n)$(reg_all(n))..
   DAMFRAC(t,n)  =E=  ( DAMFRAC_UPBOUND(t,n) - %max_gain% + Sqrt( Sqr(DAMFRAC_UPBOUND(t,n) + %max_gain%) + Sqr(delta) ) )/2  ;

$else.dc
 
eq_damfrac(t,n)$(reg_all(n))..    DAMFRAC(t,n)  =E=  DAMFRAC_UNBOUNDED(t,n); 

$endif.dc

* Effective net Damages
 eq_damages(t,n)$(reg_all(n))..   DAMAGES(t,n)  =E=  YGROSS(t,n) * DAMFRAC(t,n);

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
DAMFRAC_UNBOUNDED

$endif.ph


#===============================================================================
*     /////////////////    SUBMODULE SELECTION   ////////////////////
#===============================================================================

* Include the impact full logic (selected as global option)
* Alternatives: | off | dice | burke | dell | kahn |
$if not %impact%=="off" $batinclude 'modules/mod_impact_%impact%'  %1
