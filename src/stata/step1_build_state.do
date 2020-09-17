*****************************************************************************
* This file builds a State-Week datasets for estimating the impact of
* Stay-at-Home Policies on UI Claims
*****************************************************************************
version 14.2
set more off

* Local of state abreviations useful for downloading FRED data
local all_states = "AK AL AR AZ CA CO CT DC DE FL GA HI IA ID IL IN " + ///
                   "KS KY LA MA MD ME MI MN MO MS MT NC ND NE NH NJ " + ///
                   "NM NV NY OH OK OR PA PRI RI SC SD TN TX UT VA " + ///
                   "VIR VT WA WI WV WY"

*----------------------------------------------------------------------------
* Step 1: Download FRED UI Claims data
*         These data were queried on June 17, 2020
*----------------------------------------------------------------------------
if 1 == 0{
local claims_series = ""
foreach st_abr in `all_states' {
    local claims_series "`claims_series' `st_abr'ICLAIMS"
}

capture clear
freduse `claims_series'

// Drop date string and reshape
drop date

qui ds *ICLAIMS

// Rename variables to be amenable to reshaping
foreach var in `r(varlist)' {
    local st = subinstr("`var'","ICLAIMS","",. )
    local new_name = "ICLAIMS" + "`st'"
    qui rename `var' `new_name'
}

// Reshape

reshape long ICLAIMS, i(daten) j(state_abrev) string
sort state_abrev daten

statastates, abbreviation(state_abrev) nogenerate
keep if ~missing(state_fips)
keep state_fips daten ICLAIMS

// Save to a stata file
save "../../data/stata/state_ICLAIMS.dta", replace
}
*----------------------------------------------------------------------------
* Step 2A: Stay at Home Dates by County
*          Hand-coded based on data reported at https://www.nytimes.com/interactive/2020/us/coronavirus-stay-at-home-order.html
*          (Note: We used the Wayback Machine to capture early reporting
*                 on substate timing of SAH orders)
*----------------------------------------------------------------------------
import delimited "../../data/nytimes/county-shelter-in-place.csv", ///
       encoding(UTF-8) clear

gen countyfips = state*1000 + county

gen SAH_date = date(shelter_date, "MD20Y")
format SAH_date %td

keep countyfips SAH_date state stname ctyname

save "../../data/stata/county_SAH.dta", replace

*----------------------------------------------------------------------------
* Step 2B: Employment by County from QCEW (file created with QCEW.ipynb)
*          and Merge with county SAH
*----------------------------------------------------------------------------
// First, create first Covid Case at County Level
import delimited "../../data/usaFacts/confirmed_county_covid.csv", ///
       encoding(UTF-8) clear

drop if countyfips < 1000
keep countyfips statefips confirmed_*
reshape long confirmed_, i(countyfips) j(date_str) string
replace date_str = subinstr(date_str,"_","/",.)
gen daten = date(date_str,"MD20Y")
format daten %td

drop if confirmed ==0
bysort countyfips (daten): keep if _n == 1

keep countyfips daten
rename daten first_covid_date
tempfile first_covid_county
save `first_covid_county'

import delimited "../../data/bls/county_qcew_emp.csv", encoding(UTF-8) clear

keep countyfips annual_avg_emplvl

tempfile qcew_county_emp
save `qcew_county_emp'

// Merge with county SAH orders
merge 1:1 countyfips using "../../data/stata/county_SAH.dta"
keep if _merge == 3
drop _merge stname ctyname

bysort state: egen tot_emp = total(annual_avg_emplvl)
gen emp_wgt = annual_avg_emplvl/tot_emp

// Merge with first Covid Date
merge 1:1 countyfips using `first_covid_county'
keep if _merge == 3 | _merge == 1
drop _merge

// Create weeks
local start_date = date("03/21/2020", "MDY")
local nweeks = 15
forvalues i = 1(1)`nweeks'{
    gen daten`i' = `start_date' + 7*(`i'-1)
    format daten`i' %td
}

// SAH Exposure by County
forvalues i = 1(1)`nweeks'{
    gen SAH_cumexp`i' = (1 + daten`i' - SAH_date)/7
    replace SAH_cumexp`i' = 0 if SAH_cumexp`i' < 0 | missing(SAH_cumexp`i')

    gen covid_cumexp`i' = (1 + daten`i' - first_covid_date)/7
    replace covid_cumexp`i' = 0 if covid_cumexp`i' < 0 | missing(covid_cumexp`i')

    gen SAH_wkexp`i' = SAH_cumexp`i'
    replace SAH_wkexp`i' = 1 if SAH_wkexp`i' > 1
}

