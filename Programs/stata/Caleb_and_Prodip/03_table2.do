********************************************************************************
* FSSSP Replication: Table 2
* Effect of FSSSP on maternal education and child immunization
*
* Structure: 3 Panels × 4 Columns each
* Panel A: Mother Sample - Years of Schooling, Secondary Education
* Panel B: Child Sample (birth_sample 12-59mo) - Same outcomes
* Panel C: Child Sample (child_sample) - Full Immunization, Any Immunization
* Columns: (1) No covariates, (2) With covariates, (3) No covariates, (4) With covariates
********************************************************************************

********************************************************************************
* PANEL A: MOTHER SAMPLE
********************************************************************************

use "${analysis_data}/mother_sample.dta", clear
egen birth_year_rural = group(maternal_birth_year rural)

eststo clear

* Col 1: Years of Schooling WITHOUT covariates
eststo A1: qui regress years_schooling c.fully_exposed##c.rural c.partially_exposed##c.rural rural, vce(cluster birth_year_rural)
estadd local covariates ""
qui sum years_schooling if e(sample)
estadd scalar mean_y = r(mean)

* Col 2: Years of Schooling WITH covariates
eststo A2: qui regress years_schooling c.fully_exposed##c.rural c.partially_exposed##c.rural rural muslim i.maternal_birth_year i.survey_wave i.division, vce(cluster birth_year_rural)
estadd local covariates "X"
qui sum years_schooling if e(sample)
estadd scalar mean_y = r(mean)

* Col 3: Secondary or Higher Education WITHOUT covariates
eststo A3: qui regress secondary_plus c.fully_exposed##c.rural c.partially_exposed##c.rural rural, vce(cluster birth_year_rural)
estadd local covariates ""
qui sum secondary_plus if e(sample)
estadd scalar mean_y = r(mean)

* Col 4: Secondary or Higher Education WITH covariates
eststo A4: qui regress secondary_plus c.fully_exposed##c.rural c.partially_exposed##c.rural rural muslim i.maternal_birth_year i.survey_wave i.division, vce(cluster birth_year_rural)
estadd local covariates "X"
qui sum secondary_plus if e(sample)
estadd scalar mean_y = r(mean)

