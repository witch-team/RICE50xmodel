# The RICE50+ model

Version 1.0
This is RICE50+, a multi-regional DICE-like Integrated Assessment Model.


<br>

## Quick setup

1) Have GAMS installed (https://www.gams.com/, you will need a working `GAMS/CONOPT` license).


2) Download and unzip calibrated input data from:  https://github.com/witch-team/RICE50xmodel/releases/download/v1.0.0/data_ed57.zip

3) Run the model  in Gams IDE/Studio or in the shell.
```Shell
    gams run_rice50x.gms
```

4) Define run scenario passing flags as:
```Shell
    gams run_rice50x.gms --flagname=flagvalue 
```

<br>

# Main settings flags

What follows is a summary of main model settings.

**Bolded** elements are model default values.


| flag | values | description |
|:-----|:------:|:----------  |
| `policy` |**bau**<br>bau-impacts<br>cba<br>cba-ndcs<br>cea-cbudget<br>cea-tatm| **Baseline with no damages**<br>Baseline with damages active<br>Cost-benefit analysis<br>Cost-benefit analysis starting from 2030 NDCs levels<br>Carbon-budget limit (CO2)<br>GMT increase limit (over pre-industrial) |
|`baseline` |ssp1<br>**ssp2**<br>ssp3<br>ssp4<br>ssp5| Shared Socio-economic Pathways| 
|`cooperation`|coop<br>**noncoop**<br>coalitions|Maximize aggregated welfare<br>Maximize self-interest (Nash eq.)<br>coop among coalition members, noncoop among coalitions |
|`weighting`|**pop**<br>negishi| |
|`n`|**ed57** | Regional schema|
|`impact`| off<br>dice<br>**burke**<br>djo<br>kahn| Impact function |
|`bhm_spec`|**sr**<br>srdiff<br>lr<br>lrdiff|Burke's function type <br>(if ``impact`` is different than burke it is simply ignored)|
|``climate``| dice2016<br>**witchco2**<br>cbsimple<br> | dice 2016  <br>dice with coeffs. corrected as in witch <br>Simple transient concentration response|
|``savings``| **fixed**<br>free<br> |**starting differentiated and all converging to dice-opt value**<br>Free variable to optimize| 
|`macc_shape`| **enerdata**<br>dice2016||
|`disentangled`| **1**<br>0 | disentangled welfare<br>DICE welfare |
|`gamma`|`number`|Inequality aversion |
|`prstp`|`number`|Pure rate of social time preference |
|`elasmu`|`number`|Elasticity of marginal utility of consumption |
|`gama`|`number`|Capital elasticity in the production function |
---

<br><br>

## Output settings

Define results name and destination path.

| flag | values | description |
|:-----|:------:|:----------  |
|`nameout`| `string` | Set output gdx filename |
|`output_dir`|`string`| Set output results folder (DEFAULT: "**./results**" )|
|`experiment_id`|`string`| Use this flag to gather results inside a common (`output_dir/experiment_id/`) directory |
---
<br><br>


## Startboost options

Startboot enables an automated loading of the best-matching results/startboost/ gdx-file available. It leads the model to a faster convergence by setting variables at a feasible and well-founded starting point. 
Good startboost solutions must be first manually generated using the `startboost_export` option when running significative scenarios. 
Startboost is disabled by default.

| flag | values | description |
|:-----|:------:|:----------  |
|`startboost`|**0** \| 1 | Activate it to enable startboost logic |
| `startboost_manual` |**0** \| `string` | Activate it to manually provide startboost gdx file name <br> (*write it without .gdx extension*) <br> **Target file is searched inside *startboost folder* inside regional datafolder** <br>*(i.e., RICExdata_ed57_t58/startboost/)*| 
|`startboost_export`|**0** \| 1 | Activate it to save current output as startboost source into startboost folder|
---


<br><br>


# Additional policies and run modes

<br>

## Simulation
Simulate providing  Mitigation (mandatory) and Savings (optional) trajectories from an external gdx file.

| flag | values | description |
|:-----|:------:|:----------  |
| `policy` |sim| Model in simulation mode |
|`sim_miu_gdx`| `string` | File .gdx (filename and relative path) from which extract regional mitigation (**MIU**.l) trajectories|
|`sim_savings_gdx`| `string` | File .gdx (optional, filename and relative path) from which extract regional Savings (**S**.l) trajectories |
---
<br><br>

## CBA-Delay
Simulate up to a specific time, providing Mitigation (mandatory) and Savings (optional) trajectories.
Then, from that time on, search for the best Benefit-Cost solution. 

| flag | values | description |
|:-----|:------:|:----------  |
| `policy` | cba&#8209;delay <br> cba&#8209;ndcs| CBA  delayed to  `tdelay` timestep <br> CBA starting 2030 and NDCs levels |
|`tdelay` | `numeric` | Last timestep for fixed trajectories (optimization starts from `x`+1 one) |
|`sim_miu_gdx`| `string` | File .gdx (filename and relative path) from which extract regional mitigation (**MIU**.l) trajectories|
|`sim_savings_gdx`| `string` | File .gdx (optional, filename and relative path) from which extract regional Savings (**S**.l) trajectories |
---

<br><br>

## Simulation with exogen temperatures
Simulate providing Mitigation (optional), Savings (optional) and exogenous temperature trajectories.


| flag | values | description |
|:-----|:------:|:----------  |
| `policy` | sim&#8209;exogen&#8209;temp| Model in simulation mode |
|`exogen_source`|treg<br>tatm<br>treg_rcp<br>treg_linear|Import external regional temperature trajectories<br>Import external atmospheric temperature trajectory<br>Regional temperatures follow rcp data trajectories<br>Set GMT increase at 2100. Regional temperatures are linearized between 2015-2100 extremes. |
|`rcp` | 26<br>45<br>60<br>85 | Set reference rcp (only for `exogen_source`=treg_rcp) |
|`exogen_tatm_2100` | `numeric` | GMT increase at 2100 (only for `exogen_source`=treg_linear) |
|`sim_temp_gdx`|  `string`  | File .gdx (filename and relative path) from which extract:<br> - atmospheric temperatures (**TATM**.l, only for `exogen_source`=tatm)<br>- regional temperatures (**TEMP_REGION**.l, only for `exogen_source`=treg)|
|`sim_miu_gdx`|  `string`  | File .gdx (_optional_, filename and relative path) from which extract regional mitigation (**MIU**.l) trajectories|
|`sim_savings_gdx`|  `string`  | File .gdx (_optional_, filename and relative path) from which extract regional Savings (**S**.l) trajectories |
---
<br><br>

## CTAX

Apply a carbon tax. 

| flag | values | description |
|:-----|:------:|:----------  |
| `policy` | ctax<br>ctax-advance | Model in general ctax-mode<br>Model adopts specified ADVANCE diagnostic ctax |
| `ctax_spec` | **no_ctax**<br>`numeric` | **No ctax applied**<br>Apply carbon tax starting from given value [$/CO2] and increasing by 5% p.a. (only with `policy`=ctax)   |
|`ctax_diag`| c30_const<br>c80_const<br>**c30_gr5**<br>c80_gr5<br> c0to30_const<br>c0to80_const<br> c0to30_gr5<br> c0to80_gr5 <br>c80_lin<br>hybrid  | ADVANCE diagnostic carbon tax selected <br>(only with `policy`=ctax-advance)|
---

<br><br>

## Contact information

paolo.gazzotti@polimi.it