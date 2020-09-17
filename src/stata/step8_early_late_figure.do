*****************************************************************************
* This Estimates the State Level Regressions and County Level Event Stuides
*****************************************************************************
version 14.2
set more off
est clear


use "../../data/stata/state_build.dta", clear

* Early Adopter
bysort state_fips: egen early = total(SAH_cumexp/(daten==td(4apr2020)))
xtile early2 = early, nquantiles(4)
keep if early2==1 | early2==4

* Demean
bysort state_fips: egen mean_post = mean(claims_to_emp/(daten<td(14mar2020)))
gen claims_to_emp_demean = claims_to_emp

* Zeros' for Graph
replace SAH_cumexp = 0 if missing(SAH_cumexp)

* Reshape for Figure
keep state_fips daten claims_to_emp_demean early2
reshape wide claims_to_emp_demean, i(state_fips daten) j(early)

* Label Values for Figure
g sdate=string(daten,"%tdmd")
labmask daten, values(sdate)								

// Graph
set scheme s2mono 
gr box claims_to_emp_demean4 claims_to_emp_demean1 /// 
          if daten>=td(14mar2020) & daten<=td(4apr2020), over(daten) nooutsides /// 
          legend(label(1 "Early Adopter") label(2 "Late Adopter") title("As of April 4")) note("") ///
          ytitle("Unemployment Claims Relative to Employment") ///
          box(1, fcolor(gray) lcolor(black)) box(2, fcolor(black) lcolor(gs12)) graphregion(color(white))

gr export "../../output/plots/early_late.pdf", replace 
