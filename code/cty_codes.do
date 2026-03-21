/**************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
* 4-digit country codes from Census
**************************************************/

*Set directories
do "$code/00_directories.do"

*Read trade file
u id cty_name cty_iso3 cty_code if cty_code>0 using "$raw/census_trade/m_flow_hs10_fm",clear
gcollapse (sum) id, by(cty_name cty_iso3 cty_code)
g idm = _n
reclink2 cty_name using "$processed/iso_codes", idm(idm) idu(iso_code) gen(score)
replace cty_iso3 = "VAT" if cty_name == "VATICAN CITY"
replace cty_iso3 = "ISR" if cty_name == "WEST BANK ADMINISTERED BY ISRAEL"
replace cty_iso3 = "MAC" if cty_name == "MACAU"
replace cty_iso3 = "PSE" if cty_name == "GAZA STRIP ADMINISTERED BY ISRAEL"
replace cty_iso3 = "COD" if cty_name == "CONGO (KINSHASA)"
replace cty_iso3 = "SJM" if cty_name == "SVALBARD, JAN MAYEN ISLAND"
drop if cty_name == "WEST BANK ADMINISTERED BY ISRAEL"
replace cty_iso3 = iso3 if mi(cty_iso3)
assert !mi(cty_iso3)
gisid cty_iso3
drop iso3
rename cty_iso3 iso3
gisid cty_code
drop score endvalidyear _m idm id iso_code Ucty_name

*Add the US
insobs 1
replace iso3 = "USA" if mi(iso3)
replace cty_name = "UNITED STATES" if iso3 == "USA"
replace cty_code = 842 if iso3 == "USA"
insobs 1
replace iso3 = "PRI" if mi(iso3)
replace cty_name = "PUERTO RICO" if iso3 == "PRI"
replace cty_code = 9030 if iso3 == "PRI"

*Save 
compress
save "$processed/cty_codes2", replace
