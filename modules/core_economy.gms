* CORE ECONOMY MODULE
* -
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

## CONF
*-------------------------------------------------------------------
* Definition of the global flags and settings specific to the module
$ifthen.ph %phase%=='conf'

* SAVINGS RATE
* | fixed | flexible |
$setglobal savings 'fixed'

* Calibrate capital and labour share for the CD function
*$setglobal calib_labour_share

*SSPs have been updated to 2020 based on Koch and Marian (2021), so no update anymore needed
*$setglobal update_ssp_by_historical

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
$setglobal default_savings "fixed"

* Run the model on PPP or MMM
*| PPP | MER |
$setglobal exchange_rate 'PPP'


## SETS
#_________________________________________________________________________
* In the phase SETS you should declare all your sets, or add to the existing
* sets the element that you need.
$elseif.ph %phase%=='sets'

SET
    ssp     'SSP baseline names'       / ssp1,ssp2,ssp3,ssp4,ssp5 /
    gdpadj  'GDP-adjustment type'      / PPP,MER /
;

set prodfact /labour,capital/;


## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'


PARAMETERS
* Population and technology
    dk              'Depreciation rate on capital (per year)'         /  0.100     /
    prodshare(prodfact, n) 'production elasticity in the Cobb-Douglas function'

* Savings Rate
    dice_opt_savings  'Gross Savings Rate level as DICE convergence'   /  0.2751    /  # DICE2016 optim savings convergence!
;


PARAMETERS
* Savings rate
    optlr_savings(n)   'Optimal long-run Savings Rate used for transversality'
    fixed_savings(t,n) 'Gross Savings Rate value if S variable is fixed [%GDP]'

* Other rates
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
$ifthen.vd set update_ssp_by_historical
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
ykali(t,n)$gdppc_kali(t,n) = gdppc_kali(t,n) * l(t,n) / 1e6;
pop(t,n) = l(t,n);

* Conversion factors between PPP and MER
$gdxin %datapath%data_baseline
parameter ppp2mer(n) 'ratio to convert PPP to MER';
$loaddc ppp2mer
$gdxin
parameter mer2ppp(t,n) 'ratio to convert MER to PPP';
ppp2mer(n)$(ppp2mer(n) eq 0) = 1;
mer2ppp(t,n) = 1 / ppp2mer(n);
#PPP adjustment in case
$if %exchange_rate%=="PPP" ykali(t,n) = ykali(t,n) * mer2ppp(t,n); gdppc_kali(t,n) = gdppc_kali(t,n) * mer2ppp(t,n);


## STARTING CAPITAL AND SAVINGS RATE
* Take from  calibrated file the capital zero as GDP weighted total capital.
PARAMETERS
    s0(*,t,n)      'Regions Savings Rate at starting time [%GDP]'
    k0(*,t,n)      'Initial Regions Capital at starting time [Trill 2005 USD]'
    r0(*,t,n)      'Regions Interest Rate at starting time [%]'
;

$gdxin '%datapath%data_validation.gdx'
$load k0=k_valid_article, s0=socecon_valid_weo_mean, r0=socecon_valid_wdi_mean
$gdxin
$if %exchange_rate%=="PPP" k0('fg',t,n) = k0('fg',t,n)*mer2ppp(t,n);
*for regions with missing capital, impute based on estimated linar relationship with GDP (R squared = 0.9604)
k0('fg','1',n)$(k0('fg','1',n) eq 0) = 2.72 * ykali('1',n) + 0.127;
s0('savings_rate', '1', n) = max(s0('savings_rate', '1', n), 1) / 100; #in percent, for negative value set to 1% to avoid negative capital
* real interest rate
r0('interest_rate', '1', n) = max(r0('interest_rate', '1', n), 1) / 100 - s0('inflation_rate', '1', n) / 200;
#use: k0('fg', '1', n) and s0('savings_rate', '1', n) and r0('interest_rate', '1', n)

PARAMETER labour_share(n) 'Labour share in GDP';
$gdxin '%datapath%data_mod_labour.gdx'
$load labour_share
$gdxin
labour_share(n)$(labour_share(n) eq 0) = 0.7; #original RICE/DICE value
labour_share(n) = min(max(labour_share(n), 0.5), 0.8); #limit to 50-80% range

