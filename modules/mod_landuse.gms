* MODULE LAND USE
* To assess how much emissions are coming from Land Use.
* Temporarily based on a distributed version of DICE2016 process.
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

$setglobal luscenario 'ssp2-base' # ssp2-base | ssp2-sdg

## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

set yearlu /1850*2300/;

set v / 'MIULAND' /; 
vcheck('MIULAND') = yes;

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

PARAMETERS
** LU-Baseline
   eland_bau(t,n,*) 'Carbon emissions baselines from land [GtCO2/year]'
   eland_maxab(n,*) 'Maximum abatement potential of land emissions [GtCO2/year]'
   lu_maccs(t,n,*,*) 'Marginal abatement cost coefficients for land emissions [trillion $/GtCO2]'
;

$gdxin  '%datapath%data_mod_landuse.gdx'
$load   eland_bau=lu_baseline eland_maxab=lu_abatemax lu_maccs
$gdxin



##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

coefact("c1",'lu') = yes;
coefact("c4",'lu') = yes;

macc_coef(t,n,'lu',coef) = lu_maccs(t,n,'%luscenario%',coef);
macc_coef(t,n,'lu',coef)$(macc_coef(t,n,'lu',coef) < 0) = 0;

##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES    ELAND(t,n)      'Land-use emissions   [GtCO2/year]',
             MACLAND(t,n)    'Marginal abatement cost of land use emissions [trillion $]',
             MIULAND(t,n)    'Control rate for land use emissions',
             ABCOSTLAND(t,n) 'Total abatement cost of land use emissions [trillion $]';


# VARIABLES STARTING LEVELS 
ELAND.l(t,n) = eland_bau(t,n,'%luscenario%');

##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

MIULAND.lo(t,n) = 0;
MIULAND.up(t,n) = 1;

MIULAND.fx(t,n)$(tmiufix(t)) = 0;



#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
* List of equations
* One per line.
$elseif.ph %phase%=='eql'

    eq_eland
    eq_mcland
    eq_tcland
    
##  EQUATIONS
#_________________________________________________________________________
* In the phase EQS, you can include new equations to the model.
* The equations are always included.
* Best practice : - condition your equation to be able to do a run with tfix(t)
$elseif.ph %phase%=='eqs'

 eq_eland(t,n)$(reg(n))..   ELAND(t,n)  =E=  eland_bau(t,n,'%luscenario%') - eland_maxab(n,'%luscenario%')*MIULAND(t,n);

 eq_mcland(t,n)$(reg(n))..   MACLAND(t,n)  =E=  sum(coef$coefact(coef,'lu'), macc_coef(t,n,'lu',coef)*power(MIULAND(t,n),(coefn(coef))));

 eq_tcland(t,n)$(reg(n))..  ABCOSTLAND(t,n)  =E= convy_ghg('co2') * eland_maxab(n,'%luscenario%') * 
    sum(coef$coefact(coef,'lu'), macc_coef(t,n,'lu',coef)*power(MIULAND(t,n),(coefn(coef)+1))/(coefn(coef)+1)); # back to trillion dollars

##  AFTER SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='after_solve'

viter(iter,'MIULAND',t,n)$nsolve(n)   = MIULAND.l(t,n);    # Keep track of last investment values



#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# Parameters -------------------------------------------
eland_bau
eland_maxab

# Variables --------------------------------------------
ELAND
MACLAND
ABCOSTLAND
MIULAND

$endif.ph

