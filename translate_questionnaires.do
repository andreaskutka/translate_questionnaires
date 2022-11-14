/*==============================================================================
	translate_questionnaires.do v1.0
==============================================================================*/
/* A tool to easily manage translations of (changing) Survey Solutions questionnaires.

For details and instructions see: https://github.com/andreaskutka/translate_questionnaires

Written by Andreas Kutka, Jan 2021
Please report any bugs or feature requests on github or write to andreas.kutka@gmail.com */

/*=============================================================================
	LET'S SET UP IT ALL UP (looks long, but only takes 5 minutes)
=============================================================================*/			
		
/* STEP 1:	List the questionnaires you would like to translate using the names as they appear on Survey Solutions designer. 
			Use quotes if names contain spaces, and composite quotes if there is more than one questionnaire (you can also just leave them for one qnr only)  */

	local qnrs `" "translate_demo_household" "translate_demo_listing"  "' // // list (macro compatible) names of Survey Solution questionnaire translation templates to translate.		

/* STEP 2	Define the directory where translation templates and outputs will be saved. */ 
	
	local transdir "${path}/translation"
	
/* STEP 3:	For each qnr, download the translation template from the Survey Solution Designer. 
			Always download the template, do not download any existing translation.
			Save the templates in the translation directory specified in Step 2. 
			The names of the templates should follwo the follwoing pattern. "[New translation]QNR_NAME.xlsx" */
		
/* STEP 4:	Set up the translation sheet. Copy the Google sheet template & set sharing settings to view for those with link
			https://docs.google.com/spreadsheets/d/1dX-Z8hy0Crq7_UYK8BTsoiavul9MorPkvoXtT8kAXW0 */

	local google_doc 1dX-Z8hy0Crq7_UYK8BTsoiavul9MorPkvoXtT8kAXW0 // If you use a google sheet, copy the ID of the google sheet from the URL, comment out if not
	local trans_excel="`transdir'/Translation_sheet.xlsx" // path and name of the Excel sheet into which the Google sheet will be exported, or name of Excel translation sheet if not using Google sheets
	local trans_sheet translations // Name of the sheet continaing translations, must contain one column for the base language, one column for each target language
	local trans_dont dont_translate // Name of the sheet and column title containing strings not to be translated

/* STEP 5:	Specify the source language and targed language(s), using the column title of row 1 in the translation sheet. */
	
	local source EN
	local target SW ES // more than one target language can be specified

/* STEP 6:	(Optionally) update the regexm expression in chapter 3 to match your question numbering format. The expression is used to  
			create the variable to_translate containing the template text without the question numbering, so the translation does not 
			need ot be updated if the question numbering has changed. By default, the code recognizes question numbering following 
			this pattern "^S[0-9]+Q[0-9]+[A-Z]?. ", e.g. "S1Q7. How ...". Update the regexm expression to match your format. */
		
/* STEP 7:	(Optionally) Write code in chapter 3 to drop any set of observations from the translation sheet that do not need to be 
			translated. Dropped observations will not be considered as untranslated in the output if no string match 
			is found in the translations sheet. By default this do-file ignores validation messages and interviewer instructions.
			You can also drop entire sheets of the translation template, e.g. to not translate adminstrative names from cascading combo boxes. */
	
/*=============================================================================
	1. INSTALL DEPENDENCIES
=============================================================================*/		
	capture which matchit
	if _rc{
		ssc install matchit
	}
/*=============================================================================
	2. FETCH GOOGLE SHEET 			
=============================================================================*/
	if "`google_doc'"!=""{
		copy "https://docs.google.com/spreadsheets/d/`google_doc'/export?format=xlsx" "`trans_excel'", replace
	}
	