##  PARAMETERS EVALUATED ----------

PARAMETER
* Total factor productivity
   tfp(t,n)           'Regions Total Factor Productivity'
   i_tfp(t,n)         'Baselines Investments to evaluate TFP'
   k_tfp(t,n)         'Baselines Capital to evaluate TFP'
;


##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

prodshare('labour', n) = 0.7; #original RICE/DICE value
$ifthen.cs set calib_labour_share
* now calibrate capital and labour shares of GDP based on wage share in GDP indirectly based on gross capital productivity
parameter wage0(n) 'USD per capita per year';
wage0(n) = (ykali('1',n) - (r0('interest_rate', '1', n) + dk) * k0('fg', '1', n)) / pop('1',n) * 1e6;
*wage at least to be one third of GDP per capita
wage0(n) = max(wage0(n), (1/3)*gdppc_kali('1',n));
prodshare('labour', n) = (wage0(n) * pop('1',n) * 1e-6) / ykali('1',n);
#now instead take labour share directly from Guerriero (2019)
prodshare('labour', n) = labour_share(n);
$endif.cs
prodshare('capital', n) = 1 - prodshare('labour', n);


 ##  BASELINE PER-CAPITA GROWTH ------------------------
* Baseline per-capita growth
loop((t,tp1)$(pre(t,tp1) and tnolast(t)),
basegrowthcap(t,n) = ((( (ykali(tp1,n)/pop(tp1,n)) / (ykali(t,n)/pop(t,n)) )**(1/tstep)) - 1 );
);

##  SAVINGS RATE --------
* Optimal long-run Savings rate
optlr_savings(n) = (dk + .004)/(dk + .004*elasmu + prstp)*prodshare('capital',n);

* Evaluate converging Savings Rate
* Linear interpolation: S0 + (Send - S0)*(t - t0)/(tend - t0)
fixed_savings(t,n) = s0('savings_rate', '1', n) + (optlr_savings(n) - s0('savings_rate', '1', n)) * (tperiod(t) - 1)/(smax(tt,tperiod(tt)) - 1);


##  DYNAMIC CALIBRATION OF TFP FROM BASELINE AND SCENARIO ---------------------
* set capital first value
k_tfp('1',n)  =  k0('fg', '1', n);

* retrieve tfp from reverting the Cobb-Douglas Production Function based on fixed investment rates iteratively
loop((t,tp1)$pre(t,tp1),
   # Investments
   i_tfp(t,n)  =  fixed_savings(t,n)  * ykali(t,n)   ;
   # Capital
   k_tfp(tp1,n)  =  ((1-dk)**tstep) * k_tfp(t,n)  +  tstep * i_tfp(t,n)  ;
   # TFP of current scenario (explicited from Cobb-Douglas prod. function)
   tfp(t,n)  =  ykali(t,n) / {
                                 ( pop(t,n)/1000
                                 )**prodshare('labour',n) *
                                 k_tfp(t,n)**prodshare('capital',n) *
$if set mod_natural_capital      (sum(nn, natural_capital_aggregate(nn,'nN'))**natural_capital_global_elasticity(n)) * (natural_capital_aggregate(n,'mN'))**prodshare('nature',n) *
                                 1
                              };
);
tfp(t,n)$tlast(t) = sum(tt$pre(tt,t), tfp(tt,n));

tolerance("Y") = 1e-3; #0.1% of variation of economy

##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
    C(t,n)            'Consumption (%exchange_rate%) [Trill 2005 USD / year]'
    CPC(t,n)          'Per capita consumption (%exchange_rate%) [2005 USD per year per capita]'

    K(t,n)            'Capital stock (%exchange_rate%) [Trill 2005 USD / year]'
    I(t,n)            'Investments (%exchange_rate%) [Trill 2005 USD / year]'
    S(t,n)            'Gross Savings Rate as fraction of gross world product [%GDP]'
    RI(t,n)           'Real Interest Rate (per annum)'

    YGROSS(t,n)       'GDP GROSS (%exchange_rate%) [Trill 2005 USD / year]'
    YNET(t,n)         'GDP NET of climate impacts (%exchange_rate%) [Trill 2005 USD / year]'
    Y(t,n)            'GDP NET of Abatement Costs and Damages (%exchange_rate%) [Trill 2005 USD / year]'

    CTX(t,n)          'Carbon Tax effect on GDP (%exchange_rate%) [Trill 2005 USD]'
