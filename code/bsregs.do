/**************************************************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
* Main regressions + bootstraps
**************************************************************************************/

local b = `1' 		// pass argument from the shell program to run bootstraps in parallel processing

*forval b = 0/50 {	// alternately, run the bootstraps sequentially in a loop

local seedone = `b'+453
set seed `seedone' 

clear
set more off

*Set directories
global db "/Users/mehmettugsuz/Downloads/The US-China Trade War and Global Reallocations  GTW_replication/"		// Set ROOT directory here
do "$db/code/00_directories.do"

*Log file
cap log close
log using "$logs/regs_`b'.log", replace

*Outcomes and specs
local dlist us ch rw
local felist cs nofe
local speclist P CSQ CSQ_C CSQ_S CSQ_Q

*Tariff globals
global Z4 dlz_usch dlz_chus dlz_usi dlz_chrw
global Z2 dlz_usch dlz_chus

*Loop over countries and sectors (ex-leavout)
use "$processed/rf",clear
qui levels cty_iso3 if cty_iso3!="DEU", local(clist)
qui levels ind9_str if ind9_str!="Agriculture", local(slist)
	
********************************************
*** Regressions (Country)
********************************************

foreach f in `felist' {
	
	local link = "v_`f'"

	*erase files tmp files
	cap erase "$tmp/bs_beta_`link'_bs`b'.dta"
	cap erase "$tmp/bs_yhat_`link'_bs`b'.dta" 


foreach d in `dlist' {

	*create bootstrap sample, shares and tariff interactions
	use "$processed/rf",clear

	*Dummy
	g byte nofe = 1

	*bootstrap sample
	if `b'!=0 bsample, cluster(hs6) //bootstrap cluster

	*Total exports, period 0
	preserve
		collapse (sum) v_`d', by(cty_iso3)
		rename v_`d' totv0_`d'
		tempfile totv0
		save `totv0'
	restore
	merge m:1 cty_iso3 using `totv0', assert(match) nogen

	*weights
	cap drop sw*
	g sw_`d' = vwgt_i_`d'/totv0_`d'
	mvencode sw_`d', mv(0) override

	*country, sector list
	qui levels cty_iso3 if cty_iso3!="DEU", local(clist)
	qui levels ind9_str if ind9_str!="Agriculture", local(slist)


	*create size variables
	*note: some variables are redundant, but they will drop out of the regression
		*beta1
		g Q1a = E_us_lag/E_wd_lag
		g Q1b = v_wd_lag/E_wd_lag
		g Q1c = v_us_lag/E_`d'_lag

		*beta2
		g Q2a = E_ch_lag/E_wd_lag
		g Q2b = v_wd_lag/E_wd_lag
		g Q2c = v_ch_lag/E_`d'_lag

		*beta3
		g Q3a = E_us_lag/E_wd_lag
		g Q3b = v_wd_lag/E_wd_lag
		g Q3c = v_`d'_lag/E_`d'_lag
		g Q3d = v_us_lag/E_us_lag

		*beta4
		g Q4a = E_ch_lag/E_wd_lag
		g Q4b = v_wd_lag/E_wd_lag
		g Q4c = v_`d'_lag/E_`d'_lag
		g Q4d = v_ch_lag/E_ch_lag

		mvencode Q*, mv(0) override //this is just for USA and CHN size vars.

	*tariff interactions
		*country-tariff interactions
		qui foreach c in `clist' {
			foreach z in $Z4 {
				g _c_`z'_`c' = `z' if cty_iso3=="`c'"
				replace _c_`z'_`c' = 0 if mi(_c_`z'_`c')
			}
		}

		*sector-tariff interactions
		qui foreach s in `slist' {
			foreach z in $Z4 {
				g _s_`z'_`s' = `z' if ind9_str=="`s'"
				replace _s_`z'_`s' = 0 if mi(_s_`z'_`s')
			}
		}

		*size-tariff interactions
		*beta1-tariff
		foreach q in a b c {
			g _Q1`q'_usch = Q1`q'*dlz_usch
		}
		*beta2
		foreach q in a b c {
			g _Q2`q'_chus = Q2`q'*dlz_chus
		}
		*beta3
		foreach q in a b c d {
			g _Q3`q'_usi = Q3`q'*dlz_usi
		}
		*beta4
		foreach q in a b c d {
			g _Q4`q'_chrw = Q4`q'*dlz_chrw
		}

	qui compress

	save "$tmp/regs_`link'_`d'_bs`b'", replace

