/**************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
*** Rank countries by exports 
**************************************************/

clear all

*Set directories
do "$code/00_directories.do"

*Log
cap log close
log using "$logs/cty_rank.log", replace

*Global data
use * if inrange(year,2015,2017) & partner_iso3!="WLD" using "$processed/global_trade_hs6_ct_consistent_hs12.dta",clear

*Drop 
drop if reporter==partner

*Aggregate by country
gcollapse (sum) v=import_value, by(partner) fast

*Merge with country codes
gen iso_code = partner
merge m:1 iso_code using "$processed/iso_codes.dta", keep(master match) nogen keepusing(iso3 cty_name)
rename iso3 cty_iso3
cap g partner_name = upper(cty_name)
cap replace cty_name = partner_name if cty_name == ""
drop if (mi(cty_name) | mi(partner)) & partner_name!="UNITED STATES"

*Drop duplicate code for Sudan
drop if partner==736

*Compute rank
gsort -v
g rank = _n
drop v

*Check
gisid partner
drop if cty_iso3 == "NULL"

*Save
compress
save "$processed/cty_rank2", replace
