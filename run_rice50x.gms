*          _           __________
*    _____(_)_______  / ____/ __ \  __
*   / ___/ / ___/ _ \/___ \/ / / /_/ /_
*  / /  / / /__/  __/___/ / /_/ /_ x__/
* /_/  /_/\___/\___/_____/\____/ /_/
*
$title  RICE50+
$ontext
This is an extension of the RICE/DICE models, with up to 57 regions (reflecting
EnerData regional data).
The model includes SSP-based scenarios, alternative and interchangeable damage
functions, cooperation options, climate modules, region weighting.
Both optimization and simulation option is available.
$offtext
$eolcom #
* timestamp for execution-time
scalar starttime; starttime = jnow;

#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

$onmulti
$setenv gdxcompress 1
$onrecurse


## DEBUG OPTIONS
* When activated, in debug mode only one region is solved
#$setglobal DEBUG
* Select region to activate in debug
$if set debug $setglobal debug_region 'nde'


# === RUN MAIN OPTIONS ========

## RESULT FINAL FILENAME
$setglobal nameout "default"
$setglobal output_filename results_%nameout%
* Results path
$setglobal output_dir  './results'
* Set an experiment_id to gather results inside a common directory
$setglobal experiment_id ''


## POLICY
* Select policy scenario 
*| bau | bau-impacts | cba | sim | cba-ndcs | cea-cbudget | cea-tatm |
$setglobal policy 'bau'

## BASELINE SCENARIO
*| ssp1 | ssp2 | ssp3 | ssp4 | ssp5 |
$setglobal baseline 'ssp2'

## REGION DETAIL
*| ed57 | 
$setglobal n 'ed57'

## IMPACT TYPE
* (Note: runs bau/ctax evaluate impacts but do not include them in ynet count)
*| off | dice | burke | dell | kahn |
$setglobal impact 'burke'
* burke alternatives: | sr (base) | lr | srdiff | lrdiff
* (always set it, even if impact is not burke type)
$setglobal bhm_spec 'sr'

## COOPERATION
* choose solution: 'coop' for cooperative, 'noncoop' for Nash
* | coop | noncoop | 
$setglobal cooperation 'noncoop'
# debug option will activate noncoop by default

## REGION WEIGHTS
* For the coop case, activate one of the following weighting schemes:
* | negishi | pop |
$setglobal weighting 'pop'

## CLIMATE MODULE
* | dice2016 | cbsimple | witchco2 | 
$setglobal climate 'witchco2'

## SAVINGS RATE MODE
* | fixed | free |
$setglobal savings 'fixed'

## RUN MODE
*| simulation | optimization  |
$setglobal run_mode  'optimization'


# === DATA PATHS DEFINITION =======

* input datapath
$setglobal datapath  'data_%n%/'
* results path  (output_dir and -optional- experiment_id)
$setglobal resultpath '%output_dir%/%experiment_id%'
* temp path  (useful for debug)
$setglobal temppath 'results/_temp'
* startboost path  (nested in datapath to avoid different regional-aggregation conflicts)
$setglobal startboostpath '%datapath%startboost'

* Create output folders if missing
$if  NOT exist "%resultpath%"      $call mkdir "%resultpath%"
$if  NOT exist "%temppath%"        $call mkdir "%temppath%"
$if  NOT exist "%startboostpath%"  $call mkdir "%startboostpath%"



#=========================================================================
*   ///////////////////////     SETUP    ///////////////////////
#=========================================================================

* Model configuration across all modules
$batinclude "modules" "conf"
* Startboost option confguration
$if set startboost $batinclude "startboost" 'conf'
* Model definition through phases
$batinclude "modules" "sets"
$batinclude "modules" "include_data"
$batinclude "modules" "compute_data"
$batinclude "modules" "declare_vars"
* Startboost import starting feasible solution 
$if set startboost $batinclude "startboost" 'import'
* Fix model bounds
$batinclude "modules" "compute_vars"



#=========================================================================
*   /////////////////////////     EXECUTION    ///////////////////////
#=========================================================================

$batinclude "algorithm"



#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

* Evaluate reporting measures
$batinclude "modules" "report";


* Time elapsed for execution
scalar elapsed; elapsed = (jnow - starttime)*24*3600; #timestamp


# RESULTS GDX
* Only elements listed in "gdx_items" phase
* will be saved, unless full_gdx option is active
$ifthen.gdxfull not set full_gdx
execute_unload "%resultpath%/%output_filename%.gdx"
elapsed
converged
solrep
$batinclude "modules" "gdx_items";
$else.gdxfull
execute_unload "%resultpath%/%output_filename%.gdx";
$endif.gdxfull

* Startboost export this result (if explicitlye asked) as a new loadpoint
$if set startboost $batinclude startboost "export"


