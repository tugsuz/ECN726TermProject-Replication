clear all
set more off

* 1. Load data and drop US/China
use "../data/processed/rf.dta", clear
keep if !inlist(cty_iso3, "USA", "CHN")

* 2. CREATE GEOGRAPHIC REGIONS MANUALLY (Fast and safe method)
gen region = "Other"

* Asian Countries (Heart of the supply chain - broken into two lists to avoid Stata limit)
replace region = "Asia" if inlist(cty_iso3, "KOR", "JPN", "VNM", "TWN", "MYS", "THA", "IDN", "PHL")
replace region = "Asia" if inlist(cty_iso3, "SGP", "IND", "HKG", "BGD", "PAK", "LKA")

* European Countries
replace region = "Europe" if inlist(cty_iso3, "DEU", "FRA", "GBR", "ITA", "ESP", "NLD", "BEL", "CHE")
replace region = "Europe" if inlist(cty_iso3, "POL", "SWE", "AUT", "DNK", "FIN", "NOR", "PRT", "IRL")
replace region = "Europe" if inlist(cty_iso3, "CZE", "HUN")

* Americas (North and South)
replace region = "Americas" if inlist(cty_iso3, "MEX", "CAN", "BRA", "ARG", "CHL", "COL", "PER", "URY")
replace region = "Americas" if cty_iso3 == "ECU"

* 3. Set up the second postfile (to save results)
cap postutil clear
postfile mymeta2 str30 spec_name beta se using "../data/processed/meta_results_region.dta", replace

local depvar       "dlv_rw"
local tariff_shock "dlz_usch"
local controls     "dlv_rw_lag mv_v_rw"
local baseline_fe  "cs"

* Spec 1: Asia Only
reghdfe `depvar' `tariff_shock' `controls' if region == "Asia", absorb(`baseline_fe') cluster(hs6)
post mymeta2 ("1. Asia Subsample") (_b[`tariff_shock']) (_se[`tariff_shock'])

* Spec 2: Europe Only
reghdfe `depvar' `tariff_shock' `controls' if region == "Europe", absorb(`baseline_fe') cluster(hs6)
post mymeta2 ("2. Europe Subsample") (_b[`tariff_shock']) (_se[`tariff_shock'])

* Spec 3: Americas Only
reghdfe `depvar' `tariff_shock' `controls' if region == "Americas", absorb(`baseline_fe') cluster(hs6)
post mymeta2 ("3. Americas Subsample") (_b[`tariff_shock']) (_se[`tariff_shock'])

postclose mymeta2

* 4. GENERATE THE GRAPH AND PRINT THE TABLE
use "../data/processed/meta_results_region.dta", clear
gen ci_low = beta - 1.96*se
gen ci_high = beta + 1.96*se
gen id = _n

twoway (rcap ci_low ci_high id, horizontal lcolor(dknavy)) ///
       (scatter id beta, mcolor(orange_red) msize(large)), ///
       ylabel(1 "Asia" 2 "Europe" 3 "Americas", angle(0) valuelabel) ///
       ytitle("") ///
       xtitle("Estimated Tariff Elasticity (Beta)") ///
       title("Regional Heterogeneity in Bystander Effects") ///
       subtitle("Is the Trade War Opportunity Geographically Concentrated?") ///
       legend(off) ///
       xline(0, lcolor(red) lpattern(dash)) ///
       graphregion(color(white))

graph export "../results/regional_forest_plot.png", replace
graph export "../results/regional_forest_plot.pdf", replace

* Print table to the screen:
list spec_name beta se, clean
