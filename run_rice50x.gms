$title  RICE50+
$onmulti
$setenv gdxcompress 1
$onrecurse
$eolcom #
$ontext
          _           __________
    _____(_)_______  / ____/ __ \  __
   / ___/ / ___/ _ \/___ \/ / / /_/ /_
  / /  / / /__/  __/___/ / /_/ /_ x__/
 /_/  /_/\___/\___/_____/\____/ /_/

This is an extension of the DICE-2016 model, with 57 regions.
The model includes SSP-based scenarios, alternative and interchangeable damage
functions, cooperation options, climate modules, etc.
$offtext
scalar starttime; starttime = jnow;

*=========================================================================
*   ///////////////////////       SETTINGS      ///////////////////////
*=========================================================================
* REGION DEFINITION
*| ed57 | witch17 | r5 | global |
$setglobal n 'ed57'

* BASELINE SCENARIO
*| ssp1 | ssp2 | ssp3 | ssp4 | ssp5 |
$setglobal baseline 'ssp2'

* POLICY
* | bau | bau_impact | cba | cbudget | cbudget_regional | ctax | simulation | simulation_tatm_exogen | simulation_climate_regional_exogen |
$setglobal policy 'bau'

* COOPERATION
* | coop | noncoop | coalitions
$setglobal cooperation 'noncoop'

* IMPACT SPECIFICATION
* | off | dice | burke | dell | kalkuhl | howard | climcost | coacch |
$setglobal impact 'kalkuhl'

* CLIMATE MODULE
* | dice2016 | cbsimple | witchco2 | witchoghg |
$setglobal climate 'witchco2'

* SAVINGS RATE
* | fixed | flexible |
$setglobal savings 'fixed'

* DEFAULT RESULTS FILENAME if nameout is not set
$setglobal nameout "%baseline%_%policy%"


*=========================================================================
**  DATA PATH DEFINITION
$setglobal datapath  data_%n%/
** Results path
$ifthen not set workdir
$setglobal resdir "%gams.curdir%"
$else
$setglobal resdir "%workdir%\"
$if %system.filesys% == UNIX $setglobal resdir "%workdir%/"
$endif
** DEBUG OPTIONS
*$setglobal onlysolve usa
*$setglobal all_data_temp #to create an all_data_temp_%nameout%.gdx file after each iteration

*=========================================================================
*   ///////////////////////     SETUP    ///////////////////////
*=========================================================================

* Model configuration across all modules
$batinclude "modules" "conf"

** Results filename
$setglobal output_filename results_%nameout%

* Model definition through phases
$batinclude "modules" "sets"
$batinclude "modules" "include_data"
$batinclude "modules" "compute_data"
$batinclude "modules" "declare_vars"

* Fixing model bounds
$batinclude "modules" "compute_vars"



*=========================================================================
*   /////////////////////////     EXECUTION    ///////////////////////
*=========================================================================

$batinclude "algorithm"

*===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
*===============================================================================

* Evaluate reporting measures
$batinclude "modules" "report";

* Time elapsed for execution
scalar elapsed; elapsed = (jnow - starttime)*24*3600;
#Just for quick analysis display a few values
Parameters tatm2100, world_damfrac2100, gdp2100;
tatm2100=TATM.l('18');
world_damfrac2100=world_damfrac('18');
gdp2100=sum(n,YNET.l('18',n));
display tatm2100,gdp2100,world_damfrac2100,elapsed;

* PRODUCE RESULTS GDX
execute_unload "%resdir%/%output_filename%.gdx"
$batinclude "modules" "gdx_items"
;