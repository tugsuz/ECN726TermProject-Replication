/**************************************************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
* China tariffs on the US
**************************************************************************************/

clear all 

*Set directories
do "$code/00_directories.do"

*Log
cap log close
log using "$logs/z_chus.log", replace

********************************************************************************
***** compute weighted hs6 retaliatory tariffs (CHN on US)
********************************************************************************

* import raw china september 2019 tariffs 
import excel using "$raw/retaliatory_tariffs/retaliatory_tariffs_2019.xlsx", ///
	 	clear sheet(china) firstrow allstring case(lower)
keep hs8 tariff effective_date
replace hs8 = subinstr(hs8,".","",.)
replace hs8 = "0" + hs8 if length(hs8) == 7
destring hs8 tariff, force replace
drop if hs8 == .
tempfile x
save `x'

* import raw china may 2019 tariffs
import excel using "$raw/retaliatory_tariffs/retaliatory_tariffs.xlsx", ///
	clear sheet(china_may2019) firstrow allstring case(lower)
keep hs8 tariff effective_date
replace hs8 = "0" + hs8 if length(hs8) == 7
destring hs8 tariff, force replace
drop if hs8 == .
tempfile xx
save `xx'

* import raw china 2018 tariffs
import excel using "$raw/retaliatory_tariffs/retaliatory_tariffs.xlsx", ///
 clear sheet(china) firstrow allstring case(lower)
keep hs8 tariff effective_date
replace hs8 = "0" + hs8 if length(hs8) == 7
destring hs8 tariff, replace
append using `x'
append using `xx'
tostring hs8, replace
replace hs8 = "0" + hs8 if length(hs8) == 7
g year = substr(effective_date,-2,2)
replace year = substr(effective_date,-4,4) if strpos(effective_date,"/")>0
replace year = "2018" if year == "18"
replace year = "2019" if year == "19"
g month = substr(effective_date, strpos(effective_date,"-")+1,3)
replace month = "9" if month == "Sep"
replace month = "4" if month == "Apr"
replace month = "7" if month == "Jul"
replace month = "8" if month == "Aug"
destring month year, replace
drop effective_date
gen mdate = ym(year, month)
format mdate %tm
drop month year

* use bown tariff files to get the effective date of car parts (these were exempted on Jan '19)
preserve
	u "$raw/bown_etal/CHN_TR_onUS_HS10.dta", clear 
	replace hs08=substr(hs10,1,8)
	collapse (mean) reta*, by(hs08)
	drop if mi(hs08)
	keep hs08 reta_2019* reta_2018*
	keep if reta_2018Sep24>0 & (reta_2019Jan01 == 0 | reta_2019Jun01 == 0 | reta_2019Sep01 == 0 | reta_2019Sep17 == 0 | reta_2019Dec26 == 0)	// keep tariffs that went down to 0 in 2019
	egen x = rowtotal(reta_*)
	drop if x == 0
	drop x
	g mdate = tm(2019m1)
	format mdate %tm
	replace mdate = tm(2019m12) if reta_2019Sep17>0 & reta_2019Dec26 == 0
	g tariff = -reta_2018Sep24/100 if mdate == tm(2019m1)
	replace tariff = -reta_2019Sep17/100 if mdate == tm(2019m12)
	rename hs08 hs8
	keep hs8 tariff mdate
	tempfile exempted
	save `exempted'
restore
append using `exempted'
save "$tmp/chn_hs8_tariffs", replace

* merge tariffs with 2017 CHN imports from US values
u "$tmp/chn_hs8_tariffs", clear
merge m:1 hs8 using "$raw/china_trade_hs8/china_imports_from_usa.dta"
g hs6 = substr(hs8,1,6)
drop if _m == 2

*merge hs6 total
preserve
	u "$raw/china_trade_hs8/china_imports_from_usa.dta", clear
	g hs6 = substr(hs8,1,6)
	gcollapse (sum) val, by(hs6)
	rename val tot_hs6
	tempfile toths6
	save `toths6'
restore
merge m:1 hs6 using `toths6', keep(master match) nogen
g sh = value/tot_hs6
replace sh = 0 if mi(sh)
g tariff_w = sh*tariff
egen tariff_m = max(tariff), by(hs6 mdate)
gcollapse (sum) tariff_w (max) tariff_m (mean) tariff, by(hs6 mdate)	
rename tariff z_chus
rename tariff_w z_chus_w
rename tariff_m z_chus_max
save "$tmp/chn_hs6_tariffs_weighted", replace

* create template if 24-month period
u "$tmp/chn_hs6_tariffs_weighted", clear
duplicates drop hs6, force
keep hs6 mdate
replace mdate = tm(2018m1)
expand 24
bys hs6: g id = _n
replace mdate = mdate+(id-1)
drop id
save "$tmp/template", replace

****************
* a) weighted tariffs by mdate
****************

