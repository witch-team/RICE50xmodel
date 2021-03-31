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
* Short run
    bhm_SR_T            'Short Run Temperature coeff'                      /  0.0127184 /
    bhm_SR_T2           'Short Run squared Temperature coeff'              / -0.0004871 /

* Long run
    bhm_LR_T            'Long-Run Temperature coeff'                       / -0.0037497 /
    bhm_LR_T2           'Long-Run squared Temperature coeff'               / -0.0000955 /

* Short run differentiated
    bhm_SRdiff_rich_T   'Short-Run diff, rich, Temperature coeff'          /  0.0088951 /
    bhm_SRdiff_rich_T2  'Short-Run diff, rich, squared Temperature coeff'  / -0.0003155 /
    bhm_SRdiff_poor_T   'Short-Run diff, poor, Temperature coeff'          /  0.0254342 /
    bhm_SRdiff_poor_T2  'Short-Run diff, poor, squared Temperature coeff'  / -0.000772  /

* Long run differentiated
    bhm_LRdiff_rich_T   'Long-Run diff, rich, Temperature coeff'           / -0.0026918 /
    bhm_LRdiff_rich_T2  'Long-Run diff, rich, squared Temperature coeff'   / -0.000022  /
    bhm_LRdiff_poor_T   'Long-Run diff, poor, Temperature coeff'           / -0.0186    /
    bhm_LRdiff_poor_T2  'Long-Run diff, poor, squared Temperature coeff'   /  0.0001513 /
;

PARAMETERS
* Impact function coefficients
   beta_bhm(*, n, t)        'Burke local damage coefficient'
* Rich/poor cutoff threshold
    rich_poor_cutoff(t)     'Threshold differentiating rich from poor countries [GDP per capita]'
    rank(t,n)               'Income GDP per-capita rank'
    ykalicap_median(t)      'World median GDP per capita'
    ykalicap_worldavg(t)    'World average GDP per capita'
* Calibrated safety bounds of climate change effect
    ynet_maximum(t,n)       'Maximum allowed gains from climate change'
    ynet_minimum(t,n)       'Maximum allowed damages from climate change'
;


##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

## MEDIAN CUTOFF EVALUATION ----------------------------
#...........................................................................
# Not trivial in GAMS,
# ranking code inspired by solution here:
# https://support.gams.com/gams:compute_the_median_of_a_parameter_s_values
#...........................................................................

* This is ugly and slow ranking, but it works:
rank(t,n) = sum(nn$((ykali(t,nn)*1e6/pop(t,nn)) gt (ykali(t,n)*1e6/pop(t,n))), 1) + 1;

* There could be a tie in median individuals.
* To be safe, average through the number of median individuals:
ykalicap_median(t) = sum(n$(rank(t,n) eq round(card(n)/2)), (ykali(t,n)*1e6/pop(t,n)))
                   / sum(n$(rank(t,n) eq round(card(n)/2)), 1);

* World Average could be an alternative cutoff threshold
ykalicap_worldavg(t) = sum(n,(ykali(t,n)*1e6)) / sum(n,pop(t,n));

$ifthen.coff %cutoff% == 'median'
* Rich countries threshold: median
rich_poor_cutoff(t) = ykalicap_median(t) ;
$else.coff
* Rich countries threshold: world AVG pro-capita GDP(t)
rich_poor_cutoff(t) = ykalicap_worldavg(t) ;
$endif.coff

##  IMPACT COEFFICIENTS --------------------------------
#....................................................................
# Needs for Burke-growth "beta_bhm" coefficients
# Note: Burke impact function is also often indicated
# with delta(T) symbol:
# delta(n,t) = bhm1 * TEMP_REGION(n,t) + bhm2 * TEMP_REGION(n,t)^2
#...................................................................

*SR Baseline specification (SR, not differentiated)
$ifthen.bhm %bhm_spec%=='sr'
beta_bhm('T',  n, t) = bhm_SR_T  ;
beta_bhm('T2', n, t) = bhm_SR_T2 ;

