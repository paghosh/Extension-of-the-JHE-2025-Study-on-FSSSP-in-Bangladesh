********************************************************************************
* FSSSP Replication: Table 1 - Summary Statistics
* Uses iebaltab from ietoolkit for balance table with group comparisons
*
* Structure: 3 panels (Mother/Child/Birth samples)
* Columns: Full Sample Mean (SD), Fully Exposed Mean (t-stat),
*          Partially Exposed Mean, Unexposed Mean, Diff(2)-(4), Diff(3)-(4)
********************************************************************************

********************************************************************************
* PANEL A: MOTHER SAMPLE
********************************************************************************

use "${analysis_data}/mother_sample.dta", clear

* Create exposure group variable for iebaltab (needs single grouping var)
gen exposure_group = 0 if unexposed == 1
replace exposure_group = 1 if partially_exposed == 1
replace exposure_group = 2 if fully_exposed == 1

label define expgrp 0 "Unexposed" 1 "Partially Exposed" 2 "Fully Exposed"
label values exposure_group expgrp

* Label variables to match paper
label var years_schooling "Years of Schooling"
label var secondary_plus "Secondary or Higher Education"
label var maternal_age "(Maternal) Age"
label var rural "Rural"
label var muslim "Muslim"

* Generate Panel A using iebaltab
iebaltab years_schooling secondary_plus maternal_age rural muslim, ///
    grpvar(exposure_group) ///
    savetex("${tables}/table1_panelA.tex") replace ///
    tblnonote ///
    format(%9.3f) ///
    starlevels(0.10 0.05 0.01) ///
    rowvarlabels ///
    texnotewidth(1) ///
    tblnote("") ///
    nonote

* Store sample sizes for Panel A
qui count
local panelA_N = r(N)
qui count if fully_exposed == 1
local panelA_fully_N = r(N)
qui count if partially_exposed == 1
local panelA_part_N = r(N)
qui count if unexposed == 1
local panelA_unexp_N = r(N)

********************************************************************************
* PANEL B: CHILD SAMPLE
********************************************************************************

use "${analysis_data}/child_sample.dta", clear

gen exposure_group = 0 if unexposed == 1
replace exposure_group = 1 if partially_exposed == 1
replace exposure_group = 2 if fully_exposed == 1
label values exposure_group expgrp

label var full_immunization "Full Immunization"
label var any_immunization "Any Immunization"
label var years_schooling "(Maternal) Years of Schooling"
label var secondary_plus "(Maternal) Secondary or Higher Education"
label var maternal_age "(Maternal) Age"
label var rural "Rural"
label var muslim "Muslim"

iebaltab full_immunization any_immunization years_schooling secondary_plus ///
    maternal_age rural muslim, ///
    grpvar(exposure_group) ///
    savetex("${tables}/table1_panelB.tex") replace ///
    tblnonote ///
    format(%9.3f) ///
    starlevels(0.10 0.05 0.01) ///
    rowvarlabels ///
    nonote

qui count
local panelB_N = r(N)
qui count if fully_exposed == 1
local panelB_fully_N = r(N)
qui count if partially_exposed == 1
local panelB_part_N = r(N)
qui count if unexposed == 1
local panelB_unexp_N = r(N)

********************************************************************************
* PANEL C: BIRTH SAMPLE
********************************************************************************

use "${analysis_data}/birth_sample.dta", clear

gen exposure_group = 0 if unexposed == 1
replace exposure_group = 1 if partially_exposed == 1
replace exposure_group = 2 if fully_exposed == 1
label values exposure_group expgrp

label var neonatal_mort "Neonatal Mortality"
label var infant_mort "Infant Mortality"
label var child_mort "Child Mortality"
label var years_schooling "(Maternal) Years of Schooling"
label var secondary_plus "(Maternal) Secondary or Higher Education"
label var maternal_age "(Maternal) Age"
label var rural "Rural"
label var muslim "Muslim"

