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
$setglobal ndcs_extr "linear"

$setglobal nameout "%baseline%_ndc%ndcs_type%_%cooperation%_extr%ndcs_extr%"
$setglobal output_filename results_%nameout%

*MIU is fixed up to 2030, by default other policies start in 2035
$setglobal ctax_start 2035

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

parameter cprice_hotel(t,n);
cprice_hotel(t,n)=0;

##  COMPUTE VARIABLES
#_________________________________________________________________________
* In the phase COMPUTE_VARS, you fix starting points and bounds.
* DO NOT put VAR.l here! (use the declare_vars phase) 
$elseif.ph %phase%=='compute_vars'

$if %policy%=="bau" MIU.lo(t,n)$(not tmiufix(t))=0; MIU.up(t,n)$(not tmiufix(t))=max_miu; #undo MIU fix to allow for NDCs continuation
MIU.fx(t,n)$tmiufix(t) = miu_fixed_levels(t,n); # Fixing mitigation variable in 2015-2030 period; .lo if NDCs are meant as a minumum mitigation effort
CPRICE.lo(t,n)$tmiufix(t) = mx(t,n)* ((ax_co2('%maccfit%','Total_CO2',t,n)*MIU.lo(t,n)) + (bx_co2('%maccfit%','Total_CO2',t,n)*power(MIU.lo(t,n),4))); #needed for recomputation of ctax_corrected

##  BEFORE SOLVE
#_________________________________________________________________________
* In the phase BEFORE_SOLVE, you can update parameters (fixed
* variables, ...) inside the nash loop and right before solving the
* model. This is typically done for externalities, spillovers, ...
$elseif.ph %phase%=='before_solve'

$ifthen.ndc %ndcs_extr%=="const"

CPRICE.lo(t,n)$(year(t) gt 2030) =  min(CPRICE.l('4',n), mx(t,n)* ((ax_co2('%maccfit%','Total_CO2',t,n)*MIU.up(t,n)) + (bx_co2('%maccfit%','Total_CO2',t,n)*power(MIU.up(t,n),4))) );

$elseif.ndc %ndcs_extr%=="linear"

CPRICE.lo(t,n)$(year(t) gt 2030 and CPRICE.l('2',n) ne 0) =  min(CPRICE.l('4',n) * (1 + (CPRICE.l('4',n) - CPRICE.l('2',n))/(CPRICE.l('4',n)*tstep*2) * (year(t) - 2030) ) , mx(t,n)* ((ax_co2('%maccfit%','Total_CO2',t,n)*MIU.up(t,n)) + (bx_co2('%maccfit%','Total_CO2',t,n)*power(MIU.up(t,n),4))) );

$elseif.ndc %ndcs_extr%=="hotelling"

cprice_hotel('4',n) = CPRICE.l('4',n);
loop( (t,tt)$pre(tt,t),
cprice_hotel(t,n)$(year(t) gt 2030)=cprice_hotel(tt,n) * (1 + prstp + elasmu * (ykali(t,n)-ykali(tt,n))/(tstep*ykali(tt,n)) ) ** tstep );
CPRICE.lo(t,n)$(year(t) gt 2030) = min(cprice_hotel(t,n), mx(t,n)* ((ax_co2('%maccfit%','Total_CO2',t,n)*MIU.up(t,n)) + (bx_co2('%maccfit%','Total_CO2',t,n)*power(MIU.up(t,n),4))) );

$endif.ndc

* Recompute ctax corrected to avoid inconsistencies with NDCs
ctax_corrected(t,n) = max(CPRICE.lo(t,n), min(ctax(t,n)*1e3, 
                            mx(t,n)* ((ax_co2('%maccfit%','Total_CO2',t,n)*MIU.up(t,n)) + (bx_co2('%maccfit%','Total_CO2',t,n)*power(MIU.up(t,n),4))) ) );


##  GDX ITEMS
#_________________________________________________________________________
* List the items to be kept in the final gdx
$elseif.ph %phase%=='gdx_items'

miu_fixed_levels
miu_ndcs_2030

$endif.ph
