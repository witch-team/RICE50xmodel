$set startboostphase %1


##  STARTBOOST CONFIG
#_________________________________________________________________________
$ifthen.ph %startboostphase%=='conf'


# === SET NAMNG CONVENTION ======

* An internal convention to save/load best/matching startboost file.
* Has to distinguish among main model settings

* Policy
$setglobal opt_policy "_%policy%"
* Socio-economc baseline 
$setglobal opt_baseline "_%baseline%"
* Cooperation (optional: relevant only in run_mode=optimization)
$setglobal opt_cooperation ""
$if.opt %run_mode%=='optimization' $setglobal opt_cooperation '_%solmode%-%weighting%'
* Savings rate
$setglobal opt_savings "_sav-%savings%"
* Climate module
$setglobal opt_climate "_clim-%climate%"
* Impacts module
$setglobal opt_impact "_%impact%"
$if.dam %impact%=='burke' $setglobal opt_impact "_burke-%bhm_spec%"
$if.dam %impact%=='off'   $setglobal opt_impact "_no-impact"


# === AUTO-SEARCHING FOR BEST STARTBOOST ======

#.....................................................................
* Auto-search for a closest available option:  regionality, baseline, policy
* Priority:   startboost_FORCED  >>  startboost  >>  startboost_backup
#......................................................................

* 1- full match
$ifthen.bestboost exist  '%startboostpath%/startboost%opt_policy%%opt_baseline%%opt_cooperation%%opt_savings%%opt_climate%%opt_impact%.gdx'
$setglobal startboost_best_gdx            'startboost%opt_policy%%opt_baseline%%opt_cooperation%%opt_savings%%opt_climate%%opt_impact%'
* 2- skip savings match
$elseif.bestboost exist  '%startboostpath%/startboost%opt_policy%%opt_baseline%%opt_cooperation%_sav-fixed%opt_climate%%opt_impact%.gdx'
$setglobal startboost_best_gdx            'startboost%opt_policy%%opt_baseline%%opt_cooperation%_sav-fixed%opt_climate%%opt_impact%'
* 3- skip also climate match
$elseif.bestboost exist  '%startboostpath%/startboost%opt_policy%%opt_baseline%%opt_cooperation%_sav-fixed_clim-witchco2%opt_impact%.gdx'
$setglobal startboost_best_gdx            'startboost%opt_policy%%opt_baseline%%opt_cooperation%_sav-fixed_clim-witchco2%opt_impact%'
* 4- skip also impacts match
$elseif.bestboost exist  '%startboostpath%/startboost%opt_policy%%opt_baseline%%opt_cooperation%_sav-fixed_clim-witchco2_burke-sr.gdx'
$setglobal startboost_best_gdx           '/startboost%opt_policy%%opt_baseline%%opt_cooperation%_sav-fixed_clim-witchco2_burke-sr'
* 5- skip also baseline match
$elseif.bestboost exist  '%startboostpath%/startboost%opt_policy%_ssp2%opt_cooperation%_sav-fixed_clim-witchco2_burke-sr.gdx'
$setglobal startboost_best_gdx            'startboost%opt_policy%_ssp2%opt_cooperation%_sav-fixed_clim-witchco2_burke-sr'
* 6- skip also cooperation match
$elseif.bestboost exist  '%startboostpath%/startboost%opt_policy%_ssp2_noncoop-pop_sav-fixed_clim-witchco2_burke-sr.gdx'
$setglobal startboost_best_gdx            'startboost%opt_policy%_ssp2_noncoop-pop_sav-fixed_clim-witchco2_burke-sr'
* 7- skip also policy match
$elseif.bestboost exist  '%startboostpath%/startboost_cba_ssp2_noncoop-pop_sav-fixed_clim-witchco2_burke-sr.gdx'
$setglobal startboost_best_gdx            'startboost_cba_ssp2_noncoop-pop_sav-fixed_clim-witchco2_burke-sr'
* 8- only bau-no-impacts default match
$else.bestboost
$setglobal startboost_best_gdx            'startboost_bau-noimp_ssp2_noncoop-pop_sav-fixed_clim-witchco2_off'
$endif.bestboost

#.....................................................
# NOTE: until now this was a speculative selection
# There's no guarantee that at least one existing 
# best-startboost is effectively available.
# That's why we also add a backup...
#...................................................... 

# BACKUP: bau-no-impacts default scenario for ssp2 
$setglobal startboost_start_gdx 'results_ssp2_bau_start'


# === FINAL STARTBOOST OPTIONS DEFINITION ======

* best startboost
$setglobal startboost_best_source                              '%datapath%startboost/%startboost_best_gdx%.gdx'
* start startboost (backup-file always avail. in repository)
$setglobal startboost_start_source                            'input/%startboost_start_gdx%.gdx'
* manual starboost (defined by user)
$if set startboost_manual $setglobal startboost_manual_source  '%datapath%/startboost/%startboost_manual%.gdx'


## STARTBOOST IMPORT
#_________________________________________________________________________
$elseif.ph %startboostphase%=='import'

* Conditions to perform a startboost:
*  - optimization mode
*  - no explicit "startboost_off"
$ifThen.boost    %run_mode% == 'optimization'
$ifThen.allowed not set startboost_off

#.................................................................
# GDX-loading priority:
# startboost manual  >>  startboost best >>  startboost start
#.................................................................

* 1st choice: if activated, choose the manual source
$ifthen.manualboost set startboost_manual
execute_loadpoint    '%startboost_manual_source%' ;
$else.manualboost
* 2nd choice: if present, choose the startboost-best (most compatible choice)
$ifthen.best exist   '%startboost_best_source%'
execute_loadpoint    '%startboost_best_source%'   ;
$else.best
* 3rd choice: last attempt is to load startboost-start option
$ifthen.backup exist '%startboost_start_source%'
execute_loadpoint    '%startboost_start_source%'  ;
$endif.backup
$endif.best
$endif.manualboost

#........................................................
# NOTE:
# If everything fails, no execute_loadpoint will be executed.
# Solver may take much more time to converge and eventually 
# get stucked to locally infeas/optimal solution with no general
# optimal guarantee.
#.......................................................
$endIf.allowed
$endif.boost


#  STARTBOOST EXPORT
#_________________________________________________________________________
$elseif.ph %startboostphase%=='export'

$ifthen.boost set startboost_export 
#................................................
# If explicitly asked for a startboost_export,
# current result is saved in startboost folder 
# with correct naming.
#................................................

* Set name following auto-naming rules
$setlocal output_startboostname 'startboost%opt_policy%%opt_baseline%%opt_cooperation%%opt_savings%%opt_climate%%opt_impact%'
* Save everything
execute_unload '%startboostpath%/%output_startboostname%.gdx' ;

$endif.boost


$endif.ph
