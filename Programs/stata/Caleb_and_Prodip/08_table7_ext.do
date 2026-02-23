/*==============================================================================
Project: FSSSP Replication
Author: 
Date: 
Purpose: Replicate Table 7 - Effect of FSSSP on Early Marriage and Female Autonomy

TABLE 7 STRUCTURE:
Column 1: Age at first marriage (N=32,751)
Column 2: Married before 18 (N=32,751)
Column 3: Decides on health care (N=26,765)
Column 4: Decides on purchases (N=26,756)
Column 5: Decides on visits (N=26,756)
Column 6: Decision-making index (N=26,765)
Column 7: Can go to hospital alone (N=24,132)

NOTE: Columns 3-7 use decision variables only available 2004+ (Phase 5-7)
==============================================================================*/

display as result _n(2) "================================================================================"
display as result "REPLICATING TABLE 7: EARLY MARRIAGE AND FEMALE AUTONOMY"
display as result "================================================================================\" _n

/*------------------------------------------------------------------------------
1. Load Child Sample and Collapse to Mother Level
------------------------------------------------------------------------------*/

use "${analysis_data}/child_sample.dta", clear

display as text "Child sample: " _N " children from child-level data"

* Collapse to mother level (keep first observation per mother)
* All mother-level variables are constant within mother
egen tag_mother = tag(caseid)
keep if tag_mother == 1

display as text "Unique mothers: " _N
display as text "Paper reports N=32,751 (child count, not mother count)" _n

/*------------------------------------------------------------------------------
2. Verify Variable Means (Critical Check!)
------------------------------------------------------------------------------*/

display as result "=== VERIFICATION: Variable Means ===\" _n

* Marriage variables (all waves)
summarize v212
display as text "age_marriage:        " %7.3f r(mean) " (target: 15.696, " %5.1f (r(mean)/15.696*100) "%)"
local N_marriage = r(N)

gen teen_pregnancy = (v212 < 18) if !missing(v212)
summarize teen_pregnancy
display as text "pregnant_before_18:   " %7.3f r(mean) " (target:  0.641, " %5.1f (r(mean)/0.641*100) "%)"

display as text _n "Decision-making variables (2004+ only):" _n

* Column 3: Decides on health care
summarize decides_health
display as text "decides_health:      " %7.3f r(mean) " (target:  0.626, " %5.1f (r(mean)/0.626*100) "%)"
local N_health = r(N)

* Column 4: Decides on purchases
summarize decides_purchases
display as text "decides_purchases:   " %7.3f r(mean) " (target:  0.608, " %5.1f (r(mean)/0.608*100) "%)"
local N_purchases = r(N)

* Column 5: Decides on visits
summarize decides_visits
display as text "decides_visits:      " %7.3f r(mean) " (target:  0.627, " %5.1f (r(mean)/0.627*100) "%)"
local N_visits = r(N)

* Column 6: Decision-making index
summarize decision_index
display as text "decision_index:      " %7.3f r(mean) " (target:  1.861, " %5.1f (r(mean)/1.861*100) "%)"
local N_index = r(N)

* Column 7: Can go to hospital alone
summarize can_go_hospital
display as text "can_go_hospital:     " %7.3f r(mean) " (target:  0.065, " %5.1f (r(mean)/0.065*100) "%)" _n
local N_hospital = r(N)

display as text "Sample sizes:" _n
display as text "  Columns 1-2 (marriage): " `N_marriage'
display as text "  Column 3 (health):      " `N_health'
display as text "  Column 4 (purchases):   " `N_purchases'
display as text "  Column 5 (visits):      " `N_visits'
display as text "  Column 6 (index):       " `N_index'
display as text "  Column 7 (hospital):    " `N_hospital' _n

*gen teen_pregnancy = (v212 <= 18) if v212 != .

/*------------------------------------------------------------------------------
3. Run All Regressions
------------------------------------------------------------------------------*/

display as result "=== Running Table 7 Regressions ===\" _n