// Weight by employment
forvalues i = 1(1)`nweeks'{
    gen SAH_cumexp_wgted`i' = SAH_cumexp`i'*emp_wgt
    gen covid_cumexp_wgted`i' = covid_cumexp`i'*emp_wgt
    gen SAH_wkexp_wgted`i' = SAH_wkexp`i'*emp_wgt
}

// Collapse to state
rename state state_fips
collapse (sum) SAH_cumexp_wgted* SAH_wkexp_wgted* ///
               covid_cumexp_wgted* annual_avg_emplvl, by(state_fips)

reshape long SAH_cumexp_wgted SAH_wkexp_wgted ///
             covid_cumexp_wgted, i(state_fips) j(week_num)

gen daten = `start_date' + 7*(week_num - 1)
format daten %td

// Export State-Week Exposure
preserve

keep state_fips daten SAH_cumexp_wgted ///
     SAH_wkexp_wgted covid_cumexp_wgted

rename (SAH_cumexp_wgted SAH_wkexp_wgted ///
        covid_cumexp_wgted) ///
       (SAH_cumexp SAH_wkexp ///
        covid_cumexp)

// Save to a stata file
save "../../data/stata/state_SAH_exp.dta", replace
restore

// Export State Employment
keep state_fips annual_avg_emplvl
duplicates drop

save "../../data/stata/state_emp2018.dta", replace

*----------------------------------------------------------------------------
* Step 2C: County-level Google Mobility Data
*          and Merge with county SAH
*----------------------------------------------------------------------------
import delimited "../../data/google/Global_Mobility_Report.csv", clear

keep if country_region=="United States"
ren sub_region_1 stname
ren sub_region_2 ctyname
replace ctyname = "District of Columbia" if stname=="District of Columbia"
keep if !missing(ctyname)

// Make County Names congruent with SAH data
replace ctyname = "Anchorage Municipality" if ctyname=="Anchorage" & stname=="Alaska"
replace ctyname = "Bethel Census Area" if ctyname=="Bethel" & stname=="Alaska"
replace ctyname = "Fairbanks North Star Borough" if ctyname=="Fairbanks North Star" & stname=="Alaska"
replace ctyname = "Juneau City and Borough" if ctyname=="Juneau" & stname=="Alaska"
replace ctyname = "Ketchikan Gateway Borough" if ctyname=="Ketchikan Gateway" & stname=="Alaska"
replace ctyname = "Matanuska-Susitna Borough" if ctyname=="Matanuska-Susitna" & stname=="Alaska"
replace ctyname = "North Slope Borough" if ctyname=="North Slope" & stname=="Alaska"
replace ctyname = "Sitka City and Borough" if ctyname=="Sitka" & stname=="Alaska"
replace ctyname = "Southeast Fairbanks Census Area" if ctyname=="Southeast Fairbanks" & stname=="Alaska"
replace ctyname = "Valdez-Cordova Census Area" if ctyname=="Valdez-Cordova" & stname=="Alaska"
replace ctyname = "LaSalle Parish" if ctyname=="La Salle Parish" & stname=="Louisiana"
replace ctyname = "Baltimore city" if ctyname=="Baltimore" & stname=="Maryland"
replace ctyname = "St. Louis city" if ctyname=="St. Louis" & stname=="Missouri"
replace ctyname = "DoÃ±a Ana County" if ctyname=="DoÒa Ana County" & stname=="New Mexico"
replace ctyname = "Alexandria city" if ctyname=="Alexandria" & stname=="Virginia"
replace ctyname = "Bristol city" if ctyname=="Bristol" & stname=="Virginia"
replace ctyname = "Buena Vista city" if ctyname=="Buena Vista" & stname=="Virginia"
replace ctyname = "Charlottesville city" if ctyname=="Charlottesville" & stname=="Virginia"
replace ctyname = "Chesapeake city" if ctyname=="Chesapeake" & stname=="Virginia"
replace ctyname = "Colonial Heights city" if ctyname=="Colonial Heights" & stname=="Virginia"
replace ctyname = "Covington city" if ctyname=="Covington" & stname=="Virginia"
replace ctyname = "Danville city" if ctyname=="Danville" & stname=="Virginia"
replace ctyname = "Emporia city" if ctyname=="Emporia" & stname=="Virginia"
replace ctyname = "Fairfax city city" if ctyname=="Fairfax city" & stname=="Virginia"
replace ctyname = "Falls Church city" if ctyname=="Falls Church" & stname=="Virginia"
replace ctyname = "Franklin city" if ctyname=="Franklin" & stname=="Virginia"
replace ctyname = "Fredericksburg city" if ctyname=="Fredericksburg" & stname=="Virginia"
replace ctyname = "Galax city" if ctyname=="Galax" & stname=="Virginia"
replace ctyname = "Hampton city" if ctyname=="Hampton" & stname=="Virginia"
replace ctyname = "Harrisonburg city" if ctyname=="Harrisonburg" & stname=="Virginia"
replace ctyname = "Hopewell city" if ctyname=="Hopewell" & stname=="Virginia"
replace ctyname = "Lexington city" if ctyname=="Lexington" & stname=="Virginia"
replace ctyname = "Lynchburg city" if ctyname=="Lynchburg" & stname=="Virginia"
replace ctyname = "Manassas Park city" if ctyname=="Manassas Park" & stname=="Virginia"
replace ctyname = "Martinsville city" if ctyname=="Martinsville" & stname=="Virginia"
replace ctyname = "Newport News city" if ctyname=="Newport News" & stname=="Virginia"
replace ctyname = "Norfolk city" if ctyname=="Norfolk" & stname=="Virginia"
replace ctyname = "Norton city" if ctyname=="Norton" & stname=="Virginia"
replace ctyname = "Petersburg city" if ctyname=="Petersburg" & stname=="Virginia"
replace ctyname = "Poquoson city" if ctyname=="Poquoson" & stname=="Virginia"
replace ctyname = "Portsmouth city" if ctyname=="Portsmouth" & stname=="Virginia"
replace ctyname = "Radford city" if ctyname=="Radford" & stname=="Virginia"
replace ctyname = "Richmond city" if ctyname=="Richmond" & stname=="Virginia"
replace ctyname = "Roanoke city" if ctyname=="Roanoke" & stname=="Virginia"
replace ctyname = "Salem city" if ctyname=="Salem" & stname=="Virginia"
replace ctyname = "Suffolk city" if ctyname=="Suffolk" & stname=="Virginia"
replace ctyname = "Virginia Beach city" if ctyname=="Virginia Beach" & stname=="Virginia"
replace ctyname = "Waynesboro city" if ctyname=="Waynesboro" & stname=="Virginia"
replace ctyname = "Williamsburg city" if ctyname=="Williamsburg" & stname=="Virginia"
replace ctyname = "Winchester city" if ctyname=="Winchester" & stname=="Virginia"

gen daten = mdy(real(substr(date,6,2)),real(substr(date,9,2)),real(substr(date,1,4)))
format daten %td

ren retail_and_recreation_percent_ch mobility_retail
ren workplaces_percent_change_from_b mobility_workplaces

keep daten stname ctyname mobility_*

merge m:1 stname ctyname using "../../data/stata/county_SAH.dta"
keep if _merge==3
drop _merge

save "../../data/stata/county_SAH_mobility.dta", replace

*----------------------------------------------------------------------------
* Step 3: Read in USAFacts Data
*----------------------------------------------------------------------------
import delimited "../../data/usaFacts/confirmed_county_covid.csv", ///
       encoding(UTF-8) clear

drop if countyfips < 1000
keep countyfips statefips confirmed_*
reshape long confirmed_, i(countyfips) j(date_str) string

collapse (sum) confirmed_, by(statefips date_str)

replace date_str = subinstr(date_str,"_","/",.)
gen daten = date(date_str,"MD20Y")
format daten %td

rename (statefips confirmed_) (state_fips confirmed)

keep state_fips daten confirmed

save "../../data/stata/state_c19_confirmed.dta", replace

*----------------------------------------------------------------------------
* Step 4: Bartik Emp
*----------------------------------------------------------------------------
import delimited "../../data/bls/state_bartiks.csv", ///
       encoding(UTF-8) clear

rename state state_fips

save "../../data/stata/state_bartik_ctrl.dta", replace

*----------------------------------------------------------------------------
* Step 5: State Population
*----------------------------------------------------------------------------
import delimited "../../data/census/co-est2019-alldata.csv", encoding(UTF-8) clear
keep if sumlev == 40
drop if state == 0

rename state state_fips
keep state_fips census2010pop

save "../../data/stata/state_census_pop.dta", replace


* State age shares
import delimited using "../../data/census/sc-est2018-agesex-civ.csv", encoding(UTF-8) clear
keep if sumlev==40
drop if state==0 | age==999 | inrange(sex,1,2)

bysort state: egen poptot_agesex = total(estbase2010_civ)
bysort state: egen pop60_agesex = total(estbase2010_civ/(age>=60))
ren state state_fips

keep state_fips pop60_agesex poptot_agesex
duplicates drop
keep state_fips pop60_agesex poptot_agesex
compress

// Share over 60
gen share_over60 = pop60_agesex/poptot_agesex

save "../../data/stata/state_census_agesex.dta", replace

*----------------------------------------------------------------------------
* Step 7: State Replacement Rates
*----------------------------------------------------------------------------
import delimited "../../data/dol/ui-replacement-rates.csv", clear

keep state replacementratio1
ren replacementratio replacementrate
replace state = trim(state)
drop if missing(state) | inlist(state,"US","PR")
statastates, abbreviation(state) nogenerate

keep state_fips replacementrate

save "../../data/stata/state_replacementrates.dta", replace

*----------------------------------------------------------------------------
* Step 8: Excess Deaths
*----------------------------------------------------------------------------
import delimited using "../../data/cdc/Excess_Deaths_Associated_with_COVID-19.csv", clear encoding(UTF-8)

* Date
gen daten = date(weekendingdate,"YMD")
format daten %td

* States
statastates, name(state) nogenerate
drop if missing(state_fips)

* Use
keep if type=="Predicted (weighted)"
keep if outcome=="All causes"

* Panel
xtset state_fips daten
keep if year==2020 & daten >=td(1Jan2020)

rename totalexcesshigherestimatein2020 upper_full
rename totalexcesslowerestimatein2020 lower_full
bysort state_fips (daten): gen lower = sum(excesslowerestimate)
bysort state_fips (daten): gen upper = sum(excesshigherestimate)

keep state_fips daten upper upper_full lower lower_full
save "../../data/stata/excess", replace

*----------------------------------------------------------------------------
* Step 8: Republican Vote Share
*----------------------------------------------------------------------------
import delimited using "../../data/nytimes/election2016.csv", clear

statastates, abbreviation(state) nogenerate
keep state_fips rep
ren rep repshare2016

save "../../data/stata/state_repshare2016", replace

*----------------------------------------------------------------------------
* Step 9: WAH State Index
*----------------------------------------------------------------------------
clear
insheet using "../../data/WAH_DingelNeiman/NAICS_workfromhome.csv"
rename naics naics2
tempfile naics_wfh
save `naics_wfh'

clear
insheet using "../../data/bls/state_emp_ind.csv"
gen naics2=int(naics_code/10)

/* Drop public sector (N/A)*/
drop if naics2==92

egen empl_si = sum(annual_avg_emplvl), by(state naics2)
egen empl_s = sum(annual_avg_emplvl), by(state)

gen empl_weight=empl_si/empl_s

sort state naics2
quietly by state naics2:  gen duplic = cond(_N==1,0,_n)
drop if duplic>1
drop duplic

keep state naics2 empl_weight

merge m:1 naics2 using `naics_wfh'
drop _merge

sort state naics2

gen temp1=empl_weight*teleworkable_manual_emp
gen temp2=empl_weight*teleworkable_emp


egen wah_manual=sum(temp1) ,by(state)
egen wah=sum(temp2),by(state)
drop temp1 temp2

quietly by state:  gen duplic = cond(_N==1,0,_n)
drop if duplic>1
drop duplic

keep state wah_manual wah

save "../../data/stata/WAH_state_industry.dta", replace