;
POSITIVE VARIABLES  Y, YNET, YGROSS, C, CPC, K, I, S;

# VARIABLES STARTING LEVELS
* to help convergence
 YGROSS.l(t,n) = ykali(t,n)  ;
   YNET.l(t,n) = ykali(t,n)  ;
      Y.l(t,n) = ykali(t,n)  ;
      S.l(t,n) = fixed_savings(t,n)  ;
      I.l(t,n) = S.l(t,n) * ykali(t,n)  ;
      C.l(t,n) = ykali(t,n) - I.l(t,n)  ;
    CPC.l(t,n) = C.l(t,n) / pop(t,n)  * 1e6;
      K.l(t,n) = k_tfp(t,n);
      RI.l(t,n) = 0.05;

##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

##  STABILITY CONSTRAINTS --------
* to avoid errors/help the solver to converge
       C.lo(t,n) = 1e-8; # needed because of eq_periodu (!! higher than 1e-7 -> infes risk!)
     CPC.lo(t,n) = 1e-8; # needed because of eq_ri (!! higher than 1e-6 -> infes risk!)
  YGROSS.lo(t,n) = 1e-8; # needed because of eq_damfrac (higher than 1e-4 -> infes risk)
       K.lo(t,n) = 1e-8; # needed because of eq_komega (!! higher than 1e-7 -> infes risk)
       S.up(t,n) = 1;    # by definition
       S.lo(t,n) = 0;    # by definition
#.................................................
# NOTE
# Hardest experiments tested:
# < ssp1 noncoop LRdiff prstp=0.03>
# < ssp3 noncoop LRdiff *>
# < ssp5 noncoop LRdiff prstp=0.03>
#.................................................

UTARG.lo(t,n)=1e-8;

# STARTING CAPITAL ----------
K.fx(tfirst,n) = k0('fg', '1', n);


# SAVINGS RATE ----------
$ifthen.sav  %savings%=='fixed'
* Savings are fixed to evaluated converging trends
  S.fx(t,n) = fixed_savings(t,n)  ;
$else.sav
* Savings are left free to be optimized
  S.lo(t,n) = 0.1;
  S.up(t,n) = 0.45;
  #allow only gradual adjustment over time from starting point
  S.lo(t,n) = s0('savings_rate', '1', n) + (S.lo('58',n) - s0('savings_rate', '1', n)) * (tperiod(t) - 1)/(smax(tt,tperiod(tt)) - 1);
  S.up(t,n) = s0('savings_rate', '1', n) + (S.up('58',n) - s0('savings_rate', '1', n)) * (tperiod(t) - 1)/(smax(tt,tperiod(tt)) - 1);
* Fix starting point
  S.fx(tfirst,n) = s0('savings_rate', '1', n);
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
eq_ygross(t,n)$(reg(n) and tperiod(t) gt 1)..  YGROSS(t,n)  =E=  tfp(t,n) * (K(t,n)**prodshare('capital',n)) * 
                                            [
$if set mod_natural_capital                  GLOBAL_NN(t,n) ** natural_capital_global_elasticity(n) * NAT_CAP_DAM('market',t,n)**prodshare('nature',n) * 
                                            (pop(t,n)/1000)**prodshare('labour',n)]
;

* GDP net of Climate Damages
$ifthen.dam set damages_postprocessed
eq_ynet(t,n)$(reg(n))..  YNET(t,n)  =E=  YGROSS(t,n) - DAMAGES.l(t,n)  ;
$else.dam
eq_ynet(t,n)$(reg(n))..  YNET(t,n)  =E=  YGROSS(t,n) - DAMAGES(t,n)  ;
$endif.dam

