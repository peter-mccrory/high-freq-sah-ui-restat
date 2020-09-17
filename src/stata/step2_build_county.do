*****************************************************************************
* This file builds a County-Month dataset for estimating the impact of
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
* Step 1: LAU Data
*----------------------------------------------------------------------------
import delimited "../../data/bls/lau.csv", clear

* Dates
gen datem = mofd(date(date,"YMD"))
format datem %tm
drop date

* Destring
destring lf emp unemp ur, replace ignore("- ,")

* Save
compress
save "../../data/stata/lau_county", replace

*----------------------------------------------------------------------------
* Step 2: SAH Data
*----------------------------------------------------------------------------
import delimited "../../data/nytimes/county-shelter-in-place.csv", ///
       encoding(UTF-8) clear
rename state state_fips
rename county county_fips

* Date
gen daten = date(shelter_date,"MD20Y")
format daten %td
drop shelter_date
rename daten SAH_date

* Save
compress
save "../../data/stata/sah_county", replace

*----------------------------------------------------------------------------
* Step 3: County QCEW Employment Data
*----------------------------------------------------------------------------

import delimited "../../data/bls/county_qcew_emp.csv", encoding(UTF-8) clear

keep countyfips annual_avg_emplvl
gen state_fips = floor(countyfips/1000)
gen county_fips = countyfips - state_fips*1000
drop countyfips


save "../../data/stata/state_emp2018_county.dta", replace
*----------------------------------------------------------------------------
* Step 3: Covid Data
*----------------------------------------------------------------------------
import delimited "../../data/usafacts/confirmed_county_covid.csv", ///
       clear encoding(UTF-8)
	   
drop if countyfips < 1000
keep countyfips statefips confirmed_*
reshape long confirmed_, i(countyfips) j(date_str) string
replace date_str = subinstr(date_str,"_","/",.)
gen daten = date(date_str,"MD20Y")
format daten %td

gen county_fips = countyfips - statefips*1e3
rename statefips state_fips

save "../../data/stata/covid_county_week", replace

gen datem = mofd(daten+15) // Add 15 days so that dates align with CPS months
format datem %tm
collapse (sum) confirmed_, by(state_fips county_fips datem)

compress
save "../../data/stata/covid_county", replace

*----------------------------------------------------------------------------
* Step 4: County-Level WAH Index
*----------------------------------------------------------------------------
* Dingel-Neiman Work from Home Index by 2-digit NAICS
import delimited using "../../data/WAH_DingelNeiman/NAICS_workfromhome.csv", clear varnames(1)
	keep naics teleworkable_emp
	tostring naics, replace

	replace naics = "31-33" if naics=="31"
	drop if naics=="32" | naics=="33"
	replace naics = "44-45" if naics=="44"
	drop if naics=="45"
	replace naics = "48-49" if naics=="48"
	drop if naics=="49"
save "../../data/stata/wah_naics", replace

use "../../data/bls/county_qcew_subset", clear

	ren annual_avg_emplvl empl
	ren annual_avg_estabs estabs
	gen censored = disclosure_code=="N"

	tempfile qcew_county
	tempfile qcew_county_ownership

	preserve
		keep if agglvl_code==70
		keep area_fips empl estabs
		ren empl empl_county
		ren estabs estabs_county
		save `qcew_county', replace
	restore

	preserve
		keep if agglvl_code==71
		gen censored_countyown = disclosure_code=="N"
		keep area_fips own_code empl estabs censored_countyown
		ren empl empl_countyown
		ren estabs estabs_countyown
		save `qcew_county_ownership', replace
	restore

	keep if agglvl_code==74
	merge m:1 area_fips using `qcew_county', nogen
	merge m:1 area_fips own_code using `qcew_county_ownership', nogen

	* If not censored at the ownership level, infer censored and non-censored employment from the ownership level
	bys area_fips own_code: egen uncensored_empl_countyown = total(empl) if censored_countyown==0
	gen censored_empl_countyown = empl_countyown - uncensored_empl_countyown if censored_countyown==0
	replace censored_empl_countyown = 0 if censored_empl_countyown < 0 & censored_countyown==0
	replace censored_empl_countyown = empl_countyown if censored_empl_countyown > empl_countyown & censored_countyown==0

	gen temp = estabs if censored & censored_countyown==0
	bys area_fips own_code: egen censored_estabs = total(temp) if censored_countyown==0
	gen share_censored_estabs = temp / censored_estabs if censored_countyown==0
	replace empl = share_censored_estabs * censored_empl_countyown if censored_countyown==0 & censored
	drop uncensored_empl_countyown censored_empl_countyown temp censored_estabs share_censored_estabs

	* If censored at the ownership level,  will need to infer censored and non-censored employment from the county level employment
	by area_fips: egen uncensored_empl_county = total(empl)
	gen censored_empl_county = empl_county - uncensored_empl_county
	replace censored_empl_county = 0 if censored_empl_county < 0

	gen temp = estabs if censored & censored_countyown==1
	by area_fips: egen censored_estabs = total(temp) if censored & censored_countyown==1
	gen share_censored_estabs = temp / censored_estabs if censored & censored_countyown==1
	replace empl = share_censored_estabs * censored_empl_county if censored & censored_countyown==1
	drop censored_countyown uncensored_empl_county censored_empl_county temp censored_estabs share_censored_estabs

	collapse (sum) empl, by(area_fips industry_code)
	ren area_fips county_fips
	ren industry_code naics
	drop if naics=="92" // No match in the Dingel-Neiman Index

	* WAH Index
	merge m:1 naics using "../../data/stata/wah_naics", nogen
	bys county_fips: egen total_empl = total(empl)
	gen share_empl = empl / total_empl
	gen contrib_wah = share_empl * teleworkable_emp
	collapse (sum) wah = contrib_wah, by(county_fips)

	destring county_fips, replace
	gen state_fips = floor(county_fips/1000)
	replace county_fips = county_fips-state_fips*1000
	drop if county_fips==999

	save "../../data/stata/wah_county", replace


