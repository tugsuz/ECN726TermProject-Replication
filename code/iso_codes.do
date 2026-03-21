/**************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
* Country ISO Codes
**************************************************/

clear all

*Set directories
do "$code/00_directories.do"

*Log file
cap log close
cap log using "$logs/iso_codes.log", replace

*Read ISO Codes
import delimited "$raw/wb_country_groups/iso_codes.csv", varnames(1) clear

*Keep relevant vars
keep iso3digitalpha ctycode ctyfullnameenglish endvalidyear

*Rename vars
rename (iso3digitalpha ctycode ctyfullnameenglish) (iso3 iso_code cty_name)

*Ensure data are unique by country
gisid iso3 iso_code

*Format country names
replace cty_name = upper(cty_name)
replace cty_name = trim(cty_name)

*Save
compress
save "$processed/iso_codes", replace