* Write Panel A
esttab A1 A2 A3 A4 using "${tables}/table2.tex", replace ///
    keep(c.fully_exposed#c.rural c.partially_exposed#c.rural) ///
    varlabels(c.fully_exposed#c.rural "Fully Exposed X Rural" ///
              c.partially_exposed#c.rural "Partially Exposed X Rural") ///
    cells(b(star fmt(3)) se(par fmt(5))) ///
    stats(covariates N mean_y, ///
          labels("Covariates" "Observations" "Dep. Var. Mean") ///
          fmt(0 %9.0fc 3)) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    booktabs fragment nomtitle nonotes nonumber collabels(none) ///
    prehead("\begin{table}[htbp]" ///
            "\centering" ///
            "\begin{threeparttable}" ///
            "\caption{Effect of FSSSP on maternal education and child immunization}" ///
            "\label{tab:table2}" ///
            "\footnotesize" ///
            "\begin{tabular}{l*{4}{c}}" ///
            "\toprule" ///
            " & (1) & (2) & (3) & (4) \\" ///
            "\midrule") ///
    posthead("\multicolumn{5}{l}{\textbf{Panel A: Mother Sample}} \\" ///
             " & \multicolumn{2}{c}{Years of Schooling} & \multicolumn{2}{c}{Secondary or Higher Education} \\" ///
             "\\")

********************************************************************************
* PANEL B: CHILD SAMPLE - EDUCATION
********************************************************************************

use "${analysis_data}/birth_sample.dta", clear
keep if child_age_months >= 12 & child_age_months <= 59
capture drop birth_year_rural
egen birth_year_rural = group(maternal_birth_year rural)

eststo clear

eststo B1: qui regress years_schooling c.fully_exposed##c.rural c.partially_exposed##c.rural rural, vce(cluster birth_year_rural)
estadd local covariates ""
qui sum years_schooling if e(sample)
estadd scalar mean_y = r(mean)

eststo B2: qui regress years_schooling c.fully_exposed##c.rural c.partially_exposed##c.rural rural muslim i.maternal_birth_year i.survey_wave i.division, vce(cluster birth_year_rural)
estadd local covariates "X"
qui sum years_schooling if e(sample)
estadd scalar mean_y = r(mean)

eststo B3: qui regress secondary_plus c.fully_exposed##c.rural c.partially_exposed##c.rural rural, vce(cluster birth_year_rural)
estadd local covariates ""
qui sum secondary_plus if e(sample)
estadd scalar mean_y = r(mean)

eststo B4: qui regress secondary_plus c.fully_exposed##c.rural c.partially_exposed##c.rural rural muslim i.maternal_birth_year i.survey_wave i.division, vce(cluster birth_year_rural)
estadd local covariates "X"
qui sum secondary_plus if e(sample)
estadd scalar mean_y = r(mean)

* Write Panel B (append)
esttab B1 B2 B3 B4 using "${tables}/table2.tex", append ///
    keep(c.fully_exposed#c.rural c.partially_exposed#c.rural) ///
    varlabels(c.fully_exposed#c.rural "Fully Exposed X Rural" ///
              c.partially_exposed#c.rural "Partially Exposed X Rural") ///
    cells(b(star fmt(3)) se(par fmt(5))) ///
    stats(covariates N mean_y, ///
          labels("Covariates" "Observations" "Dep. Var. Mean") ///
          fmt(0 %9.0fc 3)) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    booktabs fragment nomtitle nonotes nonumber collabels(none) ///
    prehead("") ///
    posthead("\multicolumn{5}{l}{\textbf{Panel B: Child Sample}} \\" ///
             " & \multicolumn{2}{c}{Years of Schooling} & \multicolumn{2}{c}{Secondary or Higher Education} \\" ///
             "\\")

********************************************************************************
* PANEL C: CHILD SAMPLE - IMMUNIZATION
********************************************************************************

use "${analysis_data}/child_sample.dta", clear
capture drop birth_year_rural
egen birth_year_rural = group(maternal_birth_year rural)

eststo clear

eststo C1: qui regress full_immunization c.fully_exposed##c.rural c.partially_exposed##c.rural rural, vce(cluster birth_year_rural)
estadd local covariates ""
qui sum full_immunization if e(sample)
estadd scalar mean_y = r(mean)

eststo C2: qui regress full_immunization c.fully_exposed##c.rural c.partially_exposed##c.rural rural muslim i.maternal_birth_year i.survey_wave i.division, vce(cluster birth_year_rural)
estadd local covariates "X"
qui sum full_immunization if e(sample)
estadd scalar mean_y = r(mean)

eststo C3: qui regress any_immunization c.fully_exposed##c.rural c.partially_exposed##c.rural rural, vce(cluster birth_year_rural)
estadd local covariates ""
qui sum any_immunization if e(sample)
estadd scalar mean_y = r(mean)

eststo C4: qui regress any_immunization c.fully_exposed##c.rural c.partially_exposed##c.rural rural muslim i.maternal_birth_year i.survey_wave i.division, vce(cluster birth_year_rural)
estadd local covariates "X"
qui sum any_immunization if e(sample)
estadd scalar mean_y = r(mean)

* Write Panel C (append, with footer)
esttab C1 C2 C3 C4 using "${tables}/table2.tex", append ///
    keep(c.fully_exposed#c.rural c.partially_exposed#c.rural) ///
    varlabels(c.fully_exposed#c.rural "Fully Exposed X Rural" ///
              c.partially_exposed#c.rural "Partially Exposed X Rural") ///
    cells(b(star fmt(4)) se(par fmt(5))) ///
    stats(covariates N mean_y, ///
          labels("Covariates" "Observations" "Dep. Var. Mean") ///
          fmt(0 %9.0fc 3)) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    booktabs fragment nomtitle nonotes nonumber collabels(none) ///
    prehead("") ///
    posthead("\multicolumn{5}{l}{\textbf{Panel C: Child Sample}} \\" ///
             " & \multicolumn{2}{c}{Full Immunization} & \multicolumn{2}{c}{Any Immunization} \\" ///
             "\\") ///
    postfoot("\bottomrule" ///
             "\end{tabular}" ///
             "\begin{tablenotes}" ///
             "\footnotesize" ///
             "\item \textit{Notes:} The mother's sample includes women born between 1971 and 1998 and the child sample includes children under 5 born to women born between 1971 and 1998. Full immunization indicates that the child received all eight doses of WHO recommended vaccines, and any immunization indicates that the child received at least one of the eight recommended vaccine doses. Fully exposed cohorts are born between 1983 and 1998, partially exposed cohorts are born between 1980 and 1982, and unexposed cohorts (reference group) are born between 1971 and 1979. Covariates include a binary indicator for rural residence, a binary indicator for Muslim, maternal birth year fixed effects, survey wave fixed effects, and division fixed effects. Standard errors in parentheses are clustered at the maternal year of birth $\times$ rural levels. ***, **, and * represent statistical significance at 0.01, 0.05, and 0.1 levels, respectively." ///
             "\item \textit{Source:} Bangladesh Demographic and Health Surveys, 1996--97 through 2017--18." ///
             "\end{tablenotes}" ///
             "\end{threeparttable}" ///
             "\end{table}")

display ""
display "================================================================================"
display "TABLE 2 CREATED: tables/table2.tex"
display "================================================================================"
