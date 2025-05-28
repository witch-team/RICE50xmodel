* CLIMATE MODULE
*
* This module gathers all main climate parameters, variables and sets.
* Those will be mapped with specific climate submodules varibles.

#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
* Definition of the global flags and settings specific to the module 
$ifthen.ph %phase%=='conf'


## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

set box "boxes for co2 concentration module"
                                /     "geological processes",
                                      "deep ocean",
                                      "biosphere",
                                      "ocean mixed layer" /;

set cghg(ghg) "Core greenhouse gases";
set oghg(ghg) "Other well-mixed greenhouse gases";
cghg("co2") = yes;
cghg("ch4") = yes;
cghg("n2o") = yes;
oghg(ghg)$(not cghg(ghg)) = yes;

set climagents "Climate agents that interact with ghgs" / "h2o", "o3trop" /;

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'


scalar delta "Delta for smooth approximation" /1e-3/; 

SCALARS
        tsloweq    "Thermal equilibration parameter for box 1 (m^2 per KW)"         /0.324/
        tfasteq    "Thermal equilibration parameter for box 2 (m^2 per KW)"        /0.44/
        dslow      "Thermal response timescale for deep ocean (year)"               /236/
        dfast      "Thermal response timescale for upper ocean (year)"              /4.07/
 
        irf_preindustrial     "Pre-industrial IRF100 (%)"                         /35/
        irf_max               "Maximum IRF100 (%)"                                /97/
        irC      "Increase in IRF100 with cumulative carbon uptake (years per GtC)"  /0.019/
        irT      "Increase in IRF100 with warming (years per degree K)"                /4.165/
        atmosphere_mass "Mass of atmosphere (kg)"                                     /5.1352e18/ 
        atmosphere_mm   "Molecular mass of atmosphere (kg mol-1)"                     /28.97/
        Tecs            "equilbrium climate sensitivity (K)" /3/
        Ttcr            "Transient climate response (K)" /1.8/
        forc2x          "Forcing for 2xCO2 (Wm-2)" /3.71/
        scaling_forc2x  "Scaling factor for CO2 forcing to ensure consistency with user-specified 2xforcing" /1.0/
        catm_preindustrial          "Equilibrium concentration atmosphere  (GtCO2)"  ;
 
PARAMETERS         emshare(box) "Carbon emissions share into Reservoir i"  
                   taubox(box)    "Decay time constant for reservoir *  (year)"
                   taughg(ghg)    "Decay time constant for ghg *  (year)"
                   forcing_coeff(ghg) "Concentration to forcing for other green-house gases [W/m2]";

PARAMETER ghg_mm(*) "Molecular mass of greenhouse gases (kg mol-1)";

# Conversion between ppb/ppt concentrations and Mt/kt emissions
# in the RCP databases ppb = Mt and ppt = kt so factor always 1e18
PARAMETER emitoconc(*) "Conversion factor from emissions to concentration for greenhouse gas i (Gt to ppm/ Mt to ppb)";

PARAMETERS 
res0(box)  "Initial concentration in Reservoir i in 2025 (GtCO2)",
cumemi0 "Initial CO2 cumulative emissions in 2015 (GtCO2)",
tslow0 "Initial temperature box 1 change in 2015(K from 1765)",
tfast0 "Initial temperature box 2 change in 2015 (K from 1765)",
conc0(ghg) "Initial concentration of greenhouse gas i in 2015 (ppm/ppb)",
emshare0(box) "Initial share of carbon in sinks",
tslowshare0  "Initial ratio of low to fast temperature contributions",
conc_preindustrial(ghg) "Pre-industrial concentration of greenhouse gas i (ppm/ppb)";

##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

# decay time constants for the four reservoirs
taubox("geological processes") = 1000000;
taubox("deep ocean") = 394.4;
taubox("biosphere") = 36.53;
taubox("ocean mixed layer") = 4.304;

# half-lives of methane and n2os
taughg("ch4") = 9.3; 
taughg("n2o") = 121;

# initial share of cumulative co2 in reservoirs
emshare("geological processes") = 0.2173;
emshare("deep ocean") = 0.224;
emshare("biosphere") = 0.2824;
emshare("ocean mixed layer") = 0.2763;

# molar masses for greenhouse gases
ghg_mm('co2') = 44.01;
ghg_mm('ch4') = 16.04;
ghg_mm('n2o') = 44.013;
ghg_mm('c') = 12.01;
ghg_mm('n2') = 28.013;

# conversion factors for emissions to concentrations
emitoconc(ghg) = 1e18 / atmosphere_mass * atmosphere_mm / ghg_mm(ghg) ;
emitoconc('c') = 1e18 / atmosphere_mass * atmosphere_mm / ghg_mm('c');
emitoconc('n2o') = emitoconc('n2o') * ghg_mm('n2o') / ghg_mm('n2') ; #n2o is expressed in n2 equivalent

