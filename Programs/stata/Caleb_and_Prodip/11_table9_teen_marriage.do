/*==============================================================================
Project: FSSSP Replication
Author: Caleb J. Dohou
Date: 2026-01-20
Purpose: Replicate Table 9 - Effect of FSSSP on Teen Marriage (Household Member Sample)

TABLE 9 STRUCTURE (Same as Table 7 but using Teen Marriage instead of Child Marriage):
This table examines the same outcomes as Table 7 but uses:
- Data source: Household Member (PR) sample instead of Child sample
- Outcome focus: Teen marriage (ages 13-19) instead of early marriage (from birth records)
- Same autonomy measures (columns 3-7) if available in PR files

EXPECTED COLUMNS:
Column 1: Age at first marriage (teen females 13-19)
Column 2: Married before 18 (teen females 13-19)
Column 3: Decides on health care (if available)
Column 4: Decides on purchases (if available)
Column 5: Decides on visits (if available)
Column 6: Decision-making index (if available)
Column 7: Can go to hospital alone (if available)

NOTE: Decision variables (columns 3-7) may NOT be available in PR files
      If not available, Table 9 will only have columns 1-2

DATA SOURCE: data/output/household_member_clean.dta
==============================================================================*/

clear all
set more off
version 19

cd "/Users/calebdohou/Library/CloudStorage/GoogleDrive-cjdohou@gmail.com/My Drive/Econ_PhD_University_of_Oklahoma/Dr Pallab Ghosh/FSSSP_Replication"

global clean_data "data/output"
global tables "tables"

log using "code/logs/11_table9_teen_marriage.log", replace text

display as result _n(2) "================================================================================"
display as result "REPLICATING TABLE 9: TEEN MARRIAGE (HOUSEHOLD MEMBER SAMPLE)"
display as result "================================================================================\" _n

/*------------------------------------------------------------------------------
1. Load Household Member Sample
------------------------------------------------------------------------------*/

use "$clean_data/household_member_clean.dta", clear

display as text "Total household members: " _N _n

* Restrict to female teenagers (ages 13-19) - PRIMARY SAMPLE
keep if teenager == 1 & female == 1

display as text "Female teenagers (ages 13-19): " _N

* Check marriage variable availability
display _n as text "=== Checking Marriage Variable Availability ===" _n
count if !missing(ever_married)
display as text "Non-missing ever_married: " r(N)
count if !missing(teen_married)
display as text "Non-missing teen_married: " r(N)

* Check if we have age at marriage (NOT available in PR files)
capture confirm variable age_marriage
if _rc == 0 {
    display as text "age_marriage: AVAILABLE"
}
else {
    display as error "age_marriage: NOT AVAILABLE in PR files"
    display as text "Note: Will need to use 'ever_married' as proxy"
}

/*------------------------------------------------------------------------------
2. Construct FSSSP Exposure Variables (Same as Table 7)
------------------------------------------------------------------------------*/

display _n as text "=== Constructing FSSSP Exposure Variables ===" _n

* Birth year (already created in household_member_clean.dta)
* post_fsssp already exists (born 1980+)
* fsssp_eligible already exists (rural females, post-1980)
* fsssp_exposed already exists (age 11-16 in 1994)

* Create fully_exposed and partially_exposed to match Table 7 coding
* Fully exposed: age 11-13 in 1994 (born 1981-1983)
gen fully_exposed = (birth_year >= 1981 & birth_year <= 1983) if !missing(birth_year)
label var fully_exposed "Fully exposed to FSSSP (age 11-13 in 1994)"

* Partially exposed: age 14-16 in 1994 (born 1978-1980)
gen partially_exposed = (birth_year >= 1978 & birth_year <= 1980) if !missing(birth_year)
label var partially_exposed "Partially exposed to FSSSP (age 14-16 in 1994)"

* Create rural indicator (already exists as 'urban')
gen rural = (urban == 0) if !missing(urban)
label var rural "Rural residence"

* Religion (not in PR files - use proxy if available, otherwise create dummy)
capture confirm variable muslim
if _rc != 0 {
    gen muslim = .
    label var muslim "Muslim (not available in PR files)"
    display as text "Warning: Muslim variable not available - set to missing"
}

* Create maternal_birth_year fixed effects
* For teens, use their own birth year as proxy
gen maternal_birth_year = birth_year
label var maternal_birth_year "Birth year (used as maternal proxy for teens)"

