/**************************************************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
*** China tariffs on RW
**************************************************************************************/

clear all
set more off 

*Set directories
do "$code/00_directories.do"

*Log
cap log close
log using "$logs/z_chrw.log", replace

************************************************
** 1 CLEAN DATA
************************************************

*****************
** 1.1 CLEAN TARIFF DATA 
*****************

*Read in data
import excel using "$raw/bown_etal/bown-jung-zhang-2019-06-12.xlsx", sheet("China Tariff Rates") cellrange(A2) clear 

*Rename variables
rename A hs10
drop   B
rename C z_chrw 							// China MFN level on world
rename D dz_chus_2apr18							// April 2, 2018 - Change in China tariff on US
rename E dz_chrw_1may18							// May 1, 2018	 - Change in China MFN tariff on world (pharmaceuticals)
rename F dz_chrw_1jul18							// July 1, 2018	 - Change in China MFN tariff on world (consumer goods,autos, ITA)
rename G dz_chus_6jul18							// July 6, 2018	 - Change in China tariff on US (Section 301)
rename H dz_chus_23aug18						// Aug 23, 2018	 - Change in China tariff on US (Section 301)
rename I dz_chus_24sep18						// Sep 24, 2018	 - Change in China tariff on US (Section 301)
rename J dz_chrw_1nov18							// Nov 1, 2018	 - Change in China MFN tariff on world (industry goods)
rename K dz_chrw_1jan19							// Jan 1, 2019	 - Change in China MFN tariff on world (temporary)
rename L dz_chus_1jan19							// Jan 1, 2019	 - Change in China tariff on US (auto and parts)
rename M dz_chus_1jun19							// June 1, 2019	 - Change in China tariff on US (various products)

*Create panel format
expand 72 								// duplicate each observation 24 times, for 24 months
gsort hs10
bysort hs10: g row = _n - 1						// count how many times each hs10 entry exists
g mdate = tm(2014m1) + row						// start with date 2018m1 and then add months.
drop row
format mdate %tm	
g year = year(dofm(mdate))						// extract year, dofm() gets code of date
order hs10 mdate year

*Cumulative changes of Chinese tariffs increases on the US
g 	dz_chus = 0
replace dz_chus = dz_chus + dz_chus_2apr18 			if mdate>=tm(2018m4) 
replace dz_chus = dz_chus + dz_chus_6jul18 			if mdate>=tm(2018m7) 
replace dz_chus = dz_chus + dz_chus_23aug18			if mdate>=tm(2018m8)
replace dz_chus = dz_chus + dz_chus_24sep18			if mdate>=tm(2018m9)
replace dz_chus = dz_chus + dz_chus_1jan19 			if mdate>=tm(2019m1)
replace dz_chus = dz_chus + dz_chus_1jun19 			if mdate>=tm(2019m6)

*Chinese tariffs on US in levels
g 	z_chus 	= z_chrw
replace	z_chus  = z_chus + dz_chus 					// adjust the levels; MS: start here with WORLD level for US???

*Cumulative changes of Chinese tariff cuts on ROW
g 	dz_chrw = 0 
replace dz_chrw = dz_chrw + dz_chrw_1may18 			if mdate>=tm(2018m5)
replace dz_chrw = dz_chrw + dz_chrw_1jul18			if mdate>=tm(2018m7)
replace dz_chrw = dz_chrw + dz_chrw_1nov18			if mdate>=tm(2018m11)
replace dz_chrw = dz_chrw + dz_chrw_1jan19			if mdate>=tm(2019m1)
replace z_chrw  = z_chrw + dz_chrw 					// adjust the levels

*Collapse by HS6
g hs6=substr(hs10,1,6)
drop hs10
order hs6 mdate year
destring hs6, force replace
gcollapse (mean) z* dz* /// 
(min) z_chrw_max = z_chrw z_chus_max = z_chus , by(hs6 mdate year)

*merge with HS6 broad cateogries
merge m:1 hs6 using "$raw/crosswalk/hs6_broad_sectors", keep(master match)	
bysort hs6: gen nomatch = _n if _merge == 1				// create variable nomatch
list hs6 if nomatch == 1						// show hs6 codes that dont match
drop _merge nomatch							// drop some (just a few)
rename hsind hs6_broad_sectors
replace hs6_broad_sectors = 5 	if hs6==281216				// fix missing broad sectors
replace hs6_broad_sectors = 5	if hs6==290433				// fix missing broad sectors
replace hs6_broad_sectors = 11	if hs6==710820				// fix missing broad sectors

*Check if panel is fine
order hs6 mdate year
gsort hs6 mdate
tsset hs6 mdate
gisid hs6 mdate

*save hs6 code as string
tostring hs6, replace
replace hs6 = "0" + hs6 if length(hs6)==5

*create tariff change variable (not cumulative)
g dz_chus_nc=	dz_chus[_n]-dz_chus[_n-1]
g dz_chrw_nc=	dz_chrw[_n]-dz_chrw[_n-1]

