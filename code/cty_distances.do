/************************************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
Description: Country distances to the US and China
************************************************************************/

clear all
set more off 

*Set directories
do "$code/00_directories.do"

*Data from CEPII
u "$raw/distances/dist_cepii", clear

*keep US and China vs all countries
	keep iso_o iso_d dist distw
	keep if iso_d == "USA" | iso_d == "CHN"
	replace iso_o = "ROU" if iso_o == "ROM"

*create US distance variables
	gegen dist_us= mean(dist), by (iso_o iso_d)
	gegen distw_us= mean(distw), by (iso_o iso_d)
	replace dist_us = 0 if iso_d == "CHN"
	replace distw_us = 0 if iso_d == "CHN"

*create CHINA distance variables
	gegen dist_ch= mean(dist), by (iso_o iso_d)
	gegen distw_ch= mean(distw), by (iso_o iso_d)
	replace dist_ch = 0 if iso_d == "USA"
	replace distw_ch = 0 if iso_d == "USA"

*collapse to obtain desired format
	gcollapse (sum) dist_us distw_us dist_ch distw_ch, by(iso_o)
	rename iso_o cty_iso3

* merge remaining ones
preserve
	u "$raw/distances/country_dist", clear
	rename (iso3_o iso3_d) (iso_o iso_d)
	keep if iso_d == "USA" | iso_d == "CHN"
	
	*create US distance variables
	gegen dist_us= mean(dist), by (iso_o iso_d)
	replace dist_us = 0 if iso_d == "CHN"

	*create CHINA distance variables
	gegen dist_ch= mean(dist), by (iso_o iso_d)
	replace dist_ch = 0 if iso_d == "USA"
	drop dist
	
	*collapse to obtain desired format
	gcollapse (sum) dist_us dist_ch, by(iso_o)
		
	rename iso_o cty_iso3
	tempfile x
	save `x'
restore
append using `x'

duplicates tag cty_iso3, gen(dupl)
drop if dupl == 1 & dist_us == . 
drop if dupl == 1 & dist_ch == . 
duplicates drop cty_iso3, force
drop dupl

insobs 1
replace cty_iso3 = "SSD" if mi(cty_iso3)
replace dist_us = 12653 if cty_iso3 == "SSD"
replace dist_ch = 8015 if cty_iso3 == "SSD"

insobs 1
replace cty_iso3 = "CUW" if mi(cty_iso3)
replace dist_us = 3840 if cty_iso3 == "CUW"
replace dist_ch = 14617 if cty_iso3 == "CUW"

insobs 1
replace cty_iso3 = "SXM" if mi(cty_iso3)
replace dist_us = 3817 if cty_iso3 == "SXM"
replace dist_ch = 13864 if cty_iso3 == "SXM"

*save
compress
save "$processed/cty_distances_US_CN", replace