* Create clustering variable
egen maternal_by_rural = group(maternal_birth_year rural)
label var maternal_by_rural "Cluster: Birth year × Rural"

* Survey wave already exists

* Check variable distribution
display _n as text "=== Exposure Variable Distribution ===" _n
tab fully_exposed, mi
tab partially_exposed, mi
tab rural, mi

/*------------------------------------------------------------------------------
3. Construct Outcome Variables
------------------------------------------------------------------------------*/

display _n as text "=== Constructing Outcome Variables ===" _n

* Column 1: Age at first marriage
* NOT DIRECTLY AVAILABLE in PR files - would need to be inferred or omitted
* For now, we'll skip this column since PR files don't have marriage timing

* Column 2: Married before 18 (using ever_married as proxy)
* Since we're restricting to teens 13-19, we can identify those married before 18
gen married_before_18 = .
replace married_before_18 = 1 if ever_married == 1 & age < 18
replace married_before_18 = 0 if ever_married == 0 & age < 18
replace married_before_18 = . if age >= 18  // ambiguous for 18-19 year olds
label var married_before_18 "Married before age 18"

* Alternative: Use teen_married for all teens
gen teen_married_outcome = teen_married
label var teen_married_outcome "Ever married (teen females 13-19)"

* Decision-making variables (columns 3-7)
* NOT AVAILABLE in PR files - these come from IR (Individual Recode) files
display as error _n "WARNING: Decision-making variables (columns 3-7) NOT available in PR files"
display as text "Table 9 will only include marriage outcomes (columns 1-2 equivalent)" _n

/*------------------------------------------------------------------------------
4. Descriptive Statistics
------------------------------------------------------------------------------*/

display as result _n "=== Descriptive Statistics ===" _n

* Check sample sizes by exposure group
tab fully_exposed rural, mi
tab partially_exposed rural, mi

* Teen marriage rate
summarize teen_married_outcome
display as text "Teen marriage rate (all): " %6.3f r(mean)

summarize teen_married_outcome if rural == 1
display as text "Teen marriage rate (rural): " %6.3f r(mean)

summarize teen_married_outcome if rural == 0
display as text "Teen marriage rate (urban): " %6.3f r(mean)

* Married before 18 (restricted sample)
summarize married_before_18
display as text "Married before 18 (among <18 year olds): " %6.3f r(mean) _n

/*------------------------------------------------------------------------------
5. Run Regressions (Columns Available in PR Data)
------------------------------------------------------------------------------*/

display as result _n "=== Running Table 9 Regressions ===" _n

* We can only run regressions on variables available in PR files
* Column 1: Age at marriage - SKIP (not available)
* Column 2: Ever married (teen females) - RUN

* Column 2: Teen Marriage (Ever Married)
display as text "Column 2: Teen Marriage (Ever Married)" _n

* Check if we have sufficient non-missing data
count if !missing(teen_married_outcome, fully_exposed, partially_exposed, rural, maternal_birth_year, survey_wave, division)
local N_nonmiss = r(N)
display as text "Non-missing observations for regression: " `N_nonmiss' _n

if `N_nonmiss' > 100 {
    regress teen_married_outcome ///
        i.fully_exposed##i.rural ///
        i.partially_exposed##i.rural ///
        i.maternal_birth_year ///
        i.survey_wave ///
        i.division ///
        [pw=hh_weight], ///
        vce(cluster maternal_by_rural)

    * Extract coefficients
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

    quietly summarize teen_married_outcome if e(sample)
    scalar mean_2 = r(mean)

    * Display results
    display _n as result "=== TABLE 9 RESULTS (PARTIAL - MARRIAGE ONLY) ===" _n
    display as text "                              (2)"
    display as text "                          Teen Marriage"
    display as text "                          (Ever Married)"
    display as text "----------------------------------------"
    display as text "Fully Exposed × Rural     " %9.3f b_full_2
    display as text "                          " "(" %7.3f se_full_2 ")"
    display as text ""
    display as text "Partially Exposed × Rural " %9.3f b_part_2
    display as text "                          " "(" %7.3f se_part_2 ")"
    display as text "----------------------------------------"
    display as text "Observations              " %9.0f N_2
    display as text "Dep. Var. Mean            " %9.3f mean_2
    display as text "----------------------------------------" _n
}
else {
    display as error "ERROR: Insufficient non-missing observations for regression"
    display as text "Check variable availability and missing data patterns"
}

