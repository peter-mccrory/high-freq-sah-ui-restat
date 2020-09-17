*****************************************************************************
* This file builds data/bls/county_qcew_subset.dta
* Which is used in step2_build_county.do
* The source of data/2019.annual.singlefile.csv is https://data.bls.gov/cew/data/files/2019/csv/2019_annual_singlefile.zip
*****************************************************************************
* This is separate from the main construction because this file is 
* large and takes time to process.
version 14.2
set more off

import delimited using "2019.annual.singlefile.csv", clear

	keep if inlist(agglvl_code,70,71,74)
	keep area_fips own_code industry_code agglvl_code disclosure_code annual_avg_estabs annual_avg_emplvl

save "county_qcew_subset.dta"