# preindustrial conditions
conc_preindustrial('co2') = 278.05;
conc_preindustrial('ch4') = 722.0;
conc_preindustrial('n2o') = 255.0;
catm_preindustrial = conc_preindustrial('co2') / emitoconc('co2');
scaling_forc2x = ( -2.4e-7 * sqr( conc_preindustrial('co2') ) +  7.2e-4 * conc_preindustrial('co2') -  1.05e-4 * ( 2*conc_preindustrial('n2o') ) + 5.36 ) * log( 2 ) / forc2x;

# initial share of cumulative co2 in reservoirs (from historical run of FAIR model with 5 year resolution)
emshare0("geological processes") = 0.551;
emshare0("deep ocean") = 0.238;
emshare0("biosphere") = 0.175;
emshare0("ocean mixed layer") = 0.036;
cumemi0 = 2070.6;
tslowshare0 = 0.153443/1.10308;

# initial conditions for year 2015 (from observations)
conc0('co2') = 400.724;
conc0('ch4') = 1822.1;
conc0('n2o') = 324.314;

* extrpolate coherent initial conditions for FAIR
res0(box) = emshare0(box)*(conc0("co2")-conc_preindustrial("co2"));
tslow0 = (tatm0+dt0)*tslowshare0;
tfast0 = (tatm0+dt0)*(1-tslowshare0);

forcing_coeff(cghg) = 0;

##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
*Note: Stock variables correspond to levels at the END of the period
        CONC(ghg,t)    "Concentration of greenhouse gas i (ppm/ppb from 1765)"
        ORF(climagents,t) "Radiative forcing from other climate agents that interact with ghgs [W/m2]"
        OXI_CH4(t)     "CO2 emissions from methane oxidation (GtC per year)"
        FF_CH4(t)      "Fraction of fossil methane emissions"
        RES(box,t)     "Carbon concentration in Reservoir i (GtC from 1765)"
        TATM(t)        "Increase temperature of atmosphere (degrees L from 1765)"     
        TSLOW(t)       "Increase temperature from slow response (degrees K from 1765)"
        TFAST(t)       "Increase temperature from fast response (degrees K from 1765)"
        CUMEMI(t)      "Total co2 emitted (GtC from 1765)"
        C_SINKS(t)     "Accumulated carbon in ocean and other sinks (GtC)"
        C_ATM(t)       "Accumulated carbon in atmoshpere (GtC)"
        IRF(t)         "IRF100 at time t"
        CD_SCALE(t)    "Carbon decay time scaling factor";     

VARIABLES QSLOW, QFAST;

* IMPORTANT PROGRAMMING NOTE. Earlier implementations has reservoirs as non-negative.
* However, these are not physical but mathematical solutions.
* So, they need to be unconstrained so that can have negative emissions.
POSITIVE VARIABLES   CONC, IRF, CD_SCALE, FF_CH4, CUMEMI;

** Initialize variables
ORF.l(climagents,t) = 0;
CD_SCALE.l(t) = 0.35;
FF_CH4.l(t) = fossilch4_frac(t,'%rcp%');

##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

**  Upper and lower bounds for stability
CONC.LO(cghg,t) = 1e-9;
CONC.LO(oghg,t) = 0;
TATM.LO(t)  = -10;
TATM.UP(t)  = 10;
CD_SCALE.lo(t) = 1e-2;
CD_SCALE.up(t) = 1e3;
IRF.up(t) = 100;
FF_CH4.up(t) = 1;

** initial conditions for year 2015
CONC.fx(ghg,tfirst)$(not sameas(ghg,'co2')) = conc0(ghg); #co2 is defined by constraining RES.fx(box,tfirst)
RES.fx(box,tfirst) = res0(box);
CUMEMI.fx(tfirst) = cumemi0;
TSLOW.fx(tfirst) = tslow0;
TFAST.fx(tfirst) = tfast0;

* find QSLOW and QFAST given TCR, ECS, and forc2x parameters 
* PRE MODEL 1
* find QSLOW and QFAST given climate specifications
EQUATIONS eq_tecs, eq_ttcr;
* calculate Qi imposing ECS and TCR (more efficient as a parameter)
eq_tecs..          Tecs =E= forc2x * (QSLOW + QFAST); 

eq_ttcr..          Ttcr =E= forc2x * (QSLOW * (1 - dslow/69.7 * (1 - exp(-69.7/dslow)) ) +
                            QFAST * (1 - dfast/69.7 * (1 - exp(-69.7/dfast)) ) ) ; 

model solveqs  / eq_tecs, eq_ttcr /;
solve solveqs using cns; 

