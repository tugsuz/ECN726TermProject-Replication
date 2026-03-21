/**************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
* Read trade flow data
**************************************************/

clear all
set more off

*Set directories
do "$code/00_directories.do"

*Log file
cap log close
cap log using "$logs/global_trade_hs6_ct_consistent_hs12.log", replace

************************
*** Clean comtrade data
************************

cap log close
log using "${logs}clean_tradecomtrade.log", replace

*Append raw comtrade files (HS 2012 codes)
clear
forval t=2014/2019 {
	append using "$raw/comtrade/`t'.dta"
}

*Rename vars 
rename commoditycode hs6
rename (partneriso partnercode reporteriso reportercode) (partner_iso3 partner reporter_iso3 reporter)
rename (imports_q exports_q imports_v exports_v) (import_quantity export_quantity import_value export_value)

*Scale trade flows
replace import_v = import_v/10^6
replace export_v = export_v/10^6

*Save
compress
save "$processed/global_trade_hs6_ct_consistent_hs12.dta", replace

**********************************
*** Save list of partner names
**********************************

*REad file
u * if year>=2016 using "$processed/global_trade_hs6_ct_consistent_hs12.dta", clear

*Get partner names
gcollapse (sum) imp* exp*, by(partner) fast
duplicates drop partner, force
keep partner

*Merging country code partner_cd (exporter)
rename partner iso_code
preserve
	import delimited "$raw/wb_country_groups/iso_codes.csv", varnames(1) clear
	keep iso3digitalpha ctycode ctyfullnameenglish endvalidyear
	rename (iso3digitalpha ctycode ctyfullnameenglish) (iso3 iso_code cty_name)
	gisid iso3 iso_code
	tempfile iso
	save `iso'
restore
merge m:1 iso_code using `iso', keep(master match) keepusing(iso3 cty_name)
replace iso_code = 642 if iso_code == 946
rename iso3 cty_iso3
drop _m
drop if cty_iso3 == "NULL"
drop if cty_name == ""
drop if iso_code == 736 // "former sudan"

*Save
compress
save "$processed/global_trade_hs6_ct_hs12_partnerlist", replace

cap log close