iebaltab neonatal_mort infant_mort child_mort years_schooling secondary_plus ///
    maternal_age rural muslim, ///
    grpvar(exposure_group) ///
    savetex("${tables}/table1_panelC.tex") replace ///
    tblnonote ///
    format(%9.3f) ///
    starlevels(0.10 0.05 0.01) ///
    rowvarlabels ///
    nonote

qui count
local panelC_N = r(N)
qui count if fully_exposed == 1
local panelC_fully_N = r(N)
qui count if partially_exposed == 1
local panelC_part_N = r(N)
qui count if unexposed == 1
local panelC_unexp_N = r(N)

********************************************************************************
* COMBINE PANELS INTO SINGLE TABLE
* Since iebaltab produces standalone tables, we combine the panels manually
* using the iebaltab fragment outputs
********************************************************************************

* Build combined table with all 3 panels
file open tex using "${tables}/table1.tex", write replace

file write tex "\begin{table}[htbp]" _n
file write tex "\centering" _n
file write tex "\begin{threeparttable}" _n
file write tex "\caption{Summary Statistics}" _n
file write tex "\label{tab:table1}" _n
file write tex "\footnotesize" _n
file write tex "\begin{tabular}{l*{6}{c}}" _n
file write tex "\toprule" _n
file write tex " & Full Sample & Fully & Partially & Unexposed & (2)-(4) & (3)-(4) \\" _n
file write tex " & Mean & Exposed & Exposed & Mean &  &  \\" _n
file write tex " & (Std. Dev.) & Mean & Mean &  &  &  \\" _n
file write tex " &  & (t statistic) &  &  & (t statistic) & (t statistic) \\" _n
file write tex " & (1) & (2) & (3) & (4) & (5) & (6) \\" _n
file write tex "\midrule" _n

* --- PANEL A ---
file write tex "\multicolumn{7}{l}{\textbf{Panel A: Mother Sample}} \\" _n
file write tex "\\" _n

* Compute Panel A stats manually (more reliable than parsing iebaltab fragments)
use "${analysis_data}/mother_sample.dta", clear

