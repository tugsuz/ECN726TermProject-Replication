/**************************************************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
* Create Figures 2 and 3
**************************************************************************************/

clear

*Set directories
do "$code/00_directories.do"

*Log file
cap log close
log using "$logs/winners.log", replace

*********************************************
** Assemble Winners File
*********************************************

*Base case
do "$code/bsregs.do" 0 

*merge bootstraps
clear
use "$tmp/bs_yhat_v_cs_bs0",clear
rename yhat* b0_yhat*
rename dlv* b0_dlv*
forval b=1/50 {
	merge 1:1 iso using "$tmp/bs_yhat_v_cs_bs`b'", nogen assert(3)
}

*construct bootstrap deviations from b0 to each destination
foreach d in us ch rw awd {
	forval b=1/50 {
		g dmCSQ_`b'  = (yhatCSQ_`d'_`b' - b0_yhatCSQ_`d')^2
	}
	egen sumdmCSQ = rowtotal(dmCSQ_*)
	g seCSQ_`d' = sqrt(sumdmCSQ/(50-1))
	drop dm* sumdm*
}

*drop bootstraps
drop yhat*_* dlv_*
rename b0_* *

rename yhat* b0_yhat*
rename b0_yhat*_0 b0_yhat*

*save
drop if inlist(iso,"CHN","USA")
compress
save "$processed/winners_v_cs",replace

*********************************************
** Plot Winners, by Specification
*********************************************

use "$processed/winners_v_cs",clear
	
*winners to WD
g ub_awd = b0_yhatCSQ_awd + 1.65*seCSQ_awd
g lb_awd = b0_yhatCSQ_awd - 1.65*seCSQ_awd

* sort, label countries
gsort b0_yhatCSQ_awd
count
global lab ""
local N = r(N)
forval i = 1/`N' {
	local coef = iso[`i']
	global lab "$lab `i' "`coef'" "
}
g k = _n
label define LBL ${lab} , replace
label values k LBL

*Scatter plot
twoway  ///
	(scatter b0_yhatCSQ_awd k, mcolor(black) mlw(medium) msymbol(Th) xlabel(1/`N',valuelabel labsize(small) angle(90)))  ///
	(rcap lb_awd ub_awd k, lcolor(black%30) msize(vtiny)) ///
       ,legend(off) xtitle("") ytitle("Log Change") /// ylabel(-0.35(.05)0.35)  ///
       caption("", pos(6) size(vsmall) span) ///
       yline(0, lpattern(dash) lcolor(gs7)) ///
       yscale(titlegap(*-10)) ylabel(,labsize(medsmall))
       graph export "$results/fig_2.pdf", as(pdf) replace      
      
	       
*Regressions of Yhats on country characteristics
g iso3 = iso 
merge 1:1 iso3 using "$processed/chars", nogen
rename c_* *

*"Explain" plots
drop distus distch
rename distw_us distus
rename distw_ch distch
lab var distch "Distance to CH"
lab var distus "Distance to US"
lab var gdppc "GDP Per Capita"
lab var gdp "GDP"
lab var fdi "FDI stock"
lab var deeptrade "Trade Agreement Trade Share"

est clear
local covar distus distch gdp deeptrade fdi
eststo y: reg b0_yhatCSQ_awd `covar'

*Coefficient plot
coefplot (y, ms(o) msize(medlarge) mc(maroon) ciopts(lc(maroon) lw(thin))) ///
	, drop(_cons) order(`covar') ///
	xline(0, lcolor(gs7) lpattern(dash)) ///
	legend(off) xline(0) ///
	levels(1.65 90) ///
	ylabel(,labsize(medsmall)) xlabel(,labsize(medsmall))
graph export "$results/appendix/country_correlates.pdf", replace 

*********************************************
** Decomposition
*********************************************

*Read file
use "$processed/winners_v_cs",clear

*Rename vars
rename b0_yhatCSQ_awd CSQ
rename b0_yhatCSQ_C_awd C
rename b0_yhatCSQ_S_awd S
rename b0_yhatCSQ_Q_awd Q
g CS = C + S
rename b0_yhatP_awd P

*Plot
twoway 	///
	(scatter P CSQ, mc(gs7) ms(+)) ///
	(scatter S CSQ, mc(red) ms(Dh)) ///
	(scatter Q CSQ, mc(green) ms(X)) ///
	(scatter C CSQ, mc(blue) ms(Oh)) ///
	(scatter CSQ CSQ, mc(black) ms(Sh)) ///
	(lfit P CSQ, lp(solid) lc(gs7) lw(thin)) ///
	(lfit S CSQ, lp(solid) lc(red) lw(thin)) ///
	(lfit Q CSQ, lp(solid) lc(green) lw(thin)) ///
	(lfit C CSQ, lp(solid) lc(blue) lw(thin)) ///
	(lfit CSQ CSQ, lp(solid) lc(black) lw(thin)) ///
	, ytitle("{&Delta} X(i), Alternative Configurations of {&Delta}{&beta}(ziw)", ///
		size(small)) xtitle("{&Delta} X(i), Full Heterogeneity", size(small)) ///
		legend(order(6 "Homogenous Response" 7 "Sector Component Only" 8 "Size Component Only"  9 "Country Component Only") ///
		size(vsmall) pos(12) ring(1) row(1))
graph export "$results/fig_3.pdf", as(pdf) replace