/*-- TRANSLATIONS -----------------------------------------------------------*/	
	import excel "`trans_excel'", clear sheet("`trans_sheet'") firstrow
	capture confirm variable `source' `target' 
	if _rc{
		di as err "at least one of the columns for source or target language(s)"_n"does not exist in translation sheet: `source' `target'"
		exit		
	}
	foreach var in `source' `target' {
		capture tostring `var', replace
		replace `var'="" if `var'=="."
	}	
	gen trans_row=_n+1
	gen to_translate=`source' 
	format `source' `target' to_translate %-20s
	sort to_translate trans_row
	bys to_translate: keep if _n==1 // in case we have duplicate translation in google, keep the first occurence
	sort trans_row 
	tempfile translations
	save `translations', replace 

/*-- NOT TO BE TRANSLATED ----------------------------------------------------*/	
	if "`trans_dont'"!=""{
		capture import excel "`trans_excel'", clear sheet("`trans_dont'") firstrow
		keep `trans_dont'
		rename `trans_dont' to_translate
		keep if to_translate != ""
		duplicates drop 	
		tempfile donttranslate
		save `donttranslate'
	}

/*-- CHECK IF STRING IN TRANSLATIONS AND DONT_TRANSLATE -----------------------*/
	merge 1:1 to_translate using `translations', keep(3) nogen 
	if _N>0{
		di as err "rows on Translations and Don't Translate sheets"
		exit
	}
	
/*=============================================================================
	3. IMPORT TEMPLATES FROM SURVEY SOLUTIONS & MAKE TO-TRANSLATE SHEET
=============================================================================*/	
	clear
	gen to_translate=""
	tempfile  to_translate one_template
	save `to_translate'
	save `one_template'
	
	cd "`transdir'"
	foreach qnr in `qnrs' {
		import excel using "[New translation]`qnr'.xlsx", describe
		local n_sheets `r(N_worksheet)'
		forvalues i = 1/`n_sheets' {
			local sheet`i'  `r(worksheet_`i')'
		}	
		forvalues i = 1/`n_sheets' {
			import excel using "[New translation]`qnr'.xlsx", sheet("`sheet`i''") firstrow clear all
			gen Sheet="`sheet`i''"
			append using `one_template'
			save `one_template', replace
		}
		gen temp_row=_n

// -- WRITE HERE CODE TO GENERATE A VARIABLE to_translate USED FOR STRING MATCHING TO THE TRANSLATION SHEET --

		gen qn=regexm(Originaltext,"^S[0-9]+Q[0-9]+[A-Z]?. ")==1
		gen qstnum=substr(Originaltext,1,strpos(Originaltext,". ")+1) if qn==1
		replace to_translate=substr(Originaltext,strpos(Originaltext,". ")+2,length(Originaltext)) if qn==1
		replace to_translate=Originaltext if qn==0	
		
//-----------------------------------------------------------------------------------------------------------
		
		format Originaltext to_translate %-20s
		tempfile `qnr'_temp
		save ``qnr'_temp'
		
		gen qnr="`qnr'"
		append using `to_translate'
		save `to_translate', replace
	}		
	
// -- WRITE HERE CODE TO DROP ANY OBSERVATIONS OF THE TRANSLATION TEMPLATE THAT SHOULD NOT BE TRANSLATED  --

	drop if Type=="Instruction" // instructions in questions 
	drop if Type=="ValidationMessage" // validation messages
	*drop if Sheet=="@@village" // drop all entries from sheet village, corresponding to answer options in question with varname village

//----------------------------------------------------------------------------------------------------------	

	sort to_translate qnr temp_row
	by to_translate: keep if _n==1 // only keep first occurance of the same english string
	gen length=length(to_translate)
	count if length > 2045 
	if `r(N)' > 0{
		br if length > 2045
		di as err "String too long. Cannot exceed 2045 caharacters. Split text in Survey Soltuions, e.g. using static text."
		exit 111
	}
	drop length	
	if "`donttranslate'"!=""{
		merge 1:1 to_translate using `donttranslate', keep(1) nogen // filter out rows from the don't translate tab			
	}
	save `to_translate', replace	