* Column 1: Age at first marriage
display as text "Column 1: Age at First Marriage" _n
regress v212 ///
    i.fully_exposed##i.rural ///
    i.partially_exposed##i.rural ///
    i.muslim ///
    i.maternal_birth_year ///
    i.survey_wave ///
    i.division ///
    [pw=weight], ///
    vce(cluster maternal_by_rural)

lincom 1.fully_exposed#1.rural
scalar b_full_1 = r(estimate)
scalar se_full_1 = r(se)
scalar p_full_1 = 2*ttail(r(df), abs(r(estimate)/r(se)))
lincom 1.partially_exposed#1.rural
scalar b_part_1 = r(estimate)
scalar se_part_1 = r(se)
scalar p_part_1 = 2*ttail(r(df), abs(r(estimate)/r(se)))
quietly count if e(sample)
scalar N_1 = r(N)
quietly summarize age_marriage if e(sample)
scalar mean_1 = r(mean)

* Column 2: Married before age 18
display as text _n "Column 2: Married Before Age 18" _n
regress teen_pregnancy ///
    i.fully_exposed##i.rural ///
    i.partially_exposed##i.rural ///
    i.muslim ///
    i.maternal_birth_year ///
    i.survey_wave ///
    i.division ///
    [pw=weight], ///
    vce(cluster maternal_by_rural)

lincom 1.fully_exposed#1.rural
scalar b_full_2 = r(estimate)
scalar se_full_2 = r(se)
scalar p_full_2 = 2*ttail(r(df), abs(r(estimate)/r(se)))
lincom 1.partially_exposed#1.rural
scalar b_part_2 = r(estimate)
scalar se_part_2 = r(se)
scalar p_part_2 = 2*ttail(r(df), abs(r(estimate)/r(se)))
quietly count if e(sample)
scalar N_2 = r(N)
quietly summarize married_before_18 if e(sample)
scalar mean_2 = r(mean)

* Column 3: Decides on health care
display as text _n "Column 3: Decides on Health Care" _n
regress decides_health ///
    i.fully_exposed##i.rural ///
    i.partially_exposed##i.rural ///
    i.muslim ///
    i.maternal_birth_year ///
    i.survey_wave ///
    i.division ///
    [pw=weight], ///
    vce(cluster maternal_by_rural)

lincom 1.fully_exposed#1.rural
scalar b_full_3 = r(estimate)
scalar se_full_3 = r(se)
scalar p_full_3 = 2*ttail(r(df), abs(r(estimate)/r(se)))
lincom 1.partially_exposed#1.rural
scalar b_part_3 = r(estimate)
scalar se_part_3 = r(se)
scalar p_part_3 = 2*ttail(r(df), abs(r(estimate)/r(se)))
quietly count if e(sample)
scalar N_3 = r(N)
quietly summarize decides_health if e(sample)
scalar mean_3 = r(mean)

* Column 4: Decides on large household purchases
display as text _n "Column 4: Decides on Large Purchases" _n
regress decides_purchases ///
    i.fully_exposed##i.rural ///
    i.partially_exposed##i.rural ///
    i.muslim ///
    i.maternal_birth_year ///
    i.survey_wave ///
    i.division ///
    [pw=weight], ///
    vce(cluster maternal_by_rural)

lincom 1.fully_exposed#1.rural
scalar b_full_4 = r(estimate)
scalar se_full_4 = r(se)
scalar p_full_4 = 2*ttail(r(df), abs(r(estimate)/r(se)))
lincom 1.partially_exposed#1.rural
scalar b_part_4 = r(estimate)
scalar se_part_4 = r(se)
scalar p_part_4 = 2*ttail(r(df), abs(r(estimate)/r(se)))
quietly count if e(sample)
scalar N_4 = r(N)
quietly summarize decides_purchases if e(sample)
scalar mean_4 = r(mean)

