* IMPACT DELL SUB-MODULE
* DELL's damage function implemented according to model regional detail (n)
*____________
* REFERENCES
* - Dell et al. 2014
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
$setglobal  omega_eq 'simple'

* Given the Dell extreme impact functions, use a damage cap by default
$setglobal damage_cap

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

PARAMETERS
    djo_rich   'rich DJO temperature coeff' / 0.00261/
;

PARAMETERS
* Impact function coefficients
    beta_djo(*, n, t)      'DJO local damage coefficient'
* Rich/poor cutoff threshold
    rich_poor_cutoff(t)    'Threshold differentiating rich from poor countries (GDPcap)'
    rank(t,n)              'Income rank'
    ykalipc_median(t)      'World median GDP per capita'
    ykalipc_worldavg(t)    'World average GDP per capita'
;


##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

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

##  IMPACT COEFFICIENTS --------------------------------
* Rich coeffs
beta_djo('T',  n, t)$(((ykali('1',n)*1e6)/pop('1',n)) gt rich_poor_cutoff('1'))  =  0.00261;
* Poor coeffs
beta_djo('T',  n, t)$(((ykali('1',n)*1e6)/pop('1',n)) le rich_poor_cutoff('1'))  =  0.00261 - 0.01655;


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
    DJOIMPACT(t,n)       'Impact coefficient according to DJO equation'
    KOMEGA(t,n)              'Capital-Omega cross factor'
    DAMFRAC_UNBOUNDED(t,n)   'Potential unbounded damages, as GDP Gross fraction [%GDPgross]: (+) damages (-) gains '
    YNET_UNBOUNDED(t,n)      'Potential unbounded GDP, net of damages [Trill 2005 USD / year]'
    YNET_UPBOUND(t,n)        'Potential GDP, net of damages, bounded in maximum gains [Trill 2005 USD / year]'
;
KOMEGA.lo(t,n) = 0;

# VARIABLES STARTING LEVELS ----------------------------
KOMEGA.l(t,n) = 1 ;
DJOIMPACT.l(t,n) = 0 ;


##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

##  STABILITY CONSTRAINTS ------------------------------
* to avoid errors/help the solver to converge
DJOIMPACT.lo(t,n) = (-1 + 1e-5) ; # needed because of eq_omega
DJOIMPACT.fx(tfirst,n) = 0;

#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'
eq_omega      # Yearly impact equation 
eq_djoimpact  # DJO tstep impact equation
$if %omega_eq% == 'full' eq_komega     # Capital-Omega impact factor equation (only for full-omega)


##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

##  DJO'S IMPACT --------------------------------------
* DJO's yearly local impact
 eq_djoimpact(t,n)$(reg(n) and not tfirst(t))..  DJOIMPACT(t,n)  =E=  beta_djo('T',n,t) * (TEMP_REGION_DAM(t,n)-climate_region_coef('base_temp',n))  ;             

# OMEGA FULL
$ifthen.omg %omega_eq% == 'full'
* Omega full formulation
 eq_omega(t,n)$(reg(n) and not tlast(t))..  OMEGA(t+1,n)  =E=  (  (1 + (OMEGA(t,n)))
                                                                            #  TFP factor
                                                                            *  (tfp(t+1,n)/tfp(t,n))
                                                                            #  Pop factor
                                                                            *  ((( pop(t+1,n)/1000  )/( pop(t,n)/1000 ))**prodshare('labour',n)) * (pop(t,n)/pop(t+1,n))
                                                                            #  Capital-Omega factor
                                                                            *  KOMEGA(t,n)
                                                                            #  BHM impact on pc-growth
                                                                            /  ((1 + basegrowthcap(t,n) +  DJOIMPACT(t,n)   )**tstep)
                                                                        ) - 1  ;
* Capital-Omega factor
 eq_komega(t,n)$(reg(n))..  KOMEGA(t,n)  =E=  ( (((1-dk)**tstep) * K(t,n)  +  tstep * S(t,n) * tfp(t,n) * (K(t,n)**prodshare('capital',n)) * ((pop(t,n)/1000)**prodshare('labour',n)) * (1/(1+OMEGA(t,n))) ) / K(t,n) )**prodshare('capital',n)  ;
# OMEGA SIMPLE
$else.omg
* Omega-simple formulation
 eq_omega(t,n)$(reg(n)  and not tlast(t))..  OMEGA(t+1,n)  =E=  (  (1 + (OMEGA(t,n))) / ((1 + DJOIMPACT(t,n))**tstep)  ) - 1  ;
$endif.omg


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
DJOIMPACT
KOMEGA


$endif.ph

