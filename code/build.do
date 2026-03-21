/**************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
*** Main data build
**************************************************/

clear all
set more off 

*Set directories
do "$code/00_directories.do"

*Log file
cap log close
cap log using "$logs/build.log", replace

*Trade trade flows
use "$processed/global_trade_hs6_ct_consistent_hs12.dta" ///
	if inrange(year,2014,2019) & partner_iso3!="WLD" & reporter_iso3!="WLD", clear
		
*Include countries that report in all years
preserve
	keep if year == 2014
	keep reporter
	gduplicates drop
	tempfile reporter
	save `reporter', replace
restore
merge m:1 reporter using `reporter', keep(match) nogen

*Create three export destination groups (ie, groups of importers): US, China, all other
g rep = 1 if reporter_iso3=="USA"
replace rep = 2 if reporter_iso3=="CHN"
replace rep = 3 if mi(rep)

*Drop same-country imports/exports
drop if partner==reporter

*Rename var
rename import_value v
	
*Collapse by partner group
gcollapse (sum) v, by(partner* rep hs6 year)

*Label partner groups
label define repLBL 1 "US" 2 "China" 3 "ROW", replace
label values rep repLBL
label var rep "Reporting Group"

*Bin years
g t = -1 if inrange(year,2014,2015)
replace t = 0 if inrange(year,2016,2017)
replace t = 1 if inrange(year,2018,2019)
drop if mi(t)				

*Fix code error for SUDAN
replace partner = 729 if partner == 736
cap replace partner_name = "SUDAN" if partner_name == "FORMER SUDAN" | partner == 736

*Aggregate over pre- and post-period
gcollapse (sum) v, by(partner* rep hs6 t)

*Save tmp dataset as checkpoint
save "${tmp}tmpcheck1.dta", replace

***********
* Merge to get exporter iso3 country code
************

u "${tmp}tmpcheck1.dta", clear

*Fix Romania country code
g iso_code = partner
replace iso_code = 642 if partner == 946 
replace partner = 642 if partner == 946
drop if partner == 175

*Merge iso codes 
preserve
	import delimited "$raw/wb_country_groups/iso_codes.csv", varnames(1) clear
	keep iso3digitalpha ctycode ctyfullnameenglish endvalidyear
	rename (iso3digitalpha ctycode ctyfullnameenglish) (iso3 iso_code cty_name)
	replace cty_name = "UNITED STATES" if iso3 == "USA"
	replace cty_name = "CHINA" if iso3 == "CHN"
	replace cty_name = "HONG KONG" if iso3 == "HKG"
	insobs 1
	replace iso3 = "BLM" if mi(iso3)
	replace iso_code = 652 if iso3 == "BLM"
	replace cty_name = "Saint Barthelemy" if iso3 == "BLM"
	gisid iso3 iso_code
	tempfile iso
	save `iso'
restore
merge m:1 iso_code using `iso', keep(master match) keepusing(iso3 cty_name endvalidyear)
assert _m == 3
drop _m
	
*Country name/code fixes
rename iso3 cty_iso3
drop iso_code
g partner_name = upper(cty_name)
replace cty_name = partner_name if cty_name == ""
replace partner_name = upper(partner_name)
replace partner_name = "SWITZERLAND" if partner == 757
replace cty_name = "SWITZERLAND" if partner == 757
replace cty_iso3 = "MCO" if partner_name == "MONACO"
replace partner_name = "HONG KONG" if cty_iso3 == "HKG"

*Fix Taiwan
replace cty_iso3 = "TWN" if partner == 490
replace partner_name = "TAIWAN" if cty_iso3 == "TWN"
replace cty_name = "TAIWAN" if cty_iso3 == "TWN"
replace partner_iso3 = "TWN" if cty_iso3 == "TWN"

*Exclude oil exporters
drop if regexm(cty_iso3, "(SAU|RUS|IRQ|ARE|NGA|QAT|NOR|KAZ|KWT|IRN|AGO|DZA|OMN|VEN)")

*Drop if missing country
drop if cty_iso3 == "NULL"

******************************
* Merge tariffs
******************************

*Make HS codes numeric
destring hs6, replace

