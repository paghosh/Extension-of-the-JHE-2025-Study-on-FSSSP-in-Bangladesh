/*==============================================================================
TABLE 7: Effect of FSSSP on Early Marriage and Female Autonomy

7 columns:
  (1) Age at first marriage     (all waves)
  (2) Married before 18         (all waves)
  (3) Decides on health care    (2004+ only)
  (4) Decides on purchases      (2004+ only)
  (5) Decides on visits          (2004+ only)
  (6) Decision-making index      (2004+ only)
  (7) Can go to hospital alone   (2004+ only)

Sample: Child sample mothers with sampling weights
==============================================================================*/

display as result _n(2) "================================================================================"
display as result "TABLE 7: EARLY MARRIAGE AND FEMALE AUTONOMY"
display as result "================================================================================" _n

/*------------------------------------------------------------------------------
1. Load Child Sample and Collapse to Mother Level
------------------------------------------------------------------------------*/

use "${analysis_data}/child_sample.dta", clear

* Collapse to mother level (paper uses mother-level for marriage/autonomy)
egen tag_mother = tag(caseid)
keep if tag_mother == 1

display as text "Unique mothers: " _N

* Create married_before_18
gen married_before_18 = (age_marriage < 18) if !missing(age_marriage)

/*------------------------------------------------------------------------------
2. Run Regressions and Export
------------------------------------------------------------------------------*/

local outcomes age_marriage married_before_18 decides_health decides_purchases decides_visits decision_index can_go_hospital

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

esttab using "${tables}/table7.tex", replace ///
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
            "\caption{Effect of FSSSP on Early Marriage and Female Autonomy}" ///
            "\label{tab:table7}" ///
            "\tiny" ///
            "\begin{tabular}{l*{7}{c}}" ///
            "\toprule" ///
            " & (1) & (2) & (3) & (4) & (5) & (6) & (7) \\" ///
            " & Age First & Married & Decides & Decides & Decides & Decision & Can Go \\" ///
            " & Marriage & Before 18 & Health & Purchase & Visits & Index & Hospital \\") ///
    postfoot("\bottomrule" ///
             "\end{tabular}" ///
             "\begin{tablenotes}" ///
             "\footnotesize" ///
             "\item \textit{Notes:} All regressions include controls for rural residence, Muslim, maternal birth year fixed effects, survey wave fixed effects, and division fixed effects. Fully exposed cohorts are born between 1983 and 1998, partially exposed cohorts are born between 1980 and 1982, and unexposed cohorts (reference group) are born between 1971 and 1979. Standard errors in parentheses are clustered at the maternal year of birth $\times$ rural levels. ***, **, and * represent statistical significance at 0.01, 0.05, and 0.1 levels, respectively. Columns 3--7 use decision-making variables available only in 2004--2017 surveys. Sample uses child sample mothers with weights." ///
             "\item \textit{Source:} Bangladesh Demographic and Health Surveys, 1996--97 through 2017--18." ///
             "\end{tablenotes}" ///
             "\end{threeparttable}" ///
             "\end{table}")

display ""
display "================================================================================"
display "TABLE 7 CREATED: tables/table7.tex"
display "================================================================================"