local panelA_vars years_schooling secondary_plus maternal_age rural muslim
local panelA_labels `" "Years of Schooling" "Secondary or Higher Education" "(Maternal) Age" "Rural" "Muslim" "'

local i = 1
foreach var of local panelA_vars {
    local varname : word `i' of `panelA_labels'

    * Full sample
    qui sum `var'
    local mean_full = r(mean)
    local sd_full = r(sd)

    * Group means
    qui sum `var' if fully_exposed == 1
    local mean_fully = r(mean)
    qui sum `var' if partially_exposed == 1
    local mean_part = r(mean)
    qui sum `var' if unexposed == 1
    local mean_unexp = r(mean)

    * Differences
    local diff_fu = `mean_fully' - `mean_unexp'
    local diff_pu = `mean_part' - `mean_unexp'

    * T-tests: Fully vs Unexposed
    preserve
    keep if fully_exposed == 1 | unexposed == 1
    qui ttest `var', by(fully_exposed) unequal
    local tstat_fu = r(t)
    local pval_fu = r(p)
    restore

    * T-tests: Partially vs Unexposed
    preserve
    keep if partially_exposed == 1 | unexposed == 1
    qui ttest `var', by(partially_exposed) unequal
    local tstat_pu = r(t)
    local pval_pu = r(p)
    restore

    * Stars
    local stars_fu = ""
    if `pval_fu' < 0.01      local stars_fu = "***"
    else if `pval_fu' < 0.05 local stars_fu = "**"
    else if `pval_fu' < 0.10 local stars_fu = "*"

    local stars_pu = ""
    if `pval_pu' < 0.01      local stars_pu = "***"
    else if `pval_pu' < 0.05 local stars_pu = "**"
    else if `pval_pu' < 0.10 local stars_pu = "*"

    * Write rows
    file write tex "`varname' & " %6.3f (`mean_full') " & " %6.3f (`mean_fully') " & " %6.3f (`mean_part') " & " %6.3f (`mean_unexp') " & " %6.3f (`diff_fu') "`stars_fu' & " %6.3f (`diff_pu') "`stars_pu' \\" _n
    file write tex " & (" %6.3f (`sd_full') ") & (" %6.2f (`tstat_fu') ") & & & (" %6.2f (`tstat_fu') ") & (" %6.2f (`tstat_pu') ") \\" _n

    local i = `i' + 1
}

qui count
file write tex "Observations & " %9.0fc (r(N)) " & " %9.0fc (`panelA_fully_N') " & " %9.0fc (`panelA_part_N') " & " %9.0fc (`panelA_unexp_N') " & & \\" _n
file write tex "\\" _n

* --- PANEL B ---
file write tex "\multicolumn{7}{l}{\textbf{Panel B: Child Sample}} \\" _n
file write tex "\\" _n

use "${analysis_data}/child_sample.dta", clear

local panelB_vars full_immunization any_immunization years_schooling secondary_plus maternal_age rural muslim
local panelB_labels `" "Full Immunization" "Any Immunization" "(Maternal) Years of Schooling" "(Maternal) Secondary or Higher Education" "(Maternal) Age" "Rural" "Muslim" "'

local i = 1
foreach var of local panelB_vars {
    local varname : word `i' of `panelB_labels'

    qui sum `var'
    local mean_full = r(mean)
    local sd_full = r(sd)

    qui sum `var' if fully_exposed == 1
    local mean_fully = r(mean)
    qui sum `var' if partially_exposed == 1
    local mean_part = r(mean)
    qui sum `var' if unexposed == 1
    local mean_unexp = r(mean)

    local diff_fu = `mean_fully' - `mean_unexp'
    local diff_pu = `mean_part' - `mean_unexp'

    preserve
    keep if fully_exposed == 1 | unexposed == 1
    qui ttest `var', by(fully_exposed) unequal
    local tstat_fu = r(t)
    local pval_fu = r(p)
    restore

    preserve
    keep if partially_exposed == 1 | unexposed == 1
    qui ttest `var', by(partially_exposed) unequal
    local tstat_pu = r(t)
    local pval_pu = r(p)
    restore

    local stars_fu = ""
    if `pval_fu' < 0.01      local stars_fu = "***"
    else if `pval_fu' < 0.05 local stars_fu = "**"
    else if `pval_fu' < 0.10 local stars_fu = "*"

    local stars_pu = ""
    if `pval_pu' < 0.01      local stars_pu = "***"
    else if `pval_pu' < 0.05 local stars_pu = "**"
    else if `pval_pu' < 0.10 local stars_pu = "*"

    file write tex "`varname' & " %6.3f (`mean_full') " & " %6.3f (`mean_fully') " & " %6.3f (`mean_part') " & " %6.3f (`mean_unexp') " & " %6.3f (`diff_fu') "`stars_fu' & " %6.3f (`diff_pu') "`stars_pu' \\" _n
    file write tex " & (" %6.3f (`sd_full') ") & (" %6.2f (`tstat_fu') ") & & & (" %6.2f (`tstat_fu') ") & (" %6.2f (`tstat_pu') ") \\" _n

    local i = `i' + 1
}

qui count
file write tex "Observations & " %9.0fc (r(N)) " & " %9.0fc (`panelB_fully_N') " & " %9.0fc (`panelB_part_N') " & " %9.0fc (`panelB_unexp_N') " & & \\" _n
file write tex "\\" _n

* --- PANEL C ---
file write tex "\multicolumn{7}{l}{\textbf{Panel C: Birth Sample}} \\" _n
file write tex "\\" _n

use "${analysis_data}/birth_sample.dta", clear

local panelC_vars neonatal_mort infant_mort child_mort years_schooling secondary_plus maternal_age rural muslim
local panelC_labels `" "Neonatal Mortality" "Infant Mortality" "Child Mortality" "(Maternal) Years of Schooling" "(Maternal) Secondary or Higher Education" "(Maternal) Age" "Rural" "Muslim" "'

local i = 1
foreach var of local panelC_vars {
    local varname : word `i' of `panelC_labels'

    qui sum `var'
    local mean_full = r(mean)
    local sd_full = r(sd)

    qui sum `var' if fully_exposed == 1
    local mean_fully = r(mean)
    qui sum `var' if partially_exposed == 1
    local mean_part = r(mean)
    qui sum `var' if unexposed == 1
    local mean_unexp = r(mean)

    local diff_fu = `mean_fully' - `mean_unexp'
    local diff_pu = `mean_part' - `mean_unexp'

    preserve
    keep if fully_exposed == 1 | unexposed == 1
    qui ttest `var', by(fully_exposed) unequal
    local tstat_fu = r(t)
    local pval_fu = r(p)
    restore

    preserve
    keep if partially_exposed == 1 | unexposed == 1
    qui ttest `var', by(partially_exposed) unequal
    local tstat_pu = r(t)
    local pval_pu = r(p)
    restore

    local stars_fu = ""
    if `pval_fu' < 0.01      local stars_fu = "***"
    else if `pval_fu' < 0.05 local stars_fu = "**"
    else if `pval_fu' < 0.10 local stars_fu = "*"

    local stars_pu = ""
    if `pval_pu' < 0.01      local stars_pu = "***"
    else if `pval_pu' < 0.05 local stars_pu = "**"
    else if `pval_pu' < 0.10 local stars_pu = "*"

    file write tex "`varname' & " %6.3f (`mean_full') " & " %6.3f (`mean_fully') " & " %6.3f (`mean_part') " & " %6.3f (`mean_unexp') " & " %6.3f (`diff_fu') "`stars_fu' & " %6.3f (`diff_pu') "`stars_pu' \\" _n
    file write tex " & (" %6.3f (`sd_full') ") & (" %6.2f (`tstat_fu') ") & & & (" %6.2f (`tstat_fu') ") & (" %6.2f (`tstat_pu') ") \\" _n

    local i = `i' + 1
}

qui count
file write tex "Observations & " %9.0fc (r(N)) " & " %9.0fc (`panelC_fully_N') " & " %9.0fc (`panelC_part_N') " & " %9.0fc (`panelC_unexp_N') " & & \\" _n

* Footer
file write tex "\bottomrule" _n
file write tex "\end{tabular}" _n
file write tex "\begin{tablenotes}" _n
file write tex "\footnotesize" _n
file write tex "\item \textit{Notes:} The mother sample includes women born between 1971 and 1998. The child sample includes children aged 12--59 months born to women born between 1971 and 1998. The birth sample includes all births recorded in the surveys. Fully exposed cohorts are born between 1983 and 1998, partially exposed cohorts are born between 1980 and 1982, and unexposed cohorts (reference group) are born between 1971 and 1979. Columns (5) and (6) report the difference in means between the indicated groups, with t-statistics in parentheses from two-sample t-tests with unequal variances. ***, **, and * represent statistical significance at 0.01, 0.05, and 0.1 levels, respectively." _n
file write tex "\item \textit{Source:} Bangladesh Demographic and Health Surveys, 1996--97 through 2017--18." _n
file write tex "\end{tablenotes}" _n
file write tex "\end{threeparttable}" _n
file write tex "\end{table}" _n

file close tex

* Clean up iebaltab panel files
capture erase "${tables}/table1_panelA.tex"
capture erase "${tables}/table1_panelB.tex"
capture erase "${tables}/table1_panelC.tex"

display ""
display "================================================================================"
display "TABLE 1 CREATED: tables/table1.tex"
display "================================================================================"