*Merge with US tariffs on China
merge m:1 hs6 t using "$processed/z_usch_w", nogen keep(master match) keepusing(z* dlz* dz*)

*China tariffs on US
merge m:1 hs6 t using "$processed/z_chus_w", nogen keep(master match) keepusing(z* dlz* dz*)

*Merge with China tariffs on ROW (ex-US)
fmerge m:1 hs6 t using "$processed/z_chrw", nogen keep(master match) keepusing(z* dlz* dz*)

*Merge with US variety-level tariffs on country i
merge m:1 cty_iso3 hs6 t using "$processed/z_usi", nogen keep(master match) keepusing(z_usi* dlz_usi* dz_usi*)

*Save data as checkpoint	
save "$tmp/tmpcheck2", replace
	
******************************
* Prepare panel
******************************

*Read file
u "$tmp/tmpcheck2", clear

*Log outcome
g lv = log(v)

*Set Panel
gegen id = group(partner rep hs6)
gsort id t
tsset id t 

*Log Difference
g dlv = d.lv

*Lags
g dlv_lag = l.dlv

*Set missing tariff values to zero
mvencode z_* dz_*, mv(0) override 
	
*New ID's / set panel
cap drop id
gegen id = group(partner_name rep hs6)
gsort id t
tsset id t 

*HS2 and HS4 codes
g x = string(hs6)
replace x = "0" + x if length(x)==5
g hs2 = real(substr(x,1,2))
g hs4 = real(substr(x,1,4))
drop x

*Merge with broad hs6 sectors 
fmerge m:1 hs6 using "$raw/crosswalk/hs6_broad_sectors", keep(master match) nogen
gegen xx = mode(hsind), by(hs4)
replace hsind = xx if mi(hsind)
gegen xxx = mode(hsind), by(hs2)
replace hsind = xxx if mi(hsind)
drop xx xxx
decode hsind, gen(ind)

*Sectors
encode partner_name, gen(country)
replace ind = "Leathers" if ind=="Footwear"
replace ind = "StoneGlass" if ind=="Stone and Glass"
replace ind = "WoodProducts" if ind=="Wood Products"
replace ind = "AnimalProducts" if ind=="Animal Products"
replace ind = "Apparel" if inlist(ind,"Footwear","Leathers","Textiles")
replace ind = "Agriculture" if inlist(ind,"AnimalProducts","Foodstuffs","Vegetables")
replace ind = "Materials" if inlist(ind,"Plastics","WoodProducts","StoneGlass")	
encode ind, gen(ind9)
rename ind ind9_str

*Save tmp file as checkpoint
save "$tmp/tmpcheck3", replace

	
**************************
* Make some variables wide
**************************

*Read file
u "$tmp/tmpcheck3", clear

*Set panel 
gsort id t
tsset id t

*Loop outcomes
foreach v in v lv dlv {

	*US imports from China
	g x = `v' if rep==1 & partner_name=="CHINA"
	gegen `v'_usch = mean(x), by(hs6 t)
	g z = l.`v'_usch
	gegen `v'_usch_lag = mean(z), by(hs6 t)
	drop x z

	*US imports from country i
	g x = `v' if rep==1  & partner_name!="WORLD" // exlcude world aggregate
	gegen `v'_us = mean(x), by(partner_name hs6 t)
	g z = l.`v'_us
	gegen `v'_us_lag = mean(z), by(partner_name hs6 t)
	drop x z

	*China imports from US
	g x = `v' if rep==2 & partner_name=="UNITED STATES"
	gegen `v'_chus = mean(x), by(hs6 t)
	g z = l.`v'_chus
	gegen `v'_chus_lag = mean(z), by(hs6 t)
	drop x z

	*China imports from country i 
	g x = `v' if rep==2  & partner_name!="WORLD" // >0 exlcude world aggregate
	gegen `v'_ch = mean(x), by(partner_name hs6 t)
	g z = l.`v'_ch
	gegen `v'_ch_lag = mean(z), by(partner_name hs6 t)
	drop x z	

	*ROW imports from country i
	g x = `v' if rep==3  & partner_name!="WORLD"
	gegen `v'_rw = mean(x), by(partner_name hs6 t)
	g z = l.`v'_rw
	gegen `v'_rw_lag = mean(z), by(partner_name hs6 t)
	drop x z	

}

