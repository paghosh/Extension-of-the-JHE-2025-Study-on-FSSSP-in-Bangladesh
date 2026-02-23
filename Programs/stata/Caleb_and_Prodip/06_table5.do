********************************************************************************
* TABLE 5: Effect of FSSSP on Husband's Education and Labor Supply
*
* 4 columns: Husband Secondary+, Currently Working, Formal Sector, Husband Formal
* Sample: Child sample with sampling weights
* Clustering: maternal_by_rural
********************************************************************************

use "${analysis_data}/child_sample.dta", clear

display as text "Sample size: " _N

********************************************************************************
* RUN REGRESSIONS
********************************************************************************

local outcomes  husband_secondary_plus currently_working formal_sector husband_formal

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

********************************************************************************
* EXPORT TO LATEX
********************************************************************************

esttab using "${tables}/table5.tex", replace ///
    keep(1.fully_exposed#1.rural 1.partially_exposed#1.rural) ///
    varlabels(1.fully_exposed#1.rural "Fully Exposed X Rural" ///
              1.partially_exposed#1.rural "Partially Exposed X Rural") ///
    cells(b(star fmt(4)) se(par fmt(4))) ///
    stats(N mean_y, ///
          labels("Observations" "Dep. Var. Mean") ///
          fmt(%9.0fc 3)) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    booktabs fragment nomtitle nonotes nonumber collabels(none) ///
    prehead("\begin{table}[htbp]" ///
            "\centering" ///
            "\begin{threeparttable}" ///
            "\caption{Effect of FSSSP on Husband's Education and Labor Supply}" ///
            "\label{tab:table5}" ///
            "\footnotesize" ///
            "\begin{tabular}{l*{4}{c}}" ///
            "\toprule" ///
            " & (1) & (2) & (3) & (4) \\" ///
            " & Husband & Currently & Works in & Husband \\" ///
            " & Secondary+ & Working & Formal Sec & Formal Sec \\") ///
    postfoot("\bottomrule" ///
             "\end{tabular}" ///
             "\begin{tablenotes}" ///
             "\footnotesize" ///
             "\item \textit{Notes:} All columns include controls for rural residence, Muslim, maternal birth year fixed effects, survey wave fixed effects, and division fixed effects. Fully exposed cohorts are born between 1983 and 1998, partially exposed cohorts are born between 1980 and 1982, and unexposed cohorts (reference group) are born between 1971 and 1979. Standard errors in parentheses are clustered at the maternal year of birth $\times$ rural levels. ***, **, and * represent statistical significance at 0.01, 0.05, and 0.1 levels, respectively." ///
             "\item \textit{Source:} Bangladesh Demographic and Health Surveys, 1996--97 through 2017--18." ///
             "\end{tablenotes}" ///
             "\end{threeparttable}" ///
             "\end{table}")

display ""
display "================================================================================"
display "TABLE 5 CREATED: tables/table5.tex"
display "================================================================================"
