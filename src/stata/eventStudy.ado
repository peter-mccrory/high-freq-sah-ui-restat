program define eventStudy,
	version 14.2
	syntax varlist [if], eventVar(string) [lags(int 4) leads(int 4) controls(string) title(string) subtitle(string) ytitle(string) xtitle(string) graphname(string) selevel(int 95) addnote(string) twoway absorbing(string) longrun rescale clusterext(varname) norm(int 1) vert_event keep_lag]
	set scheme s2mono
	marksample touse

	tempvar t_of_event_first t_of_event_last dummylower dummyupper

	disp "eventStudy.ado from ./src/"
	* Check that the data is set.
	qui xtset
	local time_var = r(timevar)
	local panel_var = r(panelvar)

	local lowerBin = `leads' + 1
	local upperBin = `lags' + 1

	qui bysort `panel_var': egen `t_of_event_first' = min(`time_var'/(`eventVar'==1))
	qui gen `dummylower' = `time_var' <= (`t_of_event_first'-`lowerBin') & !missing(`t_of_event_first')
	qui replace `dummylower' = 0 if missing(`dummylower')

	qui bysort `panel_var': egen `t_of_event_last' = max(`time_var'/(`eventVar'==1))
	qui gen `dummyupper' = `time_var' >= (`t_of_event_last'+`upperBin') & !missing(`t_of_event_last')
	qui replace `dummyupper' = 0 if missing(`dummyupper')

	qui forvalues x=1/`leads'{
		gen F`x'`eventVar' = F`x'.`eventVar'
		* Fixes issues with creating leads for events happening early in the sample
		replace F`x'`eventVar' = 0 if F`x'`eventVar' ==.
	}
	qui forvalues x=0/`lags'{
		gen L`x'`eventVar' = L`x'.`eventVar'
		* Fixes issues with creating lags for events happening late in the sample
		replace L`x'`eventVar' = 0 if L`x'`eventVar' ==.
	}

	if "`twoway'"=="twoway" {
		local clusterext = "`time_var'"
		local clustertext = "SE Clustered by `panel_var' and `time_var'"
	}
	else {
		local clustertext = "SE Clustered by `panel_var'"
	}
	if "`absorbing'"=="" {
		local absorbing = "`panel_var' `time_var'"
	}

	if "`longrun'"=="longrun" {
		local longrun_vars = "`dummylower' `dummyupper'"
		if "`keep_lag'" == ""{
			drop F`norm'`eventVar'
		}
	}

	reghdfe `varlist' L*`eventVar' F*`eventVar' `longrun_vars' `controls' if `touse', absorb(`absorbing') vce(cluster `panel_var' `clusterext')
	disp "`e(cmdline)'"

	drop L*`eventVar' F*`eventVar'

	*Normalize year t-1
	qui forval f = 1/`leads'{
		if "`rescale'" == "rescale"{
			local nlc ///
			"`nlc' (B`f': _b[F`f'`eventVar'] - _b[F`norm'`eventVar'])"
		}
		else{
			if `f'==`norm' & "`longrun'" == "longrun" & "`keep_lag'" == ""{
				continue
			}
			local nlc "`nlc' (B`f': _b[F`f'`eventVar'])"
		}
	}
	qui forval l = 0/ `lags'{
		if "`rescale'" == "rescale"{
			local nlc ///
			"`nlc' (A`l': _b[L`l'`eventVar'] - _b[F`norm'`eventVar'])"
		}
		else{
			local nlc "`nlc' (A`l': _b[L`l'`eventVar'])"
		}
	}

	quietly nlcom `nlc', post level(`selevel')


	preserve
		parmest, norestore level(`selevel')
		gen t = substr(parm,2,.)

		destring t, replace
		replace t = -t if substr(parm,1,1) =="B"
		sort t
		disp "`longrun'"

		if "`longrun'"=="longrun" {
			expand 2 if t==0
			replace t = -`norm' if _n==_N
			replace min`selevel' = 0 if _n==_N
			replace max`selevel' = 0 if _n==_N
			replace estimate = 0 if _n==_N
		}

		gsort t

		if "`vert_event'" != "" ///
		   local xline_cd = "xline(0,lcolor(black) lpattern(dash))"

		local xlow = -5*floor(`leads'/5)
		local xhi  = 5*floor(`lags'/5)



		* Graph
		if "`ytitle'"=="" local ytitle = "Relative to t-1"
		graph twoway (connected estimate t) (line min`selevel' t) (line max`selevel' t), title("`title'") ytitle("`ytitle'" " ") xtitle("`xtitle'") subtitle("`subtitle'") name("`varlist'_`eventVar'", replace) legend(order(2 3)) ///
		`xline_cd' xlabel(`xlow'(5)`xhi')
		if "`graphname'"~="" graph export "`graphname'.png", replace

	restore

end