u "$tmp/template", clear
merge 1:1 hs6 mdate using "$tmp/chn_hs6_tariffs_weighted"
drop _m 
fillin hs6 mdate
drop _fillin
gsort hs6 mdate
foreach v of varlist z_chus* {
	by hs6: replace `v' = sum(`v')
}
rename (z_chus z_chus_w z_chus_max) (z_chus_mdate z_chus_w_mdate z_chus_max_mdate)
mvencode z_chus*, mv(0) override
save "$tmp/z_chus_w_mdate", replace

***********
* b) weighted tariffs by year
****************

u "$tmp/template", clear
merge 1:1 hs6 mdate using "$tmp/chn_hs6_tariffs_weighted"
drop _m 
fillin hs6 mdate
gsort hs6 mdate
foreach v of varlist z_chus* {
	by hs6: replace `v' = sum(`v')
}
mvencode z_chus*, mv(0) override
g date = dofm(mdate)
format date %d
g year=year(date)
drop date
rename (z_chus z_chus_w z_chus_max) (z_chus_yr z_chus_w_yr z_chus_max_yr)
gcollapse (mean) z_chus*, by(hs6 year)
save "$tmp/z_chus_w_year", replace

****************
* c) weighted tariffs scaled 24month
****************

u "$tmp/template", clear
merge 1:1 hs6 mdate using "$tmp/chn_hs6_tariffs_weighted"
drop _m 
fillin hs6 mdate
gsort hs6 mdate
foreach v of varlist z_chus* {
	by hs6: replace `v' = sum(`v')
}
mvencode z_chus*, mv(0) override
rename (z_chus z_chus_w z_chus_max) (z_chus_2yr z_chus_w_2yr z_chus_max_2yr)
gcollapse (mean) z_chus*, by(hs6)
save "$tmp/z_chus_w_2yr", replace

 
****************************
*** Final file
****************************

u "$tmp/z_chus_w_2yr", clear
g t = 1
foreach v of varlist z_chus* {
	replace `v' = 0 if inrange(`v',-0.000001,0.00001)
	assert `v'>=0
}
destring hs6, replace

// make consistent to hs12
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
joinby hs6 using `x', _merge(_m) unmatched(master)
tab _m

*merge 1:m hs6 using `x', keep(master match) keepusing(HS12)
replace hs6 = HS12 if _m == 3
drop _m

*Collapse
gcollapse (mean)  z_chus_w_2yr z_chus_2yr (max) z_chus_max, by(hs6 t)

*Rename vars
rename (z_chus_w_2yr z_chus_2yr) (z_chus_w z_chus)

*Square panel
insobs 1
replace t = 0 if mi(t)
insobs 1
replace t = -1 if mi(t)
fillin hs6 t 
drop if mi(hs6)
mvencode z*, mv(0) override

*Compute tariff changes
foreach z of varlist z_chus* {
	g d`z' = `z'
	replace d`z' = 0 if mi(d`z')

}

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
g lz_chus = log(1+z_chus)
g lz_chus_w = log(1+z_chus_w)
g dlz_chus = d.lz_chus
g dlz_chus_w = d.lz_chus_w

*Missings
mvencode dlz*, mv(0) override

*Keep vars
keep hs6 t dlz* z* dz*

*Save
compress
save "$processed/z_chus_w", replace

