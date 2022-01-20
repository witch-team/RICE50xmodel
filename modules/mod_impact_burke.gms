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

* Burke alternatives: | sr | lr | srdiff | lrdiff
$setglobal bhm_spec 'sr'

# RICH/POOR CUTOFF
* | median | avg |
$setglobal cutoff 'median'

# OMEGA EQUATION DEFINITION
* | simple | full |
$setglobal  omega_eq 'simple'

* Damages in the optimization ('' using the endogenous variable) or post-processed ('.l' using the level in the equation)
$setglobal dam_endo '' #'.l'

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


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
    BIMPACT(t,n)             'Impact coefficient according to Burke equation'
    KOMEGA(t,n)              'Capital-Omega cross factor'
;
KOMEGA.lo(t,n) = 0;


# VARIABLES STARTING LEVELS ----------------------------
BIMPACT.l(t,n) = 0 ;
KOMEGA.l(t,n) = 1 ;


##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

##  STABILITY CONSTRAINTS ------------------------------
* to avoid errors/help the solver to converge
BIMPACT.lo(t,n) = (-1 + 1e-6) ; # needed because of eq_omega 


#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

eq_bimpact   # BHM yearly impact equation
eq_omega     # Impact over time equation
$if %omega_eq% == 'full' eq_komega     # Capital-Omega impact factor equation (only for full-omega)


##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

##  BURKE'S IMPACT --------------------------------------
* BHM's yearly local impact
 eq_bimpact(t,n)$(reg(n))..  BIMPACT(t,n)  =E=  beta_bhm('T', n, t) * TEMP_REGION_DAM%dam_endo%(t,n)
                                            +   beta_bhm('T2', n, t)* power(TEMP_REGION_DAM%dam_endo%(t,n),2)
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

# Variables --------------------------------------------
BIMPACT
KOMEGA


$endif.ph
