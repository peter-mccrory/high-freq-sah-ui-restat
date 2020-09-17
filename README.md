# Data Archive for "Unemployment Effects of Stay-at-Home Orders: Evidence from High Frequency Claims Data"

## By  ChaeWon Baek, Peter B. McCrory, Todd Messer, and Preston Mui

### Intro

This repository contains all the data and code required to replicate the analysis that appears in "Unemployment Effects of Stay-at-Home Orders: Evidence from High Frequency Claims Data".

The repository is organized as follows:
  - **./data/**: Contains the raw data as well as the compiled Stata datasets used in the analysis. A description of each file follows below.
  - **./src/**: All the code necessary to do the analysis is contained in this folder. There are three sub-directories for each of the languages used. A description of each file is contained below. The empirical analysis is done in Stata, the theoretical analysis is done in Matlab, and some of the figures are created in a Jupyter notebook using a Python 3 kernel.
  - **./output/**: This folder contains the plots and tables appearing in the paper. Running the code (in the order described below) will reproduce all such analysis.

The root directory also contains a `.gitignore` file for ignoring files for the Github repository (code also available at: [https://github.com/peter-mccrory/high-freq-sah-ui-restat](https://github.com/peter-mccrory/high-freq-sah-ui-restat)).

All scripts were verified to work with the following software: (i) Stata 14, (ii) Python 3.8.3 installed with Anaconda, and (iii) Matlab 2020b.

### Steps for Replicating Analysis in Paper

To replicate the analysis in Baek, McCrory, Messer, Mui (2020) do the following:

- **Main Empirics:** From within the `./src/stata/` directory, run `run_all.do` in Stata. This will call on the following do files contained in the `./src/stata/` directory, briefly described below. Each step can be run separately from `run_all.do`.
    - *step1_build_state:* This file imports all underlying data files in the data directory needed for the state-level analysis. Intermediate files are saved in `./data/stata/`
    - *step2_build_county:* This file imports all underlying data files in the data directory needed for the county-level analysis. Intermediate files are saved in `./data/stata/`
    - *step3_merge_state:* This file merges together the state-level datasets to produce the main state-build dataset, `./data/stata/state_build.dta`
    - *step4_merge_county:* This file merges together the county-level datasets to produce the main state-build dataset, `./data/stata/state_build.dta`
    - *step5_analysis_main:* This file estimates state-level regressions and saves all regression tables appearing in the main text and online appendix to
    - *step6_analysis_county:* This file estimates the county-level regressions underlying Tables 3 and 4 in the main text, saving those tables to `./output/tables/`.
    - *step7_eventstudies:* This file estimates event study regressions described in the online appendix, saving the figures in the online appendix to `./output/plots/`.
    - *step8_early_late_figure:* This file creates Figure 3 in the main text, saving it to `./output/plots/`
    - *step9_rel-implied-agg:* This file calculates the relative-implied aggregate employment loss attributable to SAH orders.
- **Theoretical Results:** From the command line Matlab and while located in the `./src/matlab/`, using [Dynare](https://www.dynare.org/), run baseline.mod with `dynare baseline`. This will create and save Figure 5 to `./output/plots/`. It will also calculate and report numbers appearing in Table 2 of the main text.
- **Additional Figures:** To make all remaining figures in the paper (main text and online appendix), run `./src/python/QCEW.ipynb` in a Jupyter notebook (Python 3 kernel). This will create and save figures to `./output/plots/`. Note: the user will need to install plotly-related packages to their conda distribution; if these are not already installed, an error will be produced prompting them to install the appropriate package (e.g. `cufflinks`, `plotly-orca`).

### Brief Description of ./data/ Directory Files
****
The data used in the analysis is organized by source. Each source has its own separate folder, which are described completely below:

- **bls:** This folder contains five data files used to build the state and county-level datasets used in the paper
  - *county_qcew_emp.csv*: This file reports 2018 county-level employment from the Quarterly Census of Employment and Wages (QCEW). `./src/python/QCEW.ipynb` queries the QCEW data and creates this file. These data were downloaded April 10, 2020.
  - *county_qcew_subset.dta*: This file is created from the 2019 county-level employment from the QCEW. It is created with `./data/bls/build_county_qcew_subset.do`. The raw file from which this subset was created is available at https://data.bls.gov/cew/data/files/2019/csv/2019_annual_singlefile.zip. These data were downloaded June 27, 2020
  - *lau.csv*: This file contains county-level employment and unemployment statistics produced from the BLS Local Area Unemployment Statistics. These data are downloaded and saved with `Load-LAU.ipynb`. These data were downloaded with this script June 4, 2020.
  - *state_bartiks.csv:* This file is created in the Jupyter notebook `BLS-jobs.ipynb`. This represents the Bartik-style control described in the main text. The underlying data were downloaded April 10, 2020.
  - *state_emp_ind.csv:* This file reports average annual employment from 2018 levels by sector and state. It is created with `QCEW.ipynb`. These data were downloaded by this script on April 10, 2020.
- **cdc:** This folder contains the excess deaths associated with Covid-19 as downloaded from the [CDC](https://www.cdc.gov/nchs/nvss/vsrr/covid19/excess_deaths.htm)
- **census:** This folder contains data from U.S. census Bureau, including state demographic data (https://www.census.gov/data/tables/time-series/demo/popest/2010s-state-detail.html; accessed June 16, 2020) and county population estimates for 2020 (https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/; accessed March 28, 2020)
- **CZ:** This folder contains the USDA commuting zone to county crosswalk created by the USDA (https://www.ers.usda.gov/data-products/commuting-zones-and-labor-market-areas/; accessed July 1, 2020)
- **dol:** This folder contains state UI replacement rates calculated by the Department of Labor (https://oui.doleta.gov/unemploy/ui_replacement_rates.asp; accessed June 16, 2020)
- **google:** This folder contains the Google Mobility Report (https://www.google.com/covid19/mobility/; accessed May 21, 2020)
- **kong-prinze:** This folder contains the business closure dates as reported in Kong and Prinz (2020), hand-coded September 9, 2020)
- **nytimes:** This folder contains reported county-level SAH order dates as reported by the *New York Times*. (https://www.nytimes.com/interactive/2020/us/coronavirus-stay-at-home-order.html; accessed various dates using [Wayback Machine](https://archive.org/web/)). This folder also contains presidential vote shares by state (https://www.nytimes.com/elections/2016/results/president; accessed and hand-coded June 17, 2020)
- **opportunitylab:** This folder contains data from the *Opportunity Insights Economic Tracker* (https://github.com/OpportunityInsights/EconomicTracker; downloaded September 4, 2020)
- **stata:** This folder contains intermediate files created when running `run_all.do`
- **usaFacts:** This folder contains confirmed daily, county-level COVID-19 cases (https://usafacts.org/visualizations/coronavirus-covid-19-spread-map/; accessed and downloaded June 5, 2020)
- **WAH_DingelNeiman:** This folder contains the Dingel and Neiman (2020) work at home index, hand-coded April 17, 2020