*Lagged specification (5 years LDV)
$elseif.bhm %bhm_spec%=='lr'
beta_bhm('T',  n, t)  =  bhm_LR_T    ;
beta_bhm('T2', n, t)  =  bhm_LR_T2   ;

*Differentiated lagged values (short run for now since LR coefficients not in the paper nor SI) Rich for compared to mean income
$elseif.bhm %bhm_spec%=='srdiff'
#rich
beta_bhm('T',  n, t)$(((ykali(t,n)*1e6)/pop(t,n)) gt rich_poor_cutoff(t))  =  bhm_SRdiff_rich_T   ;
beta_bhm('T2', n, t)$(((ykali(t,n)*1e6)/pop(t,n)) gt rich_poor_cutoff(t))  =  bhm_SRdiff_rich_T2  ;
#poor
beta_bhm('T',  n, t)$(((ykali(t,n)*1e6)/pop(t,n)) le rich_poor_cutoff(t))  =  bhm_SRdiff_poor_T   ;
beta_bhm('T2', n, t)$(((ykali(t,n)*1e6)/pop(t,n)) le rich_poor_cutoff(t))  =  bhm_SRdiff_poor_T2  ;

*Differentiated lagged values (5 lagged values)
$elseif.bhm %bhm_spec%=='lrdiff'
#rich
beta_bhm('T',  n, t)$(((ykali(t,n)*1e6)/pop(t,n)) gt rich_poor_cutoff(t))  =  bhm_LRdiff_rich_T   ;
beta_bhm('T2', n, t)$(((ykali(t,n)*1e6)/pop(t,n)) gt rich_poor_cutoff(t))  =  bhm_LRdiff_rich_T2  ;
#poor
beta_bhm('T',  n, t)$(((ykali(t,n)*1e6)/pop(t,n)) le rich_poor_cutoff(t))  =  bhm_LRdiff_poor_T   ;
beta_bhm('T2', n, t)$(((ykali(t,n)*1e6)/pop(t,n)) le rich_poor_cutoff(t))  =  bhm_LRdiff_poor_T2  ;
$endif.bhm

# DAMAGES CAP LEVELS -----------------------------------
* Maximum and minimum reachable values (compared to baseline SSP GDP level)
 ynet_maximum(t,n) =   %max_gain%   * ykali(t,n) ;
 ynet_minimum(t,n) =   %max_damage% * ykali(t,n) ;


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
    BIMPACT(t,n)         'Impact coefficient according to Burke equation'
    OMEGA(t,n)           'Economic Burke impact from Climate Change [% of GDP]'
    KOMEGA(t,n)          'Capital-Omega cross factor'
    DAMFRAC_UNBOUNDED(t,n)   'Potential unbounded damages, as GDP Gross fraction [%GDPgross]: (+) damages (-) gains '
    YNET_UNBOUNDED(t,n)      'Potential unbounded GDP, net of damages [Trill 2005 USD / year]'
    YNET_UPBOUND(t,n)        'Potential GDP, net of damages, bounded in maximum gains [Trill 2005 USD / year]'
;
POSITIVE VARIABLE KOMEGA;


# VARIABLES STARTING LEVELS ----------------------------
* to help convergence if no startboost is loaded
OMEGA.l(t,n) = 0 ;
BIMPACT.l(t,n) = 0 ;
KOMEGA.l(t,n) = 1 ;
DAMFRAC_UNBOUNDED.l(t,n) = 0 ;
YNET_UNBOUNDED.l(t,n) = ykali(t,n) ;
YNET_UPBOUND.l(t,n) = ykali(t,n)  ;


##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

##  STABILITY CONSTRAINTS ------------------------------
* to avoid errors/help the solver to converge
  OMEGA.lo(t,n) = (-1 + 1e-6) ; # needed because of eq_komega [not > 1e-3!]
BIMPACT.lo(t,n) = (-1 + 1e-6) ; # needed because of eq_omega 

* Tolerance for min/max nlp smooting
SCALAR   delta  /1e-2/ ; #-14 more than 1e-8 get solver stucked

# NOTE ...........................................
# Don't limit YNET_* variables
# The bounding logic already limits the interval
#.................................................

##  CONTROL RATE LIMITS --------------------------------
OMEGA.fx(tfirst,n)   = 0    ;