*Total world exports of country i 
gegen v_wd = sum(v), by(partner hs6 t)

*Take logs and differences and lags of exports to world
gsort id t
tsset id t
g lv_wd = log(v_wd)
g x = d.lv_wd
gegen dlv_wd = mean(x), by(partner hs6 t)
drop x

g x = l.dlv_wd
gegen dlv_wd_lag = mean(x), by(partner hs6 t)
drop x

g x = l.v_wd
gegen v_wd_lag = mean(x), by(partner hs6 t)
drop x

*Set missing tariff changes to zero
foreach v of varlist dlz* {
	replace `v' = 0 if mi(`v') & t==1
}

*Drop duplicate observations
duplicates drop partner hs6 t, force
gisid partner hs6 t
drop rep

*Set panel
cap drop id
gegen id = group(partner hs6)
tsset id t

*Save
compress
save "$tmp/tmpcheck4", replace

********************************
*** Final Data   ***
********************************

*Read file
u "$tmp/tmpcheck4", clear

*No tariff changes in the pre-period
foreach v of varlist dz_* dlz_* {
	replace `v' = 0 if t<1
	}

*Fix country and industry names
replace partner_name="VENEZUELA" if partner_name=="BOLIVARIAN REPUBLIC OF VENEZUELA"
replace partner_name="TAIWAN" if partner_name=="TAIWAN, PROVINCE OF CHINA"
replace partner_name=subinstr(partner_name," ","",.)

*************
* Compute weights and other shares
*************

*weights: ij share of i's exports in {wd,rw} 
preserve
	keep if t==0 //set pre-period for weights
	keep hs6 partner_name v_wd v_rw v_ch v_us
	foreach q in wd rw us ch {
		bys partner_name: gegen tot_i = sum(v_`q')
		g sw_`q' = v_`q'/tot_i
		bys partner_name: gegen mintmp = min(sw_`q') if sw_`q'>0
		bys partner_name: gegen mintmp2 = min(mintmp)
		g sw_`q'_no0 = sw_`q'
		replace sw_`q'_no0 = mintmp2 if sw_`q'==0 //set zero weights to r(min)
		bys partner_name: gegen tot_i2 = sum(sw_`q'_no0)
		replace sw_`q'_no0 = sw_`q'_no0/tot_i2
		drop mintmp mintmp2 tot_i tot_i2
	}
	keep hs6 partner_name sw_*
	tempfile sw
	save `sw'
restore
merge m:1 partner_name hs6 using `sw', keep(master match) nogen

***************************************
* add additional destinations
***************************************

foreach d in IND HKG CHNplusHKG rwexclHKG {

	preserve

	if "`d'" == "IND" local d1 `"reporter_iso3=="IND""'
	if "`d'" == "HKG" local d1 `"reporter_iso3=="HKG""'	
	if "`d'" == "CHNplusHKG" local d1 `"inlist(reporter_iso3,"CHN","HKG")"'	
	if "`d'" == "rwexclHKG" local d1 `"!inlist(reporter_iso3,"CHN","USA","HKG")"'	

	if "`d'" == "IND" local country_str "india"
	if "`d'" == "HKG" local country_str "HKG"
	if "`d'" == "CHNplusHKG" local country_str "CHNplusHKG"
	if "`d'" == "rwexclHKG" local country_str "rwexclHKG"


	*Read in global trade data
	use "${processed}/global_trade_hs6_ct_consistent_hs12.dta" ///
		if inrange(year,2014,2019) ///
		& `d1' , clear
		
	keep if partner_iso3!="WLD" & reporter_iso3!="WLD"
	
	*Drop these
	drop if partner==reporter
	
	*rename
	rename import_value v
	
	*Collapse by partner group
	gcollapse (sum) v, by(partner* hs6 year)

	// if its based on years
	g t = -1 if inrange(year,2014,2015)
	replace t = 0 if inrange(year,2016,2017)
	replace t = 1 if inrange(year,2018,2019)
	drop if mi(t)
	
	* fix SUDAN
	cap replace partner = 729 if partner == 736
	cap replace partner_name = "SUDAN" if partner_name == "FORMER SUDAN" | partner == 736

	*Aggregate over pre- and post-period
	gcollapse (sum) v, by(partner* hs6 t)
	g iso_code = partner

	* fix Romania country code
	replace iso_code = 642 if partner == 946 
	replace partner = 642 if partner == 946
	
	* drop partner 175 (country Mayotte, only exists in t==-1)
	drop if partner == 175
	
	tempfile tmp
	save `tmp', replace
	
	* merge iso codes 
		import delimited "$raw/wb_country_groups/iso_codes.csv", varnames(1) clear
		keep iso3digitalpha ctycode ctyfullnameenglish endvalidyear
		rename (iso3digitalpha ctycode ctyfullnameenglish) (iso3 iso_code cty_name)
		replace cty_name = "UNITED STATES" if iso3 == "USA"
		replace cty_name = "CHINA" if iso3 == "CHN"
		replace cty_name = "HONG KONG" if iso3 == "HKG"
		insobs 1
		replace iso3 = "BLM" if mi(iso3)
		replace iso_code = 652 if iso3 == "BLM"
		replace cty_name = "Saint Barthelemy" if iso3 == "BLM"
		gisid iso3 iso_code
		tempfile iso
		save `iso'
		
	* load back data
	u `tmp', clear
	fmerge m:1 iso_code using `iso', keep(master match) keepusing(iso3 cty_name)
	assert _m == 3
	drop _m

	* some country name/code fixes
	rename iso3 cty_iso3
	drop iso_code
	cap g partner_name = upper(cty_name)
	replace cty_name = partner_name if cty_name == ""
	replace partner_name = cty_name if partner_name == ""
	replace partner_name = upper(partner_name)
	replace partner_name = "SWITZERLAND" if partner == 757
	replace cty_name = "Switzerland" if partner == 757
	replace cty_iso3 = "MCO" if partner_name == "MONACO"
	replace partner_name = "HONG KONG" if cty_iso3 == "HKG"

	* Drop oil exporters
	drop if regexm(cty_iso3, "(SAU|RUS|IRQ|ARE|NGA|QAT|NOR|KAZ|KWT|IRN|AGO|DZA|OMN|VEN)")

	* Fix Taiwan
	replace cty_iso3 = "TWN" if partner == 490
	replace partner_name = "TAIWAN" if cty_iso3 == "TWN"
	replace cty_name = "TAIWAN" if cty_iso3 == "TWN"
	replace partner_iso3 = "TWN" if cty_iso3 == "TWN"

	* drop
	drop if cty_iso3 == "NULL"
	gisid cty_iso3 hs6 t
	
	* compute first diff and logs
	egen id = group(cty_iso3 hs6)
	gsort id t
	tsset id t
	rename v v_`country_str'
	foreach v of varlist *_`country_str' {
		g `v'_lag = l.`v'
		g l`v' = log(`v')
		g dl`v' = d.l`v'
		g dl`v'_lag = l.dl`v'
		drop l`v'
	}
		
	la var v_`country_str' "Exports value to `country_str'"	
	la var dlv_`country_str' "Change in log export value to `country_str'"
	
	destring hs6, replace
	tempfile dests
	save `dests', replace
	
	restore

	merge 1:1 cty_iso3 hs6 t using `dests', keep(master match) keepusing(v_* dlv_*)
	drop _m
	foreach v of varlist v_`country_str' dlv_`country_str' dlv_`country_str'_lag v_`country_str'_lag {
		replace `v' = . if cty_iso3 == "`d'"
	}
}

**************************
* small adjustments
**************************

*Drop unused vars
drop v lv dlv cty_name

*Labels
label var dlz_usch "USCH"
label var dlz_chus "CHUS"
label var dlz_usi  "USi"
label var dlz_chrw "CHi"

*Sort
gsort country hs6 t
gisid country hs6 t
gsort partner_name hs6 t

*************
* merge country ranking
*************

* merge country ranking
preserve
	keep if t < 1
	gcollapse (sum) v_wd, by(partner partner_name)
	gsort -v_wd
	g rank = _n
	tempfile rank
	save `rank'
restore
merge m:1 partner using `rank', keep(master match) keepusing(rank)
tab partner_iso3 if _m == 1
drop if _m == 1 &partner_iso3 == "ANT" // drop ANT because does not report in t-1
drop _m

* Check
gisid hs6 partner t

*Fix Korea
replace partner_name = "SOUTHKOREA" if cty_iso3 == "KOR"

*Lag of wd
gsort id t
g lv_wd_lag = l.lv_wd

*Drop hs6 == 999999 = not specified
drop if hs6 == 999999

*Keep top 50 exporters
preserve
gcollapse (sum) v_wd, by(cty_iso3)
gsort - v_wd
keep in 1/50
keep cty_iso3
tempfile top50
save "$processed/top50",replace 
restore
merge m:1 cty_iso3 using "$processed/top50", keep(match) nogen

*Save
compress
save "$processed/data5", replace
	
*******************************************************
*** 		Create file used for analysis	    ***
*******************************************************

*Read raw data
u "${processed}data5", clear

*Keep important vars
keep id partner partner_name cty_iso3 hs6 hsind ind9_str t ///
	dlz_usch dlz_chus dlz_usi dlz_chrw ///
	dl*_us dl*_ch dl*_rw dl*_wd  /// 
	dl*_us_lag dl*_ch_lag dl*_rw_lag dl*_wd_lag *_us *_rw *_ch *_wd *_us_lag *_ch_lag *_rw_lag *_wd_lag v_*_lag

*Square the panel
fillin cty_iso3 hs6 t
drop _fillin

*Replace missings in the panel
mvencode v_*, mv(0) override

*New ID variable
cap drop id 
gegen id = group(cty_iso3 hs6)
tsset id t
gsort id t

// Ensure no missing industry codes
preserve
	keep hs6 ind9_str
	drop if mi(ind9_str)
	duplicates drop
	tempfile ind
	save `ind', replace
restore
merge m:1 hs6 using `ind', nogen update
assert !mi(ind9_str)
encode ind9_str, gen(industry)
gegen cs = group(cty_iso3 industry)

*Entry/exit variables
foreach d in us ch rw wd {
	g dle_`d' = v_`d'_lag==0 & v_`d'!=0
	g dlx_`d' = v_`d'_lag!=0 & v_`d'==0
	replace dle_`d' = . if v_`d'_lag!=0 	//remove incumbents & exiters
	replace dlx_`d' = . if v_`d'_lag==0 	//remove entrants & 0-0
}

*Value changes
sort id t
foreach v in v_us v_ch v_rw {
	g d`v' = d.`v'
}

*Country dummies
g us = cty_iso3=="USA"
g ch = cty_iso3=="CHN"
g rw = !inlist(cty_iso3,"USA","CHN")

***Tariff variables
replace dlz_chrw = 0 if inlist(cty_iso3,"USA","CHN")
replace dlz_usi = 0 if inlist(cty_iso3,"USA","CHN")

*Fill in tariffs missing b/c of squaring the data
foreach v of varlist dlz* {
	replace `v' = 0 if t<=0
}
gegen x = max(dlz_usch), by(hs6 t)
replace dlz_usch = x if mi(dlz_usch)
drop x
gegen x = max(dlz_chus), by(hs6 t)
replace dlz_chus = x if mi(dlz_chus)
drop x
gegen x = max(dlz_usi), by(hs6 t)
replace dlz_usi = x if mi(dlz_usi) & cty_iso3!="CHN"
drop x
gegen x = max(dlz_chrw), by(hs6 t)
replace dlz_usi = x if mi(dlz_usi) & cty_iso3!="USA"
drop x
foreach v of varlist dlz* {
	replace `v' = 0 if mi(`v')
}

