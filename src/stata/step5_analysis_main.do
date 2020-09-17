*****************************************************************************
* This file estimates the main state-level specification, as well as 
* the panel specification and robustness specifications appearing in the
* online appendix.
*****************************************************************************
version 14.2
set more off
est clear

// Pre SAH Employment Changes
import delimited "../../data/opportunitylab/Affinity - State - Daily.csv", ///
       clear 

keep if month == 3 & (day == 14 | day == 7)
keep statefips spend_all month day
bysort statefips (month day): gen spend_all_diff = spend_all ///
                                                 - spend_all[_n-1]
drop if spend_all_diff == .
rename statefips state_fips
tempfile state_spend_thru_mar14
save `state_spend_thru_mar14'

// Add in the State-level Business Closure Robustness
import delimited "../../data/kong-prinz/biz-closures.csv", ///
       encoding(ISO-8859-1) clear 

rename (v1 v2) (state_abbrev biz_close_dt)
statastates, abbreviation(state_abbrev) nogenerate

// Generate Difference Between business closure date and April 3
gen biz_close_date = date(biz_close_dt, "MD20Y")
format biz_close_date %td

gen biz_close_exp = (td(4Apr2020) - biz_close_date + 1)/7
replace biz_close_exp = 0 if missing(biz_close_exp)
tempfile biz_close_dates
save `biz_close_dates'

use "../../data/stata/state_build.dta", clear

merge m:1 state_fips using `state_spend_thru_mar14'
drop _merge

merge m:1 state_fips using `biz_close_dates'
drop _merge

gen max_sah_biz_exp = max(SAH_cumexp,biz_close_exp)

*----------------------------------------------------------------------------
* Step 1: Cross-Sectional Regressions
*----------------------------------------------------------------------------
local if_table_1 "if daten == td(4Apr2020)"
local if_table_2wk "if daten == td(28Mar2020)"
local if_table_4wk "if daten == td(11Apr2020)"
local weight_var "annual_avg_emplvl"
local depvar_CX "cum_claims_to_emp"

* TABLE 1: Benchmark

gen week = wofd(daten)
xtset state_fips week
// Bivariate
reg `depvar_CX' SAH_cumexp ///
  `if_table_1', robust
  eststo tab1_mod0

// + Controls for Covid
reg `depvar_CX' SAH_cumexp ///
  confirm_to_1k middle_to_1k share_over60 ///
  `if_table_1', robust
  eststo tab1_mod1

// + Controls for Political Economy
reg `depvar_CX' SAH_cumexp ///
  replacementrate repshare2016 ///
  `if_table_1', robust
  eststo tab1_mod2

// + Controls for Sector
reg `depvar_CX' SAH_cumexp ///
  wah emp_diff_times_share ///
  `if_table_1', robust
  eststo tab1_mod3

// Benchmark
reg `depvar_CX' SAH_cumexp ///
  confirm_to_1k middle_to_1k ///
  wah replacementrate ///
  `if_table_1', robust

  eststo tab1_mod4

// ALL (rep_share bins) | Dropping WY or WV
_pctile repshare2016, percentiles(10 90)
gen repub = repshare2016 > r(r2)
gen dem = repshare2016 < r(r1)
reg `depvar_CX' SAH_cumexp ///
                confirm_to_1k middle_to_1k share_over60 ///
                wah replacementrate repub dem emp_diff_times_share ///
                `if_table_1', robust

reg `depvar_CX' SAH_cumexp confirm_to_1k middle_to_1k ///
                share_over60 wah replacementrate repshare2016 ///
                emp_diff_times_share ///
                `if_table_1' ///
                & ~inlist(state_name, "WYOMING", "WEST VIRGINIA"), robust

// Benchmark WAH interaction
egen wah_hi = cut(wah), group(2)
reg `depvar_CX' SAH_cumexp c.SAH_cumexp#i.wah_hi ///
  confirm_to_1k middle_to_1k ///
  wah replacementrate wah_hi ///
  `if_table_1', robust

