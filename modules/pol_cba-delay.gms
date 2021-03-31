# POLICY: Delayed Cost-Benefit Analysis
* ---------------------------------------
* Simulate up to [tdelay] providing MIU and Savings (optonal) trajetories.
* Then search for the best Benefit-Cost results
*

#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

* Starting t for CBA
$setglobal tdelay 4

* Optimization run_mode
$setglobal run_mode  'optimization'
$ifi not %run_mode%=='optimization' $abort 'USER ERROR: [run_mode] must be -optimization- for CBA policy!'
* Set MIU trajectory to be imported
$setglobal sim_miu_gdx "insert_path_and_filename"
$ifi not exist '%sim_miu_gdx%' $abort "File -%sim_miu_gdx%- not found!  Please set [sim_miu_gdx] flag with -path/filename.gdx- (needed for MIU trajectory)!"
* Set Savings trajectory to be imported (optional: fixed trajectory as default)
$setglobal sim_savings_gdx ""



## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

SET tvarsfix(t) "Time periods of fixed levels" /1*%tdelay%/  ;


## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

PARAMETERS 
    sim_miu(t,n) 
    sim_savings(t,n) 
;
* Load a MIU trajectory from a give GDX 
$gdxin '%sim_miu_gdx%'
$load sim_miu=MIU.l
$gdxin
* Load external S trajectories if flag refers to an existing file 
$iftheni.sav exist '%sim_savings_gdx%'
$gdxin '%sim_savings_gdx%'
$load sim_savings=S.l
$gdxin
$endif.sav



##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

* fixing mitigation 
loop(tvarsfix(t), MIU.fx(t,n) = sim_miu(t,n); );
* fixing savings
$iftheni.sav exist '%sim_savings_gdx%'
loop(tvarsfix(t), S.fx(t,n) = sim_savings(t,n); );
$endif.sav



$endif.ph