*Formal
order cty_iso3 hs6 ind9 t
gsort id t

tempfile hold
save `hold'

****Weights
*Destination weights
preserve 
	keep if t==0
	collapse (sum) v_us v_ch v_rw v_wd, by(cty_iso3)
	foreach d in us ch rw wd {
		g W_`d' = v_`d'/ v_wd
	}
	keep cty_iso3 W_*
	g iso = cty_iso3
	save "$processed/Dweights", replace
restore

*Exporter weights
preserve 
	keep if t==0
	collapse (sum) v_us v_ch v_rw v_wd, by(cty_iso3) fast
	foreach d in us ch rw wd {
		gegen xx = sum(v_`d')
		g X_`d' = v_`d' / xx
		drop xx
		}
		keep cty_iso3 X_*
		g iso = cty_iso3
	save "$processed/Xweights", replace
restore

**Save off sample of countries 
preserve
	keep if t==1
	keep cty_iso3 hs6
	tempfile fullsample
	save `fullsample'
restore

*Intensive margin weights
foreach d in us ch rw wd {
	use `hold',clear
	keep if v_`d'!=0 & v_`d'_lag!=0 //intensive margin
	keep if t==1
	keep cty_iso3 hs6 v_`d'_lag //period 0
	rename v_`d' vwgt_i_`d'
	isid cty_iso3 hs6
	save "$processed/vgwt_i_`d'",replace
}
	