*drop values close to zero
replace dz_chus_nc = 0 	if dz_chus_nc <= 0.0001 & dz_chus_nc >= -0.0001
replace dz_chrw_nc = 0 	if dz_chrw_nc <= 0.0001 & dz_chrw_nc >= -0.0001
replace dz_chus = 0 	if dz_chus <= 0.0001 & dz_chus >= -0.0001
replace dz_chrw = 0 	if dz_chrw <= 0.0001 & dz_chrw >= -0.0001
replace dz_chus_nc = 0 	if mdate == tm(2018m1)
replace dz_chrw_nc = 0 	if mdate == tm(2018m1)

*label vars
la var z_chrw 		"China: tariff levels on ROW"
la var z_chus 		"China: tariff levels on US"
la var dz_chrw 		"China: cum. tariff changes on ROW"
la var dz_chus 		"China: cum. tariff changes on US"
la var dz_chrw_nc 	"China: tariff changes on ROW"
la var dz_chus_nc 	"China: tariff changes on US"
la var hs6 		"HS6 code"
la var mdate 		"Month and Date"
la var year 		"Year"

*drop individual tariff variables
keep hs6 mdate year z_chrw z_chus dz_chus dz_chrw dz_chus_nc dz_chrw_nc *_max hs6_broad_sectors

*Save
compress
save "$tmp/china_mfn_tmp1", replace


*****************
** 1.2 ADD TARIFF WEIGHTS and WEIGHTED TARIFF series
*****************

*Data preparation
use "$processed/global_trade_hs6_ct_consistent_hs12.dta", clear
keep if reporter_iso3	== "CHN" & inrange(year,2015,2017)
drop if partner_iso3	== "WLD"
gcollapse (sum) import_value, by (hs6 partner_iso3)

*compute total imports of China by hs6 
gegen m_tot  	= sum(import_value), by(hs6)

*Compute total imports by hs6 and country			
gegen m_c   	= sum(import_value), by(hs6 partner_iso3)

*calculate import weights for US and ROW by product	
g weights   	= m_c/m_tot						
keep if partner_iso3 == "USA"					
rename weights w_us
g w_rw		= 1-w_us	
					
*save
keep hs6 w_us w_rw				
compress
tempfile weights
save `weights', replace

*merge with china_mfn
use "$tmp/china_mfn_tmp1", clear
destring hs6, replace
merge m:1 hs6 using `weights', keep(master match)	
drop _merge

la var w_us "US Share of total Chinese imports by HS6"
la var w_rw "ROW Share of total Chinese imports by HS6"

*Save
compress
sa "$tmp/china_mfn_tmp2", replace

*****************
** 1.3 Construct both an unweighted average (called z_chwd, dz_chwd) and a weighted average (z_chwd_w, dz_chrw_w)
*****************

*Data
u "$tmp/china_mfn_tmp2", clear

*compute tariff levels and increase for world (weighted average of ROW and US)
g z_chwd_w 	= w_us * z_chus  + w_rw * z_chrw
g dz_chwd_w 	= w_us * dz_chus + w_rw * dz_chrw
g dz_chwd_nc_w 	= w_us * dz_chus_nc + w_rw * dz_chrw_nc				//nc = non-cumulative changes

*compute tariff levels and increase for world (unweighted average of ROW and US)
g z_chwd 	= (z_chus   + z_chrw) /2
g dz_chwd 	= (dz_chus  + dz_chrw)/2
g dz_chwd_nc 	= (dz_chus_nc  + dz_chrw_nc)/2

*var labels
la var z_chwd_w 	"China: weighted tariff levels on WLD"
la var dz_chwd_w 	"China: weighted cum. tariff increases on WLD"
la var dz_chwd_nc_w 	"China: weighted tariff increases on WLD"
la var z_chwd 		"China: unweighted tariff levels on WLD"
la var dz_chwd 		"China: unweighted cum. tariff increases on WLD"
la var dz_chwd_nc 	"China: unweighted tariff increases on WLD"

*Save
save "$tmp/china_mfn_tmp3", replace

****************
* Final file
****************

u "$tmp/china_mfn_tmp3", clear
destring hs6, replace

*Define pre- and post- period
g t = -1 if inrange(year,2014,2015)
replace t = 0 if inrange(year,2016,2017)
replace t = 1 if inrange(year,2018,2019)
drop if mi(t)

*HS crosswalk
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
replace hs6 = HS12 if _m == 3
drop _m

*Collapse
gcollapse (mean) z_chrw	dz_chrw (min) dz_chrw_max = dz_chrw, by(hs6 t)

*carryforward
tsset hs6 t
by hs6: carryforward z_*, replace

*Missings
mvencode dz_chrw_max, mv(0) override

*No tariff changes in the pre-period
foreach v of varlist dz* {
	replace `v' = 0 if t<1
}

*Proper scaling
foreach v of varlist  z_* dz_* {
	replace `v' = `v'/100
}

*Ensure levels match changes
foreach v of varlist z* {
	replace `v' = l.`v' if t>=0
	replace `v' = l.`v' + d`v' if t>=0 
}

*Log of tariffs 
g lz_chrw = log(1+z_chrw)
cap g dlz_chrw = d.lz_chrw

*Missings
mvencode dlz*, mv(0) override

*Check
gsort hs6 t
gisid hs6 t

*Save
compress
save "$processed/z_chrw", replace
