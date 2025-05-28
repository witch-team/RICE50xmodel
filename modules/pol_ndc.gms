# MODULE TEMPLATE
*
* Short description 
#____________
# REFERENCES
* - 
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
* Definition of the global flags and settings specific to the module 
$ifthen.ph %phase%=='conf'

* NDCs extrapolation: | no | const | linear | hotelling |
$setglobal ndcs_bound ".fx" # .fx fixes the NDCs, .lo sets a lower bound
$setglobal ndcs_extr "linear"

*MIU is fixed up to 2030, by default other policies start in 2035
$setglobal ctax_start 2035

$setglobal tax_oghg_as_co2

## SETS
#_________________________________________________________________________
* In the phase SETS you should declare all your sets, or add to the existing 
* sets the element that you need.
$elseif.ph %phase%=='sets'

Set tmiufix(t) "Time periods of fixed mitigation levels" /1,2,3,4/;


## INCLUDE DATA
#_________________________________________________________________________
* In the phase INCLUDE_DATA you should declare and include all exogenous parameters. 
* You can also modify the data loaded in data.gms
* Best practice : - create a .gdx containing those and to loading it 
*                 - this is the only phase where we should have numbers...
$elseif.ph %phase%=='include_data'

parameter cprice_hotel(t,n,ghg);
cprice_hotel(t,n,ghg)=0;

##  COMPUTE VARIABLES
#_________________________________________________________________________
* In the phase COMPUTE_VARS, you fix starting points and bounds.
* DO NOT put VAR.l here! (use the declare_vars phase) 
$elseif.ph %phase%=='compute_vars'

$if %policy%=="bau" MIU.lo(t,n,ghg)$(not tmiufix(t))=0; MIU.up(t,n,ghg)$(not tmiufix(t))=1; #undo MIU fix to allow for NDCs continuation
MIU%ndcs_bound%(t,n,ghg)$tmiufix(t) = miu_fixed(t,n,ghg); # Fixing mitigation variable in 2015-2030 period; .lo if NDCs are meant as a minumum mitigation effort
MAC.lo(t,n,ghg)$tmiufix(t) = sum(coef$coefact(coef,ghg), macc_coef(t,n,ghg,coef)*power(MIU.lo(t,n,ghg),(coefn(coef)))); #needed for recomputation of ctax_corrected

##  BEFORE SOLVE
#_________________________________________________________________________
* In the phase BEFORE_SOLVE, you can update parameters (fixed
* variables, ...) inside the nash loop and right before solving the
* model. This is typically done for externalities, spillovers, ...
$elseif.ph %phase%=='before_solve'

$ifthen.ndc %ndcs_extr%=="const"

MAC.lo(t,n,ghg)$(year(t) gt 2030) =  min(MAC.lo('4',n,ghg), cprice_max(t,n,ghg) );

$elseif.ndc %ndcs_extr%=="linear"

MAC.lo(t,n,ghg)$(year(t) gt 2030 and MAC.l('4',n,ghg) ne 0) =  min(MAC.lo('4',n,ghg) * (1 + (MAC.lo('4',n,ghg) - MAC.lo('2',n,ghg))/(MAC.lo('4',n,ghg)*tstep*2) * (year(t) - 2030) ) , cprice_max(t,n,ghg) );

$elseif.ndc %ndcs_extr%=="hotelling"


cprice_hotel('4',n,ghg) = MAC.lo('4',n,ghg);
loop( (t,tt)$pre(tt,t), cprice_hotel(t,n,ghg)$(year(t) gt 2030)=cprice_hotel(tt,n,ghg) * (1 + prstp + elasmu * (ykali(t,n)-ykali(tt,n))/(tstep*ykali(tt,n)) ) ** tstep );
MAC.lo(t,n,ghg)$(year(t) gt 2030) = min(cprice_hotel(t,n,ghg), cprice_max(t,n,ghg));

$endif.ndc

* Recompute ctax corrected to avoid inconsistencies with NDCs
ctax_corrected(t,n,ghg) = min(MAC.lo(t,n,ghg), cprice_max(t,n,ghg) );
$if set tax_oghg_as_co2 ctax_corrected(t,n,ghg)$(not sameas(ghg,'co2')) = min( MAC.lo(t,n,'co2') * emi_gwp(ghg),  cprice_max(t,n,ghg) );

##  GDX ITEMS
#_________________________________________________________________________
* List the items to be kept in the final gdx
$elseif.ph %phase%=='gdx_items'

miu_fixed
miu_ndcs_2030

$endif.ph
