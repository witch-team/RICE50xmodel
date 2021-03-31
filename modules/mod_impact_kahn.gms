* IMPACT KAHN SUB-MODULE
* Kahn's damage function implemented according to model regional detail (n)
*____________
* REFERENCES
* - Kahn et al. 2019 (WP) 
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

$setglobal solvermode nlp
#$setglobal solvermode dnlp

# RICH/POOR CUTOFF
* | median | avg |
$setglobal cutoff 'median'

# OMEGA EQUATION DEFINITION
* | simple | full |
$setglobal  omega_eq 'full'
* if savings are free, simgplified omega_eq is needed 
$if not %savings%=="fixed" $setglobal  omega_eq 'simple'
$if not %savings%=="fixed" $if not %omega_eq%=='simple' $abort "Simple Omega equation has to be set under free savings option!"


## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

PARAMETERS
* Impact function coefficients
    beta_kahn(*, n, t)      'KAHN local damage coefficient'
* Rich/poor cutoff threshold
    rich_poor_cutoff(t)     'threshold differentiating rich from poor countries [GDP per capita]'
    rank(t,n)               'countries income rank'
    ykalipc_median(t)       'World median GDP per capita'
    ykalipc_worldavg(t)     'World average GDP per capita'
* Calibrated safety bounds of climate change effect
    ynet_maximum(t,n)       'Maximum allowed gains from climate change'
    ynet_minimum(t,n)       'Maximum allowed damages from climate change'
;


##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'


## MEDIAN CUTOFF EVALUATION ----------------------------
* This is ugly and slow ranking, but it works:
rank(t,n) = sum(nn$((ykali(t,nn)*1e6/pop(t,nn)) gt (ykali(t,n)*1e6/pop(t,n))), 1) + 1;
* There could be a tie in median individuals.
* To be safe, average through the number of median individuals:
ykalipc_median(t) = sum(n$(rank(t,n) eq round(card(n)/2)), (ykali(t,n)*1e6/pop(t,n)))
                  / sum(n$(rank(t,n) eq round(card(n)/2)), 1);
* World Average could be an alternative cutoff threshold
ykalipc_worldavg(t) = sum(n,(ykali(t,n)*1e6)) / sum(n,pop(t,n));

$ifthen.coff %cutoff% == 'median'
* Rich countries threshold: median
rich_poor_cutoff(t) = ykalipc_median(t) ;
$else.coff
* Rich countries threshold: world AVG pro-capita GDP(t)
rich_poor_cutoff(t) = ykalipc_worldavg(t) ;
$endif.coff

# DAMAGES CAP LEVELS -----------------------------------
* Maximum and minimum reachable values (compared to baseline SSP GDP level)
 ynet_maximum(t,n) =   %max_gain%   * ykali(t,n) ;
 ynet_minimum(t,n) =   %max_damage% * ykali(t,n) ;


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
    OMEGA(t,n)           'Economic impact from Climate Change [% of GDP]'
    KIMPACT(t,n)         'Impact coefficient according to KAHN equation'
    KOMEGA(t,n)
    DAMFRAC_UNBOUNDED(t,n)   'Potential unbounded damages, as GDP Gross fraction [%GDPgross]: (+) damages (-) gains '
    YNET_UNBOUNDED(t,n)      'Potential unbounded GDP, net of damages [Trill 2005 USD / year]'
    YNET_UPBOUND(t,n)        'Potential GDP, net of damages, bounded in maximum gains [Trill 2005 USD / year]'
;
POSITIVE VARIABLE KOMEGA;

# VARIABLES STARTING LEVELS ----------------------------
* to help convergence if no startboost is loaded
KOMEGA.l(t,n) = 1 ;
OMEGA.l(t,n) = 0 ;
KIMPACT.l(t,n) = 0 ;
DAMFRAC_UNBOUNDED.l(t,n) = 0 ;
YNET_UNBOUNDED.l(t,n) = ykali(t,n) ;
YNET_UPBOUND.l(t,n) = ykali(t,n)  ;


##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

##  STABILITY CONSTRAINTS ------------------------------
* to avoid errors/help the solver to converge
KIMPACT.lo(t,n) = (-1 + 1e-6) ; # needed because of eq_omega
  OMEGA.lo(t,n) = (-1 + 1e-6) ; # needed because of eq_komega 

* Tolerance for min/max nlp smooting
SCALAR   delta  /1e-8/ ; #-14 more than 1e-8 get solver stucked

##  CONTROL RATE LIMITS --------------------------------
OMEGA.fx(tfirst,n)   = 0    ;


