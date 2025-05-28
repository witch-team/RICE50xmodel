# The RICE50+ model

A calibrated multi-regional Integrated Assessment Model with 50+ regions, calibrated abatement cost curves, a modular and phase structure of the code, and additional optional modules.

## Requirements

1) **Installation:** Install R, Rtools, RStudio, GAMS, Github Desktop, (and optionally VSCode as advanced editor)  
* R from [https://cran.r-project.org/bin/windows/base/](https://cran.r-project.org/bin/windows/base/)  
* RStudio from [https://rstudio.com/products/rstudio/download/\#download](https://rstudio.com/products/rstudio/download/#download)  
* GAMS from [https://www.gams.com/download/](https://www.gams.com/download/) (Run the installer in advanced mode and mark the check-box `Add GAMS directory to PATH environment variable`).  
* GitHub Desktop from [https://desktop.github.com/](https://desktop.github.com/) and log-in with your personal GitHub Account.  
* VisualStudio Code from [https://code.visualstudio.com/](https://code.visualstudio.com/) (optional)  
2) **System configuration**  
* Verify in case that your GAMS (and preferrably also R) directory has been added to your PATH environment variable.   
3) **GAMS license**  
* In order to run the model, you need a GAMS license and CONOPT (or KNITRO) license. You can request a temporary license from gams [https://www.gams.com/download/](https://www.gams.com/download/) but for serious model runs you will need a full license, academic and non-for-profit versions might be available. Once you obtain the license as `gamslice.txt` file, copy this file to your GAMS folder.

## Create the data folder, run the model, and analyze results

4) Get the source code of the RICE50x model: Either cloning it in Github desktop (preferred), download it from [https://github.com/witch-team/RICE50x](https://github.com/witch-team/RICE50x) ([https://github.com/witch-team/RICE50xmodel](https://github.com/witch-team/RICE50xmodel) for the open source version), or using git at the command line.  
     
5) For the open source version [https://github.com/witch-team/RICE50xmodel](https://github.com/witch-team/RICE50xmodel), just download and unzip calibrated input data from [https://github.com/witch-team/RICE50xmodel/releases/download/v2.5.0/data\_ed58.zip](https://github.com/witch-team/RICE50xmodel/releases/download/v2.0.0/data_ed57.zip) into the same folder.   
   For the development version, you can recreate the data yourself: generate the data for the model, with default region (ed58) mapping in R by running in Rstudio (opening the RICE50x folder as project) or on the command line

```

Rscript input/translate_rice50x_data.R

```

	

6) Run the model in gams or on the command line:

```

gams run_rice50x.gms

```

7) \[OPTIONAL\] Analyze and visualize model output, using the produced results\_\*.gdx files in the RICE50x folder. This can be done in GAMS itself, or exporting to Excel, or using your software of choice with a gdx importing possibility. You can also get the "witch-plot" repository from github ([https://github.com/witch-team/witch-plot](https://github.com/witch-team/witch-plot)) download it to the same root folder as RICE50x, and after running the model, launch the interactive visualization tool:

```

Rscript plotgdx_rice50x.R

```

## Main setting flags for the RICE50x to be set in run\_rice50x.gms

What follows is a summary of main model settings. **Bold** elements are model default values.

| flag | values | description |
| :---- | ----- | :---- |
| `policy` | **bau** bau\_impact cba cbudget ctax | **BAU without damages** BAU with damages cost-benefit analysis carbon budget carbon tax |
| `baseline` | ssp1 \*\*ssp2\*\* ssp3 ssp4 ssp5 | Shared Socio-Economic Pathway for TFP, population, and carbon intensity baseline |
| `cooperation` | coop \*\*noncoop\*\* coalitions |  |
| `impact` | off dice burke dell \*\*kalkuhl\*\* howard climcost coacch |  |
| `climate` | \*\*fair\*\* witchco2  |  |
| `savings` |  \*\*fixed\*\* flexible  | **Fixed saving rates (converging to DICE optimal in 2150\)** Free saving rates |

## Contributing authors:

- Pietro Andreoni  
- Matteo Calcaterra  
- Leonardo Chiani  
- Laurent Drouet  
- Johannes Emmerling  
- Paolo Gazzotti  
- Francesco Granella  
- Giacomo Marangoni  
- Piergiuseppe Pezzoli  
- Lara Aleluia Reis  
- Alessandro Taberna  
- Massimo Tavoni  
- Tommaso Zaini

Contact: [rice50xmodel@witchmodel.org](mailto:rice50xmodel@witchmodel.org) 

## Publications using the RICE50+ model

- Gazzotti, Paolo, Johannes Emmerling, Giacomo Marangoni, Andrea Castelletti, Kaj-Ivar van der Wijst, Andries Hof, and Massimo Tavoni. “Persistent Inequality in Economically Optimal Climate Policies.” Nature Communications 12, no. 1 (June 8, 2021): 3421\. [https://doi.org/10.1038/s41467-021-23613-y](https://doi.org/10.1038/s41467-021-23613-y).  
- Gazzotti, Paolo. “RICE50+: DICE Model at Country and Regional Level.” Socio-Environmental Systems Modelling 4 (April 13, 2022): 18038–18038. [https://doi.org/10.18174/sesmo.18038](https://doi.org/10.18174/sesmo.18038).  
- Ferrari, Luca, Angelo Carlino, Paolo Gazzotti, Massimo Tavoni, and Andrea Castelletti. “From Optimal to Robust Climate Strategies: Expanding Integrated Assessment Model Ensembles to Manage Economic, Social, and Environmental Objectives.” Environmental Research Letters 17, no. 8 (August 2022): 084029\. [https://doi.org/10.1088/1748-9326/ac843b](https://doi.org/10.1088/1748-9326/ac843b).  
- Pezzoli, Piergiuseppe, Johannes Emmerling, and Massimo Tavoni. “SRM on the Table: The Role of Geoengineering for the Stability and Effectiveness of Climate Coalitions.” Climatic Change 176, no. 10 (October 5, 2023): 141\. [https://doi.org/10.1007/s10584-023-03604-2](https://doi.org/10.1007/s10584-023-03604-2).  
- Andreoni, Pietro, Johannes Emmerling, and Massimo Tavoni. “Inequality Repercussions of Financing Negative Emissions.” Nature Climate Change 14, no. 1 (November 30, 2023): 48–54. [https://doi.org/10.1038/s41558-023-01870-7](https://doi.org/10.1038/s41558-023-01870-7).  
- Bastien-Olvera, B. A., M. N. Conte, X. Dong, T. Briceno, D. Batker, J. Emmerling, M. Tavoni, F. Granella, and F. C. Moore. “Unequal Climate Impacts on Global Values of Natural Capital.” Nature, December 18, 2023, 1–6. [https://doi.org/10.1038/s41586-023-06769-z](https://doi.org/10.1038/s41586-023-06769-z).  
- Emmerling, Johannes, Pietro Andreoni, and Massimo Tavoni. “Global Inequality Consequences of Climate Policies When Accounting for Avoided Climate Impacts.” Cell Reports Sustainability 1, no. 1 (January 26, 2024): 100008\. [https://doi.org/10.1016/j.crsus.2023.100008](https://doi.org/10.1016/j.crsus.2023.100008).  
- Gilli, Martino, Matteo Calcaterra, Johannes Emmerling, and Francesco Granella. “Climate Change Impacts on the Within-Country Income Distributions.” Journal of Environmental Economics and Management 127 (September 2024): 103012\. [https://doi.org/10.1016/j.jeem.2024.103012](https://doi.org/10.1016/j.jeem.2024.103012).  
- Emmerling, Johannes, Pietro Andreoni, Ioannis Charalampidis, Shouro Dasgupta, Francis Dennig, Simon Feindt, Dimitris Fragkiadakis, et al. “A Multi-Model Assessment of Inequality and Climate Change.” Nature Climate Change, October 4, 2024, 1–7. [https://doi.org/10.1038/s41558-024-02151-7](https://doi.org/10.1038/s41558-024-02151-7).  
- Chiani, Leonardo, Emanuele Borgonovo, Elmar Plischke, and Massimo Tavoni. “Global Sensitivity Analysis of Integrated Assessment Models with Multivariate Outputs.” Risk Analysis: An Official Publication of the Society for Risk Analysis, February 22, 2025\. [https://doi.org/10.1111/risa.70002](https://doi.org/10.1111/risa.70002).  