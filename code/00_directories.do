/**************************************************
The US-China Trade War and Global Reallocations
Fajgelbaum, Goldberg, Kennedy, Khandelwal, and Taglioni
July 2023
*** Set directories
**************************************************/

// Set root directory
global db "/Users/mehmettugsuz/Downloads/The US-China Trade War and Global Reallocations  GTW_replication/" // replace this line with your root directory

// All other paths set automatically
global code 		"${db}code/"
global logs 		"${db}code/logs/"
global raw 		"${db}data/raw/"
global tmp 		"${db}data/tmp/"
global processed 	"${db}data/processed/" 
global results 		"${db}results/" 

// Set scheme
cap net install scheme-modern, from("https://raw.githubusercontent.com/mdroste/stata-scheme-modern/master/")
set scheme modern, perm

* Variable abbreviations 
set varabbrev on 

