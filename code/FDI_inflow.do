**************************************************
* Author: Maximilian Schwarz
* Date: Aug 28, 2020
* This file cleans FDI data from UN
**************************************************

clear all
set more off 

*Set directories
do "$code/00_directories.do"

*******************************************************
* 1. Clean dataset
*******************************************************

*1.1 load
import excel "$raw/unctad/WIR2020Tab01.xlsx", cellrange(A3:AE236) firstrow clear

*1.2 drop subtotals and totals
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

*1.3 keep only 2016-2018; rename vars and create id
	keep Regioneconomy AB AC AD
	rename (AB AC AD) (flow2016 flow2017 flow2018)
	rename Regioneconomy cty_name
	*reshape long stock, i(cty_name) j(year)
	*la var stock "FDI inward stock in million USD"
	la var cty_name   "ISO Country Name"
	replace cty_name = upper(cty_name)
	g id = _n
	la var id "Observation ID"

*1.4 rename country names for merge
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
	replace cty_name = "SAO TOME AND PRINCIPE" 	if cty_name == "SãO TOMé AND PRINCIPE"
	replace cty_name = "TAIWAN" 			if cty_name == "TAIWAN PROVINCE OF CHINA"
	replace cty_name = "TANZANIA" 			if cty_name == "UNITED REPUBLIC OF TANZANIA"
	replace cty_name = "VIETNAM" 			if cty_name == "VIET NAM"
	replace cty_name = "CZECH REPUBLIC" 		if cty_name == "CZECHIA"

*1.5 merging with iso codes
	merge m:m cty_name using "$processed/iso_codes", keep (master match)
	drop if flow2016 == "-" & flow2017 == "-" & flow2018 == "-"

*1.6 iso_codes_updated is not unique (have to fix this file..) --> drop duplicates
	drop if  iso3 == "ABW"
	drop if iso_code == 250
	drop if iso_code == 699
	drop if iso_code == 381
	drop if iso_code == 485
	drop if iso_code == 579
	drop if iso_code == 736
	drop if iso_code == 757
	drop if iso_code == 842
	replace cty_name = trim(cty_name)
*1.7 fixing missing iso codes
	replace iso3 = "VGB" 		if cty_name == "BRITISH VIRGIN ISLANDS" 
	replace iso3 = "CIV" 		if cty_name == "CôTE D' IVOIRE" 
	replace iso3 = "SWZ" 		if cty_name == "ESWATINI" 
	replace iso3 = "PRK" 		if cty_name == "KOREA, DEMOCRATIC PEOPLE'S REPUBLIC OF"
	replace iso3 = "KOR" 		if cty_name == "KOREA, REPUBLIC OF"
	replace iso3 = "MKD" 		if cty_name == "NORTH MACEDONIA" 
	replace iso3 = "VEN" 		if cty_name == "VENEZUELA, BOLIVARIAN REPUBLIC OF"
	replace iso3 = "COD" 		if cty_name == "CONGO, DEMOCRATIC REPUBLIC OF"
	replace iso3 = "PST" 		if cty_name == "STATE OF PALESTINE"
	replace iso3 = "NOR" 		if cty_name == "NORWAY"
	replace iso3 = "TZA" 		if cty_name == "TANZANIA"
	replace iso3 = "HKG" 		if cty_name == "HONG KONG"
	replace iso3 = "MAC" 		if cty_name == "MACAO"
	replace iso3 = "TWN" 		if cty_name == "TAIWAN"
	replace iso3 = "LAO" 		if cty_name == "LAOS"
	replace iso3 = "BOL" 		if cty_name == "BOLIVIA"

	replace iso3 = "BIH" 		if cty_name == "BOSNIA"
	replace iso3 = "CPV" 		if cty_name == "CAPE VERDE"
	replace iso3 = "HRV" 		if cty_name == "CROATIA"
	replace iso3 = "FRA" 		if cty_name == "FRANCE"
	replace iso3 = "IRN" 		if cty_name == "IRAN"
	replace iso3 = "XKX" 		if cty_name == "KOSOVO"
	replace iso3 = "SXM" 		if cty_name == "SINT MAARTEN"
	replace iso3 = "USA" 		if cty_name == "UNITED STATES"
	replace iso3 = "VNM" 		if cty_name == "VIETNAM"
	replace iso3 = "CHE" 		if cty_name == "SWITZERLAND"
	gisid iso3

*1.8 drop merge & ctycode
	drop endvalid _m
	destring flow*, ignore("-") replace
	order id cty_name iso3 iso_code flow*
	sort iso3
	drop id
	compress
	save "$processed/cty_FDI_flow", replace