#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

eq_bimpact   # BHM yearly impact equation
eq_omega     # Impact over time equation
$if %omega_eq% == 'full' eq_komega     # Capital-Omega impact factor equation (only for full-omega)
eq_damfrac_nobnd
eq_ynet_nobnd
eq_ynet_upbnd


##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

##  BURKE'S IMPACT --------------------------------------
* BHM's yearly local impact
 eq_bimpact(t,n)$(reg(n))..  BIMPACT(t,n)  =E=  beta_bhm('T', n, t) * TEMP_REGION_DAM(t,n)
                                            +   beta_bhm('T2', n, t)* power(TEMP_REGION_DAM(t,n),2)
                                            -   beta_bhm('T', n, t) * climate_region_coef('base_temp', n)
                                            -   beta_bhm('T2', n, t)* power(climate_region_coef('base_temp', n),2) ;

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
                                                                            /  ((1 + basegrowthcap(t,n) +  BIMPACT(t,n)   )**tstep)
                                                                        ) - 1  ;

* Capital-Omega factor
 eq_komega(t,n)$(reg(n))..  KOMEGA(t,n)  =E=  ( (((1-dk)**tstep) * K(t,n)  +  tstep * S(t,n) * tfp(t,n) * (K(t,n)**gama) * ((pop(t,n)/1000)**(1-gama)) * (1/(1+OMEGA(t,n))) ) / K(t,n) )**gama  ;
# OMEGA SIMPLE
$else.omg
* Omega-simple formulation
 eq_omega(t,n)$(reg(n)  and not tlast(t))..  OMEGA(t+1,n)  =E=  (  (1 + (OMEGA(t,n))) / ((1 + BIMPACT(t,n))**tstep)  ) - 1  ;
$endif.omg

##  ESTIMATED YNET AND DAMAGES -------------------------
* Unbounded Damfrac
 eq_damfrac_nobnd(t,n)$(reg(n))..   DAMFRAC_UNBOUNDED(t,n)  =E=   1 - ( 1/(1+OMEGA(t,n)) )  ;
* Unbounded YNET esteem
 eq_ynet_nobnd(t,n)$(reg(n))..   YNET_UNBOUNDED(t,n)  =E=  YGROSS(t,n) * (1 - DAMFRAC_UNBOUNDED(t,n))  ;
* Gains upperbound 
 eq_ynet_upbnd(t,n)$(reg(n))..   
   YNET_UPBOUND(t,n)  =E=  ( YNET_UNBOUNDED(t,n) + ynet_maximum(t,n) - Sqrt( Sqr(YNET_UNBOUNDED(t,n)-ynet_maximum(t,n)) + Sqr(delta) ) )/2  ;

* Damages lowerbound and final YNET estimated
 eq_ynet_estim(t,n)$(reg(n))..  
   YNET_ESTIMATED(t,n)  =E=  ( YNET_UPBOUND(t,n) + ynet_minimum(t,n) + Sqrt( Sqr(YNET_UPBOUND(t,n)-ynet_minimum(t,n)) + Sqr(delta) ) )/2  ;

    #................................................................................
    # UPPER BOUND ->  fix maximum YNET level -> min( YNET_UNBOUNDED, ynet_maximum )
    # LOWER BOUND ->  fix minimum YNET level -> max( YNET_UNBOUNDED, ynet_minimum )
    #
    # A smooth GAMS approximation for  min(f(x),g(y))  is:
    #    ( f(x) + g(y) - Sqrt( Sqr( f(x)-g(y) ) + Sqr(delta) ) )/2
    #
    # A smooth GAMS approximation for  max(f(x),g(y))  is:
    #   ( a(x) + b(y) + Sqrt( Sqr(a(x)-b(y)) + Sqr(delta) ) )/2
    #................................................................................

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

