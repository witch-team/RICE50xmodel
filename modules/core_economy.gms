* CORE ECONOMY MODULE
* -
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

## CONF
*-------------------------------------------------------------------
* Definition of the global flags and settings specific to the module
$ifthen.ph %phase%=='conf'

* Time Discount Rate (ro) of the Ramsey equation
* [0.001, 0.03] with default 0.015 in DICE2016
$setglobal prstp 0.015

* Elasticity of marginal utility of consumption in the Ramsey equation
* with default 1.45 in DICE2016
$setglobal elasmu 1.45

* Capital elasticity in the production function
$setglobal gama 0.300

* Do not adjust ssp values on today values
$setglobal original_ssp  

#MACRO: Load from the same parameter but with first ssp index. Name starts with ssp_
$macro load_from_ssp(par,idx,ssp,suxfile) \
parameter ssp_&par(*,&&idx); \
execute_loaddc '%datapath%data_&suxfile' ssp_&par; \
&par(&&idx) = ssp_&par('&ssp',&&idx);


##  CALIBRATED CONF ------------------------------------
# These settings shouldn't be changed

* Default options
$setglobal default_prstp   0.015
$setglobal default_elasmu  1.45
$setglobal default_gama    0.300
$setglobal default_savings "fixed"

* Run the model on PPP or MMM
*| PPP | MER |
$setglobal gdp_adjustment 'PPP'


## SETS
#_________________________________________________________________________
* In the phase SETS you should declare all your sets, or add to the existing
* sets the element that you need.
$elseif.ph %phase%=='sets'

SET
    ssp     'SSP baseline names'       / ssp1,ssp2,ssp3,ssp4,ssp5 /
    gdpadj  'GDP-adjustment type'      / PPP,MER /
;


## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'


PARAMETERS
* Preferences
    elasmu          'Elasticity of marginal utility of consumption'   /  %elasmu%  / # DICE16 1.45 (alpha)
    prstp           'Initial rate of social time preference per year' /  %prstp%   / # DICE16 .015 (ro-discount rate)

* Population and technology
    gama            'Capital elasticity in production function'       /  %gama%    /
    dk              'Depreciation rate on capital (per year)'         /  0.100     /

* Carbon price
    cprice0         'Initial base Carbon Price [2005 USD / tCO2]'     /  2.0       /  #DICE2013: 1.0  #DICE2016: 2.0
    gcprice         'Growth rate of base Carbon Price per year'       /  0.02      /

* Savings Rate
    dice_opt_savings  'Gross Savings Rate level as DICE convergence'   /  0.2751    /  # DICE2016 optim savings convergence!
;


PARAMETERS
* Savings rate
    optlr_savings      'Optimal long-run Savings Rate used for transversality'
    fixed_savings(t,n) 'Gross Savings Rate value if S variable is fixed [%GDP]'

* Carbon price
    scc(t,n)           'Social Cost of Carbon'
    cprice_base(t)     'Carbon Price in base case'
    photel(t,n)        'Carbon Price under no Damages (Hotelling rent condition)'

* Other rates
    rr(t)              'Average utility Social Discount rate'
    ga(t,n)            'Growth rate of Productivity from'
    gl(t,n)            'Growth rate of Labor'

* World values
    world_c(t)
    world_y(t)
    world_ygross(t)
    world_ynet(t)
    world_k(t)
    world_avg_s(t)
;


##  PARAMETERS LOADED ----------
parameter ykali(t,n) 'GDP for the dynamic calibration [T$]';
load_from_ssp(ykali,'t,n',%baseline%,baseline)

parameter l(t,n) 'Population [million people]';
parameter pop(t,n) 'Population [million people]';
load_from_ssp(l,'t,n',%baseline%,baseline)

parameter gdppc_kali(t,n) 'GDP per capita used for calibration [MER]';
gdppc_kali(t,n) = ykali(t,n) / l(t,n) * 1e6;
parameter basegrowthcap(t,n)          'GDPcap baseline growth factor';