* Column 5: Decides on visits to family or relatives
display as text _n "Column 5: Decides on Family Visits" _n
regress decides_visits ///
    i.fully_exposed##i.rural ///
    i.partially_exposed##i.rural ///
    i.muslim ///
    i.maternal_birth_year ///
    i.survey_wave ///
    i.division ///
    [pw=weight], ///
    vce(cluster maternal_by_rural)

lincom 1.fully_exposed#1.rural
scalar b_full_5 = r(estimate)
scalar se_full_5 = r(se)
scalar p_full_5 = 2*ttail(r(df), abs(r(estimate)/r(se)))
lincom 1.partially_exposed#1.rural
scalar b_part_5 = r(estimate)
scalar se_part_5 = r(se)
scalar p_part_5 = 2*ttail(r(df), abs(r(estimate)/r(se)))
quietly count if e(sample)
scalar N_5 = r(N)
quietly summarize decides_visits if e(sample)
scalar mean_5 = r(mean)

* Column 6: Decision-making index
display as text _n "Column 6: Decision-Making Index" _n
regress decision_index ///
    i.fully_exposed##i.rural ///
    i.partially_exposed##i.rural ///
    i.muslim ///
    i.maternal_birth_year ///
    i.survey_wave ///
    i.division ///
    [pw=weight], ///
    vce(cluster maternal_by_rural)

lincom 1.fully_exposed#1.rural
scalar b_full_6 = r(estimate)
scalar se_full_6 = r(se)
scalar p_full_6 = 2*ttail(r(df), abs(r(estimate)/r(se)))
lincom 1.partially_exposed#1.rural
scalar b_part_6 = r(estimate)
scalar se_part_6 = r(se)
scalar p_part_6 = 2*ttail(r(df), abs(r(estimate)/r(se)))
quietly count if e(sample)
scalar N_6 = r(N)
quietly summarize decision_index if e(sample)
scalar mean_6 = r(mean)

* Column 7: Can go to hospital alone
display as text _n "Column 7: Can Go to Hospital Alone" _n
regress can_go_hospital ///
    i.fully_exposed##i.rural ///
    i.partially_exposed##i.rural ///
    i.muslim ///
    i.maternal_birth_year ///
    i.survey_wave ///
    i.division ///
    [pw=weight], ///
    vce(cluster maternal_by_rural)

lincom 1.fully_exposed#1.rural
scalar b_full_7 = r(estimate)
scalar se_full_7 = r(se)
scalar p_full_7 = 2*ttail(r(df), abs(r(estimate)/r(se)))
lincom 1.partially_exposed#1.rural
scalar b_part_7 = r(estimate)
scalar se_part_7 = r(se)
scalar p_part_7 = 2*ttail(r(df), abs(r(estimate)/r(se)))
quietly count if e(sample)
scalar N_7 = r(N)
quietly summarize can_go_hospital if e(sample)
scalar mean_7 = r(mean)

/*------------------------------------------------------------------------------
4. Display Results Table
------------------------------------------------------------------------------*/

display as result _n(2) "================================================================================"
display as result "TABLE 7: EARLY MARRIAGE AND FEMALE AUTONOMY"
display as result "================================================================================\" _n

display as text "                              (1)       (2)       (3)       (4)       (5)       (6)       (7)"
display as text "                          Age First  Married   Decides   Decides   Decides  Decision    Can Go"
display as text "                           Marriage  Before 18  Health   Purchase   Visits    Index   Hospital"
display as text "--------------------------------------------------------------------------------------------"

display as text "Fully Exposed X Rural   " ///
    %9.3f b_full_1 "  " %9.3f b_full_2 "  " %9.3f b_full_3 "  " %9.3f b_full_4 "  " %9.3f b_full_5 "  " %9.3f b_full_6 "  " %9.3f b_full_7
display as text "                        " ///
    "(" %7.3f se_full_1 ") " "(" %7.3f se_full_2 ") " "(" %7.3f se_full_3 ") " "(" %7.3f se_full_4 ") " "(" %7.3f se_full_5 ") " "(" %7.3f se_full_6 ") " "(" %7.3f se_full_7 ")"

