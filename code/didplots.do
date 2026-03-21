/**************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
*** Create Figures 1, A3, and A4; and Table A2 
**************************************************/

clear all
set more off 

*Set directories
do "$code/00_directories.do"

*Log file
cap log close
cap log using "$logs/did.log", replace

*Read file
u id cty_iso3 country hs6 hs4 hs2 t *_wd *_wd_lag dl*_wd dl*_wd_lag dlz_usch dlz_chus dlz_usi dlz_chrw ind9  ///
	dl*_us dl*_ch dl*_us_lag dl*_ch_lag dl*_rw dl*_rw_lag v_rw v_us v_ch ///
	using "$processed/data5", clear

*China exports to US var and vice versa
g x = dlv_us if cty_iso3=="CHN"
gegen dlv_usch = max(x), by(hs6)
g xx = dlv_ch if cty_iso3=="USA"
gegen dlv_chus = max(xx), by(hs6)
drop x xx

*Separate trade by source (not by destination)
g iso = cty_iso3
replace v_rw = v_wd if !inlist(iso,"USA","CHN")
replace v_us = v_wd if iso=="USA"
replace v_ch = v_wd if iso=="CHN"
g usch = inlist(iso,"USA","CHN")

*Assign tariff change in post-period to pre-period to run pre-trend test
foreach v of varlist dlz* {
	gegen x = max(`v'), by(hs6)
	replace `v' = x
	drop x
}

*Variety-level FE
gegen cs = group(iso ind9)

*Set panel
tsset id t 

*Quantiles of exports in pre-period by country-sector 
gquantiles x = v_wd if t==0, by(cs) xtile nq(10)
gegen q = max(x), by(id)
drop x

*set figure headers
local panela "{bf:Panel A}" "China's Export Value to US"
local panelb "{bf:Panel B}" "US Export Value to China"
local panelc "{bf:Panel A}" "Bystanders' Export Value to US"
local paneld "{bf:Panel B}" "Bystanders' Export Value to China"
local panele "{bf:Panel C}" "Bystanders' Export Value to RW"
local panelf "{bf:Panel D}" "Bystanders' Export Value to RW"

*Binscatter: US imports from China on USCH tariff
	
	*Raw data
	eststo usch_t0_fe0: reghdfe dlv_us dlz_usch if iso=="CHN" & t==0, noab
		estadd local c1 "No"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_pre = string(_b[dlz_usch],"%9.2f")
	local se_pre = string(_se[dlz_usch],"%9.2f")
	eststo usch_t1_fe0: reghdfe dlv_us dlz_usch if iso=="CHN" & t==1, noab
		estadd local c1 "No"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_post = string(_b[dlz_usch],"%9.2f")
	local se_post = string(_se[dlz_usch],"%9.2f")		
	binscatter dlv_us dlz_usch if iso=="CHN", by(t) ///
		legend(order(1 "2015-17" 2 "2017-19") pos(12) row(1) ring(1) size(medsmall)) ///
		xtitle("{&Delta} ln T(US,CH)", size(medsmall)) ytitle("{&Delta}ln X(US,CH)", size(medsmall)) ///
		title("`panela'") ///
		note("Pre-period: {&beta}=`b_pre' (`se_pre'). Post-period: {&beta}=`b_post' (`se_post').", ///
		     size(small) pos(7) ring(1) justification(left)) ///
		     colors(gs10 navy) ms(Oh Di) ysc(titlegap(*-25))  ///
		     xlabel(,labsize(medsmall)) ylabel(,labsize(medsmall))
	graph save "$tmp/g1a.gph", replace

*Binscatter: China imports from US on CHUS tariff

	*Raw data
	eststo chus_t0_fe0: reghdfe dlv_ch dlz_chus if iso=="USA" & t==0, noab 
		estadd local c1 "No"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_pre = string(_b[dlz_chus],"%9.2f")
	local se_pre = string(_se[dlz_chus],"%9.2f")
	eststo chus_t1_fe0: reghdfe dlv_ch dlz_chus if iso=="USA" & t==1, noab 
		estadd local c1 "No"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_post = string(_b[dlz_chus],"%9.2f")
	local se_post = string(_se[dlz_chus],"%9.2f")	
	binscatter dlv_ch dlz_chus if iso=="USA", by(t) ///
		legend(order(1 "2015-17" 2 "2017-19") pos(12) row(1) ring(1) size(medsmall)) ///
		xtitle("{&Delta} ln T(CH,US)", size(medsmall)) ytitle("{&Delta}ln X(CH,US)", size(medsmall)) ///
		title("`panelb'") ///
		note("Pre-period: {&beta}=`b_pre' (`se_pre'). Post-period: {&beta}=`b_post' (`se_post').", ///
		     size(small) pos(7) ring(1) justification(left)) ///
		      colors(gs10 navy) ms(Oh Di)  ///
		     xlabel(,labsize(medsmall)) ylabel(,labsize(medsmall))
	graph save "$tmp/g2a.gph", replace

*Binscatter: RW exports to US on USCH tariff

	*Raw data
	eststo rwus_usch_t0_fe0: reghdfe dlv_us dlz_usch if !usch & t==0, noab cluster(hs6)
		estadd local c1 "No"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_pre = string(_b[dlz_usch],"%9.2f")
	local se_pre = string(_se[dlz_usch],"%9.2f")

	eststo rwus_usch_t1_fe0: reghdfe dlv_us dlz_usch if !usch & t==1, noab cluster(hs6)
		estadd local c1 "No"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_post = string(_b[dlz_usch],"%9.2f")
	local se_post = string(_se[dlz_usch],"%9.2f")

	binscatter dlv_us dlz_usch if !usch, by(t)  ///
		legend(order(1 "2015-17" 2 "2017-19") pos(12) row(1) ring(1) size(medsmall)) ///
		xtitle("{&Delta} ln T(US,CH)", size(medsmall)) ytitle("{&Delta}ln X(US,i)", size(medsmall)) ///
		title("`panelc'") ///
		note("Pre-period: {&beta}=`b_pre' (`se_pre'). Post-period: {&beta}=`b_post' (`se_post').", ///
		     size(small) pos(7) ring(1) justification(left)) ///
		      colors(gs10 navy) ms(Oh Di)  ///
		     xlabel(,labsize(medsmall)) ylabel(,labsize(medsmall))
	graph save "$tmp/g3a.gph", replace
	
	*With fixed effects 
	eststo rwus_usch_t0_fe1: reghdfe dlv_us dlz_usch if !usch & t==0, a(cs) cluster(hs6)
		estadd local c1 "Yes"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_pre = string(_b[dlz_usch],"%9.2f")
	local se_pre = string(_se[dlz_usch],"%9.2f")
	eststo rwus_usch_t1_fe1: reghdfe dlv_us dlz_usch if !usch & t==1, a(cs) cluster(hs6)
		estadd local c1 "Yes"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_post = string(_b[dlz_usch],"%9.2f")
	local se_post = string(_se[dlz_usch],"%9.2f")	
	binscatter dlv_us dlz_usch if !usch, by(t) absorb(cs) ///
		legend(order(1 "2015-17" 2 "2017-19") pos(12) row(1) ring(1) size(medsmall)) ///
		xtitle("{&Delta} ln T(US,CH)", size(medsmall)) ytitle("{&Delta}ln X(US,i)", size(medsmall)) ///
		title("`panelc'") ///
		note("Pre-period: {&beta}=`b_pre' (`se_pre'). Post-period: {&beta}=`b_post' (`se_post').", ///
		     size(small) pos(7) ring(1) justification(left)) ///
		    colors(gs10 navy) ms(Oh Di)  ///
		     xlabel(,labsize(medsmall)) ylabel(,labsize(medsmall))
	graph save "$tmp/g3b.gph", replace

*Binscatter: RW exports to CH on CHUS tariff

	*Raw data
	eststo rwch_chus_t0_fe0: reghdfe dlv_ch dlz_chus if !usch & t==0, noab cluster(hs6)
		estadd local c1 "No"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_pre = string(_b[dlz_chus],"%9.2f")
	local se_pre = string(_se[dlz_chus],"%9.2f")

	eststo rwch_chus_t1_fe0: reghdfe dlv_ch dlz_chus if !usch & t==1, noab cluster(hs6)
		estadd local c1 "No"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_post = string(_b[dlz_chus],"%9.2f")
	local se_post = string(_se[dlz_chus],"%9.2f")

	*plot
	binscatter dlv_ch dlz_chus if !usch, by(t)  ///
		legend(order(1 "2015-17" 2 "2017-19") pos(12) row(1) ring(1) size(medsmall)) ///
		xtitle("{&Delta} ln T(CH,US)", size(medsmall)) ytitle("{&Delta}ln X(CH,i)", size(medsmall)) ///
		title("`paneld'") ///
		note("Pre-period: {&beta}=`b_pre' (`se_pre'). Post-period: {&beta}=`b_post' (`se_post').", ///
		     size(small) pos(7) ring(1) justification(left)) ///
		     colors(gs10 navy) ms(Oh Di)  ///
		     xlabel(,labsize(medsmall)) ylabel(,labsize(medsmall))
	graph save "$tmp/g4a.gph", replace	
	
	*With fixed effects 
	eststo rwch_chus_t0_fe1: reghdfe dlv_ch dlz_chus if !usch & t==0, a(cs) cluster(hs6)
		estadd local c1 "Yes"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_pre = string(_b[dlz_chus],"%9.2f")
	local se_pre = string(_se[dlz_chus],"%9.2f")
	eststo rwch_chus_t1_fe1: reghdfe dlv_ch dlz_chus if !usch & t==1, a(cs) cluster(hs6)
		estadd local c1 "Yes"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_post = string(_b[dlz_chus],"%9.2f")
	local se_post = string(_se[dlz_chus],"%9.2f")	
	binscatter dlv_ch dlz_chus if !usch, absorb(cs) by(t)  ///
		legend(order(1 "2015-17" 2 "2017-19") pos(12) row(1) ring(1) size(medsmall)) ///
		xtitle("{&Delta} ln T(CH,US)", size(medsmall)) ytitle("{&Delta}ln X(CH,i)", size(medsmall)) ///
		title("`paneld'") ///
		note("Pre-period: {&beta}=`b_pre' (`se_pre'). Post-period: {&beta}=`b_post' (`se_post').", ///
		     size(small) pos(7) ring(1) justification(left)) ///
		       colors(gs10 navy) ms(Oh Di)  ///
		     xlabel(,labsize(medsmall)) ylabel(,labsize(medsmall))
	graph save "$tmp/g4b.gph", replace

*Binscatter: RW exports to RW on USCH tariff

	*Raw data
	eststo rwrw_usch_t0_fe0: reghdfe dlv_rw dlz_usch if !usch & t==0, noab cluster(hs6)
		estadd local c1 "No"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_pre = string(_b[dlz_usch],"%9.2f")
	local se_pre = string(_se[dlz_usch],"%9.2f")

	eststo rwrw_usch_t1_fe0: reghdfe dlv_rw dlz_usch if !usch & t==1, noab cluster(hs6)
		estadd local c1 "No"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_post = string(_b[dlz_usch],"%9.2f")
	local se_post = string(_se[dlz_usch],"%9.2f")

	binscatter dlv_rw dlz_usch if !usch, by(t)  ///
		legend(order(1 "2015-17" 2 "2017-19") pos(12) row(1) ring(1) size(medsmall)) ///
		xtitle("{&Delta} ln T(US,CH)", size(medsmall)) ytitle("{&Delta}ln X(RW,i)", size(medsmall)) ///
		title("`panele'") ///
		note("Pre-period: {&beta}=`b_pre' (`se_pre'). Post-period: {&beta}=`b_post' (`se_post').", ///
		     size(small) pos(7) ring(1) justification(left)) ///
		     colors(gs10 navy) ms(Oh Di)  ///
		     xlabel(,labsize(medsmall)) ylabel(,labsize(medsmall))
	graph save "$tmp/g5a.gph", replace
	
	*With fixed effects 
	eststo rwrw_usch_t0_fe1: reghdfe dlv_rw dlz_usch if !usch & t==0, a(cs) cluster(hs6)
		estadd local c1 "Yes"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_pre = string(_b[dlz_usch],"%9.2f")
	local se_pre = string(_se[dlz_usch],"%9.2f")
	eststo rwrw_usch_t1_fe1: reghdfe dlv_rw dlz_usch if !usch & t==1, a(cs) cluster(hs6)
		estadd local c1 "Yes"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_post = string(_b[dlz_usch],"%9.2f")
	local se_post = string(_se[dlz_usch],"%9.2f")	
	binscatter dlv_rw dlz_usch if !usch, by(t) absorb(cs) ///
		legend(order(1 "2015-17" 2 "2017-19") pos(12) row(1) ring(1) size(medsmall)) ///
		xtitle("{&Delta} ln T(US,CH)", size(medsmall)) ytitle("{&Delta}ln X(RW,i)", size(medsmall)) ///
		title("`panele'") ///
		note("Pre-period: {&beta}=`b_pre' (`se_pre'). Post-period: {&beta}=`b_post' (`se_post').", ///
		     size(small) pos(7) ring(1) justification(left)) ///
		     colors(gs10 navy) ms(Oh Di)  ///
		     xlabel(,labsize(medsmall)) ylabel(,labsize(medsmall))
	graph save "$tmp/g5b.gph", replace
	
*Binscatter: RW exports to RW on CHUS tariff
	
	*Raw data
	eststo rwrw_chus_t0_fe0: reghdfe dlv_rw dlz_chus if !usch & t==0, noab cluster(hs6)
		estadd local c1 "No"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_pre = string(_b[dlz_chus ],"%9.2f")
	local se_pre = string(_se[dlz_chus ],"%9.2f")

	eststo rwrw_chus_t1_fe0: reghdfe dlv_rw dlz_chus  if !usch & t==1, noab cluster(hs6)
		estadd local c1 "No"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_post = string(_b[dlz_chus ],"%9.2f")
	local se_post = string(_se[dlz_chus],"%9.2f")

	binscatter dlv_rw dlz_chus if !usch, by(t)  ///
		legend(order(1 "2015-17" 2 "2017-19") pos(12) row(1) ring(1) size(medsmall)) ///
		xtitle("{&Delta} ln T(CH,US)", size(medsmall)) ytitle("{&Delta}ln X(RW,i)", size(medsmall)) ///
		title("`panelf'") ///
		note("Pre-period: {&beta}=`b_pre' (`se_pre'). Post-period: {&beta}=`b_post' (`se_post').", ///
		     size(small) pos(7) ring(1) justification(left)) ///
		     colors(gs10 navy) ms(Oh Di)  ///
		     xlabel(,labsize(medsmall)) ylabel(,labsize(medsmall))
	graph save "$tmp/g6a.gph", replace
	
	*With fixed effects
	eststo rwrw_chus_t0_fe1: reghdfe dlv_rw dlz_chus if !usch & t==0, a(cs) cluster(hs6)
		estadd local c1 "Yes"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_pre = string(_b[dlz_chus ],"%9.2f")
	local se_pre = string(_se[dlz_chus ],"%9.2f")
	eststo rwrw_chus_t1_fe1: reghdfe dlv_rw dlz_chus  if !usch & t==1, a(cs) cluster(hs6)
		estadd local c1 "Yes"
		local R = string(e(r2),"%9.2fc")
		estadd local R2 "`R'"
	local b_post = string(_b[dlz_chus ],"%9.2f")
	local se_post = string(_se[dlz_chus],"%9.2f")	
	binscatter dlv_rw dlz_chus if !usch, absorb(cs) by(t)  ///
		legend(order(1 "2015-17" 2 "2017-19") pos(12) row(1) ring(1) size(medsmall)) ///
		xtitle("{&Delta} ln T(CH,US)", size(medsmall)) ytitle("{&Delta}ln X(RW,i)", size(medsmall)) ///
		title("`panelf'") /// 
		note("Pre-period: {&beta}=`b_pre' (`se_pre'). Post-period: {&beta}=`b_post' (`se_post').", ///
		     size(small) pos(7) ring(1) justification(left)) ///
		     colors(gs10 navy) ms(Oh Di)  ///
		     xlabel(,labsize(medsmall)) ylabel(,labsize(medsmall))
	graph save "$tmp/g6b.gph", replace

*Figure 1
cd "$tmp"
graph combine g3a.gph g4a.gph g5a.gph g6a.gph, rows(3) xsize(6) ysize(8) iscale(.5)
graph export "$results/fig_1.pdf",replace

*Figure A
graph combine g3b.gph g4b.gph g5b.gph g6b.gph, rows(3) xsize(6) ysize(8) iscale(.5)
graph export "$results/appendix/fig_a2.pdf",replace

*Figure A3
graph combine g1a.gph g2a.gph, rows(1) iscale(.7)
graph export "$results/appendix/fig_a3.pdf", replace

*Table A2
lab var dlz_usch "T_USCH"
lab var dlz_chus "T_CHUS"
cap erase "$results/appendix/tab_a2.csv"
foreach t in 0 1 {
foreach fe in 0 1 {
	
	*Appendix Table 2
	global specs_t`t'_fe`fe' "rwus_usch_t`t'_fe`fe' rwch_chus_t`t'_fe`fe' rwrw_usch_t`t'_fe`fe' rwrw_chus_t`t'_fe`fe'"
	esttab ${specs_t`t'_fe`fe'} using "$results/appendix/tab_a2.csv" , ///
		drop(_cons) label se(%9.2f) b(%9.2f) stats(c1 N, label("Exporter $\times$ Sector FE" "N") fmt(%9.0f %9.0f)) ///
		nogaps compress nomtitles nonotes star(* 0.10 ** 0.05 *** 0.01) append	

	
}
}	
		
	
