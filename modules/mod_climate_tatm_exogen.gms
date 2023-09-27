* EXOGEN TATM CLIMATE SUB-MODULE
*
* Athmospheric mean Temperature imposed by external data (ssp-based)
* Climate dynamics follow simple-climate specifications
* Intended for SIMULATION mainly
*____________
* REFERENCES
* - IPCC: https://unfccc.int/sites/default/files/7_knutti.reto.3sed2.pdf

#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

$setglobal tatm_inc_tstep 0.05
#setglobal results_for_fixed_tatm results_ssp2_cba_noncoop.gdx

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

Scalar tatm_inc_tstep 'Exogenous increase per tstep (5yrs)' / %tatm_inc_tstep% /;


PARAMETERS
** Climate model parameters
        fex0        '2015 forcings of non-CO2 GHG [Wm-2]'                   / 0.5 /    #DICE2013: 0.25    #DICE2016: 0.5
        fex1        '2100 forcings of non-CO2 GHG [Wm-2]'                   / 1.0 /    #DICE2013: 0.70    #DICE2016: 1.0
        t2xco2      'Equilibrium temp impact [°C per doubling CO2]'         /3.1 /     #DICE2013: 2.9     #DICE2016: 3.1
        fco22x      'Forcings of equilibrium CO2 doubling (Wm-2)'           /3.6813/   #DICE2013: 3.8     #DICE2016: 3.6813
        c10         'Initial climate equation coefficient for upper level'  /0.098  /
        c1beta      'Regression slope coefficient(SoA~Equil TSC)'           /0.01243/
        c1          'Climate equation coefficient for upper level'          /0.1005/   #DICE2013: 0.098   #DICE2016: 0.1005
        c3          'Transfer coefficient upper to lower stratum'           /0.088 /
        c4          'Transfer coefficient for lower level'                  /0.025 /
        force2015                                                           /2.4634/
        tatm2010                                                            /0.80/
        tcorr       'Correction factor for TATM'                            /0.3291984/
;

##  PARAMETERS EVALUATED ----------
PARAMETERS
  forcoth(t)      'Exogenous forcing from other greenhouse gases'
  fcorr           'Correction factor for Radiative Forcing'
  force0ev        'Starting forcing level'
;

##  PARAMETERS LOADED ----------
# EXOGENOUS TATM
PARAMETER
    temp_tatm_exogen(t)   'Atmospheric temperature increase from external data [+°C]'
;

$ifthen.exo set results_for_fixed_tatm 
$gdxin %results_for_fixed_tatm%
$loaddc temp_tatm_exogen = TATM.l
$gdxin
$endif.exo
##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

$ifthen.exo not set results_for_fixed_tatm
#for now simplified trajectories for tatm
temp_tatm_exogen(t) = tatm0 + tatm_inc_tstep * (t.val - 1);
$endif.exo

* OGHG forcing exogenous DICE-like
forcoth(t) = fex0 + (1/17) * (fex1-fex0) * (t.val-1)$(t.val lt 18)  # Linear interpolation from fex0 (t1) to fex1 (t17),
                  + (fex1-fex0)$(t.val ge 18) ;                     # then (t > 17) level fixed to fex1

*Transient TSC Correction ("Speed of Adjustment Parameter")
c1 =  c10 + c1beta*(t2xco2-2.9);

force0ev =  ((fco22x/t2xco2) * tatm2010)
         +   ((tatm0 -tatm2010)/c1)
         +   (c3*(tatm2010 - tocean0));

fcorr = 0.6*( force2015 - force0ev);


##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

FORC.FX(tfirst) = 2.4634;  # from DICE2016
TATM.lo(tfirst) = -inf;
TATM.up(tfirst) = +inf;

#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

# TEMPERATURE
* Athmosphere
eq_tatm(t)..   TATM(t)  =E=  temp_tatm_exogen(t) ;
* Ocean
eq_tocean(t+1)..   TOCEAN(t+1)  =E=  TOCEAN(t) + c4 * (TATM(t)-TOCEAN(t))  ;

# FORCING
eq_forc(t+1)..   FORC(t+1)  =E=  ( (fco22x/t2xco2) * TATM(t) ) # Inversion of the original DICE2016
                             +   ( (TATM(t+1)-TATM(t))  / c1 ) # TATM( FORC,... ) equation
                             +   ( c3 *  (TATM(t)-TOCEAN(t)) ) #
                             +   fcorr   ;                     # Empirical correction factor.


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# parameters
temp_tatm_exogen


$endif.ph