esttab tab1_mod* ///
       using "../../output/tables/tab1.tex", ///
       varlabel(SAH_cumexp "SAH Exposure thru Apr. 4" ///
                confirm_to_1k "COVID-19 Cases per 1K" ///
                middle_to_1k "Excess Deaths per 1K" ///
                replacementrate "Avg. UI Replacement Rate" ///
                emp_diff_times_share "Bartik-Predicted Job Loss" ///
                wah "Work at Home Index" ///
                share_over60 "Share Age 60+" ///
                repshare2016 "2016 Trump Vote Share" ///
                _cons "Constant") ///
       stats(r2_a N, labels("Adj. R-Square" "No. Obs.")) tex ///
       star(+ 0.10 ** 0.05 *** 0.01) replace ///
       mlabels("Bivariate" "Covid" "Pol. Econ." "Sectoral" "All") se nonotes

* Table 2: Robustness Table
reg `depvar_CX' SAH_cumexp ///
    confirm_to_1k middle_to_1k  wah `if_table_2wk', robust
    est store robust1

// Four Week Horizon
reg `depvar_CX' SAH_cumexp ///
    confirm_to_1k middle_to_1k  wah `if_table_4wk', robust
    est store robust2

// Weighted Benchmark
reg `depvar_CX' SAH_cumexp ///
    confirm_to_1k middle_to_1k  wah `if_table_1' ///
    [aweight = `weight_var'] , robust
    est store robust3

esttab robust* ///
       using "../../output/tables/tab2.tex", ///
       varlabel(SAH_cumexp "SAH Exposure (varied horizons)" ///
                confirm_to_1k "COVID-19 Cases per 1K" ///
                middle_to_1k "Excess Deaths per 1K" ///
                replacementrate "Avg. UI Replacement Rate" ///
                emp_diff_times_share "Bartik-Predicted Job Loss" ///
                wah "Work at Home Index" ///
                share_over60 "60+ Ratio to Total Population" ///
                repshare2016 "2016 Trump Vote Share" ///
                _cons "Constant") ///
       stats(r2_a N, labels("Adj. R-Square" "No. Obs.")) ///
       star(+ 0.10 ** 0.05 *** 0.01) replace ///
       mlabels("Thru Mar. 28" "Thru Apr. 11" "WLS" "All" "All (no WV/WY)") se nonotes

*-------
* Regressions Controlling for Pre-SAH Determinants of Unprecedented Claims:
*    (1) Change in employment index March 7 to March 14 (Worries about
*        pre-trend movements in employment)
*    (2) Max of (SAH_Exposure, Non-Essential Business Closure), which 
*        accounts for discrepancy observed for some states (such as PA)
*-------
// Bivariate
reg `depvar_CX' max_sah_biz spend_all_diff ///
  `if_table_1', robust
  est store preSAH_1

// + Controls for Covid
reg `depvar_CX' max_sah_biz spend_all_diff ///
  confirm_to_1k middle_to_1k share_over60 ///
  `if_table_1', robust
  est store preSAH_2

// + Controls for Political Economy
reg `depvar_CX' max_sah_biz spend_all_diff ///
  replacementrate repshare2016 ///
  `if_table_1', robust
  est store preSAH_3

// + Controls for Sector
reg `depvar_CX' max_sah_biz spend_all_diff ///
  wah emp_diff_times_share ///
  `if_table_1', robust
  est store preSAH_4

// Benchmark
reg `depvar_CX' max_sah_biz spend_all_diff ///
  confirm_to_1k middle_to_1k ///
  wah replacementrate ///
  `if_table_1', robust
  est store preSAH_5

esttab preSAH* ///
      using "../../output/tables/preSAH_tab.tex", ///
      varlabel(max_sah_biz_exp "SAH/Business Closure Exposure" ///
              confirm_to_1k "COVID-19 Cases per 1K" ///
              middle_to_1k "Excess Deaths per 1K" ///
              replacementrate "Avg. UI Replacement Rate" ///
              emp_diff_times_share "Bartik-Predicted Job Loss" ///
              wah "Work at Home Index" ///
              share_over60 "60+ Ratio to Total Population" ///
              repshare2016 "2016 Trump Vote Share" ///
              spend_all_diff "Mar. 7 to Mar. 14 Spending Change" ///
              _cons "Constant") ///
      stats(r2_a N, labels("Adj. R-Square" "No. Obs.")) ///
      star(+ 0.10 ** 0.05 *** 0.01) replace ///
      mlabels("Bivariate" "Covid" "Pol. Econ." "Sectoral" "All") se nonotes

local coeff_biz = _b[max_sah_biz]

qui g UI_claims_apr4_biz = `coeff_biz' * annual_avg_emplvl * max_sah_biz ///
                           `if_table_1'

total UI_claims_apr4_biz
*----------------------------------------------------------------------------
* Step 3: Panel Regressions
*----------------------------------------------------------------------------
// Panel Regression
// State FEs + Week FEs + State-Controls after March 21
// Outcome: Claims to Employment
// Treatment: wgted avg of share of week exposure at time t
eststo panel1: reghdfe claims_to_emp SAH_wkexp ///
      if daten >= td(01Jan2020) & daten <=td(11Apr2020), absorb(week state_fips) vce(cluster state_fips) nocons
estadd local Lags "N"
estadd local StateFE "Y"
estadd local WeekFE "Y"
estadd local postWAH "N"
estadd local postExc "N"
estadd local postCov "N"
estadd local postUI "N"

eststo panel2: reghdfe claims_to_emp L(0/2)SAH_wkexp ///
      if daten >= td(01Jan2020) & daten <=td(11Apr2020), ///
      absorb(week state_fips) vce(cluster state_fips) nocons
estadd local Lags "Y"
estadd local StateFE "Y"
estadd local WeekFE "Y"
estadd local postWAH "N"
estadd local postExc "N"
estadd local postCov "N"
estadd local postUI "N"


eststo panel3: reghdfe claims_to_emp L(0/2)SAH_wkexp ///
      if daten >= td(01Jan2020) & daten <=td(11Apr2020), ///
      absorb(week state_fips after_mar21_idx##c.wah ///
             after_mar21_idx##c.middle_to_1k ///
             after_mar21_idx##c.confirm_to_1k ///
             after_mar21_idx##c.replacementrate) ///
      vce(cluster state_fips) nocons
estadd local Lags "Y"
estadd local StateFE "Y"
estadd local WeekFE "Y"
estadd local postWAH "Y"
estadd local postExc "Y"
estadd local postCov "Y"
estadd local postUI "Y"

eststo panel4: reghdfe claims_to_emp L(0/2)SAH_wkexp ///
      if daten >= td(01Jan2020) & daten <=td(11Apr2020), ///
      absorb(week after_mar21_idx##c.wah ///
             after_mar21_idx##c.middle_to_1k ///
             after_mar21_idx##c.confirm_to_1k ///
             after_mar21_idx##c.replacementrate) ///
      vce(cluster state_fips) nocons
estadd local Lags "Y"
estadd local StateFE "N"
estadd local WeekFE "Y"
estadd local postWAH "Y"
estadd local postExc "Y"
estadd local postCov "Y"
estadd local postUI "Y"

esttab panel* ///
       using "../../output/tables/tab3.tex", ///
       varlabel(SAH_wkexp "SAH Exposure Current Week" ///
                L.SAH_wkexp "SAH Exposure First Lag" ///
                L2.SAH_wkexp "SAH Exposure Second Lag") ///
       stats(StateFE WeekFE postWAH postExc postCov postUI r2_a N, ///
             labels("State FE" "Week FE" ///
                    "Post-March 21 X Work at Home Index" ///
                    "Post-March 21 X Excess Deaths per 1K" ///
                    "Post-March 21 X COVID-19 Cases per 1K" ///
                    "Post-March 21 X Avg. UI Replacement Rate" ///
                    "Adj. R-Square" "No. Obs.")) tex ///
       star(+ 0.10 ** 0.05 *** 0.01) replace mlabels(none) se nonotes

