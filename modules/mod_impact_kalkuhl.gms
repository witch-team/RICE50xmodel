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

# OMEGA EQUATION DEFINITION
* | simple | full |
$setglobal  omega_eq 'simple'


## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

PARAMETERS
* Short run
    kw_DT          / 0.00641  /
    kw_DT_lag      / 0.00345  /
    kw_TDT         / -.00105  /
    kw_TDT_lag     / -.000718 /
    kw_T           / -.00675  /
;


##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'


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

#since requires lags fixed first period
#BIMPACT.fx('1',n)  =  (kw_DT+kw_DT_lag) * ((TEMP_REGION_DAM_INCPAST.l('1',n) - TEMP_REGION_DAM_INCPAST.l('0',n)) / tlen('1') )
#+   (kw_TDT+kw_TDT_lag) * (( TEMP_REGION_DAM_INCPAST.l('1',n) - TEMP_REGION_DAM_INCPAST.l('0',n) ) / tlen('1'))  * ( 2*(TEMP_REGION_DAM_INCPAST.l('1',n)-TEMP_REGION_DAM_INCPAST.l('0',n)) + 5 *(TEMP_REGION_DAM_INCPAST.l('0',n)) );
BIMPACT.fx(t,n)$(year(t) le 2020) = 0;
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
  eq_bimpact(t,tm1,n)$(reg(n) and tperiod(t) gt 2 and pre(tm1,t))..  BIMPACT(t,n)  =E=  (kw_DT+kw_DT_lag) * ((TEMP_REGION_DAM(t,n)-TEMP_REGION_DAM(tm1,n)))
                                            +   (kw_TDT+kw_TDT_lag) *(TEMP_REGION_DAM(t,n)-TEMP_REGION_DAM(tm1,n))/tlen(t) * ( 2*(TEMP_REGION_DAM(t,n)-TEMP_REGION_DAM(tm1,n)) + 5 *(TEMP_REGION_DAM(tm1,n)) )
#
;

# OMEGA FULL
$ifthen.omg %omega_eq% == 'full'
* Omega full formulation
 eq_omega(t,tp1,n)$(reg_all(n) and pre(t,tp1) and not tlast(t))..  OMEGA(tp1,n)  =E=  (  (1 + (OMEGA(t,n)))
                                                                            #  TFP factor
                                                                            *  (tfp(tp1,n)/tfp(t,n))
                                                                            #  Pop factor
                                                                            *  ((( pop(tp1,n)/1000  )/( pop(t,n)/1000 ))**prodshare('labour',n)) * (pop(t,n)/pop(tp1,n))
                                                                            #  Capital-Omega factor
                                                                            *  KOMEGA(t,n)
                                                                            #  BHM impact on pc-growth
                                                                            /  ((1 + basegrowthcap(t,n) +  BIMPACT(t,n)   )**tstep)
                                                                        ) - 1  ;

* Capital-Omega factor
 eq_komega(t,n)$(reg_all(n))..  KOMEGA(t,n)  =E=  ( (((1-dk)**tstep) * K(t,n)  +  tstep * S(t,n) * tfp(t,n) * (K(t,n)**prodshare('capital',n)) * ((pop(t,n)/1000)**prodshare('labour',n)) * (1/(1+OMEGA(t,n))) ) / K(t,n) )**prodshare('capital',n)  ;
# OMEGA SIMPLE
$else.omg
* Omega-simple formulation
eq_omega(t,tp1,n)$(reg_all(n) and pre(t,tp1) and not tlast(t))..  OMEGA(tp1,n)  =E=  1/(BIMPACT(tp1,n)+1/(1+OMEGA(t,n)))-1 ;
$endif.omg


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  REPORT
#_________________________________________________________________________
$elseif.ph %phase%=='report'


##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# Variables --------------------------------------------
BIMPACT
KOMEGA


$endif.ph
