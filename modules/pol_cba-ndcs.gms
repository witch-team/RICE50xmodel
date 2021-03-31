# POLICY: NDCS Cost-Benefit Analysis
* --------------------------------------
* Fix mitigation up to 2030 NDCs levels.
* Then search for the best policy for the given setting, taking into account
* climate impacts, mitigation costs and cooperation in effort as standard CBA.
*


#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================


##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

* NDCs type: | cond | uncond |
$setglobal ndcs_type "cond"

* Optimization run_mode
$setglobal run_mode  'optimization'
$ifi not %run_mode%=='optimization' $abort 'USER ERROR: [run_mode] must be -optimization- for CBA-NDCS policy!'


## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

SET tmiufix(t) "Time periods of fixed mitigation levels" /1,2,3,4/;


## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

PARAMETER miu_ndcs_2030(n) "Mitigation levels in 2030 according to countries NDCs";
$gdxin  '%datapath%data_ndcs.gdx'
$load    miu_ndcs_2030 = pbl_%ndcs_type%_2030
$gdxin

PARAMETER miu_fixed_levels(t,n) "Mitigation levels fixed to meet 2030 %ndcs_type% NDCs";
# extreme levels
miu_fixed_levels('1',n) = miu0;
miu_fixed_levels('4',n) = miu_ndcs_2030(n);
# intermediate values
miu_fixed_levels('2',n) = miu_fixed_levels('1',n) + ((1/3) * (miu_fixed_levels('4',n) - miu_fixed_levels('1',n))) ;
miu_fixed_levels('3',n) = miu_fixed_levels('1',n) + ((2/3) * (miu_fixed_levels('4',n) - miu_fixed_levels('1',n))) ;


##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

# Fixing mitigation variable in 2015-2030 period
MIU.fx(t,n)$tmiufix(t) = miu_fixed_levels(t,n); 



#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================


##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

miu_fixed_levels
miu_ndcs_2030



$endif.ph
