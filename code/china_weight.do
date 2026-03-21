/**************************************************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
* Compute pre-war trade weights used to collapse US trade data from HS10 to HS6
**************************************************************************************/

clear all
set more off 

*Set directories
do "$code/00_directories.do"

*Log
cap log close
log using "$logs/china_weight_hs10.log", replace

*******************
*** Imports
*******************

use * if inrange(year,2015,2017) & cty_name=="CHINA" ///
	using "$raw/census_trade/m_flow_hs10_fm",clear

*Sum up total trade over all countries within product
gegen tot = sum(m_val), by(hs6)

*Compute variety total within HS6 product
gegen c   = sum(m_val), by(hs10 cty_code)

*Compute country market share within product
g m_cty_weight_hs6   = c/tot

*Collapse to variety level
gcollapse m_cty_weight_hs6, by(hs10 hs6 cty_code)

*Label
label var m_cty_weight_hs6 "Pre-war weight of variety within total HS6 imports"

*Check
drop if mi(cty_code, hs10, hs6)		
gegen checkm = sum(m_cty_weight), by(hs6)
sum checkm 
assert inrange(r(mean),0.999,1.001)
drop check
gisid hs10 cty_code

*Save
compress
save "$tmp/china_weight_hs6_m", replace

*******************
*** Exports
*******************	

use * if inrange(year,2015,2017) & cty_name=="CHINA" ///
	using "$raw/census_trade/x_flow_hs10_fm",clear

*Sum up total trade over all countries within product	
gegen tot = sum(x_val), by(hs6)

*Compute variety total within product	
gegen c   = sum(x_val), by(hs10 cty_code)

*Compute country market share within product	
g x_cty_weight_hs6   = c/tot

*Collapse to variety level
gcollapse x_cty_weight_hs6, by(hs10 hs6 cty_code)

*Label
label var x_cty_weight_hs6 "Pre-war weight of variety within total HS6 exports"

*Check 
drop if mi(cty_code, hs10, hs6)	
gegen checkx = sum(x_cty_weight), by(hs6)
sum checkx
assert inrange(r(mean),0.999,1.001)	
drop check
gisid hs10 cty_code	

*Save
compress
save "$tmp/china_weight_hs6_x", replace

*Merge them
use "$tmp/china_weight_hs6_m", clear
merge 1:1 hs10 cty_code using "$tmp/china_weight_hs6_x", nogen
gsort hs10 cty_code

*Check
gisid cty_code hs10

*Save
compress
save "$processed/china_weight_hs6", replace

exit
