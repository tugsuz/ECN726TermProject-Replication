/**************************************************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
* Create Figure 4
**************************************************************************************/

clear

*Set directories
do "$code/00_directories.do"

*Log file
cap log close
cap log using "$logs/quadplot.log", replace

*Destinations
local dlist us ch rw

*******************************************
*** Plot Country-specific betas (CSQ_C) ***
*******************************************

*Read beta file
use "$tmp/bs_beta_v_cs_bs0",clear

*Make unique at the country-level
keep iso hs6 betaCSQ*
gcollapse (mean) betaCSQ*, by(iso)
duplicates drop
isid iso
rename beta*_bs0 b0_beta*	

*Drop usi chrw tariffs
drop *usi* *chrw*

*Drop components
drop *CSQ_C_* *CSQ_S_* *CSQ_Q_*

*Keep bystanders only
drop if inlist(iso,"CHN","USA")	

*Make variable names shorter
rename b0_beta* b_*
keep iso b_CSQ_*
rename b_CSQ_* b_*
drop *_usch_ch *_chus_us

*Quadrants
g quad_same = .
replace quad_same = 1 if (b_usch_us>0 & b_usch_rw>0) & (b_chus_ch>0 & b_chus_rw>0)
replace quad_same = 1 if (b_usch_us<0 & b_usch_rw<0) & (b_chus_ch<0 & b_chus_rw<0)
g quad_diag_down = .
replace quad_diag_down = 1 if (b_usch_us>0 & b_usch_rw>0) & (b_chus_ch<0 & b_chus_rw<0)
replace quad_diag_down = 1 if (b_usch_us<0 & b_usch_rw<0) & (b_chus_ch>0 & b_chus_rw>0)
g quad_diag_up = .
replace quad_diag_up = 1 if (b_usch_us<0 & b_usch_rw>0) & (b_chus_ch>0 & b_chus_rw<0)
replace quad_diag_up = 1 if (b_usch_us>0 & b_usch_rw<0) & (b_chus_ch<0 & b_chus_rw>0)
mvencode quad_*, mv(0) override
egen quad = rowtotal(quad_*)