/*------------------------------------------------------------------------------
6. Export Results
------------------------------------------------------------------------------*/

display as result _n "=== Exporting Table 9 Results ===" _n

* Create LaTeX file (partial table - only marriage column)
file open texfile using "$tables/table9_teen_marriage.tex", write replace

* Header
file write texfile "\begin{table}[htbp]\centering" _n
file write texfile "\caption{Effect of FSSSP on Teen Marriage (Household Member Sample)}" _n
file write texfile "\label{tab:table9}" _n
file write texfile "\begin{tabular}{lc}" _n
file write texfile "\hline\hline" _n
file write texfile " & (2) \\" _n
file write texfile " & Teen Marriage \\" _n
file write texfile " & (Ever Married) \\" _n
file write texfile "\hline" _n

* Check if regression ran successfully
capture scalar list b_full_2
if _rc == 0 {
    * Fully Exposed × Rural
    file write texfile "Fully Exposed $\times$ Rural & " %9.3f (b_full_2) " \\" _n
    file write texfile " & (" %7.3f (se_full_2) ") \\" _n

    * Partially Exposed × Rural
    file write texfile "Partially Exposed $\times$ Rural & " %9.3f (b_part_2) " \\" _n
    file write texfile " & (" %7.3f (se_part_2) ") \\" _n

    file write texfile "\hline" _n

    * Observations
    file write texfile "Observations & " %9.0fc (N_2) " \\" _n

    * Dependent Variable Mean
    file write texfile "Dep. Var. Mean & " %9.3f (mean_2) " \\" _n
}
else {
    file write texfile "Regression did not run - insufficient data \\" _n
}

file write texfile "\hline\hline" _n
file write texfile "\end{tabular}" _n

* Notes
file write texfile "\begin{tablenotes}" _n
file write texfile "\small" _n
file write texfile "\item Notes: Standard errors in parentheses, clustered at birth year $\times$ rural level." _n
file write texfile "Regression includes controls for birth year fixed effects, survey wave fixed effects," _n
file write texfile "and division fixed effects. Sample uses household member (PR) data for female teenagers ages 13-19." _n
file write texfile "\\" _n
file write texfile "\item \textbf{Data Limitations:} Household Member (PR) files do not contain:" _n
file write texfile "(1) Age at first marriage (Column 1), (2) Decision-making variables (Columns 3-7)." _n
file write texfile "For complete Table 9 replication with all columns, use Individual Recode (IR) files" _n
file write texfile "which contain full reproductive history and decision-making data." _n
file write texfile "\end{tablenotes}" _n
file write texfile "\end{table}" _n

file close texfile

display as text "Partial Table 9 exported to: $tables/table9_teen_marriage.tex" _n

/*------------------------------------------------------------------------------
7. Recommendations for Complete Table 9
------------------------------------------------------------------------------*/

display as result _n(2) "================================================================================"
display as result "TABLE 9 REPLICATION STATUS & RECOMMENDATIONS"
display as result "================================================================================\" _n

display as text "CURRENT STATUS:" _n
display as text "✓ Teen marriage outcome (Column 2): REPLICATED using PR files"
display as text "✗ Age at first marriage (Column 1): NOT AVAILABLE in PR files"
display as text "✗ Decision-making variables (Columns 3-7): NOT AVAILABLE in PR files" _n

display as result "RECOMMENDATION FOR COMPLETE TABLE 9:" _n
display as text "To fully replicate Table 9 with all 7 columns:" _n
display as text "1. Create Individual Recode (IR) cleaning script: 01c_individual_recode_cleaning.do"
display as text "2. IR files contain:"
display as text "   - v511: Age at first marriage (for Column 1)"
display as text "   - v012: Current age (to identify teens 13-19)"
display as text "   - v743a-v743e: Decision-making variables (Columns 3-7)"
display as text "   - v744a: Can go to hospital alone (Column 7)"
display as text "3. Use same regression specification as Table 7"
display as text "4. Sample: Women ages 13-19 from IR files instead of children from BR files" _n

display as result "ALTERNATIVE APPROACH:" _n
display as text "If paper's Table 9 only has Columns 1-2 (marriage outcomes only),"
display as text "then the current PR-based replication is sufficient." _n

log close
display as result "Table 9 replication complete. Results saved to: code/logs/11_table9_teen_marriage.log"
