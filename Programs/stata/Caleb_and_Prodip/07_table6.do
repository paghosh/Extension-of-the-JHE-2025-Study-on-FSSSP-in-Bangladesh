/*==============================================================================
TABLE 6: Effect of FSSSP on Fertility Preferences and Outcomes

5 columns: Age at 1st Birth, Num Living Children, Ideal Children,
           Has Daughter, Ideal Girls=0
Sample: Child sample mothers with sampling weights

NOTE: Data construction for has_daughter requires loading birth records
      and merging back. This logic is preserved exactly from the original.
==============================================================================*/

display as result _n(2) "================================================================================"
display as result "TABLE 6: FERTILITY PREFERENCES AND OUTCOMES"
display as result "================================================================================" _n

/*------------------------------------------------------------------------------
Step 1: Identify Child Sample Mothers
------------------------------------------------------------------------------*/

use "${analysis_data}/child_sample.dta", clear

display as text "Child sample (child-level): " _N " children"

* Save list of mothers from child sample
preserve
keep caseid survey_wave
duplicates drop caseid survey_wave, force
tempfile child_sample_mothers
save `child_sample_mothers', replace
restore

* Save the original child sample for later merge
tempfile original_child
save `original_child', replace

/*------------------------------------------------------------------------------
Step 2: Load Complete Birth History for Child Sample Mothers
------------------------------------------------------------------------------*/

clear
tempfile all_births
local first = 1

local br_files `" "BD_1996-97_DHS_12292025_1726_237609/BDBR3ADT/BDBR3AFL" "BD_1999-00_DHS_12292025_1725_237609/BDBR41DT/BDBR41FL" "BD_2004_DHS_12292025_1724_237609/BDBR4JDT/BDBR4JFL" "BD_2007_DHS_12292025_1724_237609/BDBR51DT/BDBR51FL" "BD_2011_DHS_12292025_1723_237609/BDBR61DT/BDBR61FL" "BD_2014_DHS_12292025_1723_237609/BDBR72DT/BDBR72FL" "BD_2017-18_DHS_12292025_1722_237609/BDBR7RDT/BDBR7RFL" "'

foreach br in `br_files' {
    capture use "${raw_data}/`br'.dta", clear
    if _rc == 0 {
        keep caseid v000 b4 b5
        keep if b5 == 1

        gen survey_wave = .
        replace survey_wave = 1996 if v000 == "BD3"
        replace survey_wave = 1999 if v000 == "BD4"
        replace survey_wave = 2004 if v000 == "BD5"
        replace survey_wave = 2007 if v000 == "BD6"
        replace survey_wave = 2011 if v000 == "BD61"
        replace survey_wave = 2014 if v000 == "BD6A"
        replace survey_wave = 2017 if v000 == "BD7"

        if `first' == 1 {
            save `all_births', replace
            local first = 0
        }
        else {
            append using `all_births'
            save `all_births', replace
        }
    }
}

/*------------------------------------------------------------------------------
Step 3: Keep Only Births for Child Sample Mothers
------------------------------------------------------------------------------*/

merge m:1 caseid survey_wave using `child_sample_mothers'
keep if _merge == 3
drop _merge

/*------------------------------------------------------------------------------
Step 4: Create has_daughter from ALL Births
------------------------------------------------------------------------------*/

gen child_female = (b4 == 2)
collapse (max) has_daughter_any=child_female, by(caseid survey_wave)
label var has_daughter_any "Has at least one living daughter (ALL births)"

tempfile has_daughter_data
save `has_daughter_data', replace

/*------------------------------------------------------------------------------
Step 5: Merge Back to Child Sample
------------------------------------------------------------------------------*/

use `original_child', clear
merge m:1 caseid survey_wave using `has_daughter_data'

bysort caseid: egen has_daughter_child_sample = max(child_female)
replace has_daughter_any = has_daughter_child_sample if missing(has_daughter_any)
drop _merge has_daughter_child_sample

/*------------------------------------------------------------------------------
Step 6: Keep at Child Level (Paper uses child-level N=32,751)
------------------------------------------------------------------------------*/

display as text "Final child-level sample: " _N " children"

/*------------------------------------------------------------------------------
Step 7: Run Regressions and Export
------------------------------------------------------------------------------*/

local outcomes age_first_birth num_living_children ideal_num_children has_daughter_any ideal_girls_zero

eststo clear
foreach var of local outcomes {
    eststo: qui regress `var' ///
        i.fully_exposed##i.rural ///
        i.partially_exposed##i.rural ///
        i.muslim ///
        i.maternal_birth_year ///
        i.survey_wave ///
        i.division ///
        [pw=weight], vce(cluster maternal_by_rural)
    qui sum `var' if e(sample)
    estadd scalar mean_y = r(mean)
}

esttab using "${tables}/table6.tex", replace ///
    keep(1.fully_exposed#1.rural 1.partially_exposed#1.rural) ///
    varlabels(1.fully_exposed#1.rural "Fully Exposed $\times$ Rural" ///
              1.partially_exposed#1.rural "Partially Exposed $\times$ Rural") ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    stats(N mean_y, ///
          labels("Observations" "Dep. Var. Mean") ///
          fmt(%9.0fc 3)) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    booktabs fragment nomtitle nonotes nonumber collabels(none) ///
    prehead("\begin{table}[htbp]" ///
            "\centering" ///
            "\begin{threeparttable}" ///
            "\caption{Effect of FSSSP on Fertility Preferences and Outcomes}" ///
            "\label{tab:table6}" ///
            "\footnotesize" ///
            "\begin{tabular}{l*{5}{c}}" ///
            "\toprule" ///
            " & (1) & (2) & (3) & (4) & (5) \\" ///
            " & Age at & Num Living & Ideal & Has & Ideal \\" ///
            " & 1st Birth & Children & Children & Daughter & Girls=0 \\") ///
    postfoot("\bottomrule" ///
             "\end{tabular}" ///
             "\begin{tablenotes}" ///
             "\footnotesize" ///
             "\item \textit{Notes:} All regressions include controls for rural residence, Muslim, maternal birth year fixed effects, survey wave fixed effects, and division fixed effects. Fully exposed cohorts are born between 1983 and 1998, partially exposed cohorts are born between 1980 and 1982, and unexposed cohorts (reference group) are born between 1971 and 1979. Standard errors in parentheses are clustered at the maternal year of birth $\times$ rural levels. ***, **, and * represent statistical significance at 0.01, 0.05, and 0.1 levels, respectively. Sample uses child sample mothers with weights." ///
             "\item \textit{Source:} Bangladesh Demographic and Health Surveys, 1996--97 through 2017--18." ///
             "\end{tablenotes}" ///
             "\end{threeparttable}" ///
             "\end{table}")

display ""
display "================================================================================"
display "TABLE 6 CREATED: tables/table6.tex"
display "================================================================================"
