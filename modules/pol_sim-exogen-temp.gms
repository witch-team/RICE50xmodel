* POLICY: SIMULATE Exogenous Temperatures Trajectories
* -----------------------------------------------------
* Simulate scenario providing an exogen local temperatures path.
* Mitigation policy may either be exogeous as well or BAU (default).
*
* Remember also to provide adequate infos in "policy_details" flag to
* unequivocally define run scenario.
#____________
*

#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

* Simulation run_mode
$setglobal run_mode  'simulation'
$if not %run_mode%=='simulation' $abort 'USER ERROR: [run_mode] must be -simulation- for SIM-EXOGEN-TEMP policy!'

* Activate exogen temperature option
$setglobal exogen_temp_region 1
$if not %exogen_temp_region%=='1' $abort 'USER ERROR: [exogen_temp_region] flag must be active for SIM-EXOGEN-TEMP policy!'

* Set MIU trajectory to be imported
* (optional: BAU no-mitigation as default)
$setglobal sim_miu_gdx ""

* Set Savings trajectory to be imported
* (optional: fixed trajectory as default)
$setglobal sim_savings_gdx ""



# ==== EXOGEN TREGION  =======

$ifthen.exg '%exogen_source%'=='treg'
* Set TEMP_REGION trajectories to be imported
$setglobal sim_temp_gdx "insert_path_and_filename"
$ifi not exist '%sim_temp_gdx%' $abort "File -%sim_temp_gdx%- not found!  Please set [sim_temp_gdx] flag with -path/filename.gdx- (needed for TEMP_REGION trajectories)!"


# ==== EXOGEN TATM =======

$elseif.exg '%exogen_source%'=='tatm'
* Set TATM trajectory to be imported
$setglobal sim_temp_gdx "insert_path_and_filename"
$ifi not exist '%sim_temp_gdx%' $abort "File -%sim_temp_gdx%- not found!  Please set [sim_temp_gdx] flag with -path/filename.gdx- (needed for TATM trajectory)!"


# ==== EXOGEN TREGIONS FROM RCP =======

$elseif.exg '%exogen_source%'=='treg_rcp'
* Set exogen RCP to import
$setglobal rcp '85'


# ==== EXOGEN TREGIONS LINEARIZED ======

$elseif.exg '%exogen_source%'=='treg_linear'
* Set world temperature increase over pre-industrial levels [°C]
$setglobal exogen_tatm_2100  2


# ==== DEFAULT: NO MATCH =======

$else.exg
$abort 'USER ERROR: [exogen_source] flag not recogized! Must be: | treg | tatm | treg_rcp | treg_linear |'



$endif.exg








## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

* Exogen temperatures trajectories.
PARAMETER
   temp_region_exogen(t,n) 'Exogeous local temperatures'
   tatm_exogen(t) 'Exogenous atmospheric temperature'
;

* Simulation trajectories for free variables
PARAMETERS
    sim_miu(t,n)
    sim_savings(t,n)
;
* Load external MIU trajectories  if flag refers to an existing file
$iftheni.miu exist '%sim_miu_gdx%'
$gdxin '%sim_miu_gdx%'
$load sim_miu=MIU.l
$gdxin
$endif.miu
* Load external S trajectories if flag refers to an existing file
$iftheni.sav exist '%sim_savings_gdx%'
$gdxin '%sim_savings_gdx%'
$load sim_savings=S.l
$gdxin
$endif.sav


# ==== EXOGEN TREGION  =======

$ifthen.exg '%exogen_source%'=='treg'
* Simulation TREGIONS trajectory
PARAMETERS sim_tregions(t,n) ;
* Load external TREGIONS trajectories
$gdxin '%sim_temp_gdx%'
$load sim_tregions=TEMP_REGION.l
$gdxin


# ==== EXOGEN TATM =======

$elseif.exg '%exogen_source%'=='tatm'
* Simulation TATM trajectory
PARAMETERS sim_tatm(t) ;
* Load external MIU trajectories
$gdxin '%sim_temp_gdx%'
$load sim_tatm=TATM.l
$gdxin


# ==== EXOGEN TREGION FROM RCP =======

$elseif.exg '%exogen_source%'=='treg_rcp'

* Load local temperatures from external gdx
PARAMETER temp_region_valid_cmip5(t,n,*);
$gdxin '%datapath%data_mod_climate_regional'
$load   temp_region_valid_cmip5
$gdxin




$endif.exg




##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

* If no external file is set for MIU trajectories set it to BAU
$iftheni.miu not exist '%sim_miu_gdx%'
sim_miu(t,n) = 0  ;
$endif.miu
* If no external file is set for Savings trajectories use standard fixed-savings ones
$iftheni.sav not exist '%sim_savings_gdx%'
sim_savings(t,n) = fixed_savings(t,n)  ;
$endif.sav


# ==== EXOGEN TREGION  =======

$ifthen.exg '%exogen_source%'=='treg'

  temp_region_exogen(t,n) = sim_tregions(t,n) ;


# ==== EXOGEN TATM =======

$elseif.exg '%exogen_source%'=='tatm'

  tatm_exogen(t) = sim_tatm(t)  ;


# ==== EXOGEN TREGION FROM RCP =======

$elseif.exg '%exogen_source%'=='treg_rcp'

  temp_region_exogen(t,n) = temp_region_valid_cmip5(t,n,'%rcp%');


# ==== EXOGEN TREGIONS LINEARIZED ======

$elseif.exg '%exogen_source%'=='treg_linear'

# 1. Evaluate starting and 2100 local temperatures applying
#    regional downscaling on given TATM [TATM0, TATM_EXG].
# 2. Linearize local temperatures between extremes.

* Extremes downscaling
  temp_region_exogen('1', n)  =  climate_region_coef('alpha_temp',n)
                              +  climate_region_coef('beta_temp', n) * TATM0 ;

  temp_region_exogen('18',n)  =  climate_region_coef('alpha_temp',n)
                              +  climate_region_coef('beta_temp', n) * %exogen_tatm_2100% ;

* Linearization
  loop(t,
    temp_region_exogen(t,n) = temp_region_exogen('1',n)
                            + (((t.val - 1)/17) * (temp_region_exogen('18',n) - temp_region_exogen('1', n))) ;
  );



$endif.exg



#=========================================================================
*   ///////////////////////     SIMULATION    ///////////////////////
#=========================================================================

##  SIMULATION SETUP
#_________________________________________________________________________
$elseif.ph %phase%=='set_simulation'

* Set mitigation trajectory
MIU.fx(t,n) = sim_miu(t,n)  ;
* Set savings trajectory
S.fx(t,n) = sim_savings(t,n)  ;




*=========================================================================
*   ///////////////////////     REPORTING     ///////////////////////
*=========================================================================


##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

$ifthen.exg '%exogen_source%'=='tatm'
  tatm_exogen
$else.exg
  temp_region_exogen
$endif.exg



$endif.ph
#//
