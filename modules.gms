$set phase %1

* Algorithm:
* Every module is launched.
* Each of them has a phase-logic (based on phase logic variable) which activates only
* specific actions (those allowed by the general flow).


$batinclude 'modules/core_time'              %2 # Core block to align correctly time epriods (incl t sets)
$batinclude 'modules/core_regions'           %2 # Regions settings and exogenous data imports

$batinclude 'modules/core_economy'           %2 # Core block for economy 
$batinclude 'modules/core_emissions'         %2 # Core block for emissions
$batinclude 'modules/core_utility'           %2 # Core block for utility definitions

$batinclude 'modules/cooperation_%cooperation%'    %2 # Cooperation setup
$batinclude 'modules/core_algorithm'         %2 # Solve settings

$batinclude 'modules/hub_macc'               %2 # MAC curves, abatement cost
$batinclude 'modules/mod_land_use'           %2 # Land-use HUB
$batinclude 'modules/hub_climate'            %2 # Climate  HUB
$batinclude 'modules/mod_climate_regional'   %2 # Regional climate module
$batinclude 'modules/hub_impact'             %2 # Climate Impact  HUB
$batinclude 'modules/mod_ctax'               %2 # CTAX according to different policies


## POLICY 
* Main and simplest policy options
$batinclude 'modules/core_policy'            %2 #| bau | bau-impacts | cba | sim | cea-cbudget | cea-tatm |
* Specific and structured policies 
$ifi %policy%=='cba-delay'       $batinclude 'modules/pol_cba-delay'       %2 # CBA delayed to future year
$ifi %policy%=='cba-ndcs'        $batinclude 'modules/pol_cba-ndcs'        %2 # CBA delayed to future year
$ifi %policy%=='ctax-advance'    $batinclude 'modules/pol_ctax-advance'    %2 # ADVANCE ctax diagnostics
$ifi %policy%=='sim-exogen-temp' $batinclude 'modules/pol_sim-exogen-temp' %2 # CBA delayed to future year
* Coalitions scenarios
$ifi %policy%=='clt-scenario'      $batinclude 'modules/pol_clt-scenario'    %2 # COALITIONS scenarios