QSLOW.fx = QSLOW.l; 
QFAST.fx = QFAST.l;
* end QSLOW and QFAST

#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

        eq_w_emi             #"global emissions"  
        eq_reslom           #"Reservoir i law of motion"
        eq_concco2          #"Atmospheric concentration equation"
        eq_catm             #"Atmospheric carbon equation"
        eq_cumemi           #"Total emitted carbon"
        eq_csinks           #"Accumulated carbon in sinks equation"
        eq_concghg          #"Concentration equation for other GHGs"
        eq_methoxi          #"Methane oxidation equation"
        eq_ffch4            #"Fraction of fossil methane emissions"
        eq_forcco2          #"CO2 forcing equation"
        eq_forcch4          #"CH4 forcing equation"
        eq_forcn20          #"N2O forcing equation"
        eq_forcoghg         #"Other GHG forcing equation"
        eq_forch2o          #"H2O forcing equation"
        eq_forco3trop       #"tropospheric O3 forcing equation"
        eq_forcing          #"Total forcing"
        eq_tatm             #"Temperature-climate equation for atmosphere"
        eq_tslow            #"Temperature box 1 law of motion"
        eq_tfast            #"Temperature box 2 law of motion"
        eq_irflhs           #"Left-hand side of IRF100 equation"
        eq_irfrhs           #"Right-hand side of IRF100 equation"


##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'


# WORLD EMISSIONS --------------------------------------
* World CO2 emissions (in GTon)
eq_w_emi(t,ghg)..   W_EMI(ghg,t)  =E=  ( (sum(n$reg(n), E(t,n,ghg)) + sum(n$(not reg(n)), E.l(t,n,ghg)) )  )
$if set mod_emission_pulse           + emission_pulse(ghg,t)                                     
                                     ; # Carbon
                             
** Four box model for CO2 emission-to-concentrations (FAIR formulation)
eq_reslom(box,tp1,t)$(pre(t,tp1))..        RES(box,tp1) =E= RES(box,t) * exp( - tstep / ( taubox(box) * CD_SCALE(t) ) ) +
                                              emshare(box) * ( W_EMI('co2',tp1) + OXI_CH4(tp1) ) * emitoconc('co2') * tstep;

eq_concco2(t)..                            CONC('co2',t) =E=  conc_preindustrial('co2') + sum(box, RES(box,t) );

eq_catm(t)..                               C_ATM(t)  =E=  CONC('co2',t) / emitoconc('co2');
        
eq_cumemi(tp1,t)$(pre(t,tp1))..            CUMEMI(tp1) =E=  CUMEMI(t) +  ( W_EMI('co2',tp1) + OXI_CH4(tp1) )*tstep;

eq_csinks(t)..                             C_SINKS(t) =E=  CUMEMI(t) - ( C_ATM(t) -  catm_preindustrial );
    
** Single box model for non-CO2 GHGs  
eq_concghg(ghg,tp1,t)$(not sameas(ghg,'co2') and pre(t,tp1))..      
                        CONC(ghg,tp1) =E= CONC(ghg,t) * exp(-tstep/taughg(ghg)) + 
                        ( (  W_EMI(ghg,tp1) +   W_EMI(ghg,t) ) / 2 + natural_emissions(tp1,ghg) ) * emitoconc(ghg)  * tstep;

** methanize oxidation to CO2
eq_methoxi(t)..         OXI_CH4(t) =E= 1e-3 * ghg_mm('co2') / ghg_mm('ch4') * 0.61 * FF_CH4(t) * (CONC('ch4',t) - conc_preindustrial('ch4')) * (1 - exp(-tstep/taughg('ch4')) ) ;

** endogenous fraction of fossil methane emissions
eq_ffch4(t)..           FF_CH4(t) =E= fossilch4_frac(t,'%rcp%') * (sum(n$reg(n), EIND(t,n,'co2')) + sum(n$(not reg(n)), EIND.l(t,n,'co2'))) /(sum(n,convq_ghg('co2') * sigma(t,n,'co2')*ykali(t,n) ) ) ;

** forcing for the three main greenhouse gases (CO2, CH4, N2O) 
eq_forcco2(t)..         RF('co2',t) =E=  ( -2.4e-7 * sqr( CONC('co2',t) - conc_preindustrial('co2') ) +
                                                7.2e-4 * ( sqrt( sqr( CONC('co2',t) - conc_preindustrial('co2') ) + sqr(delta) ) - delta ) -
                                                1.05e-4 * ( CONC('n2o',t) +  conc_preindustrial('n2o') ) + 5.36 ) *
                                                log( CONC('co2',t) / conc_preindustrial('co2') ) / scaling_forc2x;
 
