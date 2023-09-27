$set phase %1

$batinclude 'modules/core_time'                                         %2 # Core block to align correctly time epriods
$batinclude 'modules/core_regions'                                      %2 # Regions settings and exogenous data imports

$batinclude 'modules/core_economy'                                      %2 # Core block for economy
$batinclude 'modules/core_emissions'                                    %2 # Core block for emissions
$batinclude 'modules/core_welfare'                                      %2 # Core block for welfare

$batinclude 'modules/cooperation_%cooperation%'                          %2 # Cooperation setup
$batinclude 'modules/core_algorithm'                                    %2 # Solve settings

$batinclude 'modules/mod_macc'                                          %2 # MAC curves, abatement cost
$batinclude 'modules/mod_land_use'                                      %2 # Land-use HUB
$batinclude 'modules/hub_climate'                                       %2 # Climate  HUB
$batinclude 'modules/mod_climate_regional'                              %2 # Regional climate module
$batinclude 'modules/hub_impact'                                        %2 # Climate Impact  HUB


# POLICY
$batinclude 'modules/core_policy'                                       %2 # All policy options
$if set pol_ndc $batinclude 'modules/pol_ndc'                           %2 # NDC policy module

# Optional Modules
$if set mod_adaptation $batinclude 'modules/mod_adaptation'             %2 # Adaptation Module
$if set mod_government $batinclude 'modules/mod_government'             %2 # Government Module
$if set mod_labour $batinclude 'modules/mod_labour'                     %2 # Labour Module
$if set mod_inequality $batinclude 'modules/mod_inequality'             %2 # Inequality Module
$if set mod_srm $batinclude 'modules/mod_srm'                           %2 # Solar Radiation management Module
$if set mod_slr $batinclude 'modules/mod_slr'                           %2 # Sea level rise Module
$if set mod_natural_capital $batinclude 'modules/mod_natural_capital'   %2 # Nature Capital Green Module
$if set mod_emission_pulse $batinclude 'modules/mod_emission_pulse'     %2 # Emission Pulse for SCC computation
$if set mod_dac $batinclude 'modules/mod_emi_stor'                      %2 # Emission storage module
$if set mod_dac $batinclude 'modules/mod_dac'                           %2 # Negative emissions module
