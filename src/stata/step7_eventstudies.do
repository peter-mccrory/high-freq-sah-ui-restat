*----------------------------------------------------------------------------
* Step 3: County Event Studies
*----------------------------------------------------------------------------
// Import Opportunity Insights Data
import delimited ///
       "../../data/opportunitylab/Employment Combined - County - Daily.csv", encoding(ISO-8859-1) clear

keep if emp_combined != .
keep month day year countyfips emp_combined
gen daten = mdy(month,day,year)
format daten %td
tempfile daily_emp_idx
save `daily_emp_idx'

// County - CZ Crosswalk from USDA
import excel "../../data/CZ/cz00_eqv_v1.xls", sheet("CZ00_Equiv") firstrow clear

destring FIPS, replace force
rename (FIPS CommutingZoneID2000) (countyfips CZ2000)
tempfile cz_county
save `cz_county'

// Import google mobility + SAH dates dataset
use "../../data/stata/county_SAH_mobility.dta", clear

rename state state_fips
gen county_fips = countyfips-state_fips*1e3
merge m:1 state_fips county_fips using "../../data/stata/wah_county", assert(match using) keep(match)
drop _merge

// Merge in county emp
merge m:1 state_fips county_fips using "../../data/stata/state_emp2018_county", assert(match using) keep(match)
drop _merge

// Merge in CZ to County
merge m:1 countyfips using `cz_county', keep(master match)
drop _merge

// Merge in Opp. Insights Employment Index
merge 1:1 countyfips daten using `daily_emp_idx'
drop _merge

// SAH Dummy
gen SAH = daten == SAH_date

// Coauthors: Someone want to make the panel balanced?
xtset countyfips daten, daily

// Interpolated
gen mobility_retail_org = mobility_retail
bysort countyfips (daten): carryforward mobility_retail, replace
bysort countyfips: egen interp_idx_retail = max(mobility_retail != mobility_retail_org)

gen mobility_workplaces_org = mobility_workplaces
bysort countyfips (daten): carryforward mobility_workplaces, replace
bysort countyfips: egen interp_idx_work = max(mobility_workplaces != mobility_workplaces_org)

// Taker Dummy
bysort countyfips: egen taker = max(SAH)

egen emp_bins = cut(annual_avg_emplvl), group(15)

// For  unreported regressions, add i.wah_bins#i.daten as additional 
// "absorbing()" argument
egen wah_bins = cut(wah), group(15)
*----------------------------------------------------------------------------
* Step 3: County Event Studies
*----------------------------------------------------------------------------
cd "../../output/plots/"
adopath + "../../src/stata/"

// Event studies appearing in online appendix
eventStudy mobility_workplaces ///
           if daten >= td(15feb2020) & daten <= td(24Apr2020), ///
           eventVar(SAH) leads(21) lags(17) twoway longrun ///
           absorbing(i.countyfips i.emp_bins#i.daten i.CZ2000#i.daten) ///
           rescale keep_lag ///
           graphname(county_SAH_mobility_workplaces) 

eventStudy mobility_retail ///
           if daten >= td(15feb2020) & daten <= td(24Apr2020), ///
           eventVar(SAH) leads(21) lags(17) twoway longrun ///
           absorbing(i.countyfips i.emp_bins#i.daten i.CZ2000#i.daten) ///
           rescale keep_lag ///
           graphname(county_SAH_mobility_retail)

// Retail Mobility More Robust in General
// Check robust to non-interpolation
eventStudy mobility_retail ///
           if daten >= td(15feb2020) & daten <= td(24Apr2020) & interp_idx_retail == 0, ///
           eventVar(SAH) leads(21) lags(17) twoway longrun

// Check exclude never takers
eventStudy mobility_retail ///
           if daten >= td(15feb2020) & daten <= td(24Apr2020) ///
              & taker == 1, ///
           eventVar(SAH) leads(8) lags(17) twoway longrun

// Check State#Time FEs (slight pre-trend)
eventStudy mobility_retail ///
           if daten >= td(15feb2020) & daten <= td(24Apr2020), ///
           eventVar(SAH) leads(21) lags(17) twoway longrun absorbing(i.countyfips i.state#i.daten)

// Employment Index
eventStudy emp_combined ///
           if daten >= td(15feb2020) & daten <= td(24Apr2020), ///
           eventVar(SAH) leads(21) lags(17) twoway longrun absorbing(i.countyfips i.state#i.daten) rescale keep_lag ///
           graphname(county_emp_idx) 

// Check that event study with CZ-by-time FEs is cool (which it is)
eventStudy emp_combined ///
           if daten >= td(15feb2020) & daten <= td(24Apr2020), ///
           eventVar(SAH) leads(21) lags(17) twoway longrun absorbing(i.countyfips i.CZ2000#i.daten) rescale keep_lag
		   
cd "../../src/stata"

