/*==============================================================================
TABLE 8: Effect of FSSSP on Exposure to Media

4 columns: Newspaper, TV, Radio, Media Sources Index
Sample: Child sample (child-level, unweighted)
Clustering: maternal_by_rural

NOTE: Unweighted regressions match paper exactly.
==============================================================================*/

display as result _n(2) "================================================================================"
display as result "TABLE 8: MEDIA EXPOSURE"
display as result "================================================================================" _n

use "${analysis_data}/child_sample.dta", clear

display as text "Child sample: " _N " observations"

/*------------------------------------------------------------------------------
Run Regressions and Export
------------------------------------------------------------------------------*/

local outcomes newspaper_weekly tv_weekly radio_weekly media_sources

eststo clear
foreach var of local outcomes {
    eststo: qui regress `var' ///
        i.fully_exposed##i.rural ///
        i.partially_exposed##i.rural ///
        i.muslim ///
        i.maternal_birth_year ///
        i.survey_wave ///
        i.division, ///
        vce(cluster maternal_by_rural)
    qui sum `var' if e(sample)
    estadd scalar mean_y = r(mean)
}

esttab using "${tables}/table8.tex", replace ///
    keep(1.fully_exposed#1.rural 1.partially_exposed#1.rural) ///
    varlabels(1.fully_exposed#1.rural "Fully Exposed $\times$ Rural" ///
              1.partially_exposed#1.rural "Partially Exposed $\times$ Rural") ///
    cells(b(star fmt(4)) se(par fmt(4))) ///
    stats(N mean_y, ///
          labels("Observations" "Dep. Var. Mean") ///
          fmt(%9.0fc 3)) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    booktabs fragment nomtitle nonotes nonumber collabels(none) ///
    prehead("\begin{table}[htbp]" ///
            "\centering" ///
            "\begin{threeparttable}" ///
            "\caption{Effect of FSSSP on Exposure to Media}" ///
            "\label{tab:table8}" ///
            "\footnotesize" ///
            "\begin{tabular}{l*{4}{c}}" ///
            "\toprule" ///
            " & (1) & (2) & (3) & (4) \\" ///
            " & Newspaper & TV & Radio & Index \\") ///
    postfoot("\bottomrule" ///
             "\end{tabular}" ///
             "\begin{tablenotes}" ///
             "\footnotesize" ///
             "\item \textit{Notes:} All regressions include controls for rural residence, Muslim, maternal birth year fixed effects, survey wave fixed effects, and division fixed effects. Fully exposed cohorts are born between 1983 and 1998, partially exposed cohorts are born between 1980 and 1982, and unexposed cohorts (reference group) are born between 1971 and 1979. Standard errors in parentheses are clustered at the maternal year of birth $\times$ rural levels. ***, **, and * represent statistical significance at 0.01, 0.05, and 0.1 levels, respectively. Media variables: Newspaper/TV/Radio are binary indicators for exposure at least once a week; Index is sum of the three media variables (0--3). Sample uses child-level observations without sampling weights." ///
             "\item \textit{Source:} Bangladesh Demographic and Health Surveys, 1996--97 through 2017--18." ///
             "\end{tablenotes}" ///
             "\end{threeparttable}" ///
             "\end{table}")

display ""
display "================================================================================"
display "TABLE 8 CREATED: tables/table8.tex"
display "================================================================================"
