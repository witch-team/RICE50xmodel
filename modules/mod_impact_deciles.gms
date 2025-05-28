* DECILE disaggregated damage functions sub-module
*
* activate with --mod_impact_deciles=1
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'


*needs mod_inequality to work
$if not set mod_inequality $abort "Please enable mod_inequality when using mod_impact_deciles"

# DAMAGE CAP
* GDP baseline multiplier (i.e., max_gain=2 -> maximum gains are 2x GDPbase)
$setglobal damage_cap
$setglobal max_gain    1.1
$setglobal max_damage  1e-5



## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

PARAMETERS
* Calibrated safety bounds of climate change effect
    ynet_maximum(t,n,dist)       'Maximum allowed gains from climate change'
    ynet_minimum(t,n,dist)       'Maximum allowed damages from climate change'
    basegrowthcap_dist(t,n,dist) ''
    beta_deciles(*,dist)         ''
    temp_region_reference(n)     'Reference temperature for each region for the damage function'
;

* Tolerance for min/max nlp smooting
SCALAR   delta  /1e-8/ ; #-14 more than 1e-8 get solver stucked


##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

table beta_deciles(*,dist)
              D1        D2       D3       D4       D5       D6       D7       D8        D9        D10     
T              0.1657   0.1390   0.1375   0.1356   0.1304   0.1281   0.1275   0.1288    0.1278    0.1180  
T2             -0.0045  -0.0032  -0.0033  -0.0033  -0.0032  -0.0031  -0.0031  -0.0031   -0.0031   -0.0028 
TxGDP          -0.0152  -0.0124  -0.0126  -0.0124  -0.0122  -0.0120  -0.0120  -0.0122   -0.0121   -0.0107 
T2xGDP         0.0004   0.0003   0.0003   0.0003   0.0003   0.0003   0.0003   0.0003    0.0003    0.0003  
;

##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
    OMEGA(t,n,dist)               'Economic impact from the impact function from Climate Change [% of GDP]'
    DAMAGES_DIST(t,n,dist)        'Damages [Trill 2005 USD / year] (negative values are gains)'
    DAMAGES(t,n)                  'Damages [Trill 2005 USD / year] (negative values are gains)'
    DAMFRAC_DIST(t,n,dist)        'Damages as GDP Gross fraction [%GDPgross]: (negative values are gains)'
    YNET_ESTIMATED(t,n,dist)      'Potential GDP net of damages [Trill 2005 USD / year]'
    DAMFRAC_UNBOUNDED(t,n,dist)   'Potential unbounded damages, as % of gross GDP (negative values are gains)'
    YNET_UNBOUNDED(t,n,dist)      'Potential unbounded GDP, net of damages [Trill 2005 USD / year]'
    YNET_UPBOUND(t,n,dist)        'Potential GDP, net of damages, bounded in maximum gains [Trill 2005 USD / year]'
    BIMPACT(t,n,dist)             'Impact coefficient according to Burke equation'
;
YNET_ESTIMATED.lo(t,n,dist) = 0;

# VARIABLES STARTING LEVELS ----------------------------
DAMAGES_DIST.l(t,n,dist) = 0 ;
DAMFRAC_DIST.l(t,n,dist) = 0 ;
YNET_ESTIMATED.l(t,n,dist) = ykali(t,n)*quantiles_ref(t,n,dist) ;
DAMFRAC_UNBOUNDED.l(t,n,dist) = 0 ;
YNET_UNBOUNDED.l(t,n,dist) = ykali(t,n)*quantiles_ref(t,n,dist) ;
YNET_UPBOUND.l(t,n,dist) = ykali(t,n)*quantiles_ref(t,n,dist) ;
BIMPACT.l(t,n,dist) = 0 ;


##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

##  STABILITY CONSTRAINTS ------------------------------
* to avoid errors/help the solver to converge
BIMPACT.lo(t,n,dist) = (-1 + 1e-6) ; # needed because of eq_omega

##  CONTROL RATE LIMITS --------------------------------
BIMPACT.fx(tfirst,n,dist) = 0 ;
YNET_UNBOUNDED.fx(tfirst,n,dist) = ykali(tfirst,n)*quantiles_ref(tfirst,n,dist) ;

# DAMAGES_DIST CAP LEVELS -----------------------------------
* Maximum and minimum reachable values (compared to baseline SSP GDP level)
ynet_maximum(t,n,dist) =   %max_gain%   * ykali(t,n) * quantiles_ref(t,n,dist) ;
ynet_minimum(t,n,dist) =   %max_damage% * ykali(t,n) * quantiles_ref(t,n,dist) ;
loop((t,tp1)$(pre(t,tp1) and tnolast(t)), basegrowthcap_dist(t,n,dist) = ((( (ykali(tp1,n)*quantiles_ref(tp1,n,dist)/pop(tp1,n)/10) / (ykali(t,n)*quantiles_ref(t,n,dist)/pop(t,n)/10) )**(1/tstep)) - 1 ) ); # last value set to 0

