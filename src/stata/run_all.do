*****************************************************************************
* Run all empirical analysis for
* "Unemployment Effects of Stay-at-Home Orders: 
*  Evidence from High Frequency Claims Data"
*
* By ChaeWon Baek, Peter B. McCrory, Todd Messer, and Preston Mui
*
* This script should be run from within the ./src/stata/ directory. Depending
* upon your installation of Stata, you may need to install additional packages
* (e.g. reghdfe, labutil, unique)
* 
*
* (Note: Figures 1-4 are created in a Jupyter Notebook with Python 3
*        kernel located at ./src/python/Make-Plots.ipynb. Figure 5
*        is created using Dynare and Matlab with code available at 
*        ./src/matlab/baseline.mod)
*****************************************************************************
version 14.2
set more off

do step1_build_state
do step2_build_county
do step3_merge_state
do step4_merge_county
do step5_analysis_main
do step6_analysis_county
do step7_eventstudies
do step8_early_late_figure
do step9_rel-implied-agg