*Entry margin weights
foreach d in us ch rw wd {
	use `hold',clear
	keep if dle_`d'==1 //actual entrants
	keep if t==1
	count
	if `r(N)'== 0 {
		use `fullsample',clear
		g v_`d' = 0
	}
	keep cty_iso3 hs6 v_`d' //period 1
	bys cty_iso3: egen xx = mean(v_`d') //get avg entrant value
	rename xx vwgt_e_`d'
	keep cty_iso3 hs6 vwgt_e_`d'
	isid cty_iso3 hs6
	save "$processed/vgwt_e_`d'",replace
}

*Exit margin weights
foreach d in us ch rw wd {
	use `hold',clear
	keep if dlx_`d'==1 //actual exiters
	keep if t==1
	count
	if `r(N)'== 0 {
		use `fullsample',clear
		g v_`d'_lag = 0
	}		
	keep cty_iso3 hs6 v_`d'_lag //period 0
	rename v_`d' vwgt_x_`d'
	isid cty_iso3 hs6
	save "$processed/vgwt_x_`d'",replace
}

*Total exports, period 0
use `hold',clear
	keep if t==0
	collapse (sum) v_us v_ch v_rw v_wd, by(cty_iso3)
	rename v_* totv0_*
	tempfile totv0
save `totv0'

*Merge in weights
use `hold',clear
	foreach d in us ch rw wd {
		merge m:1 cty_iso3 hs6 using "$processed/vgwt_i_`d'", keep(master match) nogen
		merge m:1 cty_iso3 hs6 using "$processed/vgwt_e_`d'", keep(master match) nogen
		merge m:1 cty_iso3 hs6 using "$processed/vgwt_x_`d'", keep(master match) nogen
	}
