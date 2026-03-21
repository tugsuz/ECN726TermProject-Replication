/************************************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
Description: FDI data
************************************************************************/

clear all
set more off 

*Set directories
do "$code/00_directories.do"

*******************************************************
* 1. Clean dataset
*******************************************************

*Read file
import excel "$raw/unctad/WIR2020Tab03.xlsx", cellrange(A3:AE236) firstrow clear

*Drop subtotals and totals
drop if Regioneconomy == "World"
drop if Regioneconomy == "Developed economies"
drop if Regioneconomy == "Europe"
drop if Regioneconomy == "European Union"
drop if Regioneconomy == "Other developed Europe"
drop if Regioneconomy == "Other developed economies"
drop if Regioneconomy == "Belgium / Luxembourg"
drop if Regioneconomy == "North America"
drop if Regioneconomy == "Developing economies"
drop if Regioneconomy == "Africa"
drop if Regioneconomy == "North Africa"
drop if Regioneconomy == "Other Africa"
drop if Regioneconomy == "West Africa"
drop if Regioneconomy == "Central Africa"
drop if Regioneconomy == "East Africa"
drop if Regioneconomy == "Southern Africa"
drop if Regioneconomy == "Asia"
drop if Regioneconomy == "East and South-East Asia"
drop if Regioneconomy == "East Asia"
drop if Regioneconomy == "South-East Asia"
drop if Regioneconomy == "South Asia"
drop if Regioneconomy == "West Asia"
drop if Regioneconomy == "Latin America and the Caribbean"
drop if Regioneconomy == "South America"
drop if Regioneconomy == "Central America"
drop if Regioneconomy == "Caribbean"
drop if Regioneconomy == "Oceania"
drop if Regioneconomy == "Transition Economies"
drop if Regioneconomy == "South-East Europe"
drop if Regioneconomy == "CIS"
drop if Regioneconomy == "Least developed countries (LDCs)"
drop if Regioneconomy == "Landlocked countries (LLCs)"
drop if Regioneconomy == "Small island developing states (SIDS)"

*Keep only 2016-2018; rename vars and create id
keep Regioneconomy AB AC AD
rename (AB AC AD) (stock2016 stock2017 stock2018)
rename Regioneconomy cty_name
la var cty_name   "ISO Country Name"
replace cty_name = upper(cty_name)
g id = _n
la var id "Observation ID"

*Rename country names for merge
replace cty_name = "BOLIVIA" 			if cty_name == "BOLIVIA, PLURINATIONAL STATE OF"
replace cty_name = "BOSNIA" 			if cty_name == "BOSNIA AND HERZEGOVINA"
replace cty_name = "CAPE VERDE" 		if cty_name == "CABO VERDE"
replace cty_name = "CROATIA " 			if cty_name == "CROATIA"
replace cty_name = "HONG KONG" 			if cty_name == "HONG KONG, CHINA" 
replace cty_name = "IRAN " 			if cty_name == "IRAN, ISLAMIC REPUBLIC OF"
replace cty_name = "LAOS" 			if cty_name == "LAO PEOPLE'S DEMOCRATIC REPUBLIC"
replace cty_name = "MACAO" 			if cty_name == "MACAO, CHINA"
replace cty_name = "RUSSIA" 			if cty_name == "RUSSIAN FEDERATION"
replace cty_name = "SINT MAARTEN " 		if cty_name == "SINT MAARTEN"
replace cty_name = "SAO TOME AND PRINCIPE" 	if id 	    == 70
replace cty_name = "TAIWAN" 			if cty_name == "TAIWAN PROVINCE OF CHINA"
replace cty_name = "TANZANIA" 			if cty_name == "UNITED REPUBLIC OF TANZANIA"
replace cty_name = "VIETNAM" 			if cty_name == "VIET NAM"
replace cty_name = "CZECH REPUBLIC" 		if cty_name == "CZECHIA"

*Merge with iso codes

preserve
	import delimited "$raw/wb_country_groups/iso_codes.csv", varnames(1) clear
	*drop if endvalidyear<2010
	keep iso3digitalpha ctycode ctyfullnameenglish endvalidyear
	rename (iso3digitalpha ctycode ctyfullnameenglish) (iso3 iso_code cty_name)
	replace cty_name = upper(cty_name)
	replace cty_name = trim(cty_name)
	gisid iso3 iso_code
	g idu = _n
	tempfile iso
	save `iso'
restore
g idm = _n
reclink2 cty_name using `iso', idm(idm) idu(idu) gen(score)

*Country codes
replace iso3 = "NOR" if cty_name == "NORWAY"
replace iso3 = "TZA" if cty_name == "TANZANIA"
replace iso3 = "SWZ" if cty_name == "ESWATINI"
replace iso3 = "HKG" if cty_name == "HONG KONG"
replace iso3 = "MAC" if cty_name == "MACAO"
replace iso3 = "TWN" if cty_name == "TAIWAN"
replace iso3 = "LAO" if cty_name == "LAOS"
replace iso3 = "BOL" if cty_name == "BOLIVIA"
replace iso_code= 834 if cty_name == "TANZANIA"
replace iso_code= 748 if cty_name == "ESWATINI"
replace iso_code= 344 if cty_name == "HONG KONG"
replace iso_code= 446 if cty_name == "MACAO"
replace iso_code= 158 if cty_name == "TAIWAN"
replace iso_code= 418 if cty_name == "LAOS"
replace iso_code= 68 if cty_name == "BOLIVIA"
drop _m endvalidyear
gisid id
drop idu idm score 

*Drop merge & ctycode
destring stock*, ignore("-") replace
order id cty_name iso3 iso_code stock*
sort iso3
drop id
compress
save "$processed/cty_FDI_stock", replace