/*==============================================================================
	4. MAKE TRANSLATION FOR SURVEY SOLUTION
==============================================================================*/
// merge translation sheet and templates on to_translate/source string, keep only matches and make Survey Solution translation sheets
	local today=string(date("`c(current_date)'","DMY"),"%tdY-N-D")
	local exp_vars EntityId Variable Type Index Originaltext Translation

	foreach qnr in `qnrs' {
		foreach lan in `target' {	
			use ``qnr'_temp', clear	
			drop Translation
			merge m:1 to_translate using `translations', keepusing(`lan') keep(3) nogen
			keep if `lan'!="" // only keeps translations that are not empty
		*	drop if `lan'_status=="don't translate"
			
			if _N>0{
				*drop `lan'_status
				format to_translate %-20s	
				rename `lan' Translation
				replace Translation=qstnum+Translation if qstnum!=""
				sort temp_row
				
				tempfile all_sheets
				save `all_sheets', replace
				
				levelsof Sheet
				foreach sheet in `r(levels)' {
					use `all_sheets', clear
					keep `exp_vars' Sheet
					export excel `exp_vars' using "`transdir'/[`lan']`qnr'-`today'.xlsx" if Sheet== "`sheet'", ///
						sheetreplace firstrow(var) sheet("`sheet'")
					drop if _n>1
					drop Sheet
					replace EntityId="Entity Id"	
					replace Variable="Variable"	
					replace Type="Type"
					capture tostring Index, replace
					replace Index="Index"
					replace Originaltext="Original text"
					replace Translation="Translation"
					export excel using "`transdir'/[`lan']`qnr'-`today'.xlsx", sheetmodify sheet("`sheet'")
				}
					

			}
		}
	}

/*==============================================================================
	5. UNTRANSLATED STRINGS, INCLUDING SIMILAR TEXT, PREVIOUSLY TRANSLATED 
==============================================================================*/
// compare unmtached strings from template with unmatched strings on translation sheet,
// e.g. for questions that have been updated after initial translation the string will not match but be similar
// calculate a similarity score 

/*-- UNMATCHED: in template but not in translation sheet ---------------------------*/
	use `to_translate', clear
	merge 1:1 to_translate using `translations', keep(1) nogen

	keep EntityId-to_translate `source' temp_row qnr
	sort qnr temp_row
	gen matchrow=_n
	tempfile in_temp_not_trans
	save `in_temp_not_trans'
	
/*-- UNMATCHED: in translation sheet but not in template ---------------------------*/
	use `to_translate', clear
	merge 1:1 to_translate using `translations', keep(2) nogen
	tempfile in_trans_not_temp
	save `in_trans_not_temp'	

	if _N>0{

		* similar text, untranslated
		use `in_temp_not_trans', clear
		matchit matchrow to_translate using `in_trans_not_temp', idu(trans_row) txtu(`source') t(0.75)
		gsort matchrow -similscore	
		by matchrow: keep if _n==1 // keep highest match only 
		tempfile similar 
		save `similar', replace

		merge m:1 trans_row using `in_trans_not_temp', keepusing(`target') keep(3) nogen
		merge 1:1 matchrow using `in_temp_not_trans', keepusing(EntityId Variable Type Index to_translate qnr Sheet temp_row) keep(2 3) nogen update
		drop matchrow
		order qnr Sheet temp_row EntityId Variable Type Index to_translate trans_row similscore
	}
	else{
		use `in_temp_not_trans', clear
	}
	
	format to_translate `source' %-30s
		
	* export to Excel
	if _N>0{
		sort temp_row
		capture sort trans_row temp_row
		export excel using "`transdir'/Untranslated.xlsx", replace firstrow(var) sheet(Untranslated)	
		count
	}
	else {
		di "No untranslated strings found"
	}
br	

* Don't Panic!