#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

eq_omega     # Impact over time equation
eq_kimpact   # KAHN yearly impact equation
$if %omega_eq% == 'full' eq_komega    # Capital-Omega impact factor equation (only for full-omega)
eq_damfrac_nobnd
eq_ynet_nobnd
eq_ynet_upbnd


##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

##  KAHN'S IMPACT --------------------------------------
* Kahn's yearly local impact
 eq_kimpact(t,n)$(reg(n))..
              # KIMPACT(t,n)  =E= -0.0586 * max((TEMP_REGION_DAM(t,n) - (1/6 * sum(tt$((ord(tt) le ord(t)) and (ord(tt) gt (ord(t) - 6))),TEMP_REGION_DAM(tt,n)) + max(6-ord(t), 0)/6*climate_region_coef('base_temp', n))), 0) + (-0.0520) * max(((1/6 * sum(tt$((ord(tt) le ord(t)) and (ord(tt) gt (ord(t) - 6))),TEMP_REGION_DAM(tt,n)) + max(6-ord(t), 0)/6*climate_region_coef('base_temp', n)) - TEMP_REGION_DAM(t,n)), 0);
                KIMPACT(t,n)  =E= -0.0586 * (TEMP_REGION_DAM(t,n) - (1/6 * sum(tt$((ord(tt) le ord(t)) and (ord(tt) gt (ord(t) - 6))),TEMP_REGION_DAM(tt,n)) + max(6-ord(t), 0)/6*climate_region_coef('base_temp', n)) ) ;
#..................................................................................................................
# Simplifying assumptions for the 30yrs moving-average:
# - TEMP_REGION(t,n) is the temperature in year(t), year(t) - 1, ..., year(t) - 4
# - 5-year moving average between 2010 and 1981 is always the same and equal to climate_region_coef('base_temp', n)
#...................................................................................................................

# OMEGA FULL
$ifthen.omg %omega_eq% == 'full'
* Omega full formulation
 eq_omega(t,n)$(reg(n) and not tlast(t))..  OMEGA(t+1,n)  =E=  (  (1 + (OMEGA(t,n)))
                                                                            #  TFP factor
                                                                            *  (tfp(t+1,n)/tfp(t,n))
                                                                            #  Pop factor
                                                                            *  ((( pop(t+1,n)/1000  )/( pop(t,n)/1000 ))**(1-gama)) * (pop(t,n)/pop(t+1,n))
                                                                            #  Capital-Omega factor
                                                                            *  KOMEGA(t,n)
                                                                            #  BHM impact on pc-growth
                                                                            /  ((1 + basegrowthcap(t,n) +  KIMPACT(t,n)   )**tstep)
                                                                        ) - 1  ;

* Capital-Omega factor
 eq_komega(t,n)$(reg(n))..  KOMEGA(t,n)  =E=  ( (((1-dk)**tstep) * K(t,n)  +  tstep * S(t,n) * tfp(t,n) * (K(t,n)**gama) * ((pop(t,n)/1000)**(1-gama)) * (1/(1+OMEGA(t,n))) ) / K(t,n) )**gama  ;
# OMEGA SIMPLE
$else.omg
* Omega-simple formulation
 eq_omega(t,n)$(reg(n)  and not tlast(t))..  OMEGA(t+1,n)  =E=  (  (1 + (OMEGA(t,n))) / ((1 + KIMPACT(t,n))**tstep)  ) - 1  ;
$endif.omg


##  ESTIMATED YNET AND DAMAGES -------------------------
* Unbounded Damfrac
 eq_damfrac_nobnd(t,n)$(reg(n))..   DAMFRAC_UNBOUNDED(t,n)  =E=   1 - ( 1/(1+OMEGA(t,n)) )  ;
* Unbounded YNET esteem
 eq_ynet_nobnd(t,n)$(reg(n))..   YNET_UNBOUNDED(t,n)  =E=  YGROSS(t,n) * (1 - DAMFRAC_UNBOUNDED(t,n))  ;
* Gains upperbound 
 eq_ynet_upbnd(t,n)$(reg(n))..   YNET_UPBOUND(t,n)  =E=  ( YNET_UNBOUNDED(t,n) + ynet_maximum(t,n) - Sqrt( Sqr(YNET_UNBOUNDED(t,n)-ynet_maximum(t,n)) + Sqr(delta) ) )/2  ;