* Adjust population and GDP data until present to historical values maintaining GDP per capita growth
$ifthen.vd not set original_ssp
$gdxin %datapath%data_validation
parameter ykali_valid(t,n), l_valid(t,n);
$loaddc ykali_valid=ykali_valid_wdi l_valid=l_valid_wdi
parameter i_valid(*,t,n);
$loaddc i_valid=i_valid_wdi
$gdxin
parameter lrate(t,n);
parameter gdppcrate(t,n);
loop((t,tp1)$(pre(t,tp1)),
  lrate(tp1,n) = l(tp1,n) / l(t,n);
  gdppcrate(tp1,n) =  gdppc_kali(tp1,n) / gdppc_kali(t,n);
);
l(t,n)$(year(t) le 2015) = l_valid(t,n);
gdppc_kali(t,n)$(year(t) le 2015) = ykali_valid(t,n) / l_valid(t,n) * 1e6;
loop((t,tp1)$(pre(t,tp1) and (year(tp1) gt 2015)),
  l(tp1,n) = l(t,n) * lrate(tp1,n);
  gdppc_kali(tp1,n) = gdppc_kali(t,n) * gdppcrate(tp1,n);
);
$endif.vd
# Recompute actual quantities used:
ykali(t,n) = gdppc_kali(t,n) * l(t,n) / 1e6;
pop(t,n) = l(t,n);

* Conversion factors between PPP and MER
$gdxin %datapath%data_baseline
parameter ppp2mer(t,n) 'ratio to convert PPP to MER';
$loaddc ppp2mer
$gdxin
parameter mer2ppp(t,n) 'ratio to convert MER to PPP';
mer2ppp(t,n) = 1 / ppp2mer(t,n);
#PPP adjustment in case
$if %gdp_adjustment%=="PPP" ykali(t,n) = ykali(t,n) * mer2ppp(t,n); gdppc_kali(t,n) = gdppc_kali(t,n) * mer2ppp(t,n);


## STARTING CAPITAL AND SAVINGS RATE
* Take from  calibrated file the capital zero as GDP weighted total capital.
PARAMETERS
    s0(*,t,n)      'Regions Savings Rate at starting time [%GDP]'
    k0(*,t,n)      'Initial Regions Capital at starting time [Trill 2005 USD]'
;

$gdxin '%datapath%data_validation.gdx'
$load k0=k_valid_article, s0=socecon_valid_weo_mean
$gdxin
$if %gdp_adjustment%=="PPP" k0('fg',t,n) = k0('fg',t,n)*mer2ppp(t,n);
s0('savings_rate', '1', n) = s0('savings_rate', '1', n) / 100; #in percent
#use: k0('fg', '1', n) and s0('savings_rate', '1', n)


##  PARAMETERS EVALUATED ----------

PARAMETER
* Starting values
   q0(n)              'Starting (2015) GDP for each region [Trill 2005 USD]'
   e0(n)              'Initial (2015) emissions per each Region [GtCO2-eq]'
* Total factor productivity
   tfp(t,n)           'Regions Total Factor Productivity'
   i_tfp(t,n)         'Baselines Investments to evaluate TFP'
   k_tfp(t,n)         'Baselines Capital to evaluate TFP'
;


##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

* Starting GDP
q0(n) = ykali('1',n) ;

 ##  BASELINE PER-CAPITA GROWTH ------------------------
* Baseline per-capita growth
basegrowthcap(t,n) = ((( (ykali(t+1,n)/pop(t+1,n)) / (ykali(t,n)/pop(t,n)) )**(1/tstep)) - 1 )$(t.val < card(t))  ; # last value set to 0

* Carbon price
 cprice_base(t)  = cprice0 * (1+gcprice)**(tstep*(t.val-1));

* Interest Rate
 rr(t)  =  1 / ( (1+prstp)**(tstep*(t.val-1)) );


##  SAVINGS RATE --------

* Optimal long-run Savings rate
optlr_savings = (dk + .004)/(dk + .004*elasmu + prstp)*gama;

