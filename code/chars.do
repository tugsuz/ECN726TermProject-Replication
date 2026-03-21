/**************************************************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
* File of country characteristics
**************************************************************************************/

clear

*Set directories
do "$code/00_directories.do"

*Log file
cap log close
log using "$logs/chars.log", replace

*Read GDP data
use "$processed/country_gdp",clear
	rename gdp* c_gdp*
	replace c_gdp = (543.08e9+590.73e9+609.02e9)/3 if cty_iso3=="TWN" //2016-18 current prices for TWN from IMF 
	// (https://www.imf.org/external/datamapper/NGDPD@WEO/TWN?zoom=TWN&highlight=TWN) // Taiwan cite


*GDP data from UNCTAD for small countries that are not in WB data
preserve
	import excel "$raw/unctad/unctad_gdp_current.xlsx", firstrow cellrange("A5:AY227") clear
	drop if _n == 1
	keep YEAR AV AW AX
	rename (YEAR AV AW AX) (cty_name gdp2016 gdp2017 gdp2018)
	destring gdp*, replace ignore("_")
	egen gdp_ = rowmean(gdp*)
	drop gdp2016 gdp2017 gdp2018
	replace cty_name = trim(cty_name)
	replace cty_name = "Democratic People's Republic of Korea" if cty_name == "Korea, Dem. People's Rep. of"
	replace cty_name = "Syria" if cty_name == "Syrian Arab Republic"
	replace cty_name = "Venezuela" if cty_name == "Venezuela (Bolivarian Rep. of)"
	replace gdp_ = gdp*10^6
	rename gdp_ c_gdp_
	tempfile x
	save `x'
	
	import excel "$raw/unctad/unctad_gdppc_current.xlsx", firstrow cellrange("A5:AY227") clear
	drop if _n == 1
	keep YEAR AV AW AX
	rename (YEAR AV AW AX) (cty_name gdppc2016 gdppc2017 gdppc2018)
	destring gdp*, replace ignore("_")
	egen gdppc_ = rowmean(gdp*)
	drop gdppc2016 gdppc2017 gdppc2018
	replace cty_name = trim(cty_name)
	replace cty_name = "Democratic People's Republic of Korea" if cty_name == "Korea, Dem. People's Rep. of"
	replace cty_name = "Syria" if cty_name == "Syrian Arab Republic"
	replace cty_name = "Venezuela" if cty_name == "Venezuela (Bolivarian Rep. of)"
	merge 1:1 cty_name using `x', nogen
	rename gdppc_ c_gdppc_
	tempfile gdp
	save `gdp'
restore


*merge FDI/DB data
preserve

	/*
	import excel "$raw/wb_db/Historical-data---COMPLETE-dataset-with-scores.xlsx", sheet("All data") cellrange(A4:GQ3770) firstrow clear
	rename *,lower
	keep if inrange(dbyear,2014,2017)
	rename scoretradingacrossbordersdb sc_trade_db16
	rename countrycode iso3
	collapse (mean) sc_trade_db16, by(iso3)
	rename sc_trade_db16 db_trade
	keep iso3 db_trade
	rename db_trade c_dbtrade
	tempfile db
	save `db'
	*/

	use "$processed/cty_FDI_stock",clear
	egen FDI = rowmean(stock*)
	collapse (mean) FDI, by(iso3)
	rename FDI c_fdi
	tempfile fdi
	save `fdi'
restore

*Merge data on trade agreements from Mattoo et al. 2020
preserve
	use "$raw/deeptrade/trade_by_provisions", clear
		keep iso3 exports exports_provision_x imports imports_provision_x
		g deeptrade = (imports_provision_x + exports_provision_x)/(imports+exports)
		keep iso3 deeptrade
		rename deeptrade c_deeptrade
		tempfile deeptrade
	save `deeptrade'
restore

*Merge GDP
cap g iso3 = cty_iso3
merge m:1 cty_name using `gdp', keep(master match) nogen keepusing(c_gdp*)
replace c_gdp = c_gdp_ if mi(c_gdp)
replace c_gdppc = c_gdppc_ if mi(c_gdppc)
drop c_gdp_ c_gdppc_ 

*Merge FDI, trade agreements
*merge m:1 iso3 using `db', keep(master match) nogen !!!
merge m:1 iso3 using `fdi', keep(master match) nogen
merge m:1 iso3 using `deeptrade', keep(master match) nogen
drop iso3

*Merge with distances to US and China
merge m:1 cty_iso3 using "$processed/cty_distances_US_CN", keep(master match) nogen
foreach v of varlist dist* {
	replace `v' = `v' / 1000
}
rename dist* c_dist*

*Rename
rename c_dist_us c_distus
rename c_dist_ch c_distch

*Standardize variables
foreach v of varlist c_* {
	sum `v'
	replace `v' = (`v' - r(mean))/r(sd)
}

*Generate ISO variables
g iso = cty_iso3
g iso3 = cty_iso3 

*Save 	
compress 	
save "$processed/chars",replace


