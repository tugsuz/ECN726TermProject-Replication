/**************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
* Master do file
**************************************************/

clear all
set more off 

*Set directories
do "00_directories.do"

*************************************************
*** Data processing programs
*************************************************

*** Trade flows
	do "$code/comtrade.do" 					// Comtrade data
	
*** Country codes and export ranking
	do "$code/iso_codes.do" 				// ISO Codes
	do "$code/cty_codes.do" 				// Country codes
	do "$code/cty_rank.do" 					// Ranking of countries by exports

*** Tariffs
	do "$code/china_weight.do" 				// Weights for US tariffs on China to collapse from HS10 to HS6 
	do "$code/z_usch.do" 					// US tariffs on China 	
	do "$code/z_chus.do" 					// China tariffs on the US
	do "$code/z_chrw.do" 					// China tariffs on ROW
	do "$code/z_usi.do" 					// US tariffs on other countries

*** Country characteristics
	do "$code/cty_distances.do"				// Distances to/from the US and China
	do "$code/FDI_stock.do"					// FDI stocks
	do "$code/FDI_inflow.do"				// FDI flows
	do "$code/country_gdp.do"				// GDP data
	do "$code/chars.do"					// Merge into one file
	
*** Main build
	do "$code/build.do"					// Creates datasets used in analysis 	
	
*************************************************
*** Analysis programs
*************************************************	
	
*** Binscatter plots + pre-trend table 
	do "$code/didplots.do" 					// Creates Figures 1, A3, and A4; and Table A2 
	
*** Main regressions 
	cd "$code"
	sh shbsregs.sh						// Shell program runs main regressions + bootstraps in parallel processing
	*do "$code/bsregs.do"					// Alternately, run the bootstraps sequentially in a loop (takes longer)

*** Main figures 
	do "$code/winners.do"					// Creates Figures 2 and 3
	do "$code/quadplot.do"					// Creates Figure 4
	 
*** Appendix figures 
	do "$code/sumplots.do"					// Creates Figures A1 and A2 

	
noi dis "END"
cap log close
exit 