* Evaluate converging Savings Rate
* Linear interpolation: S0 + (Send - S0)*(t - t0)/(tend - t0)
fixed_savings(t,n) = s0('savings_rate', '1', n) + (optlr_savings - s0('savings_rate', '1', n)) * (t.val - 1)/(card(t) - 1);


##  DYNAMIC CALIBRATION OF TFP FROM BASELINE AND SCENARIO ---------------------
* set capital first value
k_tfp('1',n)  =  k0('fg', '1', n);

* retrieve tfp from reverting Y-I-L process
loop(t,
   # Investments
   i_tfp(t,n)  =  fixed_savings(t,n)  * ykali(t,n)   ;
   # Capital
   k_tfp(t+1,n)  =  ((1-dk)**tstep) * k_tfp(t,n)  +  tstep * i_tfp(t,n)  ;
   # TFP of current scenario (explicited from Cobb-Douglas prod. function)
   tfp(t,n)  =  ykali(t,n) / ( ( (pop(t,n)/1000)**(1-gama) )*(k_tfp(t,n)**gama) )  ;
);


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
    C(t,n)            'Consumption (%gdp_adjustment%) [Trill 2005 USD / year]'
    CPC(t,n)          'Per capita consumption (%gdp_adjustment%) [thousands 2005 USD per year]'

    K(t,n)            'Capital stock (%gdp_adjustment%) [Trill 2005 USD / year]'
    I(t,n)            'Investments (%gdp_adjustment%) [Trill 2005 USD / year]'
    S(t,n)            'Gross Savings Rate as fraction of gross world product [%GDP]'
    RI(t,n)           'Real Interest Rate (per annum)'

    YGROSS(t,n)       'GDP GROSS (%gdp_adjustment%) [Trill 2005 USD / year]'
    YNET(t,n)         'GDP NET of climate impacts (%gdp_adjustment%) [Trill 2005 USD / year]'
    Y(t,n)            'GDP NET of Abatement Costs and Damages (%gdp_adjustment%) [Trill 2005 USD / year]'

    CTX(t,n)          'Carbon Tax effect on GDP (%gdp_adjustment%) [Trill 2005 USD]'
;
POSITIVE VARIABLES  Y, YNET, YGROSS, C, Cpc, K, I, S;


# VARIABLES STARTING LEVELS
* to help convergence
 YGROSS.l(t,n) = ykali(t,n)  ;
   YNET.l(t,n) = ykali(t,n)  ;
      Y.l(t,n) = ykali(t,n)  ;
      S.l(t,n) = fixed_savings(t,n)  ;
      I.l(t,n) = S.l(t,n) * ykali(t,n)  ;
      C.l(t,n) = ykali(t,n) - I.l(t,n)  ;
    CPC.l(t,n) = 1000 * C.l(t,n) / pop(t,n)  ;
      K.l(t,n) = k_tfp(t,n) ;


##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

##  STABILITY CONSTRAINTS --------
* to avoid errors/help the solver to converge
       C.lo(t,n) = 1e-8; # needed because of eq_periodu (!! higher than 1e-7 -> infes risk!)
     CPC.lo(t,n) = 1e-8; # needed because of eq_ri (!! higher than 1e-6 -> infes risk!)
  YGROSS.lo(t,n) = 1e-8; # needed because of eq_damfrac (higher than 1e-4 -> infes risk)
       K.lo(t,n) = 1e-8; # needed because of eq_komega (!! higher than 1e-7 -> infes risk)
       S.lo(t,n) = 0.1;
       S.up(t,n) = 0.9;
#.................................................
# NOTE
# Hardest experiments tested:
# < ssp1 noncoop LRdiff prstp=0.03>
# < ssp3 noncoop LRdiff *>
# < ssp5 noncoop LRdiff prstp=0.03>
#.................................................


# STARTING CAPITAL ----------
K.fx(tfirst,n) = k0('fg', '1', n);


# SAVINGS RATE ----------

$ifthen.sav  %savings%=='fixed'
* Savings are fixed to evaluated converging trends
  S.fx(t,n) = fixed_savings(t,n)  ;