##  BURKE'S IMPACT -------------------------------------
* BHM's yearly local impact
 BIMPACT.l(t,n)  =  beta_bhm('T',  n, t) * TEMP_REGION_DAM.l(t,n)
                 +  beta_bhm('T2', n, t) * power(TEMP_REGION_DAM.l(t,n),2)
                 -  beta_bhm('T',  n, t) * climate_region_coef('base_temp', n)
                 -  beta_bhm('T2', n, t) * power(climate_region_coef('base_temp', n),2)  ;

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
                                    /  ((1 + basegrowthcap(t,n) + BIMPACT.l(t,n))**tstep)
                                    ) - 1    )  ;
# OMEGA SIMPLE
$else.omg
* Omega-simple formulation
 OMEGA.l(t+1,n)$(not tlast(t))  =  ( (1 + (OMEGA.l(t,n))) / ((1 + BIMPACT.l(t,n))**tstep) ) - 1  ;
$endif.omg


##  ESTIMATED YNET AND DAMAGES -------------------------
* Unbounded Damfrac
DAMFRAC_UNBOUNDED.l(t,n)  =   1 - ( 1/(1+OMEGA.l(t,n)) )  ;
* Unbounded YNET
YNET_UNBOUNDED.l(t,n)  =  YGROSS.l(t,n) * (1 - DAMFRAC_UNBOUNDED.l(t,n))  ;
* Gains upperbound 
YNET_UPBOUND.l(t,n)  =  min( YNET_UNBOUNDED.l(t,n) , ynet_maximum(t,n) )  ; 
* Damages lowerbound and final YNET
YNET_ESTIMATED.l(t,n) =  max( YNET_UPBOUND.l(t,n) , ynet_minimum(t,n) )   ;

##  EFFECTIVE DAMAGES ----------------------------------
* Effective net Damages
DAMAGES.l(t,n)  =  (YGROSS.l(t,n) - YNET_ESTIMATED.l(t,n)) ;
* Effective Damages as fraction of YGROSS
DAMFRAC.l(t,n)  =  (-1) * (DAMAGES.l(t,n)/YGROSS.l(t,n))  ;


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  REPORT
#_________________________________________________________________________
$elseif.ph %phase%=='report'

##  BURKE DAMAGES SIMULATED ----------------------------
* Here we simulate corresponding Burke damages (WITHOUT ABATE COSTS)
* from his growth-based original function, applied for each country:
* GDPcap(t+1) = GDPcap(t) * (1+basegrowth(t)+ bimpact(t))**tstep

PARAMETERS
       ynet_burkesim(t,n) 
    ynetcap_burkesim(t,n)
    damfrac_burkesim(t,n)  'Burke %damages over no-ClimateChange scenario using growth formula [%GDPssp]: (-) damage (+) gain'
    damages_burkesim(t,n)  'Burke absolute damages over no-ClimateChange scenario using growth formula [T$] (Trill 2005 USD): (-) damage (+) gain'
world_damfrac_burkesim(t)  'Burke-simulated world damages [%baseline]'
;

* Starting point
 ynetcap_burkesim(tfirst(t),n) = ykali('1',n)/pop('1',n);

* Simulation using pc-growth formula
 loop(t$(t.val < card(t)),    ynetcap_burkesim(t+1,n)  =  ynetcap_burkesim(t,n) * (( 1 + basegrowthcap(t,n) + BIMPACT.l(t,n) )**tstep)  ;   );

* Damages evaluation
    damfrac_burkesim(t,n) = (  (ynetcap_burkesim(t,n) - (ykali(t,n)/pop(t,n))) / (ykali(t,n)/pop(t,n))  ) * (100)  ;
    damages_burkesim(t,n) = damfrac_burkesim(t,n) * ykali(t,n) ;
       ynet_burkesim(t,n) = ynetcap_burkesim(t,n) * pop(t,n)   ;
world_damfrac_burkesim(t) = (sum(n,ynet_burkesim(t,n)) - sum(n,ykali(t,n))) / sum(n,ykali(t,n)) * 100 ;


##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# Parameters -------------------------------------------
rich_poor_cutoff
ykalicap_median
ykalicap_worldavg
damfrac_burkesim
damages_burkesim
ynetcap_burkesim
ynet_burkesim
world_damfrac_burkesim
ynet_maximum
ynet_minimum

# Variables --------------------------------------------
BIMPACT
OMEGA
KOMEGA


$endif.ph
