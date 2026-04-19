clear all
set more off

* 1. Load the main reduced-form dataset
* (Ensure your working directory is set to the 'code' folder before running)
use "../data/processed/rf.dta", clear

* 2. Set up a 'postfile' to store our 5 meta-analysis estimates
cap postutil clear
postfile mymeta str30 spec_name beta se using "../data/processed/meta_results.dta", replace

* Define macros based on bsregs.do
local depvar       "dlv_rw"
local tariff_shock "dlz_usch"
local controls     "dlv_rw_lag mv_v_rw"
local baseline_fe  "cs"
local broad_fe     "cty_iso3"

* Drop US and China from the bystander analysis (as done in the P pooled spec)
keep if !inlist(cty_iso3, "USA", "CHN")

* ==============================================================================
* RUNNING THE 5 META-ANALYSIS SPECIFICATIONS
* ==============================================================================

* Spec 1: Baseline (All data, full controls, baseline FE)
reghdfe `depvar' `tariff_shock' `controls', absorb(`baseline_fe') cluster(hs6)
post mymeta ("1. Baseline") (_b[`tariff_shock']) (_se[`tariff_shock'])

* Spec 2: No Covariates
reghdfe `depvar' `tariff_shock', absorb(`baseline_fe') cluster(hs6)
post mymeta ("2. No Covariates") (_b[`tariff_shock']) (_se[`tariff_shock'])

* Spec 3: Broader Fixed Effects (Country-level instead of Country-Sector)
reghdfe `depvar' `tariff_shock' `controls', absorb(`broad_fe') cluster(hs6)
post mymeta ("3. Broader FEs (Country)") (_b[`tariff_shock']) (_se[`tariff_shock'])

* Spec 4: Agriculture Only
reghdfe `depvar' `tariff_shock' `controls' if ind9_str == "Agriculture", absorb(`baseline_fe') cluster(hs6)
post mymeta ("4. Agriculture Only") (_b[`tariff_shock']) (_se[`tariff_shock'])

* Spec 5: Non-Agriculture / Manufacturing
reghdfe `depvar' `tariff_shock' `controls' if ind9_str != "Agriculture", absorb(`baseline_fe') cluster(hs6)
post mymeta ("5. Non-Ag / Mfg") (_b[`tariff_shock']) (_se[`tariff_shock'])

* Close the postfile
postclose mymeta

* ==============================================================================
* 3. GENERATE THE FOREST PLOT FOR YOUR PRESENTATION & REPORT
* ==============================================================================
use "../data/processed/meta_results.dta", clear

* Generate 95% confidence intervals
gen ci_low = beta - 1.96*se
gen ci_high = beta + 1.96*se
gen id = _n

* Plot the results
twoway (rcap ci_low ci_high id, horizontal lcolor(navy)) ///
       (scatter id beta, mcolor(maroon) msize(large)), ///
       ylabel(1 "Baseline" 2 "No Covariates" 3 "Broader FEs" 4 "Agriculture Only" 5 "Non-Ag / Mfg", angle(0) valuelabel) ///
       ytitle("") ///
       xtitle("Estimated Tariff Elasticity (Beta)") ///
       title("Sensitivity of Bystander Export Elasticity") ///
       subtitle("Internal Meta-Analysis of Model Specifications") ///
       legend(off) ///
       xline(0, lcolor(red) lpattern(dash)) ///
       graphregion(color(white))

* Save the plot directly to your results folder
graph export "../results/meta_analysis_forest_plot.pdf", replace
graph export "../results/meta_analysis_forest_plot.png", replace

disp "META-ANALYSIS COMPLETE. CHECK RESULTS FOLDER FOR PLOT."
