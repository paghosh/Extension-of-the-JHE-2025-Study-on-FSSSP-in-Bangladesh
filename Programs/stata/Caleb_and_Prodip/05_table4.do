********************************************************************************
* TABLE 4: Child Mortality and Anthropometric Measures
*
* Panel A: Child Mortality (Birth Sample) - 6 columns
*          Neonatal/Infant/Child × No covariates/With covariates
* Panel B: Anthropometric Measures (Child Sample) - 6 columns
*          Height/Weight/WfH/Stunted/Underweight/Wasted (all with covariates)
********************************************************************************

********************************************************************************
* PANEL A: CHILD MORTALITY (BIRTH SAMPLE)
********************************************************************************

use "${analysis_data}/birth_sample.dta", clear
gen birth_year_rural = maternal_birth_year * 100 + rural

eststo clear

* Column 1: Neonatal Mortality WITHOUT covariates
eststo A1: qui regress neonatal_mort c.fully_exposed##c.rural c.partially_exposed##c.rural ///
    rural i.maternal_birth_year, vce(cluster birth_year_rural)
qui sum neonatal_mort if e(sample)
estadd scalar mean_y = r(mean)

* Column 2: Neonatal Mortality WITH covariates
eststo A2: qui regress neonatal_mort c.fully_exposed##c.rural c.partially_exposed##c.rural ///
    rural muslim i.maternal_birth_year i.survey_wave i.division, vce(cluster birth_year_rural)
qui sum neonatal_mort if e(sample)
estadd scalar mean_y = r(mean)

* Column 3: Infant Mortality WITHOUT covariates
eststo A3: qui regress infant_mort c.fully_exposed##c.rural c.partially_exposed##c.rural ///
    rural i.maternal_birth_year, vce(cluster birth_year_rural)
qui sum infant_mort if e(sample)
estadd scalar mean_y = r(mean)

* Column 4: Infant Mortality WITH covariates
eststo A4: qui regress infant_mort c.fully_exposed##c.rural c.partially_exposed##c.rural ///
    rural muslim i.maternal_birth_year i.survey_wave i.division, vce(cluster birth_year_rural)
qui sum infant_mort if e(sample)
estadd scalar mean_y = r(mean)

* Column 5: Child Mortality WITHOUT covariates
eststo A5: qui regress child_mort c.fully_exposed##c.rural c.partially_exposed##c.rural ///
    rural i.maternal_birth_year, vce(cluster birth_year_rural)
qui sum child_mort if e(sample)
estadd scalar mean_y = r(mean)

* Column 6: Child Mortality WITH covariates
eststo A6: qui regress child_mort c.fully_exposed##c.rural c.partially_exposed##c.rural ///
    rural muslim i.maternal_birth_year i.survey_wave i.division, vce(cluster birth_year_rural)
qui sum child_mort if e(sample)
estadd scalar mean_y = r(mean)

* Write Panel A
esttab A1 A2 A3 A4 A5 A6 using "${tables}/table4.tex", replace ///
    keep(c.fully_exposed#c.rural c.partially_exposed#c.rural) ///
    varlabels(c.fully_exposed#c.rural "Fully Exposed X Rural" ///
              c.partially_exposed#c.rural "Partially Exposed X Rural") ///
    cells(b(star fmt(4)) se(par fmt(4))) ///
    stats(N mean_y, ///
          labels("Observations" "Dep. Var. Mean") ///
          fmt(%9.0fc 3)) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    booktabs fragment nomtitle nonotes nonumber collabels(none) ///
    prehead("\begin{table}[htbp]" ///
            "\centering" ///
            "\begin{threeparttable}" ///
            "\caption{Effect of FSSSP on Child Mortality and Anthropometric Measures}" ///
            "\label{tab:table4}" ///
            "\tiny" ///
            "\begin{tabular}{l*{6}{c}}" ///
            "\toprule") ///
    posthead("\multicolumn{7}{c}{\textbf{Panel A: Child Mortality (Birth Sample)}} \\" ///
             " & (1) & (2) & (3) & (4) & (5) & (6) \\" ///
             " & \multicolumn{2}{c}{Neonatal} & \multicolumn{2}{c}{Infant} & \multicolumn{2}{c}{Child} \\" ///
             " & \multicolumn{2}{c}{Mortality} & \multicolumn{2}{c}{Mortality} & \multicolumn{2}{c}{Mortality} \\" ///
             "\midrule") ///
    prefoot("Covariates & No & Yes & No & Yes & No & Yes \\")

********************************************************************************
* PANEL B: ANTHROPOMETRIC MEASURES (CHILD SAMPLE)
********************************************************************************

use "${analysis_data}/child_sample.dta", clear
gen birth_year_rural = maternal_birth_year * 100 + rural

local outcomes height_for_age weight_for_age weight_for_height stunted underweight wasted

eststo clear
foreach var of local outcomes {
    eststo: qui regress `var' c.fully_exposed##c.rural c.partially_exposed##c.rural ///
        rural muslim i.maternal_birth_year i.survey_wave i.division, ///
        vce(cluster birth_year_rural)
    qui sum `var' if e(sample)
    estadd scalar mean_y = r(mean)
}

* Write Panel B (append, with footer)
esttab using "${tables}/table4.tex", append ///
    keep(c.fully_exposed#c.rural c.partially_exposed#c.rural) ///
    varlabels(c.fully_exposed#c.rural "Fully Exposed X Rural" ///
              c.partially_exposed#c.rural "Partially Exposed X Rural") ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    stats(N mean_y, ///
          labels("Observations" "Dep. Var. Mean") ///
          fmt(%9.0fc 3)) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    booktabs fragment nomtitle nonotes nonumber collabels(none) ///
    prehead("\midrule") ///
    posthead("\multicolumn{7}{c}{\textbf{Panel B: Anthropometric Measures (Child Sample)}} \\" ///
             " & Height & Weight & Weight & Stunted & Under- & Wasted \\" ///
             " & for Age & for Age & for Height & & weight & \\" ///
             "\midrule") ///
    postfoot("\bottomrule" ///
             "\end{tabular}" ///
             "\begin{tablenotes}" ///
             "\tiny" ///
             "\item \textit{Notes:} Panel A uses the birth sample. Panel B uses the child sample. Fully exposed cohorts are born between 1983 and 1998, partially exposed cohorts are born between 1980 and 1982, and unexposed cohorts (reference group) are born between 1971 and 1979. Panel A columns (2), (4), and (6) and all Panel B columns include controls for rural residence, Muslim, maternal birth year fixed effects, survey wave fixed effects, and division fixed effects. Panel A columns (1), (3), and (5) include only rural residence and maternal birth year fixed effects. Standard errors in parentheses are clustered at the maternal year of birth $\times$ rural levels. ***, **, and * represent statistical significance at 0.01, 0.05, and 0.1 levels, respectively." ///
             "\item \textit{Source:} Bangladesh Demographic and Health Surveys, 1996--97 through 2017--18." ///
             "\end{tablenotes}" ///
             "\end{threeparttable}" ///
             "\end{table}")

display ""
display "================================================================================"
display "TABLE 4 CREATED: tables/table4.tex"
display "================================================================================"