eq_forcch4(t)..         RF('ch4',t) =E=  ( -6.5e-7 * (CONC('ch4',t) +  conc_preindustrial('ch4')) -
                                                4.1e-6 * (CONC('n2o',t) +  conc_preindustrial('n2o')) + 0.043 ) * 
                                                ( sqrt(CONC('ch4',t)) - sqrt(conc_preindustrial('ch4')) );

eq_forcn20(t)..         RF('n2o',t) =E=  ( -4.0e-6 * (CONC('co2',t) +  conc_preindustrial('co2')) +
                                                2.1e-6 * (CONC('n2o',t) +  conc_preindustrial('n2o')) -
                                                2.45e-6 * (CONC('ch4',t) +  conc_preindustrial('ch4')) + 0.117 ) * 
                                                ( sqrt(CONC('n2o',t)) - sqrt(conc_preindustrial('n2o')) );

eq_forch2o(t)..         ORF('h2o',t) =E= 0.12 * RF('ch4',t); 

eq_forco3trop(t)..      ORF('o3trop',t) =E= 1.74e-4 * (CONC('ch4',t) - conc_preindustrial('ch4')) +
                                            9.08e-4 * (Emissions(t,'%rcp%','n_ox')-2) +
                                            8.51e-5 * (Emissions(t,'%rcp%','co')-170) +
                                            2.25e-4 * (Emissions(t,'%rcp%','nmvoc')-5) +
                                            ( 0.032 * (exp(-1.35*(TATM(t) + dt0 ) ) - 1) - sqrt( sqr(0.032 * (exp(-1.35*(TATM(t) + dt0 )) - 1) ) + sqr(1e-8)) ) / 2   ;

** forcing for other well-mixed greenhouse gases (F-gases, SOx, BC, OC, NH3, CO, NMVOC, NOx)  
eq_forcoghg(oghg,t)..     RF(oghg,t) =E=  (CONC(oghg,t) - conc_preindustrial(oghg)) * forcing_coeff(oghg);

eq_forcing(t)..           FORC(t) =E= sum(ghg, RF(ghg,t) ) + sum(climagents,ORF(climagents,t)) + forcing_exogenous(t) 
$if set mod_sai $if "%sai_experiment%"=="g0" + geoeng_forcing * W_SAI(t)
;

** forcing to temperature 
eq_tslow(tp1,t)$(pre(t,tp1))..  TSLOW(tp1) =E=  TSLOW(t) * exp(-tstep/dslow) + QSLOW * FORC(t) * ( 1 - exp(-tstep/dslow) );

eq_tfast(tp1,t)$(pre(t,tp1))..  TFAST(tp1) =E=  TFAST(t) * exp(-tstep/dfast) + QFAST * FORC(t) * ( 1 - exp(-tstep/dfast) );

eq_tatm(t)..       TATM(t)  =E=  TSLOW(t) + TFAST(t) - dt0;

** calculate alphas imposing IRF 
eq_irflhs(t)..    IRF(t)    =E= CD_SCALE(t) * sum(box, emshare(box) * taubox(box) * ( 1 - exp(-100/(CD_SCALE(t)*taubox(box)) ) ) );

*** IRF max is 97. Smooth GAMS approximation: [f(x) + g(y) - sqrt(sqr(f(x)-g(y)) + sqr(delta))] /2
eq_irfrhs(t)..    IRF(t)    =E= ( ( irf_max + ( irf_preindustrial + irC * C_SINKS(t) * CO2toC + irT * (TATM(t) + dt0) ) ) - 
                                                    sqrt( sqr(irf_max - (irf_preindustrial + irC * C_SINKS(t) * CO2toC + irT * (TATM(t) + dt0) ) ) + sqr(1e-8) ) ) / 2;

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='after_solve'

W_EMI.fx(ghg,t) = W_EMI.l(ghg,t);
FF_CH4.fx(t) = FF_CH4.l(t);
$if set mod_sai $if "%sai_experiment%"=="g0" W_SAI.fx(t) = sum(n,N_SAI.l(t,n));

solve fair using cns; 

W_EMI.lo(ghg,t) = -inf;
W_EMI.up(ghg,t) = inf;
FF_CH4.lo(t) = 0;
FF_CH4.up(t) = 1;
$if set mod_sai $if "%sai_experiment%"=="g0" W_SAI.lo(t) = 0;
$if set mod_sai $if "%sai_experiment%"=="g0" W_SAI.up(t) = +inf;

viter(iter,'TATM',t,n)$nsolve(n) = TATM.l(t);  # Keep track of last temperature values

#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
$elseif.ph %phase%=='gdx_items'


# Variables --------------------------------------------
FORC
TATM
CONC
RF
IRF 
W_EMI
FF_CH4
ORF
QSLOW
QFAST

$endif.ph