display as text "Partially Exposed X Rural " ///
    %9.3f b_part_1 "  " %9.3f b_part_2 "  " %9.3f b_part_3 "  " %9.3f b_part_4 "  " %9.3f b_part_5 "  " %9.3f b_part_6 "  " %9.3f b_part_7
display as text "                        " ///
    "(" %7.3f se_part_1 ") " "(" %7.3f se_part_2 ") " "(" %7.3f se_part_3 ") " "(" %7.3f se_part_4 ") " "(" %7.3f se_part_5 ") " "(" %7.3f se_part_6 ") " "(" %7.3f se_part_7 ")"

display as text "--------------------------------------------------------------------------------------------"
display as text "Observations            " ///
    %9.0f N_1 "  " %9.0f N_2 "  " %9.0f N_3 "  " %9.0f N_4 "  " %9.0f N_5 "  " %9.0f N_6 "  " %9.0f N_7

display as text "Dep. Var. Mean          " ///
    %9.3f mean_1 "  " %9.3f mean_2 "  " %9.3f mean_3 "  " %9.3f mean_4 "  " %9.3f mean_5 "  " %9.3f mean_6 "  " %9.3f mean_7

display as text "--------------------------------------------------------------------------------------------" _n

/*------------------------------------------------------------------------------
5. Compare to Paper Targets
------------------------------------------------------------------------------*/

display as result "=== COMPARISON TO PAPER TARGETS ===\" _n

display as text "FULLY EXPOSED × RURAL:" _n
display as text "Column 1 (Age marriage):   " %7.3f b_full_1 " vs paper  0.505*** (match: " %5.1f abs(b_full_1/0.505*100) "%)"
display as text "Column 2 (Married <18):    " %7.3f b_full_2 " vs paper -0.059*** (match: " %5.1f abs(b_full_2/-0.059*100) "%)"
display as text "Column 3 (Health):         " %7.3f b_full_3 " vs paper  0.064*** (match: " %5.1f abs(b_full_3/0.064*100) "%)"
display as text "Column 4 (Purchases):      " %7.3f b_full_4 " vs paper  0.088*** (match: " %5.1f abs(b_full_4/0.088*100) "%)"
display as text "Column 5 (Visits):         " %7.3f b_full_5 " vs paper  0.055*** (match: " %5.1f abs(b_full_5/0.055*100) "%)"
display as text "Column 6 (Index):          " %7.3f b_full_6 " vs paper  0.207*** (match: " %5.1f abs(b_full_6/0.207*100) "%)"
display as text "Column 7 (Hospital):       " %7.3f b_full_7 " vs paper  0.028*** (match: " %5.1f abs(b_full_7/0.028*100) "%)" _n

display as text "PARTIALLY EXPOSED × RURAL:" _n
display as text "Column 1 (Age marriage):   " %7.3f b_part_1 " vs paper  0.230*** (match: " %5.1f abs(b_part_1/0.230*100) "%)"
display as text "Column 2 (Married <18):    " %7.3f b_part_2 " vs paper -0.036*** (match: " %5.1f abs(b_part_2/-0.036*100) "%)"
display as text "Column 3 (Health):         " %7.3f b_part_3 " vs paper  0.019*   (match: " %5.1f abs(b_part_3/0.019*100) "%)"
display as text "Column 4 (Purchases):      " %7.3f b_part_4 " vs paper  0.031*** (match: " %5.1f abs(b_part_4/0.031*100) "%)"
display as text "Column 5 (Visits):         " %7.3f b_part_5 " vs paper  0.022*   (match: " %5.1f abs(b_part_5/0.022*100) "%)"
display as text "Column 6 (Index):          " %7.3f b_part_6 " vs paper  0.072*   (match: " %5.1f abs(b_part_6/0.072*100) "%)"
display as text "Column 7 (Hospital):       " %7.3f b_part_7 " vs paper  0.019**  (match: " %5.1f abs(b_part_7/0.019*100) "%)" _n