#temperature as reference point for damage function
temp_region_reference(n) = climate_region_coef('base_temp', n); #Burke
#for now reference from 2015
temp_region_reference(n) = TEMP_REGION.l('1',n);

Set t_damages(t);
t_damages(t) = YES$(tperiod(t) gt 2 and tperiod(t) lt smax(tt,tperiod(tt))-20);
BIMPACT.fx(t,n,dist)$(not t_damages(t)) = 0;

#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

eq_bimpact   # BHM yearly impact equation
eq_ynet_nobnd
$if set damage_cap   eq_ynet_upbnd
$if set damage_cap   eq_ynet_estim
eq_damages
eq_damfrac
eq_damagestot 

##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

##  BURKE'S IMPACT --------------------------------------
* BHM's yearly local impact
 eq_bimpact(t,n,dist)$(reg_all(n) and t_damages(t))..  BIMPACT(t,n,dist)  =E=  0
                                            +   (beta_deciles('T',dist) + beta_deciles('TxGDP',dist)*log(1.3*gdppc_kali(t,n))) * (TEMP_REGION_DAM(t,n)-temp_region_reference(n))
                                            +   (beta_deciles('T2',dist) + beta_deciles('T2xGDP',dist)*log(1.3*gdppc_kali(t,n))) * (power(TEMP_REGION_DAM(t,n),2)-power(climate_region_coef('base_temp', n),2))
  ;

* Unbounded YNET estimated
 eq_ynet_nobnd(t,tp1,n,dist)$(reg_all(n) and pre(t,tp1) and not tlast(t))..   YNET_UNBOUNDED(tp1,n,dist) * pop(t,n) / pop(tp1,n)  =E=  YNET_UNBOUNDED(t,n,dist) * (1 + basegrowthcap_dist(t,n,dist) + BIMPACT(t,n,dist))**tstep  ;

$ifthen.dc set damage_cap
* Gains upperbound
 eq_ynet_upbnd(t,n,dist)$(reg_all(n))..
   YNET_UPBOUND(t,n,dist)  =E=  ( YNET_UNBOUNDED(t,n,dist) + ynet_maximum(t,n,dist) - Sqrt( Sqr(YNET_UNBOUNDED(t,n,dist)-ynet_maximum(t,n,dist)) + Sqr(delta) ) )/2  ;
* Damages lowerbound and final YNET esteem
 eq_ynet_estim(t,n,dist)$(reg_all(n))..
   YNET_ESTIMATED(t,n,dist)  =E=  ( YNET_UPBOUND(t,n,dist) + ynet_minimum(t,n,dist) + Sqrt( Sqr(YNET_UPBOUND(t,n,dist)-ynet_minimum(t,n,dist)) + Sqr(delta) ) )/2  ;

##  EFFECTIVE DAMAGES --------
* Effective net Damages
 eq_damages(t,n,dist)$(reg_all(n))..   DAMAGES_DIST(t,n,dist)  =E=  (YGROSS_DIST(t,n,dist) - YNET_ESTIMATED(t,n,dist));

* Effective Damages as fraction of YGROSS
 eq_damfrac(t,n,dist)$(reg_all(n))..   DAMFRAC_DIST(t,n,dist)  =E= DAMAGES_DIST(t,n,dist) / YGROSS_DIST(t,n,dist);

$else.dc

* Effective net Damages
 eq_damages(t,n,dist)$(reg_all(n))..   DAMAGES_DIST(t,n,dist)  =E=  (YGROSS_DIST(t,n,dist) - YNET_UNBOUNDED(t,n,dist));

* Effective Damages as fraction of YGROSS
 eq_damfrac(t,n,dist)$(reg_all(n))..   DAMFRAC_DIST(t,n,dist)  =E= DAMAGES_DIST(t,n,dist) / YGROSS_DIST(t,n,dist);

$endif.dc

eq_damagestot(t,n)$(reg_all(n)).. DAMAGES(t,n) =E= sum(dist,DAMAGES_DIST(t,n,dist) );

#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  REPORT
#_________________________________________________________________________
$elseif.ph %phase%=='report'


##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

beta_deciles
basegrowthcap_dist
t_damages

# Variables --------------------------------------------
BIMPACT
OMEGA
DAMAGES_DIST
DAMAGES
DAMFRAC_DIST

$endif.ph
