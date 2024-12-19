* Project:	Humane Practice Adoption
* Author:	Trevor Woolley
* Date:		10/10/24
* Purpose:	Create dataset of our final 101 papers in a format that is clean
******************************************************************************
global homedir "D:\Projects\ASPCA"
global datadir "D:\Projects\ASPCA\data"
global figdir "D:\Projects\ASPCA\figures"

ssc install filelist
ssc install dataex
net install grc1leg, from( http://www.stata.com/users/vwiggins/)
******************************************************************************
* Pull in data
	use "${datadir}\clean_data\final\final_data3", clear	
******************************************************************************
	* Clean up market factors
******************************************************************************

	* Consolidate market factors that are sub-categories
	replace market_factor = "price" if market_factor == "demand"
	replace market_factor = "productivity" if market_factor == "technical efficiency"
	
	replace mf_Price = 1 if mf_Demand==1
	replace mf_Productivity=1 if mf_TechEff ==1
	
	drop mf_Price mf_TechEff
	
	tab market_factor	
	
	drop abstract not_US drop_poll_SP_TW exogenous_factor double_check_note_TW pract_irrel double_check pract_is_dep_var hygiene article_type NOTES reviewer todrop pract_indep_exact pract_dep_exact dup3 dup HomeRun_BasedOnNotes Paid_Access academic authorkeywords keywordsplus search_terms documenttype species term_category keep reason not_research home_run who health keywords term_not_practice id_2 mf_Profit mf_Sales mf_Productivity mf_Quality mf_OperationC mf_FixedC mf_Life mf_Demand mf_AnHealth motivator motivator_dum barrier barrier_dum about_cows about_pigs about_layers about_broilers cat_access cat_confin cat_enrich cat_mutilat cat_indoor_env CABI EconLit WoS
	
	* Need to merge in pubyear and journal
	merge m:1 id using "${datadir}\clean_data\all_categorized.dta", force
	
	keep if _merge ==3
	drop _merge
	
	gen pub_other = 0
	replace pub_other = 1 if pub_geo==1 | pub_engin==1 |  pub_chem==1 | pub_misc==1
	// The other thing that is weird is that there are papers assigned to multiple subjects
	
	* Make year consistent
	destring year, replace
	replace pubyear = year if pubyear==.
	
	keep id url doi authors title Species Dep_Var Dep_good_for_producer market_factor Indep_Var Relationship significant Practice pract_good_for_AW Pract_Category Data_Source sample_subject search_engine publication affiliations orcids timescitedwoscore timescitedalldatabases publisher issn eissn pubyear volume issue
	
	* Restrict to those with market factor (those where the practice is the independent variable)
	drop if market_factor ==""
	
	* Drop Dep Vars that are practices and not producer outcomes (found when revieing market factor list in next subsection)
	drop if strpos(Dep_Var, "dairies using") | strpos(Dep_Var, "Smaller space required per pig for eating, drinking, defecation, sleeping") | strpos(Dep_Var, "soaker use") | strpos(Dep_Var, "stocking rate") | strpos(Dep_Var, "administration of antimicrobial drugs") 
	
	// 79 unique papers
	
	order authors pubyear title volume issue Species Pract_Category Practice pract_good_for_AW market_factor Dep_Var Dep_good_for_producer Indep_Var Relationship significant Data_Source sample_subject search_engine publication affiliations orcids timescitedwoscore timescitedalldatabases publisher issn eissn
	
	sort Species authors pubyear title Pract_Category
	
	save  "D:\Projects\ASPCA\data\clean_data\final_results2", replace
	export excel using "D:\Projects\ASPCA\data\clean_data\final_results2.xls", firstrow(variables) replace
	// final_results2 uses final_data3
		
******************************************************************************
	* Collapse down to unique market factor list
******************************************************************************
	preserve
	
	drop url doi authors title Data_Source sample_subject search_engine publication affiliations orcids timescitedwoscore timescitedalldatabases publisher issn eissn pubyear volume issue year Indep_Var Relationship significant
	
	collapse  (count) count = id (first) market_factor Dep_good_for_producer, by(Dep_Var)
	
	sort Dep_Var
	
	 export excel using "D:\Projects\ASPCA\data\dep_vars_list.xls", firstrow(variables)
	// I edited the sheet by hand to simplify dep var terms and give them common names create dep_vars_list_simplified.xls
	
	* Import my manually edited list
	import excel "D:\Projects\ASPCA\data\dep_vars_list_simplified.xls", sheet("Sheet1") firstrow clear
	
	collapse (sum) count (first) market_factor Dep_good_for_producer, by(Dep_Var)
	
	order market_factor Dep_Var Dep_good_for_producer count
	sort market_factor Dep_Var
	// still 198 unique dep vars
	
	rename market_factor Market_Factor
	rename Dep_Var Dependent_Var
	rename count N_Results
	
	 export excel using "D:\Projects\ASPCA\data\dep_vars_list_final.xls", firstrow(variables)
	
	* need to drop results that have "dairies using" in Dep_Var. That's not a producer outcome
	* same with "Smaller space required per pig for eating, drinking, defecation, sleeping"
	* same with "soaker use"
	* same with "stocking rate"
	* same with "administration of antimicrobial drugs"
	
	restore
	
******************************************************************************
	* Collapse down to unique practice list
******************************************************************************
// Commented out because so much was done by hand. I don't want to write over any excel sheets.
// 	preserve
//	
// 	drop url doi authors title Data_Source sample_subject search_engine publication affiliations orcids timescitedwoscore timescitedalldatabases publisher issn eissn pubyear volume issue year Indep_Var Relationship significant
//	
// 	collapse  (count) count = id (first) Pract_Category pract_good_for_AW, by(Species Practice)	
//	
// 	sort Practice
//	
// 	 export excel using "D:\Projects\ASPCA\data\practices_list.xls", firstrow(variables) replace
// 	// I edited the sheet by hand to simplify dep var terms and give them common names create practices_list_simplified.xls
//	
// 	* Import my manually edited list
// 	import excel "D:\Projects\ASPCA\data\practices_list_simplified.xls", sheet("Sheet1") firstrow clear
//	
// 	collapse (sum) count (first) Pract_Category pract_good_for_AW, by(Species Practice)
//	
// 	order Pract_Category Species Practice pract_good_for_AW count
// 	sort Pract_Category Pract_Category Species Practice
// 	// still 151 unique dep vars
//	
// 	 export excel using "D:\Projects\ASPCA\data\practice_list_final.xls", firstrow(variables)
//	 
// 	 * Had to edit a few
// 	 import excel "D:\Projects\ASPCA\data\practice_list_final.xls", sheet("Sheet1") firstrow clear
//	
// 	collapse (sum) NResults (first) PractCategory GoodforAW, by(Species Practice)
//	
// 	order PractCategory Species Practice GoodforAW NResults
// 	sort Pract_Category Pract_Category Species Practice
// 	// still 137 unique dep vars
//	
// 	 export excel using "D:\Projects\ASPCA\data\practice_list_final2.xls", firstrow(variables)
//	 
// 	 	 // I implemented Daisy's edits directly in the Latex table on Overleaf. Daisy flagged mis-categorized pracrtices into Practice Categories.
//	
//	
// 	restore
	
******************************************************************************
	* Collapse down to paper level for References section
******************************************************************************
	preserve
	
	keep id doi authors title publication issue volume pubyear issn market_factor Pract_Category
	
	* Generate dummy variables for each economic factor (FKA market_factor)
	gen ef_Animal_Health = 0
	replace ef_Animal_Health = 1 if strpos(market_factor, "animal health")
	gen ef_Farmer_QOL = 0
	replace ef_Farmer_QOL = 1 if strpos(market_factor, "farmer QOL")
	gen ef_Fixed_Cost = 0
	replace ef_Fixed_Cost = 1 if strpos(market_factor, "fixed cost")
	gen ef_Operation_Cost = 0
	replace ef_Operation_Cost = 1 if strpos(market_factor, "operation cost")
	gen ef_Price = 0
	replace ef_Price = 1 if strpos(market_factor, "price")
	gen ef_Productivity = 0
	replace ef_Productivity = 1 if strpos(market_factor, "productivity")
	gen ef_Profit = 0
	replace ef_Profit = 1 if strpos(market_factor, "profit")
	gen ef_Quality = 0
	replace ef_Quality = 1 if strpos(market_factor, "quality")
	gen ef_Sales = 0
	replace ef_Sales = 1 if strpos(market_factor, "sales")
	
	* Gen dummy variables for Pract_Category (5)
	gen Outdoor_Access = 0
	replace Outdoor_Access = 1 if strpos(Pract_Category, "Outdoor Access") 
	gen Enrichment = 0
	replace Enrichment = 1 if strpos(Pract_Category, "Enrichment") 
	gen Indoor_Env = 0
	replace Indoor_Env = 1 if strpos(Pract_Category, "Indoor Env") 
	gen Mutilation = 0
	replace Mutilation = 1 if strpos(Pract_Category, "Mutilation") 
	gen Confinement = 0
	replace Confinement = 1 if strpos(Pract_Category, "Confinement") 
	
	collapse (first) doi authors title publication issue volume pubyear issn (sum) Outdoor_Access Enrichment Indoor_Env Mutilation Confinement ef_Animal_Health ef_Farmer_QOL ef_Fixed_Cost ef_Operation_Cost ef_Price ef_Productivity ef_Profit ef_Quality ef_Sales, by(id)
	
	drop id
	sort author
	
	gen number = _n
	
	export excel using "D:\Projects\ASPCA\data\clean_data\paper_list2.xlsx", firstrow(variables) replace
	// final_results2 uses final_data3
	// This has 70 final papers. Restricted to only those with a market factor (some are insignificant).
	
	
	restore

	