$else.sav
* Savings are left free to be optimized
* They are fixed to optimal DICE value only for last 10 periods
* to avoid end-of-world-effects
  S.fx(last10(t),n) = optlr_savings  ;
* Fix starting point
  S.fx(tfirst,n) = s0('savings_rate', '1', n)  ;
$endif.sav



#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

    eq_ygross     # Output gross equation
    eq_yy         # Output net equation
    eq_ynet       # Output GDP net of damages equation

    eq_cc         # Consumption equation
    eq_cpc        # Per capita consumption definition

    eq_s          # Savings rate equation
    eq_ri         # Interest rate equation
    eq_kk         # Capital balance equation

##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

* GDP gross: Cobb-Douglas production function
 eq_ygross(t,n)$(reg(n))..   YGROSS(t,n)  =E=  tfp(t,n) * (K(t,n)**gama) * (pop(t,n)/1000)**(1-gama)   ;

* GDP net of Climate Damages
 eq_ynet(t,n)$(reg(n))..  YNET(t,n)  =E=  YGROSS(t,n) - DAMAGES(t,n)  ;

* GDP net of both Damages and Abatecosts
 eq_yy(t,n)$(reg(n))..   Y(t,n)  =E=  YNET(t,n)
                                      # CO2 Abatement Costs
                                  -   ABATECOST(t,n)
                                      # CO2 Carbon Tax [Trill USD / GtCO2]
                                  -   alpha_ctax(n) * ctax(t,n) * (E(t,n) - EPREV.l(t,n))  ;

* Investments
 eq_S(t,n)$(reg(n))..   I(t,n)  =E=  S(t,n) * Y(t,n)  ;

* Consumption
 eq_cc(t,n)$(reg(n))..   C(t,n)  =E=  Y(t,n) - I(t,n)  ;

* Consumption pro-capite (in thousands USD)
 eq_cpc(t,n)$(reg(n))..   CPC(t,n)  =E=  1000 * C(t,n) / pop(t,n)  ;

* Capital according to depreciation and investments
 eq_kk(t+1,n)$(reg(n))..   K(t+1,n)  =E=  (1-dk)**tstep * K(t,n) + tstep * I(t,n)   ;

* Interest rate
 eq_ri(t+1,n)$(reg(n))..   RI(t,n)  =E=  ( (1+prstp) * (CPC(t+1,n)/CPC(t,n))**(elasmu/tstep) ) - 1  ;



##  AFTER SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='after_solve'

* Evaluate social cost of carbon per region through marginals
* (note that this phase is executed only in OPT run_mode)
scc(t,n) = div0(-1000*eq_E.m(t,n),eq_cc.m(t,n));
display scc;

 world_c(t)            = sum(n$( nsolve(n)),      C.l(t,n));
 world_y(t)            = sum(n$( nsolve(n)),      Y.l(t,n));
 world_ygross(t)       = sum(n$( nsolve(n)), YGROSS.l(t,n));
 world_ynet(t)         = sum(n$( nsolve(n)),   YNET.l(t,n));
 world_k(t)            = sum(n$( nsolve(n)),      K.l(t,n));
 world_avg_s(t)        = sum(n$( nsolve(n)),      S.l(t,n))/card(nsolve);


#=========================================================================
*   ///////////////////////     SIMULATION    ///////////////////////
#=========================================================================

##  SIMULATION SETUP
#_________________________________________________________________________
$elseif.ph %phase%=='set_simulation'


##  SIMULATION HALFLOOP 1
#_________________________________________________________________________
$elseif.ph %phase%=='simulate_1'

* GDP gross: Cobb-Douglas production function
  YGROSS.l(t,n)  =  tfp(t,n) * (K.l(t,n)**gama) * (pop(t,n)/1000)**(1-gama)  ;

##  SIMULATION HALFLOOP 2
#_________________________________________________________________________
$elseif.ph %phase%=='simulate_2'

* GDP net of Climate Damages
  YNET.l(t,n)  =  YGROSS.l(t,n) - DAMAGES.l(t,n)  ;