/*------------------------------------------------------------------------------
6. Export Table to LaTeX
------------------------------------------------------------------------------*/

display as result _n "=== Exporting Table 7 to LaTeX ===" _n

* Create LaTeX file
file open texfile using "${tables}/table7_ext.tex", write replace

* Header
file write texfile "\begin{table}[htbp]\centering" _n
file write texfile "\caption{Effect of FSSSP on Early Marriage and Female Autonomy}" _n
file write texfile "\label{tab:table7 Extended}" _n
file write texfile "\begin{tabular}{l*{7}{c}}" _n
file write texfile "\hline\hline" _n
file write texfile " & (1) & (2) & (3) & (4) & (5) & (6) & (7) \\" _n
file write texfile " & Age First & Married & Decides & Decides & Decides & Decision & Can Go \\" _n
file write texfile " & Marriage & Before 18 & Health & Purchase & Visits & Index & Hospital \\" _n
file write texfile "\hline" _n

* Fully Exposed X Rural
file write texfile "Fully Exposed $\times$ Rural & "
file write texfile %9.3f (b_full_1) " & " %9.3f (b_full_2) " & " %9.3f (b_full_3) " & "
file write texfile %9.3f (b_full_4) " & " %9.3f (b_full_5) " & " %9.3f (b_full_6) " & " %9.3f (b_full_7) " \\" _n
file write texfile " & (" %7.3f (se_full_1) ") & (" %7.3f (se_full_2) ") & (" %7.3f (se_full_3) ") & "
file write texfile "(" %7.3f (se_full_4) ") & (" %7.3f (se_full_5) ") & (" %7.3f (se_full_6) ") & (" %7.3f (se_full_7) ") \\" _n

* Partially Exposed X Rural
file write texfile "Partially Exposed $\times$ Rural & "
file write texfile %9.3f (b_part_1) " & " %9.3f (b_part_2) " & " %9.3f (b_part_3) " & "
file write texfile %9.3f (b_part_4) " & " %9.3f (b_part_5) " & " %9.3f (b_part_6) " & " %9.3f (b_part_7) " \\" _n
file write texfile " & (" %7.3f (se_part_1) ") & (" %7.3f (se_part_2) ") & (" %7.3f (se_part_3) ") & "
file write texfile "(" %7.3f (se_part_4) ") & (" %7.3f (se_part_5) ") & (" %7.3f (se_part_6) ") & (" %7.3f (se_part_7) ") \\" _n

file write texfile "\hline" _n

* Observations
file write texfile "Observations & "
file write texfile %9.0fc (N_1) " & " %9.0fc (N_2) " & " %9.0fc (N_3) " & "
file write texfile %9.0fc (N_4) " & " %9.0fc (N_5) " & " %9.0fc (N_6) " & " %9.0fc (N_7) " \\" _n

* Dependent Variable Mean
file write texfile "Dep. Var. Mean & "
file write texfile %9.3f (mean_1) " & " %9.3f (mean_2) " & " %9.3f (mean_3) " & "
file write texfile %9.3f (mean_4) " & " %9.3f (mean_5) " & " %9.3f (mean_6) " & " %9.3f (mean_7) " \\" _n

file write texfile "\hline\hline" _n
file write texfile "\end{tabular}" _n

* Notes
file write texfile "\begin{tablenotes}" _n
file write texfile "\small" _n
file write texfile "\item Notes: Standard errors in parentheses, clustered at maternal birth year $\times$ rural level." _n
file write texfile "All regressions include controls for maternal birth year fixed effects, survey wave fixed effects," _n
file write texfile "division fixed effects, and Muslim indicator. Columns 3-7 use decision-making variables available" _n
file write texfile "only in 2004-2017 surveys (Phase 5-7). Sample uses child sample mothers with weights." _n
file write texfile "\end{tablenotes}" _n
file write texfile "\end{table}" _n

file close texfile

display as text "Table 7 exported to: $tables/table7_ext.tex" _n