merge m:1 cty_iso3 using `totv0', assert(match) nogen

*Keep only a cross-section
keep if t==1
drop t 

*Set US/CH trade to self to missing
replace v_us = . if us
replace v_us_lag = . if us
replace v_ch = . if ch
replace v_ch_lag = . if ch

*Missing value dummies
foreach d in us ch rw wd {
	g dlv_`d'_lag_miss = dlv_`d'_lag
	g mv_v_`d' = mi(dlv_`d'_lag)
	replace dlv_`d'_lag = 0 if mi(dlv_`d'_lag)
}

*Size variables
foreach d in us ch rw wd {
	egen E_`d'_lag = total(v_`d'_lag), by(hs6)
}

*Labels
lab var dlz_usch "$\Delta T^{US}_{CH,\omega}$ ($\beta_{1}$)"
lab var dlz_chus "$\Delta T^{CH}_{US,\omega}$ ($\beta_{2}$)"
lab var dlz_usi "$\Delta T^{US}_{i,\omega}$ ($\beta_{3}$)"
lab var dlz_chrw "$\Delta T^{CH}_{i,\omega}$ ($\beta_{4}$)"

*cleanup variables
drop dv* partner partner_name v*usch* industry partner_name dv_* hsind
		
*Save
compress
order cty_iso3 hs6 ind9_str
compress

save "$processed/rf", replace