*Plot labels
sum b_chus_rw
g x = (abs(b_chus_rw)+abs(b_usch_rw))/2
sum x
local y_lb = abs(r(max))
di `y_lb'
local y_lb = ceil(abs(`y_lb'/0.5))*0.5
di `y_lb'
local y_ub = abs(r(max))
local y_ub = ceil(abs(`y_ub'/0.5))*0.5
drop x
g x = (abs(b_chus_ch)+abs(b_usch_us))/2
sum x
local x_lb = abs(r(max))
local x_lb = ceil(abs(`x_lb'/0.5))*0.5
local x_ub = abs(r(max))
local x_ub = ceil(abs(`x_ub'/0.5))*0.5
drop x

*Precision label for axes
local dist = 0.5
local yq_ub = 3/4 * `y_ub'
local yq_lb = 3/4 * `y_lb'
local xq_ub = 1/2 * `x_ub'
local xq_lb = 1/2 * `x_lb'


***************************		
*** Substitutes with CHN
***************************

*Plot labels
sum b_chus_rw
g x = abs(b_usch_rw)
sum x
local y_lb = abs(r(max))
di `y_lb'
local y_lb = ceil(abs(`y_lb'/0.5))*0.5
di `y_lb'
local y_ub = abs(r(max))
local y_ub = ceil(abs(`y_ub'/0.5))*0.5
drop x
g x = abs(b_usch_us)
sum x
local x_lb = abs(r(max))
local x_lb = ceil(abs(`x_lb'/0.5))*0.5
local x_ub = abs(r(max))
local x_ub = ceil(abs(`x_ub'/0.5))*0.5
drop x

*Get precision level for axes
local dist = 0.5
local yq_ub = 3/4 * `y_ub'
local yq_lb = 3/4 * `y_lb'
local xq_ub = 1/2 * `x_ub'
local xq_lb = 1/2 * `x_lb'

*Fig 4 Panel A
twoway ///
	(scatter b_usch_rw  b_usch_us if quad_same==0 & quad_diag_down==0 & quad_diag_up==0, ///
		ms(i) mlabpos(0) mlabel(iso) mlabsize(small) mlabcolor(gs10)) ///
	(scatter b_usch_rw  b_usch_us if quad_same==1, ms(i) mlabpos(0) mlabel(iso) mlabsize(small) mlabcolor(blue)) ///
	(scatter b_usch_rw  b_usch_us if quad_diag_down==1, ms(i) mlabpos(0) mlabel(iso) mlabsize(small) mlabcolor(red)) ///
	(scatter b_usch_rw  b_usch_us if quad_diag_up==1, ms(i) mlabpos(0) mlabel(iso) mlabsize(small) mlabcolor(green)) ///
	, legend(off) ytitle("{&beta}(RW,1i)") xtitle("{&beta}(US,1i)") ///
	yline(0, lpattern(solid) lcolor(maroon)) xline(0, lpattern(solid) lcolor(maroon))  ///
	xlabel(-`x_lb'(`dist')`x_ub') ylabel(-`y_lb'(`dist')`y_ub') ///
	text(`yq_ub' -`xq_lb' "upward supply, CH complement", size(small) color(gs4)) ///
	text(`yq_ub' `xq_ub' "downward supply, CH substitute", size(small) color(gs4)) ///
	text(-`yq_lb' -`xq_lb' "downward supply, CH complement", size(small) color(gs4)) ///
	text(-`yq_lb' `xq_ub' "upward supply, CH substitute", size(small) color(gs4)) ///
	caption("", span size(small) pos(6)) 
	graph save "$tmp/us.gph",replace


***************************		
*** Substitutes with USA
***************************

*Plot labels
sum b_chus_rw
g x = abs(b_chus_rw)
sum x
local y_lb = abs(r(max))
di `y_lb'
local y_lb = ceil(abs(`y_lb'/0.5))*0.5
di `y_lb'
local y_ub = abs(r(max))
local y_ub = ceil(abs(`y_ub'/0.5))*0.5
drop x
g x = abs(b_chus_ch)
sum x
local x_lb = abs(r(max))
local x_lb = ceil(abs(`x_lb'/0.5))*0.5
local x_ub = abs(r(max))
local x_ub = ceil(abs(`x_ub'/0.5))*0.5
drop x

*Precision level for axes
local dist = 0.5
local yq_ub = 3/4 * `y_ub'
local yq_lb = 3/4 * `y_lb'
local xq_ub = 1/2 * `x_ub'
local xq_lb = 1/2 * `x_lb'

*Fig 4 Panel B
twoway ///
	(scatter b_chus_rw  b_chus_ch if quad_same==0 & quad_diag_down==0 & quad_diag_up==0, ///
		ms(i) mlabpos(0) mlabel(iso) mlabsize(small) mlabcolor(gs10)) ///
	(scatter b_chus_rw  b_chus_ch if quad_same==1, ms(i) mlabpos(0) mlabel(iso) mlabsize(small) mlabcolor(blue)) ///
	(scatter b_chus_rw  b_chus_ch if quad_diag_down==1, ms(i) mlabpos(0) mlabel(iso) mlabsize(small) mlabcolor(red)) ///
	(scatter b_chus_rw  b_chus_ch if quad_diag_up==1, ms(i) mlabpos(0) mlabel(iso) mlabsize(small) mlabcolor(green)) ///
	, legend(off) ytitle("{&beta}(RW,2i)") xtitle("{&beta}(CH,2i)") ///
	yline(0, lpattern(solid) lcolor(maroon)) xline(0, lpattern(solid) lcolor(maroon))  ///
	xlabel(-`x_lb'(`dist')`x_ub') ylabel(-`y_lb'(`dist')`y_ub') ///
	text(`yq_ub' -`xq_lb' "upward supply, US complement", size(small) color(gs4)) ///
	text(`yq_ub' `xq_ub' "downward supply, US substitute", size(small) color(gs4)) ///
	text(-`yq_lb' -`xq_lb' "downward supply, US complement", size(small) color(gs4)) ///
	text(-`yq_lb' `xq_ub' "upward supply, US substitute", size(small) color(gs4)) ///
	caption("", span size(small) pos(6))
	graph save "$tmp/ch.gph",replace

*Combine panels A and B
cd "$tmp"
graph combine us.gph ch.gph, rows(2) xsize(6) ysize(8) iscale(.5)
graph export "$results/fig_4.pdf",replace

exit

