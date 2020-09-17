* -------------------------------------
* Calculate Aggregate Implied UI Claims
* -------------------------------------
use "../../data/stata/state_build.dta", clear

local if_table_1 "if daten == td(4Apr2020)"
local depvar_CX "cum_claims_to_emp"

reg `depvar_CX' SAH_cumexp ///
  confirm_to_1k middle_to_1k ///
  wah replacementrate ///
  `if_table_1', robust

local coeff = _b[SAH_cumexp]

total annual_avg_emplvl `if_table_1'

local tot_emp = _b[annual_avg_emplvl]

// California Claims over 3 weeks (Friedson et. al. (2020) comparison)
total annual_avg_emplvl `if_table_1' & state_name == "CALIFORNIA"
local CA_emp = _b[annual_avg_emplvl]

local fried_case_save = 152443
di "California Claims over 3 weeks / (`fried_case_save' fewer cases)"
di %15.2gc (`coeff' * `CA_emp' * 3)/(`fried_case_save')

// Calculate implied UI claims increase between March 14 and April 4
egen meanSAH_cumexp = mean(SAH_cumexp) `if_table_1'
gen UI_claims_apr4 = `coeff' * annual_avg_emplvl * SAH_cumexp `if_table_1'
total UI_claims_apr4*

// Calculate implied UI Claims thru April 25 Share
// Adjust for reopenings as reported by NY Times
replace SAH_cumexp = SAH_cumexp - (6/7) if state_abbrev == "SC" ///
                                        & daten == td(25Apr2020)
replace SAH_cumexp = SAH_cumexp - (1/7) if state_abbrev == "OK" ///
                                        & daten == td(25Apr2020) 
replace SAH_cumexp = SAH_cumexp - (1/7) if state_abbrev == "AK" ///
                                        & daten == td(25Apr2020)  
replace SAH_cumexp = SAH_cumexp - (1/7) if state_abbrev == "GA" ///
                                        & daten == td(25Apr2020)  

gen UI_claims_apr25 = `coeff' * annual_avg_emplvl * SAH_cumexp ///
                      if daten == td(25Apr2020)
total UI_claims_apr25