* GDP net of both Damages and Abatecosts
  Y.l(t,n)  =  YNET.l(t,n)
               # CO2 Abatement Costs
            -  ABATECOST.l(t,n)
               # CO2 Carbon Tax [Trill USD / GtCO2]
            -  ctax(t,n) * (E.l(t,n) - EPREV.l(t,n))  ;

* Investments
  I.l(t,n)  =  S.l(t,n) * Y.l(t,n)  ;

* Consumption
  C.l(t,n)  =  Y.l(t,n) - I.l(t,n)  ;

* Consumption per capita (in thousands USD)
  CPC.l(t,n)  =  1000 * C.l(t,n) / pop(t,n)  ;

* Capital according to depreciation and investments
  K.l(t+1,n)  =  (1-dk)**tstep * K.l(t,n)  +  tstep * I.l(t,n)  ;

* Rate of interest
  RI.l(t,n)  =  ( (1+prstp) * (CPC.l(t+1,n)/CPC.l(t,n))**(elasmu/tstep) ) - 1  ;


##  AFTER SIMULATION
#_________________________________________________________________________
* In this phase you are OUTSIDE the loop(t,..), at the end of the simulation process.
$elseif.ph %phase%=='after_simulation'



#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  REPORT
$elseif.ph %phase%=='report'

# LOCAL DAMAGES ----------------------------------------
PARAMETERS
* Damages fraction
    damfrac_ykali(t,n)  'Damages over baseline scenario [%baseline]: (-) damage (+) gain'
    damfrac_ygross(t,n) 'Damages over GDPgross [%GDPgross]: (-) damage (+) gain'
* Damages absolute
    damages_ykali(t,n)  'Absolute damages over baseline scenario [Trill 2005 USD]: (-) damage (+) gain'
    damages_ygross(t,n) 'Absolute damages over GDPgross [Trill 2005 USD]: (-) damage (+) gain'
;
 damfrac_ykali(t,n)  = ((YNET.l(t,n) - ykali(t,n))/ykali(t,n)       * 100 ) ;
 damfrac_ygross(t,n) = ((YNET.l(t,n) - YGROSS.l(t,n))/YGROSS.l(t,n) * 100 ) ;
 damages_ykali(t,n)  = YNET.l(t,n) - ykali(t,n)     ;
 damages_ygross(t,n) = YNET.l(t,n) - YGROSS.l(t,n)  ;

# WORLD DAMAGES ----------------------------------------
PARAMETERS
  world_damfrac(gdpadj,t)  'World damages [%baseline]'
  world_damages(gdpadj,t)  'World damages (PPP|MER) [Trill 2005 USD]'
;
 world_damfrac('PPP',t) = (sum(n,YNET.l(t,n)) - sum(n,ykali(t,n))) / sum(n,ykali(t,n)) * 100 ;
 world_damfrac('MER',t) = (sum(n,YNET.l(t,n)*ppp2mer(t,n)) - sum(n,ykali(t,n)*ppp2mer(t,n))) / sum(n,ykali(t,n)*ppp2mer(t,n)) * 100 ;
 world_damages('PPP',t) = sum(n,YNET.l(t,n)) - sum(n,ykali(t,n))  ;
 world_damages('MER',t) = sum(n,YNET.l(t,n)*ppp2mer(t,n)) - sum(n,ykali(t,n)*ppp2mer(t,n))  ;


##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# Sets (excl. aliases) ---------------------------------
ssp
gdpadj

# Parameters -------------------------------------------
ykali
ppp2mer
pop
basegrowthcap
tfp
elasmu
prstp
gama
dk
scc
cprice_base
photel
rr
ga
gl
damfrac_ykali
damfrac_ygross
damages_ykali
damages_ygross
world_damfrac
world_damages

# Variables --------------------------------------------
C
CPC
K
I
S
RI
YGROSS
YNET
Y
CTX

# Equations (only for OPT. run_mode) -------------------
$if %run_mode%=='optimization' eq_cc

$endif.ph