*****************************************************
** REGRESSIONS 
*****************************************************

	*regressions, by destination
	use "$tmp/regs_`link'_`d'_bs`b'",clear

		*****************************************************
		** P: pooled (remove USA/CHN)
		*****************************************************
		 
		est clear
		noi dis "********** P `d' `link' **********"
		reghdfe dlv_`d' $Z4 dlv_`d'_lag mv_v_`d' if !inlist(cty_iso,"USA","CHN"), a(`f') cluster(hs6)
		noi dis "********** P `d' `link' **********"
		g yhatP = 0
		qui foreach z in $Z4 {
			g betaP_`z' = 0
		}

		*yhat, common for all countries
		qui foreach z in $Z4 {
			replace yhatP 		= yhatP + _b[`z']*`z'
			replace betaP_`z' 	= _b[`z']
		}

		*****************************************************
		** CSQ: country-tariff, sector-tariff, size-tariff
		*****************************************************
		
		est clear
		noi dis "********** CSQ `d' `link' **********"
		reghdfe dlv_`d' $Z4 _c_* _s_* Q1* Q2* Q3* Q4* _Q1* _Q2* _Q3* _Q4* dlv_`d'_lag mv_v_`d', a(`f') cluster(hs6)
		noi dis "********** CSQ `d' `link' **********"

		g yhatCSQ_C = 0
		g yhatCSQ_S = 0
		g yhatCSQ_Q = 0

		qui foreach z in $Z4 {
			g betaCSQ_C_`z' 	= 0
			g betaCSQ_S_`z' 	= 0
			g betaCSQ_Q_`z' 	= 0
		}

		**country response
			*for leaveout-country
			qui foreach z in $Z4 {
				replace yhatCSQ_C 		= _b[`z']*`z' + yhatCSQ_C
				replace betaCSQ_C_`z' 	= _b[`z']
			}
			*for remaining countries
			qui foreach c in `clist' {
				foreach z in $Z4 {
					replace yhatCSQ_C 		= _b[_c_`z'_`c']*`z' 	+ yhatCSQ_C 		if cty_iso3=="`c'"
					replace betaCSQ_C_`z' 	= _b[_c_`z'_`c'] 		+ betaCSQ_C_`z'  	if cty_iso3=="`c'"
				}
			}

		*sector response
			qui foreach s in `slist' {
				foreach z in $Z4 {
					replace yhatCSQ_S 		= _b[_s_`z'_`s']*`z' 	+ yhatCSQ_S 		if ind9_str=="`s'"
					replace betaCSQ_S_`z'	= _b[_s_`z'_`s'] 		+ betaCSQ_S_`z' 	if ind9_str=="`s'"
				}
			}

		*size
			*beta1
			foreach q in a b c {
				replace yhatCSQ_Q 				=  _b[_Q1`q'_usch]*Q1`q'*dlz_usch 	+ yhatCSQ_Q
				replace betaCSQ_Q_dlz_usch		=  _b[_Q1`q'_usch]*Q1`q' 			+ betaCSQ_Q_dlz_usch
			}
			*beta2
			foreach q in a b c {
				replace yhatCSQ_Q 				=  _b[_Q2`q'_chus]*Q2`q'*dlz_chus 	+ yhatCSQ_Q
				replace betaCSQ_Q_dlz_chus		=  _b[_Q2`q'_chus]*Q2`q' 			+ betaCSQ_Q_dlz_chus
			}
			*beta3
			foreach q in a b c d {
				replace yhatCSQ_Q 				=  _b[_Q3`q'_usi]*Q3`q'*dlz_usi 	+ yhatCSQ_Q
				replace betaCSQ_Q_dlz_usi		=  _b[_Q3`q'_usi]*Q3`q' 			+ betaCSQ_Q_dlz_usi
			}
			*beta4
			foreach q in a b c d {
				replace yhatCSQ_Q 			=  _b[_Q4`q'_chrw]*Q4`q'*dlz_chrw 		+ yhatCSQ_Q
				replace betaCSQ_Q_dlz_chrw	=  _b[_Q4`q'_chrw]*Q4`q' 				+ betaCSQ_Q_dlz_chrw
			}

			g yhatCSQ = yhatCSQ_C + yhatCSQ_S + yhatCSQ_Q
			qui foreach z in $Z4 {
				g betaCSQ_`z' = betaCSQ_C_`z' + betaCSQ_S_`z' + betaCSQ_Q_`z'
			}

	******************************
	** zero out USA/CHN to self
	******************************
	if "`d'"=="us" {
		foreach v of varlist yhat* beta* {
			replace `v' = . if cty_iso=="USA"
		}
	}
	if "`d'"=="ch" {
		foreach v of varlist yhat* beta* {
			replace `v' = . if cty_iso=="CHN"
		}
	}

	******************************
	** create betas file
	******************************

	drop _*
	preserve
		rename beta*_dlz_usch beta*_usch_`d'
		rename beta*_dlz_chus beta*_chus_`d'
		rename beta*_dlz_usi beta*_usi_`d'
		rename beta*_dlz_chrw beta*_chrw_`d'

		keep cty_iso3 hs6 ind9_str beta* sw_*
		rename cty_iso3 iso
		duplicates drop
		compress
		save "$tmp/bs_beta_`link'_`d'_bs`b'",replace
	restore
	drop beta*


	******************************
	*** create winners file ***
	******************************

	 *reweight yhats
		foreach j in `speclist' {
			replace yhat`j' = sw_`d' * yhat`j'
		}
		replace dlv_`d' = sw_`d'*dlv_`d'

	***collapse
	collapse (sum) yhat* dlv_`d', by(cty_iso3)
	rename yhat* yhat*_`d'
	rename cty_iso3 iso

	*save (this is at the iso-hs level)
	compress
	save "$tmp/bs_yhat_`link'_`d'_bs`b'",replace

	*erase main regs file
	cap erase "$tmp/regs_`link'_`d'_bs`b'.dta"	

} //end d


	*Combine yhats
	use "$tmp/bs_yhat_`link'_us_bs`b'",clear
		merge 1:1 iso using "$tmp/bs_yhat_`link'_ch_bs`b'", nogen
		merge 1:1 iso using "$tmp/bs_yhat_`link'_rw_bs`b'", nogen
		erase "$tmp/bs_yhat_`link'_us_bs`b'.dta"
		erase "$tmp/bs_yhat_`link'_ch_bs`b'.dta"
		erase "$tmp/bs_yhat_`link'_rw_bs`b'.dta"

		merge 1:1 iso using "$processed/Dweights", keep(master match) nogen

		*aggregate across destinations
		foreach j in `speclist' {
			g yhat`j'_awd  = W_us*yhat`j'_us + W_ch*yhat`j'_ch + W_rw*yhat`j'_rw
		}

		rename yhat* yhat*_`b'

		g dlv_awd = W_us*dlv_us + W_ch*dlv_ch + W_rw*dlv_rw
		rename dlv_awd dlv_awd_`b'	

	*save (this is at the iso level)
	keep iso yhat* dlv_awd_`b' 
	order iso
	compress
	save "$tmp/bs_yhat_`link'_bs`b'",replace


	*Combine betas
	use "$tmp/bs_beta_`link'_us_bs`b'",clear
		merge 1:1 iso hs6 using "$tmp/bs_beta_`link'_ch_bs`b'", nogen
		merge 1:1 iso hs6 using "$tmp/bs_beta_`link'_rw_bs`b'", nogen
		erase "$tmp/bs_beta_`link'_us_bs`b'.dta"
		erase "$tmp/bs_beta_`link'_ch_bs`b'.dta"
		erase "$tmp/bs_beta_`link'_rw_bs`b'.dta" 
		rename beta* beta*_bs`b'

	compress
	save "$tmp/bs_beta_`link'_bs`b'",replace

} 

*}

dis "-- FINISHED --"
exit
