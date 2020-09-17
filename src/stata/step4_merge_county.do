*****************************************************************************
* This file merges together all the State-Week datasets for analysis
*****************************************************************************
version 14.2
set more off

*----------------------------------------------------------------------------
* Step 1: Read in UI Claims and Merge with other datasets (assuming all
*         datasets are aligned with week ending for UI claims)
*----------------------------------------------------------------------------
clear
use "../../data/stata/lau_county"
merge m:1 state_fips county_fips using "../../data/stata/state_emp2018_county", nogenerate keep(match)
merge m:1 state_fips county_fips using "../../data/stata/sah_county", nogenerate keep(match)
merge 1:1 state_fips county_fips datem using "../../data/stata/covid_county", nogenerate keep(match)
merge m:1 state_fips county_fips using "../../data/stata/wah_county", nogenerate keep(match)
save "../../data/stata/county_data", replace

*----------------------------------------------------------------------------
* Step 2: Create Regression Variables
*----------------------------------------------------------------------------
* TREATMENT
gen SAH = (1 + td(15apr2020) - SAH_date)/7
replace SAH = 0 if SAH<0 | missing(SAH)

// Updated confirmed for missing values
replace confirmed = 0 if missing(confirmed)
gen confirm_to_1k = confirmed/(annual_avg_emplvl/1000)

gen ln_emp = ln(emp)

foreach var in ln_emp ur {
	foreach dt in 2020m3 2020m4 {
		bysort state_fips county_fips: egen `var'_`dt' = total(`var'/(datem==tm(`dt')))
	}
	gen `var'_ld = `var'_2020m4 - `var'_2020m3
	drop `var'_????m?
}

*----------------------------------------------------------------------------
* Step 3: Save the analysis file
*----------------------------------------------------------------------------
// Add in the stata states
statastates, fips(state_fips) nogenerate

save "../../data/stata/county_build.dta", replace
