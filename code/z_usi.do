/**************************************************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
* US tariffs on other countries
**************************************************************************************/

clear all
set more off 

*Set directories
do "$code/00_directories.do"

*******************
*** Imports
*******************

*Read Census trade flows
use * if cty_code>0 & year>=2015 & cty_name!="CHINA" using "$raw/census_trade/m_flow_hs10_fm",clear

*Fill the panel
tsset id mdate
fillin id mdate

*Carryforward vars
rename tmp* *
gsort id -cty_code
by id: carryforward cty* hs* m_effective_mdate4 m_T, replace
gsort id mdate
by id: carryforward m_stattariff4 m_increase,  replace
gsort id -mdate
by id: carryforward m_stattariff4,  replace
gsort id mdate
mvencode m_increase, mv(0) override

*Identify from tariff changes in the post-period
replace m_increase = 0 if mdate<m_effective_mdate4 - 1	

// carryforward
gsort id -cty_code
by id: carryforward cty* hs* m_effective_mdate4 m_T, replace
gsort id mdate
by id: carryforward m_stattariff4 m_increase,  replace
gsort id -mdate
by id: carryforward m_stattariff4,  replace
gsort id mdate
mvencode m_increase, mv(0) override
replace m_stattariff4 = 0 if mfn_active == 1 & mdate<tm(2019m6)

*Tariff variable
g m_tariff = m_stattariff4

*Fix data errors
replace m_increase = 0 if m_increase>m_tariff

*Collapse to variety-level
gcollapse (mean) m_tariff m_increase (min) m_effective_mdate4, by(cty_iso3 hs6 mdate)

*Fillin again
fillin cty_iso3 hs6 mdate
gegen x = mean(m_tariff) if !inlist(cty_iso3,"CAN","MEX","IND"), by(hs6 mdate)
replace m_tariff = x if mi(m_tariff) & !inlist(cty_iso3,"CAN","MEX","IND")
gegen z = mean(m_increase) if !inlist(cty_iso3,"CAN","MEX","IND"), by(hs6 mdate)
replace m_increase = z if mi(m_increase) & !inlist(cty_iso3,"CAN","MEX","IND")
drop x z _fillin
mvencode m_increase, mv(0) override

*Check
drop if mi(cty_iso3,hs6,mdate)
gsort cty_iso3 hs6 mdate 
gisid cty_iso3 hs6 mdate

*Rename vars
rename m_tariff z_usi
rename m_increase dz_usi

*Collapse by time period
g date = dofm(mdate)
g year = yofd(date)
g t = 0 if year == 2016 | year == 2017
replace t = -1 if inrange(year,2014,2015)
replace t= 1 if inrange(year,2018,2019)
gcollapse z_usi dz_usi, by(cty_iso3 hs6 t)
g dlz_usi = ln(1+dz_usi)

*Save
compress
save "$processed/z_usi", replace

exit
