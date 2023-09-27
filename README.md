# The RICE50+ model

Version 2.0.0

This is RICE50+, a multi-regional Integrated Assessment Model, described in the paper 
Gazzotti et al. (2021): 'Persistent inequality in economically optimal climate policies', Nature Communications, 12, Article number: 3421, https://www.nature.com/articles/s41467-021-23613-y

A calibrated multi-regional Integrated Assessment Model with 50+ regions, calibrated abatement cost curves, a modular and phase structure of the code, and additional optional modules.

## Requirements

1) **Installation:** Install GAMS, Github Desktop, (and optionally VSCode as advanced editor)

* GAMS from https://www.gams.com/download/ (Run the installer in advanced mode and mark the check-box `Add GAMS directory to PATH environment variable`).
* GitHub Desktop from https://desktop.github.com/ and log-in with your personal GitHub Account.
* VisualStudio Code from https://code.visualstudio.com/ (optional)

2) **GAMS license** 
* In order to run the model, you need a GAMS license and CONOPT or KNITRO license. You can request a temporary license from gams https://www.gams.com/download/ but for serious model runs you will need a full license, academic and non-for-profit versions might be available. Once you obtain the license as `gamslice.txt` file, copy this file to your GAMS folder.
  
## Create the data folder, run the model, and analyze results

3) Get the source code of the RICE50x model: Either cloning it in Github desktop (preferred), download it from https://github.com/witch-team/RICE50xmodel, or using git at the command line.

4) Download and unzip calibrated input data from https://github.com/witch-team/RICE50xmodel/releases/download/v2.0.0/data_ed57.zip and into the same folder.

  
5) Run the model in gamsIDE (creaing a project file in the RICE50x folder) or on the command line: 

```Shell

gams run_rice50x.gms

```

6) [OPTIONAL] Analyze and visualize model output, using the produced results_*.gdx files in the RICE50x folder. This can be done in GAMS itself, or exporting to Excel, or using your sofwrate of choice with a gdx importing possibility. You can also get the "witch-plot" repository from github (https://github.com/witch-team/witch-plot) download it to the same root folder as RICE50x, and after running the model, launch teh interactive visualization tool:

```Shell

Rscript plotgdx_rice50x.R

``` 

  

## Main setting flags for the RICE50x to be set in run_rice50x.gms

What follows is a summary of main model settings. **Bold** elements are model default values.

| flag | values | description |
|:-----|:------:|:----------  |
| `policy` |**bau**<br>bau_impact<br>cba<br>cbudget<br>ctax| **BAU without damages**<br>BAU with damages<br>cost-benefit analysis<br>carbon budget<br>carbon tax |
|`baseline` |ssp1<br>**ssp2**<br>ssp3<br>ssp4<br>ssp5| Shared Socio-Economic Pathway for TFP, population, and carbon intensity baseline | 
|`cooperation`|coop<br>**noncoop**<br>coalitions| |
|`impact`| off<br>dice<br>burke<br>dell<br>**kalkuhl**<br>howard<br>coacch| |
|``climate``| dice2016<br>**witchco2**<br>cbsimple<br> | dice 2016  <br>dice with coeffs. corrected as in witch <br>Simple transient concentration response|
|``savings``| <br>**fixed**<br>flexible<br> |**Fixed saving rates (converging to DICE optimal in 2150)**<br>Free saving rates| 