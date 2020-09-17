*****************************************************************************
* This file merges together all the State-Week datasets for analysis
*****************************************************************************
version 14.2
set more off

*----------------------------------------------------------------------------
* Step 1: Read in UI Claims and Merge with other datasets (assuming all
*         datasets are aligned with week ending for UI claims)
*----------------------------------------------------------------------------
use "../../data/stata/state_ICLAIMS.dta", clear
// Keep Jan 1 onward
keep if daten > td(1Jan2020)
order state_fips daten
sort state_fips daten

// Merge
// 1:1 Matches
merge 1:1 state_fips daten using ../../data/stata/state_SAH_exp, nogenerate

merge 1:1 state_fips daten using "../../data/stata/state_c19_confirmed.dta", ///
          keep(master match) nogenerate

merge 1:1 state_fips daten using "../../data/stata/excess", nogenerate

// m:1 matches
merge m:1 state_fips using "../../data/stata/state_emp2018", nogenerate
merge m:1 state_fips using "../../data/stata/state_bartik_ctrl.dta", nogenerate
merge m:1 state_fips using "../../data/stata/state_census_pop.dta", ///
          nogenerate keep(master match)
merge m:1 state_fips using "../../data/stata/state_census_agesex.dta", ///
          nogenerate keep(master match)
merge m:1 state_fips using "../../data/stata/state_replacementrates.dta", nogenerate
merge m:1 state_fips using "../../data/stata/state_repshare2016", nogenerate

rename state_fips state
merge m:1 state using "../../data/stata/WAH_state_industry.dta", ///
          nogenerate keep(master match)
rename state state_fips

*----------------------------------------------------------------------------
* Step 2: Create Regression Variables
*----------------------------------------------------------------------------
// Replace exposure to be zero if missing
qui ds SAH_*
foreach var in `r(varlist)' {
    replace `var' = 0 if missing(`var')
}

replace confirmed = 0 if missing(confirmed)

// Claims and Covid to Employment
gen claims_to_emp = ICLAIMS/annual_avg_emplvl
gen confirm_to_1k = confirmed/(census2010pop/1000)

// Generate Cumulative claims from Mar 21 onward
gen after_mar21_idx = (daten >= td(21Mar2020))
gen ICLAIMS_mar21 	= after_mar21_idx*ICLAIMS

bysort state_fips (daten): gen num_wks_after_mar21 = sum(after_mar21_idx)
bysort state_fips (daten): gen cum_claims_mar21 = sum(ICLAIMS_mar21)

gen cum_claims_to_emp = cum_claims_mar21/annual_avg_emplvl
gen avg_claims_to_emp = cum_claims_mar21 ///
                      / (num_wks_after_mar21*annual_avg_emplvl)

gen middle = (lower+upper)/2
gen lower_to_1k = lower/(census2010pop/1000)
gen upper_to_1k = upper/(census2010pop/1000)
gen middle_to_1k = middle/(census2010pop/1000)

*----------------------------------------------------------------------------
* Step 3: Save the build file
*----------------------------------------------------------------------------
// Add in the stata states
statastates, fips(state_fips) nogenerate

save "../../data/stata/state_build.dta", replace
