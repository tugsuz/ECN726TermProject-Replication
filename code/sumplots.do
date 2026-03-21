/**************************************************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
* Create appendix figures 1 and 2
**************************************************************************************/

clear

*Set directories
do "$code/00_directories.do"

*Log file
cap log close
cap log using "$logs/sumplots.log", replace

*******************************************************************************
*** 	        Pre-war trade shares by country and industry		    ***
*******************************************************************************

*Read data
u "$processed/data5" if t==0, clear

* change ind name for plot
label define industry 8 "Misc", modify
label define ind9 8 "Misc", modify
replace ind9_str = "Misc" if ind9_str == "Miscellaneous"

*Countries
g iso = cty_iso
drop country
g country = partner_name

*Scale to billions, and annualize (ie turn 18-month into 12-month)
replace v_wd = v_wd / 1000
replace v_wd = v_wd * (2/3)

*Compute pre-war trade shares
gcollapse (sum) sw_wd v_wd, by(country iso ind9_str)

*Reshape
reshape wide sw_wd v_wd, i(country iso) j(ind) string

*Plot labels
local I ""
foreach v of varlist sw_wd* {
	local i = subinstr("`v'","sw_wd","",.)
	g `i' = `v'
	drop `v'
	local I "`I' `i'"
}

*Shares by country-industry plot
gsort iso
preserve
	keep if _n<=int(25)
	graph bar `I', over(iso, label(angle(90)) sort(iso)) stack nolabel xsize(12) legend(pos(11) row(1) size(vsmall)) title("") ylabel(,labsize(medsmall)) ///
		saving("$tmp/g1.gph", replace)
restore
preserve
	keep if _n>(25)
	graph bar `I', over(iso, label(angle(90)) sort(iso)) stack nolabel xsize(12) legend(pos(11) row(1)) title("")  ylabel(,labsize(medsmall)) ///
		saving("$tmp/g2.gph", replace)
restore
cd "$tmp"
grc1leg g1.gph g2.gph, row(2) pos(11)
graph export "$results/appendix/fig_a1.pdf", replace


*******************************************************************************
*** 			   Box plots of tariff changes			    ***
*******************************************************************************

*Read in data
u "$processed/rf", clear

*Collapsetariffs by product-sector
gcollapse dlz_usch dlz_chus dlz_usi dlz_chrw, by(hs6 ind9*)

*Replace zeros with missing
foreach v of varlist dlz_usch dlz_chus dlz_usi dlz_chrw {
	replace `v' = . if `v'==0
}

*US Tariff Changes (Panel A)
graph hbox dlz_usch dlz_usi, over(ind) noout ///
	note("") ///
	legend(order(1 "{&Delta}T(US,CH)" 2 "{&Delta}T(US,i)") pos(11) ring(0) row(2)) ///
	yscale(range(-.3(.1).3)) ylabel(-.3(0.1).3) ///
	yline(0, lpattern(dash) lcolor(red)) ///
	medtype(marker) medmarker(m(s) mc(black) msize(small))
graph export "$results/appendix/fig_a2_panelA.pdf", replace

*China Tariff Changes (Panel B)
graph hbox dlz_chus dlz_chrw, over(ind) noout ///
	note("") ///
	legend(order(1 "{&Delta}T(CH,US)" 2 "{&Delta}T(CH,i)") pos(11) ring(0) row(2)) ///
	yscale(range(-.3(.1).3)) ylabel(-.3(0.1).3) ///
	yline(0, lpattern(dash) lcolor(red)) ///
	medtype(marker) medmarker(m(s) mc(black) msize(small)) 
graph export "$results/appendix/fig_a2_panelB.pdf", replace

exit
