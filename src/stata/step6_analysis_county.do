
*****************************************************************************
* This file estimates the county-level specifications
*****************************************************************************
version 14.2
set more off
est clear
// County - CZ Crosswalk
import excel "../../data/CZ/cz00_eqv_v1.xls", sheet("CZ00_Equiv") firstrow clear

destring FIPS, replace force
rename (FIPS CommutingZoneID2000) (countyfips CZ2000)
tempfile cz_county
save `cz_county'
*----------------------------------------------------------------------------
* Step 1: March and April employment levels
*----------------------------------------------------------------------------
use "../../data/stata/county_build" if datem==tm(2020m4), clear

local depvar_CX "ln_emp_ld"
local if_table_1 "if datem == tm(2020m4)"

bysort state_fips: egen sd_SAH = sd(SAH)
replace sd_SAH =0 if missing(sd_SAH) // 1-County States

// Merge with CZ Crosswalk
gen countyfips = state_fips*1000 + county_fips
merge m:1 countyfips using `cz_county'

bysort CZ2000: egen sd_SAHCZ = sd(SAH)
replace sd_SAHCZ =0 if missing(sd_SAHCZ) // 1-County CZs
*----------------------------------------------------------------------------
* Step 2: Bring in SAH Order dates, calculate days of exposure
*----------------------------------------------------------------------------
// Bivariate
local depvar_CX "ln_emp_ld"

reg `depvar_CX' SAH `if_table_1', 	vce(cluster state_fips)
	eststo county_mod0
	estadd local "StateFE" "No"
	estadd local "CZFE" "No"
	unique state_fips if e(sample)
	estadd scalar "States"=`r(sum)'
	summ `depvar_CX' if e(sample)
	estadd scalar "MeanDep" = `r(mean)'

areg `depvar_CX' SAH `if_table_1' & sd_SAH>0.01, vce(cluster state_fips) absorb(state_fips)
	eststo county_mod1
	estadd local "StateFE" "Yes"
	estadd local "CZFE" "No"
	unique state_fips if e(sample)
	estadd scalar "States"=`r(sum)'
	summ `depvar_CX' if e(sample)
	estadd scalar "MeanDep" = `r(mean)'

areg `depvar_CX' SAH confirm_to_1k wah `if_table_1' & sd_SAH>0.01, 	vce(cluster state_fips) absorb(state_fips)
    eststo county_mod2
    estadd local "StateFE" "Yes"
	estadd local "CZFE" "No"
    unique state_fips if e(sample)
	estadd scalar "States"=`r(sum)'
	summ `depvar_CX' if e(sample)
	estadd scalar "MeanDep" = `r(mean)'
summ `depvar_CX' if e(sample)

reghdfe `depvar_CX' SAH confirm_to_1k wah `if_table_1' & sd_SAH>0.01 & sd_SAHCZ > .01, 	vce(cluster state_fips) absorb(state_fips CZ2000)
    eststo county_mod3
    estadd local "StateFE" "Yes"
	estadd local "CZFE" "Yes"
    unique state_fips if e(sample)
	estadd scalar "States"=`r(sum)'
	summ `depvar_CX' if e(sample)
	estadd scalar "MeanDep" = `r(mean)'

local depvar_CX "ur_ld"

reg `depvar_CX' SAH `if_table_1', vce(cluster state_fips)
	eststo county_mod4
	estadd local "StateFE" "No"
	estadd local "CZFE" "No"
	unique state_fips if e(sample)
	estadd scalar "States"=`r(sum)'
	summ `depvar_CX' if e(sample)
	estadd scalar "MeanDep" = `r(mean)'

areg `depvar_CX' SAH `if_table_1' & sd_SAH>0.01, vce(cluster state_fips) absorb(state_fips)
	eststo county_mod5
    estadd local "StateFE" "Yes"
	estadd local "CZFE" "No"
    unique state_fips if e(sample)
	estadd scalar "States" = `r(sum)'
	summ `depvar_CX' if e(sample)
	estadd scalar "MeanDep" = `r(mean)'
areg `depvar_CX' SAH confirm_to_1k wah `if_table_1' & sd_SAH>0.01, 	vce(cluster state_fips) absorb(state_fips)
    eststo county_mod6
    estadd local "StateFE" "Yes"
	estadd local "CZFE" "No"
    unique state_fips if e(sample)
	estadd scalar "States"=`r(sum)'
	summ `depvar_CX' if e(sample)
	estadd scalar "MeanDep" = `r(mean)'

reghdfe `depvar_CX' SAH confirm_to_1k wah `if_table_1' & sd_SAH>0.01 & sd_SAHCZ > .01, 	vce(cluster state_fips) absorb(state_fips CZ2000)
    eststo county_mod7
    estadd local "StateFE" "Yes"
	estadd local "CZFE" "Yes"
    unique state_fips if e(sample)
	estadd scalar "States"=`r(sum)'
	summ `depvar_CX' if e(sample)
	estadd scalar "MeanDep" = `r(mean)'

esttab county_mod0 county_mod1 county_mod2 county_mod3 ///
       using "../../output/tables/tab4_emp.tex", ///
       varlabel(SAH "SAH Exposure thru Apr. 15" ///
       			confirm_to_1k "Covid-19 Cases per 1K Emp" ///
				wah "Work at Home Index" ///
                _cons "Constant") ///
       stats(MeanDep States StateFE CZFE r2_a N, fmt(2 2 0 2 2) labels("Dep Mean" "States" "State FE" "CZ FE" "Adj. R-Square" "No. Obs.") ) tex ///
       star(+ 0.10 ** 0.05 *** 0.01) replace mlabels("$\Delta \ln Emp$" "$\Delta \ln Emp$" "$\Delta \ln Emp$" "$\Delta \ln Emp$" "$\Delta UR$" "$\Delta UR$" "$\Delta UR$") se nonotes

esttab county_mod4 county_mod5 county_mod6 county_mod7 ///
       using "../../output/tables/tab4_ur.tex", ///
       varlabel(SAH "SAH Exposure thru Apr. 15" ///
       			confirm_to_1k "Covid-19 Cases per 1K Emp" ///
				wah "Work at Home Index" ///
                _cons "Constant") ///
       stats(MeanDep States StateFE CZFE r2_a N, fmt(2 2 0 2 2) labels("Dep Mean" "States" "State FE" "CZ FE" "Adj. R-Square" "No. Obs.") ) tex ///
       star(+ 0.10 ** 0.05 *** 0.01) replace mlabels("$\Delta UR$" "$\Delta UR$" "$\Delta UR$" "$\Delta UR$") se nonotes