* Damages lowerbound and final YNET esteem
 eq_ynet_estim(t,n)$(reg(n))..  
   YNET_ESTIMATED(t,n)  =E=  ( YNET_UPBOUND(t,n) + ynet_minimum(t,n) + Sqrt( Sqr(YNET_UPBOUND(t,n)-ynet_minimum(t,n)) + Sqr(delta) ) )/2  ;

##  EFFECTIVE DAMAGES ----------------------------------
* Effective net Damages
eq_damages(t,n)$(reg(n))..   DAMAGES(t,n)  =E=  (YGROSS(t,n) - YNET_ESTIMATED(t,n)) ;

* Effective Damages as fraction of YGROSS
 eq_damfrac(t,n)$(reg(n))..   DAMFRAC(t,n)  =E= (-1) * ( DAMAGES(t,n) / YGROSS(t,n) )  ;


#=========================================================================
*   ///////////////////////     SIMULATION    ///////////////////////
#=========================================================================

##  SIMULATION HALFLOOP 1
#_________________________________________________________________________
$elseif.ph %phase%=='simulate_1'

##  KAHN'S IMPACT --------------------------------------
* Kahn's yearly local impact
 KIMPACT.l(t,n)  =  -0.0586 * (   TEMP_REGION_DAM.l(t,n) - 
                                 (1/6 * sum(tt$((ord(tt) le ord(t)) and (ord(tt) gt (ord(t) - 6))),TEMP_REGION_DAM.l(tt,n)) + max(6-ord(t), 0)/6*climate_region_coef('base_temp', n)) 
                              ) ;
 #-0.0586 * max((TEMP_REGION.l(t,n) - TEMP_REGION.l(t-1,n)), 0) + (-0.0520) * max((TEMP_REGION.l(t-1,n)  - TEMP_REGION.l(t,n)), 0);

# OMEGA FULL
$ifthen.omg  %omega_eq% == 'full'
* Capital-Omega factor
 KOMEGA.l(t,n)  =  ( (((1-dk)**tstep) * K.l(t,n)   +  tstep * S.l(t,n) * tfp(t,n) * (K.l(t,n)**gama) * ((pop(t,n)/1000)**(1-gama)) * (1/(1+OMEGA.l(t,n))) ) / K.l(t,n) )**gama  ;
* Omega full formulation
 OMEGA.l(t+1,n)$(not tlast(t))  =  ((  (1 + (OMEGA.l(t,n)))
                                    #  TFP factor
                                    *  (tfp(t+1,n)/tfp(t,n))
                                    #  Pop factor
                                    *  ((( pop(t+1,n)/1000  )/( pop(t,n)/1000 ))**(1-gama)) * (pop(t,n)/pop(t+1,n)) 
                                    #  Capital-Omega factor
                                    *  KOMEGA.l(t,n)
                                    #  BHM impact on pc-growth
                                    /  ((1 + basegrowthcap(t,n) + KIMPACT.l(t,n))**tstep)
                                    ) - 1    )  ;
# OMEGA SIMPLE
$else.omg
* Omega-simple formulation
 OMEGA.l(t+1,n)$(not tlast(t))  =  ( (1 + (OMEGA.l(t,n))) / ((1 + KIMPACT.l(t,n))**tstep) ) - 1  ;
$endif.omg

##  ESTIMATED YNET AND DAMAGES -------------------------
* Unbounded Damfrac
DAMFRAC_UNBOUNDED.l(t,n)  =   1 - ( 1/(1+OMEGA.l(t,n)) )  ;
* Unbounded YNET esteem
YNET_UNBOUNDED.l(t,n)  =  YGROSS.l(t,n) * (1 - DAMFRAC_UNBOUNDED.l(t,n))  ;
* Gains upperbound 
YNET_UPBOUND.l(t,n)  =  min( YNET_UNBOUNDED.l(t,n) , ynet_maximum(t,n) )  ; 
* Damages lowerbound and final YNET esteem
YNET_ESTIMATED.l(t,n) =  max( YNET_UPBOUND.l(t,n) , ynet_minimum(t,n) )   ;


##  EFFECTIVE DAMAGES ----------------------------------
* Effective net Damages
DAMAGES.l(t,n)  =  (YGROSS.l(t,n) - YNET_ESTIMATED.l(t,n)) ;
* Effective Damages as fraction of YGROSS
DAMFRAC.l(t,n)  =  (-1) * (DAMAGES.l(t,n)/YGROSS.l(t,n))  ;


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# Parameters -------------------------------------------
rich_poor_cutoff
ykalipc_median
ykalipc_worldavg

# Variables --------------------------------------------
KIMPACT
OMEGA
KOMEGA


$endif.ph