* GDP net of both Damages and Abatecosts
 eq_yy(t,n)$(reg(n))..   Y(t,n)  =E=  YNET(t,n)
                                      # GHGs Abatement Costs
                                  -   sum(ghg,ABATECOST(t,n,ghg))
                                      # Cost of land use emission control
                                  -   ABCOSTLAND(t,n)
                                      # Carbon Tax [Trill USD / Gtspecies]
                                  -   sum(ghg, ctax_corrected(t,n,ghg) * convy_ghg(ghg) * (E(t,n,ghg) - E.l(t,n,ghg)) )
                                       # Cost of stratospheric aerosol injection
$if set mod_sai                   -    COST_SAI(t,n)
                                       # Cost of carbon dioxide removal
$if set mod_dac                   -    COST_CDR(t,n)
;

* Investments
 eq_S(t,n)$(reg(n))..   I(t,n)  =E=  S(t,n) * Y(t,n)
;

* Consumption
 eq_cc(t,n)$(reg(n))..   C(t,n)  =E=  Y(t,n) - I(t,n) 
$if set mod_adaptation                - sum(g, I_ADA(g,t,n))
$if set mod_natural_capital           - sum(type, NAT_INV(type,t,n))
;

* Consumption pro-capite (in thousands USD)
 eq_cpc(t,n)$(reg(n))..   CPC(t,n)  =E=  C(t,n) / pop(t,n) * 1e6 ;

* Capital according to depreciation and investments
 eq_kk(t,tp1,n)$(reg(n) and pre(t,tp1))..   K(tp1,n)  =E=  (1-dk)**tstep * K(t,n) + tstep * I(t,n)   ;

* Interest rate
 eq_ri(t,tp1,n)$(reg(n) and pre(t,tp1))..   RI(t,n)  =E=  ( (1+prstp) * (CPC(tp1,n)/CPC(t,n))**(elasmu/tstep) ) - 1  ;
 


##  BEFORE SOLVE
#_________________________________________________________________________
* In the phase BEFORE_SOLVE, you can update parameters (fixed
* variables, ...) inside the nash loop and right before solving the
* model. This is typically done for externalities, spillovers, ...
$elseif.ph %phase%=='before_solve'

$ifthen.sav  %savings%=='flexible'
* Last ten periods keep saving rate constant to avoid terminal problems
  S.fx(t,n)$(tperiod(t) gt (smax(tt,tperiod(tt)) - 10) )  = S.l('48',n);
$endif.sav

##  AFTER SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='after_solve'

 world_c(t)            = sum(n$( nsolve(n)),      C.l(t,n));
 world_y(t)            = sum(n$( nsolve(n)),      Y.l(t,n));
 world_ygross(t)       = sum(n$( nsolve(n)), YGROSS.l(t,n));
 world_ynet(t)         = sum(n$( nsolve(n)),   YNET.l(t,n));
 world_k(t)            = sum(n$( nsolve(n)),      K.l(t,n));
 world_avg_s(t)        = sum(n$( nsolve(n)),      S.l(t,n))/card(nsolve);

viter(iter,'S',t,n)$nsolve(n)   = S.l(t,n);    # Keep track of last investment values
viter(iter,'Y',t,n)$nsolve(n)   = Y.l(t,n)/ykali(t,n);    # Keep track of last gdp values

#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  REPORT
$elseif.ph %phase%=='report'


* Social Cost of Carbon
Parameter
    scc(t,n,ghg)           'Social Cost of Carbon' 
;
* Evaluate social cost of carbon per region through marginals as in DICE
scc(t,n,ghg)$(nsolve(n) and year(t) le 2200 and eq_cc.l(t,n) gt 0) = -1e3*sum(nn$nsolve(nn), div0(eq_e.m(t,nn,ghg) , eq_cc.m(t,nn)) );

# WORLD DAMAGES ----------------------------------------
PARAMETERS
  world_damfrac(t)  'World damages [% of GDP]'
  world_damages(t)  'World damages [Trill 2005 USD]'
;
 world_damfrac(t) = sum(n,DAMAGES.l(t,n))/sum(n,YGROSS.l(t,n));



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
l
gdppc_kali
basegrowthcap
tfp
elasmu
prstp
prodshare
dk
scc
rr
ga
gl
world_damfrac
fixed_savings
labour_share
optlr_savings

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

# Equations -------------------
eq_cc

$endif.ph

