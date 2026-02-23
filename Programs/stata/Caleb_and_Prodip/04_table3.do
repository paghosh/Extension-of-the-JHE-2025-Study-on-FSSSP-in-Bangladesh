********************************************************************************
* TABLE 3: Effect of FSSSP on Other Health Inputs
*
* 10 outcome variables, all with covariates, child sample
* Outcomes: Antenatal care, delivery care, supplements, postnatal care
* Clustering: Maternal birth year × Rural
********************************************************************************

use "${analysis_data}/child_sample.dta", clear

* Create clustering variable
capture drop birth_year_rural
egen birth_year_rural = group(maternal_birth_year rural)

display "Child sample loaded: " _N " observations"

********************************************************************************
* RUN ALL 10 REGRESSIONS
********************************************************************************

local outcomes  any_antenatal doctor_antenatal nurse_antenatal num_antenatal ///
                iron_supplements facility_delivery home_delivery ///
                doctor_delivery vitamin_a postnatal_care

eststo clear
foreach var of local outcomes {
    eststo: qui regress `var' c.fully_exposed##c.rural c.partially_exposed##c.rural ///
        rural muslim i.maternal_birth_year i.survey_wave i.division, ///
        vce(cluster birth_year_rural)
    qui sum `var' if e(sample)
    estadd scalar mean_y = r(mean)
}

********************************************************************************
* EXPORT TO LATEX
********************************************************************************

esttab using "${tables}/table3.tex", replace ///
    keep(c.fully_exposed#c.rural c.partially_exposed#c.rural) ///
    varlabels(c.fully_exposed#c.rural "Fully Exposed X Rural" ///
              c.partially_exposed#c.rural "Partially Exposed X Rural") ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    stats(N mean_y, ///
          labels("Observations" "Dep. Var. Mean") ///
          fmt(%9.0fc 3)) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    booktabs fragment nomtitle nonotes nonumber collabels(none) ///
    prehead("\begin{table}[htbp]" ///
            "\centering" ///
            "\begin{threeparttable}" ///
            "\caption{Effect of FSSSP on other health inputs}" ///
            "\label{tab:table3}" ///
            "\tiny" ///
            "\begin{tabular}{l*{10}{c}}" ///
            "\toprule" ///
            " & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) & (9) & (10) \\" ///
            " & Any & Doctor & Nurse & Number of & Antenatal & Facility & Home & Doctor & Vitamin A & Any \\" ///
            " & Antenatal & Antenatal & Antenatal & Antenatal & Iron & Delivery & Delivery & Assisted & in last & Postnatal \\" ///
            " & Care & Care & Care & Visits & Supplements & & & Delivery & 6 months & Care \\") ///
    postfoot("\bottomrule" ///
             "\end{tabular}" ///
             "\begin{tablenotes}" ///
             "\tiny" ///
             "\item \textit{Notes:} The child sample includes children born to mothers aged 16+ at time of survey, with mothers born between 1971 and 1998. Fully exposed cohorts are born between 1983 and 1998, partially exposed cohorts are born between 1980 and 1982, and unexposed cohorts (reference group) are born between 1971 and 1979. All regressions include controls for rural residence, Muslim, maternal birth year fixed effects, survey wave fixed effects, and division fixed effects. Standard errors in parentheses are clustered at the maternal year of birth $\times$ rural levels. ***, **, and * represent statistical significance at 0.01, 0.05, and 0.1 levels, respectively. Sample sizes vary by outcome due to data availability across survey waves." ///
             "\item \textit{Source:} Bangladesh Demographic and Health Surveys, 1996--97 through 2017--18." ///
             "\end{tablenotes}" ///
             "\end{threeparttable}" ///
             "\end{table}")

display ""
display "================================================================================"
display "TABLE 3 CREATED: tables/table3.tex"
display "================================================================================"
