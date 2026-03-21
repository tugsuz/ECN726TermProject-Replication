/**************************************************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
* US tariffs on China
**************************************************************************************/

clear all
set more off 

*Set directories
do "$code/00_directories.do"

*Log
cap log close
log using "$logs/z_usch.log", replace

*Read Census trade flows and tariffs
use * if cty_name=="CHINA" & year>=2015 using "$raw/census_trade/m_flow_hs10_fm",clear

*Merge with pre-war trade weights
merge m:1 cty_code hs10 using "$processed/china_weight_hs6", nogen keep(match)	

*Weight 
g w = m_cty_weight

*Fill the panel
tsset id mdate
fillin id mdate

*Carryforward
rename tmp* *
gsort id -cty_code
by id: carryforward cty* hs* m_effective_mdate4 m_T, replace
gsort id mdate
by id: carryforward m_stattariff4 m_increase,  replace
gsort id-mdate
by id: carryforward m_stattariff4,  replace
gsort id -w
by id: carryforward w, replace	
gsort id mdate

*Fixes
replace m_stattariff4 = m_stattariff4 + .25 if m_effective_mdate4==tm(2018m10) & m_increase==0 & mdate>=tm(2019m5) & cty_code==5700
replace m_increase = .25 if m_effective_mdate4==tm(2018m10) & m_increase==0 & mdate>=tm(2019m5) & cty_code==5700

replace m_stattariff4 = m_stattariff4 + .02 if m_effective_mdate4==tm(2018m10) & m_increase==0 & mdate==tm(2018m9) & cty_code==5700
replace m_increase = .02 if m_effective_mdate4==tm(2018m10) & m_increase==0 & mdate==tm(2018m9) & cty_code==5700

replace m_stattariff4 = m_stattariff4 + .10 if m_effective_mdate4==tm(2018m10) & m_increase==0 & mdate>=tm(2018m10) & cty_code==5700
replace m_increase = .10 if m_effective_mdate4==tm(2018m10) & m_increase==0 & mdate>=tm(2018m10) & cty_code==5700

replace m_stattariff4 = m_stattariff4 + .15 if m_effective_mdate4==tm(2019m9) & m_increase==0 & mdate>=tm(2019m9) & cty_code==5700
replace m_increase = .15 if m_effective_mdate4==tm(2019m9) & m_increase==0 & mdate>=tm(2019m9) & cty_code==5700			

*Tariff variables
g z = m_increase 
replace z = 0 if mdate<m_effective_mdate4 - 1
g m_tariff = m_stattariff4

*Check that weights sum to 1
replace w = 0 if mi(w)
gegen check = sum(w), by(hs6 mdate)
qui sum check if check>0
assert inrange(r(mean),0.999,1.001)
drop check

*Variables for weighted/un-weighted tariffs
rename m_tariff m_tariff_weighted	 				// these tariffs will be weighted in the collapse 
rename m_increase m_increase_weighted

gegen m_tariff = mean(m_tariff_weighted), by(hs6 mdate) 		// these tariffs will be unweighted in the collapse
gegen m_increase = mean(m_increase_weighted), by(hs6 mdate) 	
gegen m_tariff_max = max(m_tariff_weighted), by(hs6 mdate) 		// these tariffs will be unweighted in the collapse and unscaled

* unscaled tariffs
g z_usch_unscaled = m_tariff
g dz_usch_unscaled = m_increase

*Collapse to product-level
gcollapse (mean) m_tariff m_tariff_weighted m_increase m_increase_weighted ///
	  (max) m_T_prod=m_T m_increase_max=z m_tariff_max (min) m_effective_mdate4 [aw=w], by(hs6 mdate)

*Labels
label var m_tariff 		"Tariff, unweighted average"
label var m_tariff_weighted 	"Tariff, pre-war weighted average"	
label var m_increase_max 	"Max tariff increase"
label var m_increase 		"Tariff increase, unweighted average"
label var m_increase_weighted 	"Tariff increase, pre-war weighted average"
label var m_T_prod 		"Product is targeted by US import tariffs"

*Check
drop if mi(hs6,mdate)
gsort hs6 mdate 
gisid hs6 mdate

* collapse to 2yr periods
g date = dofm(mdate)
g year = year(date)
drop date
g t = -1 if inrange(year,2014,2015)
replace t = 0 if inrange(year,2016,2017)
replace t = 1 if inrange(year,2018,2019)
gcollapse (mean) z_usch=m_tariff z_usch_max=m_tariff_max z_usch_w=m_tariff_weighted ///
		 dz_usch=m_increase dz_usch_w=m_increase_weighted  ///
	  (max)  dz_usch_max=m_increase_max, by(hs6 t) 
	  
*make hs6 consistent over time to HS12	
preserve
	import excel "$raw/crosswalk/Crosswalk_consistent_HS6/CompleteCorrelationsOfHS-SITC-BEC_20170606.xlsx", clear firstrow
	keep HS*
	compress
	drop if HS12 == "NULL"
	keep HS17 HS12
	destring HS*, replace
	rename HS17 hs6
	duplicates drop hs6 HS12, force
	tempfile x
	save `x', replace
restore
joinby hs6 using `x', _merge(m1) unmatched(master)
replace hs6 = HS12 if m1 == 3

*Collapse 
gcollapse (mean) z_usch z_usch_w dz_usch dz_usch_w (max) z_usch_max dz_usch_max, by(hs6 t)

*Carry forward tariff levels
gsort hs6 t
tsset hs6 t
by hs6: carryforward z_*, replace

*No tariff changes in the pre-period
foreach v of varlist dz* {
	replace `v' = 0 if t<1
}

*Ensure levels match changes
foreach v of varlist z* {
	replace `v' = l.`v' if t>=0
	replace `v' = l.`v' + d`v' if t>=0 
}

*Log of tariffs 
g lz_usch = log(1+z_usch)
g lz_usch_w = log(1+z_usch_w)
g dlz_usch = d.lz_usch
g dlz_usch_w = d.lz_usch_w

*Missings
mvencode dlz*, mv(0) override

*Keep vars
keep hs6 t dlz* z* dz*

*Save 
compress
save "$processed/z_usch_w", replace



