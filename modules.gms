$set phase %1

$batinclude 'modules/core_time'                                                %2 # Core block to align correctly time epriods
$if set stochastic $batinclude 'modules/mod_stochastic'                        %2 # stochastic programming mode

$batinclude 'modules/core_regions'                                             %2 # Regions settings and exogenous data imports

$batinclude 'modules/core_economy'                                             %2 # Core block for economy
$batinclude 'modules/core_emissions'                                           %2 # Core block for emissions
$batinclude 'modules/core_welfare'                                             %2 # Core block for welfare
$batinclude 'modules/core_abatement'

$batinclude 'modules/core_cooperation'                                         %2 # Cooperation setup
$batinclude 'modules/core_algorithm'                                           %2 # Solve settings

$batinclude 'modules/mod_landuse'                                                            %2 # Land-use HUB
$batinclude 'modules/hub_climate'                                                            %2 # Climate  HUB
$batinclude 'modules/mod_climate_regional'                                                   %2 # Regional climate module
$if not set mod_impact_deciles $if not set mod_impact_sai $batinclude 'modules/hub_impact'   %2 # Climate Impact  HUB
$if set mod_impact_deciles $batinclude 'modules/mod_impact_deciles'                          %2 # Climate Impacts, decile level
$if set mod_impact_sai $batinclude 'modules/mod_impact_sai'                                  %2 # Climate Impact, stratospheric aerosol injection

# POLICY
$batinclude 'modules/core_policy'                                              %2 # All policy options
$if set pol_ndc $batinclude 'modules/pol_ndc'                                  %2 # NDC policy module

# Optional Modules
$if set mod_adaptation $batinclude 'modules/mod_adaptation'                    %2 # Adaptation Module           
$if set mod_labour $batinclude 'modules/mod_labour'                            %2 # Labour Module
$if set mod_inequality $batinclude 'modules/mod_inequality'                    %2 # Inequality Module
$if set mod_sai $batinclude 'modules/mod_sai'                                  %2 # statospheric aerosol injection module
$if set mod_slr $batinclude 'modules/mod_slr'                                  %2 # Sea level rise Module
$if set mod_natural_capital $batinclude 'modules/mod_natural_capital'          %2 # Nature Capital Green Module
$if set mod_emission_pulse $batinclude 'modules/mod_emission_pulse'            %2 # Emission Pulse for SCC computation
$if set mod_dac $batinclude 'modules/mod_emi_stor'                             %2 # Emission storage module
$if set mod_dac $batinclude 'modules/mod_dac'                                  %2 # Negative emissions module
$if set mod_ocean $batinclude 'modules/mod_ocean'                              %2 # Nature Capital Blue Module

