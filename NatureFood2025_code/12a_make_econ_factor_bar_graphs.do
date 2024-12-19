* Project:	Humane Practice Adoption
* Author:	Trevor Woolley
* Date:		9/8/23
* Purpose:	Create bar graphs to describe the market factors that are incentives and disincentives to adopting humane practices. THESE graphs are done separately for each practice category, whereas those (for market factors) in 5_bar_graphs_finalsample are not separated by practice category.
******************************************************************************
global homedir "D:\Projects\ASPCA"
global datadir "D:\Projects\ASPCA\data"
global figdir "D:\Projects\ASPCA\figures"

ssc install filelist
ssc install dataex
net install grc1leg, from( http://www.stata.com/users/vwiggins/)
graph set window fontface "Times New Roman"
graph set eps fontface "Times New Roman"
******************************************************************************
* Pull in data
	use "${datadir}\clean_data\final\final_data3", clear
	// graphs using final_data3 have suffix 3b2.eps
******************************************************************************

**** Duplicate observations that have two market factors. One gets the one factor and the other gets the other *****************************************
	gen multi_factors = mf_TechEff + mf_AnHealth + mf_Demand + mf_Life + mf_FixedC + mf_OperationC + mf_Price + mf_Quality + mf_Productivity + mf_Sales + mf_Profit
	
	expand 2 if multi_factors == 2 
	
	bysort id Dep_Var Indep_Var Practice : gen n = _n
	bysort id Dep_Var Indep_Var Practice : gen N = _N

	tab market_factor if N==2
	tab market_factor if n==2
	replace market_factor = "quality/productivity" if strpos(market_factor, "quality") & strpos(market_factor, "production")
	replace market_factor = "quality" if strpos(market_factor, "quality") & N == 2 & n == 1
	replace market_factor = "animal health" if strpos(market_factor, "health") & N == 2 & n == 1
	replace market_factor = "productivity" if strpos(market_factor, "producti") & N == 2 & n == 2
	replace market_factor = "operation cost" if strpos(market_factor, "operation cost") & N == 2 & n == 2
	
	tab market_factor if N==2
	tab market_factor if n==1 & N==2
	tab market_factor if n==2
	// Still need to do for the shared animal wellbeing ones to extract the second market factor (or maybe I can just remove that part of the string)
	
	* Remove "animal wellbeing" and any "/"
	replace market_factor = subinstr(market_factor, "/","",.)
	
	tab market_factor
	
	* Consolidate market factors that are sub-categories
	replace market_factor = "price" if market_factor == "demand"
	replace market_factor = "productivity" if market_factor == "technical efficiency"
	
********* Drop results that are not significant or no direction ****************
	drop if motivator_dum ==0 & barrier_dum == 0
	keep if strpos(significant, "Y")
	
	codebook id if pract_is_dep_var !="Y"
	// 57 unique papers. 310 results. (Down from 101 unique papers and 794 results, among which 661 results have a sign amongst 89 unique papers.)
	// The poll + SP + TW only gave us 2 new papers and 10 new results.
	
	drop if pract_is_dep_var =="Y" 
	// Of all the "exogenous_factor" results, only three papers were not consumer preference studies (therefore not easily framable in our study about producer decisions). One studied the prevalence of pasture access under different dairy systems (Parasites and parasite management practices of organic and conventional dairy herds in Minnesota); one studies available pasture access per cow across US regions (Thirty years of organic dairy in the United States: the influences of farms, the market and the organic regulation); and one studies the drivers of cage free practice adoption (Capital Budgeting Analysis of a Vertically Integrated Egg Firm: Conventional and Cage-Free Egg Production). Only the first two were statistical.
	// I think the best thing to do might be to just show these results directly (perhaps reformatted). Table 1 from Sorge et al 2015 and Table 3, 4, & 6 and Fig 3 from Dimitri and Nehring 2022.
	
********************************************************************************
*************** Collapse data (Result id Species level) ************************
********************************************************************************

	// If not collapsing by id first, skip this section
preserve	
	collapse (mean) motivator_dum barrier_dum, by(market_factor Species id)
	
	count if motivator_dum >0 & motivator_dum <1
	// 24 paper-factors have mixed results. Some results point one way and other point another way. I'll round them up and down to 1. So if a paper had 2 motivator results and 1 barrier for animal health, that paper is counted as 1 for motivator and 0 for barrier. If there is one for each, then the paper does not count the factor as motivator or barrier. But, papers are still able to be assigned to multiple factors. 
	replace motivator_dum = 0 if motivator_dum <=.5
	replace motivator_dum = 1 if motivator_dum >.5 & motivator_dum <1
	replace barrier_dum = 0 if barrier_dum <=.5
	replace barrier_dum = 1 if barrier_dum >.5 & barrier_dum <1

****************** Collapse data (Result Species level) ***********************	
	// If not collapsing by id first (if you just want results, not by papers), you can jump straight here
	
	collapse (sum) motivator_dum barrier_dum, by(market_factor Species)
	
	replace barrier_dum = - barrier_dum
	foreach s in "Layer" "Broiler" "Dairy Cow" "Hog" {
		if "`s'" == "Dairy Cow" {
			local z = "Cow"
			local s2 = "Dairy Cow"
		}
		else if "`s'" == "Hog" {
			local z = "Hog"
			local s2 = "Pig"
		}
		else {
			local z = "`s'"
			local s2 = "`s'"
		}
		
		gen total_factor_`z' = motivator_dum + barrier_dum if Species == "`s2'"
		gen frac_factor_`z' = motivator_dum / total_factor_`z' if Species == "`s2'"
	}
	
	* No obs for hogs: profit --> drop
	drop if market_factor == "profit" & Species =="Hog"
	
	* No obs for cows: technical efficiency, ? --> drop
	drop if market_factor == "?" & Species =="Dairy Cow"
	drop if market_factor == "technical efficiency" & Species =="Dairy Cow"
	
	* No obs for layer: profit
	drop if market_factor == "profit" & Species =="Layer"
	
	* Capitalize market factors
	replace market_factor = "Animal health" if market_factor == "animal health"
	replace market_factor = "Productivity" if market_factor == "productivity"
	replace market_factor = "Price" if market_factor == "price"
	replace market_factor = "Quality" if market_factor == "quality"
	replace market_factor = "Profit" if market_factor == "profit"
	replace market_factor = "Fixed cost" if market_factor == "fixed cost"
	replace market_factor = "Farmer QOL" if market_factor == "farmer QOL"
	replace market_factor = "Sales" if market_factor == "sales"
	replace market_factor = "Operation cost" if market_factor == "operation cost"
	
************* Save data separately at results and paper levels *****************
// 	save "${datadir}\clean_data\final\finalsample_sig_collapsed_results3", replace
	save "${datadir}\clean_data\final\finalsample_sig_collapsed_papers3", replace
restore
	// The 3 means that I consolodated "demand" market factor into price and technical efficiency into productivity
********************************************************************************

preserve
foreach lvl in "Results" "Papers" {
	if "`lvl'" == "Results" {
		local title = "Significant Results"
		local labels = "-20(10)40"
		local ranges = "-25 40"
		
		use "${datadir}\clean_data\final\finalsample_sig_collapsed_results3", clear
	}
	else if "`lvl'" == "Papers" {
		local title = "Median Sig. Result per Paper"
		local labels = "-4(2)10"
		local ranges = "-4 10"
		
		use "${datadir}\clean_data\final\finalsample_sig_collapsed_papers3", clear
	}
	
	* Make graph for each species
	foreach s in "Layer" "Broiler" "Dairy Cow" "Hog" {
		if "`s'" == "Dairy Cow" {
			local z = "Cow"
			local s2 = "Dairy Cow"
		}
		else if "`s'" == "Hog" {
			local z = "Hog"
			local s2 = "Pig"
		}
		else {
			local z = "`s'"
			local s2 = "`s'"
		}
		
		graph hbar (asis) motivator_dum barrier_dum if Species=="`s2'", over(market_factor, ///
		sort(total_factor_`z') descending) ///
		stack ///
		ytitle("# of `lvl'") ///
		title("`s' Farms", span) ///
		ylabel(`labels') ///
		yscale(range(`ranges')) ///
		legend( rows(1) label(1 "Incentive") label(2 "Disincentive")) ///
		graphregion(color(white)) ///
		name(`lvl'_`z', replace)
		
		graph save `lvl'_`z', replace
	
// 		graph export "${figdir}\bar_marketfactor_motivator_finalsample_`z'_results2.png", replace
	}
// 	graph combine papers_Layer.gph papers_Broiler.gph papers_Cow.gph papers_Hog.gph, 
	
	grc1leg `lvl'_Layer `lvl'_Cow `lvl'_Broiler `lvl'_Hog, ///
		title("") ///
		graphregion(color(white)) ///
		iscale(.6) ///
		imargin(1 1 1 1 1) ///
		legendfrom(`lvl'_Layer) pos(bottom)
		
		graph export "${figdir}\bar_marketfactor_motivator_finalsample_combine_`lvl'3b2.eps", replace
	
	// I tried to add the fraction of each factor that is an incentive but could not get blabel or dot to work
	
****************** Collapse data (all species combined) ***********************	
	collapse (sum) motivator_dum barrier_dum, by(market_factor)
	
	gen total_factor = motivator_dum + barrier_dum
	gen frac_factor = motivator_dum / total_factor

	// If doing this for result level, change the ytitle to # of results, title, and file name. If on same y scal: ylabel(-50(25)100) yscale(range(-50 100)).
	graph hbar (asis) motivator_dum barrier_dum, over(market_factor, ///
	sort(total_factor) descending) ///
	stack ///
	title("`title'", span) ///
	ytitle("# of `lvl'") ///
	legend( rows(1) label(1 "Incentive") label(2 "Disincentive")) ///
	graphregion(color(white)) ///
	name(`lvl', replace)
	
	graph save `lvl', replace

// 	graph export "${figdir}\bar_marketfactor_motivator_finalsample_papers2.png", replace
}	

	grc1leg	Results Papers, ///
		title("") ///
		graphregion(color(white)) ///
		altshrink ///
		legendfrom(Papers) pos(bottom)
		
	graph export "${figdir}\bar_marketfactor_motivator_finalsample_comnbine3b2.eps", replace	
	// "_combine.png" is where both graphs have same y scale. "_combine2.png" is where they are on different scales (to see better detail onn the paper graph)
restore				
		
*******************************************************************************	
********************************************************************************

* Now repeat but for all five practice categories

********************************************************************************
********************************************************************************



********** Collapse data (Result id Species pract category level) **************
	// If not collapsing by id first (if you want result-level obs), skip this section
preserve	
	collapse (mean) motivator_dum barrier_dum, by(market_factor Species Pract_Cat id)
	
	count if motivator_dum >0 & motivator_dum <1
	// 24 paper-factors have mixed results. Some results point one way and other point another way. I'll round them up and down to 1. So if a paper had 2 motivator results and 1 barrier for animal health, that paper is counted as 1 for motivator and 0 for barrier. If there is one for each, then the paper does not count the factor as motivator or barrier. But, papers are still able to be assigned to multiple factors. 
	replace motivator_dum = 0 if motivator_dum <=.5
	replace motivator_dum = 1 if motivator_dum >.5 & motivator_dum <1
	replace barrier_dum = 0 if barrier_dum <=.5
	replace barrier_dum = 1 if barrier_dum >.5 & barrier_dum <1

****************** Collapse data (Result Species level) ***********************	
	// If not collapsing by id first (if you just want results, not by papers), you can jump straight here
	
	collapse (sum) motivator_dum barrier_dum, by(market_factor Species Pract_Cat)
	
	replace barrier_dum = - barrier_dum
	foreach s in "Layer" "Broiler" "Dairy Cow" "Hog" {
		if "`s'" == "Dairy Cow" {
			local z = "Cow"
			local s2 = "Dairy Cow"
		}
		else if "`s'" == "Hog" {
			local z = "Hog"
			local s2 = "Pig"
		}
		else {
			local z = "`s'"
			local s2 = "`s'"
		}
		
		gen total_factor_`z' = motivator_dum + barrier_dum if Species == "`s2'"
		gen frac_factor_`z' = motivator_dum / total_factor_`z' if Species == "`s2'"
	}
	
	* Fill in the gaps. There should be an observation for every market factor x Species x Pract_Cat even if that means motivator == 0
	// Still working on this v
	
	** No obs for hogs: profit --> drop
// 	replace motivator_dum = 0 if market_factor == "profit" & Species =="Hog"
// 	replace barrier_dum = 0 if market_factor == "profit" & Species =="Hog"
	
// 	expand 2 if market_factor == "profit" & Species =="Hog"
	
	* No obs for cows: technical efficiency, ? --> drop
	drop if market_factor == "?" & Species =="Dairy Cow"
	drop if market_factor == "technical efficiency" & Species =="Dairy Cow"
	
	* No obs for layer: profit
// 	drop if market_factor == "profit" & Species =="Layer"
	
	* Fill in the gaps for Broilers
// 	expand 2 if market_factor == "productivity" & Species =="Broiler"
	
				*^^^^^^^^^^^^ Go Back HERE ^^^^^^^^^^^^^^^^^^^^
	
	* Capitalize market factors
	replace market_factor = "Animal health" if market_factor == "animal health"
	replace market_factor = "Productivity" if market_factor == "productivity"
	replace market_factor = "Price" if market_factor == "price"
	replace market_factor = "Quality" if market_factor == "quality"
	replace market_factor = "Profit" if market_factor == "profit"
	replace market_factor = "Fixed cost" if market_factor == "fixed cost"
	replace market_factor = "Farmer QOL" if market_factor == "farmer QOL"
	replace market_factor = "Sales" if market_factor == "sales"
	replace market_factor = "Operation cost" if market_factor == "operation cost"
	
************* Save data separately at results and paper levels *****************
// 	save "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_results3", replace
	save "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_papers3", replace

restore
********************************************************************************
// The following code gets super complicated only bc some practice categories are missing for some species. Seems like I really should create market factors and practice categories for every species and just make the count 0.

foreach cat in "Indoor Env"  "Enrichment" "Confinement" "Outdoor Access"  "Mutilation" {
	if "`cat'" == "Confinement" {
		local c = "`cat'"
		local cat_title = "Less `cat'"
		global species "Layers Dairy"
	}
	if "`cat'" == "Mutilation" {
		local c = "`cat'"
		local cat_title = "Reducing `cat'"
	}	
	else if "`cat'" == "Outdoor Access" {
		local c = "Outdoor"
		local cat_title = "`cat'"
	}	
	else if "`cat'" == "Indoor Env" {
		local c = "Indoor"
		local cat_title = "Better `cat'"
	}
	else {
		local c = "`cat'"
		local cat_title = "`cat'"
	}
	
	if "`cat'" == "Confinement" {
		foreach lvl in "Results" "Papers" {
			if "`lvl'" == "Results" {
				local title = "Significant Results"
				local labels = "-5(5)10"
				local ranges = "-5 10"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_results3", clear
			}
			else if "`lvl'" == "Papers" {
				local title = "Median Sig. Result Per Paper"
				local labels = "-2(2)4"
				local ranges = "-2 5"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_papers3", clear
			}
			
			* Make graph for each species
			foreach s in "Layer" "Broiler" "Dairy Cow" "Hog" {
				if "`s'" == "Dairy Cow" {
					local z = "Cow"
					local s2 = "`s'"
				}
				else if "`s'" == "Hog" {
					local z = "Hog"
					local s2 = "Pig"
				}
				else {
					local z = "`s'"
					local s2 = "`s'"
				}
				
				graph hbar (asis) motivator_dum barrier_dum if Species=="`s2'" & Pract_Category == "`cat'", over(market_factor, ///
				sort(total_factor_`z') descending) ///
				stack ///
				ytitle("# of `lvl'") ///
				title("`s' Farms", span) ///
				ylabel(`labels') ///
				yscale(range(`ranges')) ///
				legend( rows(1) label(1 "Incentive") label(2 "Disincentive")) ///
				graphregion(color(white)) ///
				name(`lvl'_`z', replace)
				
				graph save `lvl'_`z', replace
			
		// 		graph export "${figdir}\bar_marketfactor_motivator_finalsample_`z'_results.png", replace
			}
		// 	graph combine papers_Layer.gph papers_Broiler.gph papers_Cow.gph papers_Hog.gph, 
			
			grc1leg `lvl'_Layer `lvl'_Cow `lvl'_Hog, ///
				title("(Dis-)Incentives for `cat_title'", ///
				span) subtitle("`title' (1990-2023)") ///
				graphregion(color(white)) ///
				iscale(.6) ///
				imargin(1 1 1 1 1) ///
				legendfrom(`lvl'_Layer) pos(bottom)
				
				graph export "${figdir}\bar_marketfactor_motivator_finalsample_combine_`c'_`lvl'3b2.png", replace
		}
	}	
	else if "`cat'" == "Enrichment" {
		foreach lvl in "Results" "Papers" {
			if "`lvl'" == "Results" {
				local title = "Significant Results"
				local labels = "-10(10)30"
				local ranges = "-15 30"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_results3", clear
			}
			else if "`lvl'" == "Papers" {
				local title = "Median Sig. Result Per Paper"
				local labels = "-2(2)4"
				local ranges = "-2 5"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_papers3", clear
			}
			
			* Make graph for each species
			foreach s in "Layer" "Dairy Cow" "Broiler" {
				if "`s'" == "Dairy Cow" {
					local z = "Cow"
					local s2 = "Dairy Cow"
				}
				else if "`s'" == "Hog" {
					local z = "Hog"
					local s2 = "Pig"
				}
				else {
					local z = "`s'"
					local s2 = "`s'"
				}
				
				graph hbar (asis) motivator_dum barrier_dum if Species=="`s2'" & Pract_Category == "`cat'", over(market_factor, ///
				sort(total_factor_`z') descending) ///
				stack ///
				ytitle("# of `lvl'") ///
				title("`s' Farms", span) ///
				ylabel(`labels') ///
				yscale(range(`ranges')) ///
				legend( rows(1) label(1 "Incentive") label(2 "Disincentive")) ///
				graphregion(color(white)) ///
				name(`lvl'_`z', replace)
				
				graph save `lvl'_`z', replace
			
		// 		graph export "${figdir}\bar_marketfactor_motivator_finalsample_`z'_results.png", replace
			}
		// 	graph combine papers_Layer.gph papers_Broiler.gph papers_Cow.gph papers_Hog.gph, 
			
			grc1leg `lvl'_Layer `lvl'_Cow `lvl'_Broiler, ///
				title("(Dis-)Incentives for `cat_title'", ///
				span) subtitle("`title' (1990-2023)") ///
				graphregion(color(white)) ///
				iscale(.6) ///
				imargin(1 1 1 1 1) ///
				legendfrom(`lvl'_Layer) pos(bottom)
				
				graph export "${figdir}\bar_marketfactor_motivator_finalsample_combine_`c'_`lvl'3b2.png", replace
		}
	}	
	else if "`cat'" == "Mutilation" {
		foreach lvl in "Results" "Papers" {
			if "`lvl'" == "Results" {
				local title = "Significant Results"
				local labels = "-10(10)30"
				local ranges = "-15 30"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_results3", clear
			}
			else if "`lvl'" == "Papers" {
				local title = "Median Sig. Result Per Paper"
				local labels = "-4(2)10"
				local ranges = "-4 10"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_papers3", clear
			}
			
			* Make graph for each species
			foreach s in "Dairy Cow" {
				if "`s'" == "Dairy Cow" {
					local z = "Cow"
					local s2 = "Dairy Cow"
				}
				else if "`s'" == "Hog" {
					local z = "Hog"
					local s2 = "Pig"
				}
				else {
					local z = "`s'"
					local s2 = "`s'"
				}
				
				graph hbar (asis) motivator_dum barrier_dum if Species=="`s2'" & Pract_Category == "`cat'", over(market_factor, ///
				sort(total_factor_`z') descending) ///
				stack ///
				ytitle("# of `lvl'") ///
				title("`s' Farms", span) ///
				ylabel(`labels') ///
				yscale(range(`ranges')) ///
				legend( rows(1) label(1 "Incentive") label(2 "Disincentive")) ///
				graphregion(color(white)) ///
				name(`lvl'_`z', replace)
				
				graph save `lvl'_`z', replace
			
		// 		graph export "${figdir}\bar_marketfactor_motivator_finalsample_`z'_results.png", replace
			}
		// 	graph combine papers_Layer.gph papers_Broiler.gph papers_Cow.gph papers_Hog.gph, 
			
			grc1leg `lvl'_Cow, ///
				title("(Dis-)Incentives for `cat_title'", ///
				span) subtitle("`title' (1990-2023)") ///
				graphregion(color(white)) ///
				altshrink ///
				legendfrom(`lvl'_Cow) pos(bottom)
				
				graph export "${figdir}\bar_marketfactor_motivator_finalsample_combine_`c'_`lvl'3b2.png", replace
		}
	}	
	else {
		foreach lvl in "Results" "Papers" {
			if "`lvl'" == "Results" {
				local title = "Significant Results"
				local labels = "-20(10)40"
				local ranges = "-25 40"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_results3", clear
			}
			else if "`lvl'" == "Papers" {
				local title = "Median Sig. Result per Paper"
				local labels = "-4(2)10"
				local ranges = "-4 10"
				
				use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_papers3", clear
			}
			
			* Make graph for each species
			foreach s in "Layer" "Dairy Cow" "Hog" "Broiler" {
				if "`s'" == "Dairy Cow" {
					local z = "Cow"
					local s2 = "`s'"
				}
				else if "`s'" == "Hog" {
					local z = "Hog"
					local s2 = "Pig"
				}
				else {
					local z = "`s'"
					local s2 = "`s'"
				}
				
				graph hbar (asis) motivator_dum barrier_dum if Species=="`s2'" & Pract_Category == "`cat'", over(market_factor, ///
				sort(total_factor_`z') descending) ///
				stack ///
				ytitle("# of `lvl'") ///
				title("`s' Farms", span) ///
				ylabel(`labels') ///
				yscale(range(`ranges')) ///
				legend( rows(1) label(1 "Incentive") label(2 "Disincentive")) ///
				graphregion(color(white)) ///
				name(`lvl'_`z', replace)
				
				graph save `lvl'_`z', replace
			
		// 		graph export "${figdir}\bar_marketfactor_motivator_finalsample_`z'_results.png", replace
			}
		// 	graph combine papers_Layer.gph papers_Broiler.gph papers_Cow.gph papers_Hog.gph, 
			
			grc1leg `lvl'_Layer `lvl'_Cow `lvl'_Broiler `lvl'_Hog, ///
				title("") ///
				graphregion(color(white)) ///
				iscale(.6) ///
				imargin(1 1 1 1 1) ///
				legendfrom(`lvl'_Cow) pos(bottom)
				
				graph export "${figdir}\bar_marketfactor_motivator_finalsample_combine_`c'_`lvl'3b2.eps", replace
		}
	}
}	
		// I tried to add the fraction of each factor that is an incentive but could not get blabel or dot to work
		
****************** Collapse data (all species combined) ***********************	

		//  If on same y scal: ylabel(-50(25)100) yscale(range(-50 100)).
foreach lvl in "Results" "Papers" {
	if "`lvl'" == "Results" {
		local title = "Significant Results (1990-2023)"
		local labels = "-20(10)50"
		local ranges = "-20 50"
		
		use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_results3", clear
	}
	else if "`lvl'" == "Papers" {
		local title = "Median Sig. Result per Paper (1990-2023)"
		local labels = "-4(2)14"
		local ranges = "-4 14"
		
		use "${datadir}\clean_data\final\finalsample_sig_collapsed_cat_papers3", clear
	}		
	foreach cat in "Indoor Env"  "Enrichment" "Outdoor Access" "Confinement" "Mutilation"  {
		if "`cat'" == "Confinement" {
			local c = "`cat'"
			local cat_title = "Less `cat'"
		}
		else if "`cat'" == "Mutilation" {
			local c = "`cat'"
			local cat_title = "Less `cat'"
		}	
		else if "`cat'" == "Outdoor Access" {
			local c = "Outdoor"
			local cat_title = "`cat'"
		}	
		else if "`cat'" == "Indoor Env" {
			local c = "Indoor"
			local cat_title = "Better `cat'ironment"
		}
		else {
			local c = "`cat'"
			local cat_title = "`cat'"
		}
		
		* Collapse away the species
		collapse (sum) motivator_dum barrier_dum, by(market_factor Pract_Category)
		
		gen total_factor = motivator_dum + barrier_dum
		gen frac_factor = motivator_dum / total_factor
		
		
		graph hbar (asis) motivator_dum barrier_dum if Pract_Category == "`cat'", over(market_factor, ///
		sort(total_factor) descending) ///
		stack ///
		title("`cat_title'", span) ///
		ytitle("# of `lvl'") ///
		ylabel(`labels') ///
		yscale(range(`ranges')) ///
		legend( rows(2) label(1 "Incentive") label(2 "Disincentive")) ///
		graphregion(color(white)) ///
		name(`lvl'_`c', replace)
		
		graph save `lvl'_`c', replace

	// 	graph export "${figdir}\bar_marketfactor_motivator_finalsample_papers.png", replace
	}	

		grc1leg	`lvl'_Indoor `lvl'_Confinement  `lvl'_Mutilation `lvl'_Enrichment `lvl'_Outdoor  , ///
			title("") ///
			graphregion(color(white)) ///
			iscale(.6) ///
			imargin(1 1 1 1 1) ///
			legendfrom(`lvl'_Outdoor) ///
			row(2) col(3)
			gr_edit legend.xoffset = 55
			gr_edit legend.yoffset = 25
			
		graph export "${figdir}\bar_marketfactor_motivator_finalsample_comnbine_cat_`lvl'3b2.eps", replace	
	}
	
	