/************************************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
Description: GDP data
************************************************************************/

clear all
set more off

*Set directories
do "$code/00_directories.do"

*Merge FDI data
u "$processed/cty_FDI_stock", clear
merge 1:1 iso3 using "$processed/cty_FDI_flow"
drop if mi(stock2016) & mi(flow2016)
drop _m
compress
save "${tmp}country_flows.dta", replace

*** Pull GDPPC data from World Bank
wbopendata, indicator("NY.GDP.PCAP.CD") clear latest iso
keep countrycode  yr* 
rename countrycode iso3
keep yr2016-yr2018 iso3
egen gdppc = rowmean(yr*)
replace gdppc = (yr2016 + yr2017)/2 if yr2018 == .
drop yr2017 yr2018
foreach var of varlist yr* {
    local str = substr("`var'", -4, .)
    rename `var' gdppc`str'
}
label variable gdppc "GDP per capital (current US$) 2016-2018 mean"
label variable gdppc2016 "GDP per capita (current US$)"
tempfile 1
save `1'

* GDP per capita, PPP (current international $)
wbopendata, indicator("NY.GDP.PCAP.PP.CD") clear latest iso
keep countrycode  yr* 
rename countrycode iso3
keep yr2016-yr2018 iso*
egen gdppc_ppp = rowmean(yr*)
replace gdppc_ppp = (yr2016 + yr2017)/2 if yr2018 == .
drop yr2017 yr2018
foreach var of varlist yr* {
    local str = substr("`var'", -4, .)
    rename `var' gdppc_ppp`str'
}
label variable gdppc_ppp "GDP per capita, PPP (current international $) 2016-2018 mean"
label variable gdppc_ppp2016 "GDP per capita, PPP (current international $)"
tempfile 2
save `2'

* GDP, PPP (current international $)
wbopendata, indicator("NY.GDP.MKTP.PP.CD") clear latest iso
keep countrycode yr* 
rename countrycode iso3
keep yr2016-yr2018 iso*
egen gdp_ppp = rowmean(yr*)
replace gdp_ppp = (yr2016 + yr2017)/2 if yr2018 == .
drop yr2017 yr2018
foreach var of varlist yr* {
    local str = substr("`var'", -4, .)
    rename `var' gdp_ppp`str'
}
label variable gdp_ppp "GDP, PPP (current international $) 2016-2018 mean"
label variable gdp_ppp2016 "GDP, PPP (current international $)"
tempfile 3
save `3'

* GDP (current US$)
wbopendata, indicator("NY.GDP.MKTP.CD") clear latest iso
keep countrycode  yr* countryname
rename countrycode iso3
keep yr2016-yr2018 iso*
egen gdp = rowmean(yr*)
replace gdp = (yr2016 + yr2017)/2 if yr2018 == .
drop yr2017 yr2018
foreach var of varlist yr* {
    local str = substr("`var'", -4, .)
    rename `var' gdp`str'
}
label variable gdp "GDP (current US$) 2016-2018 mean"
label variable gdp2016 "GDP (current US$)"
tempfile 4
save `4'

*Merge ISO2 codes
preserve
	import delimited "$raw/wb_country_groups/iso_codes.csv", varnames(1) clear
	keep iso3digitalpha iso2* ctycode ctyfullnameenglish
	rename (iso3digitalpha ctycode ctyfullnameenglish iso2digitalpha) (iso3 cty_code cty_name iso2)
	drop if iso3 == "NULL"
	drop cty_code cty_name
	duplicates drop iso3, force
	gisid iso3
	tempfile iso
	save `iso'
restore

*Read distances
u "${raw}distances/country_dist.dta", clear
keep if iso3_o == "USA"
keep iso3_d iso3_o dist
rename iso3_d iso3
duplicates drop iso3, force
merge 1:1 iso3 using `iso', nogen keep(master match)
tempfile dist
save `dist'

*** Merge all
use `1', clear
merge 1:1 iso3 using `2', nogen
merge 1:1 iso3 using `3', nogen
merge 1:1 iso3 using `4', nogen

*Add TWN GDPPC
count
local N = r(N)+1
set obs `N'
replace iso3 = "TWN" if mi(iso3)
replace gdppc = 250600 if iso3=="TWN" //2017 USD for TWN, statistic from IMF 


*Drop if all vars missing
drop if mi(gdppc2016) & mi(gdppc) & mi(gdppc_ppp2016) & mi(gdppc_ppp) & mi(gdp_ppp2016) & mi(gdp_ppp) & mi(gdp2016) & mi(gdp)

*Merge
merge 1:1 iso3 using `dist', keep(master match) keepusing(dist iso2)
sort iso3
order iso3 gdp gdp_ppp gdppc gdppc_ppp gdp2016 ///
    gdp_ppp2016 gdppc2016 gdppc_ppp2016
drop *2016

*ISO codes
preserve
	import delimited "$raw/wb_country_groups/iso_codes.csv", varnames(1) clear
	drop if endvalidyear<2014
	keep iso3digitalpha ctycode ctyfullnameenglish
	rename (iso3digitalpha ctycode ctyfullnameenglish) (iso3 cty_code cty_name)
	drop if iso3 == "NULL"
	gisid iso3
	local N = r(N)+1
	set obs `N'
	replace iso3 = "TWN" if mi(iso3)		
	save "$tmp/iso_codes", replace
restore
preserve
	keep iso3 gdp*
	merge 1:1 iso3 using "$tmp/iso_codes", keep(master match) nogen
	drop if gdppc == .
	rename iso3 cty_iso3
	save "$processed/country_gdp", replace
restore
merge 1:1 iso3 using "${tmp}country_flows.dta", keep(master match) gen(m1)

*Save
compress 
save "$processed/country_gdp_dist.dta", replace
