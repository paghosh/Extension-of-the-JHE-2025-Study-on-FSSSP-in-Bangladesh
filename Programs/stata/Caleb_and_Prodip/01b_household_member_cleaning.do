/*******************************************************************************
* FSSSP REPLICATION PROJECT
* Household Member (PR Recode) Data Cleaning
*
* Purpose: Clean and harmonize Household Member data across all DHS waves
*          Construct key variables: child labour, teen pregnancy indicators
*
* Input:   Raw PR (Household Member) recode files (1996-2017)
* Output:  data/output/household_member_clean.dta
*
* Author:  Replication Team
* Date:    January 2026
* Stata:   Version 19
*******************************************************************************/

version 19
clear all
set more off
set maxvar 10000

* Set working directory
cd "/Users/calebdohou/Library/CloudStorage/GoogleDrive-cjdohou@gmail.com/My Drive/Econ_PhD_University_of_Oklahoma/Dr Pallab Ghosh/FSSSP_Replication"

* Start log file
log using "code/logs/01b_household_member_cleaning.log", replace text

di _newline(2)
di "========================================================================="
di "HOUSEHOLD MEMBER (PR RECODE) DATA CLEANING"
di "Bangladesh DHS 1996-97 through 2017-18"
di "========================================================================="
di _newline(2)

***********************************************************************
* SECTION 1: APPEND ALL HOUSEHOLD MEMBER FILES
***********************************************************************

di "SECTION 1: Appending all Household Member (PR) files..."
di "--------------------------------------------------------"

* Initialize empty dataset
clear
tempfile alldata

***********************************************************************
* 1996-97 SURVEY
***********************************************************************

di _newline "Loading 1996-97 Bangladesh DHS..."
use "data/raw_data/BD_1996-97_DHS_12292025_1726_237609/BDPR31DT/BDPR3AFL.DTA", clear

* Generate survey year identifier
gen survey_year = 1996
label var survey_year "DHS Survey Year"

* Generate survey wave identifier
gen survey_wave = 1
label var survey_wave "Survey Wave (1=1996-97, 2=1999-00, etc.)"

* Keep relevant variables (only those that exist in 1996-97)
keep hhid hv000 hv001 hv002 hv003 hv005 hv024 hv025 hv104 hv105 hv106 ///
     hv107 hv108 hv109 hv110 hv111 hv112 hv115 hv116 hv117 hv118 ///
     hvidx sh14 survey_year survey_wave

* Rename work variable for consistency
rename sh14 work_status_raw
label var work_status_raw "Raw work status variable"

* Initialize variables not available in 1996-97
gen ha54 = .
label var ha54 "Currently pregnant (from later waves)"

gen hv120 = .
label var hv120 "Children eligibility (from later waves)"

gen hv121 = .
label var hv121 "Attended school during current year (from later waves)"

gen hv122 = .
label var hv122 "Educational level during current year (from later waves)"

* Count observations
qui count
di "  N = " %12.0fc r(N) " household members"

* Save first wave
save `alldata', replace

***********************************************************************
* 1999-00 SURVEY
***********************************************************************

di _newline "Loading 1999-00 Bangladesh DHS..."
use "data/raw_data/BD_1999-00_DHS_12292025_1725_237609/BDPR41DT/BDPR41FL.DTA", clear

gen survey_year = 1999
label var survey_year "DHS Survey Year"
gen survey_wave = 2
label var survey_wave "Survey Wave"

keep hhid hv000 hv001 hv002 hv003 hv005 hv024 hv025 hv104 hv105 hv106 ///
     hv107 hv108 hv109 hv110 hv111 hv112 hv115 hv116 hv117 hv118 ///
     hvidx sh14 survey_year survey_wave

rename sh14 work_status_raw
label var work_status_raw "Raw work status variable"

* Initialize variables not available in 1999-00
gen ha54 = .
label var ha54 "Currently pregnant (from later waves)"

gen hv120 = .
label var hv120 "Children eligibility (from later waves)"

gen hv121 = .
label var hv121 "Attended school during current year (from later waves)"

gen hv122 = .
label var hv122 "Educational level during current year (from later waves)"

qui count
di "  N = " %12.0fc r(N) " household members"

* Append to master file
append using `alldata'
save `alldata', replace

***********************************************************************
* 2007 SURVEY
***********************************************************************

di _newline "Loading 2007 Bangladesh DHS..."
use "data/raw_data/BD_2007_DHS_12292025_1724_237609/BDPR51DT/BDPR51FL.DTA", clear

gen survey_year = 2007
label var survey_year "DHS Survey Year"
gen survey_wave = 3
label var survey_wave "Survey Wave"

keep hhid hv000 hv001 hv002 hv003 hv005 hv024 hv025 hv104 hv105 hv106 ///
     hv107 hv108 hv109 hv110 hv111 hv112 hv115 hv116 hv117 hv118 hv120 hv121 hv122 ///
     hvidx sh15 ha54 survey_year survey_wave

* Note: 2007 uses sh15 instead of sh14
rename sh15 work_status_raw
label var work_status_raw "Raw work status variable"

qui count
di "  N = " %12.0fc r(N) " household members"

append using `alldata'
save `alldata', replace

***********************************************************************
* 2011 SURVEY
***********************************************************************

di _newline "Loading 2011 Bangladesh DHS..."
use "data/raw_data/BD_2011_DHS_12292025_1723_237609/BDPR61DT/BDPR61FL.DTA", clear

gen survey_year = 2011
label var survey_year "DHS Survey Year"
gen survey_wave = 4
label var survey_wave "Survey Wave"

keep hhid hv000 hv001 hv002 hv003 hv005 hv024 hv025 hv104 hv105 hv106 ///
     hv107 hv108 hv109 hv110 hv111 hv112 hv115 hv116 hv117 hv118 hv120 hv121 hv122 ///
     hvidx sh13 ha54 survey_year survey_wave

* 2011 uses sh13
rename sh13 work_status_raw
label var work_status_raw "Raw work status variable"

qui count
di "  N = " %12.0fc r(N) " household members"

append using `alldata'
save `alldata', replace

***********************************************************************
* 2014 SURVEY
***********************************************************************

di _newline "Loading 2014 Bangladesh DHS..."
use "data/raw_data/BD_2014_DHS_12292025_1723_237609/BDPR72DT/BDPR72FL.DTA", clear

gen survey_year = 2014
label var survey_year "DHS Survey Year"
gen survey_wave = 5
label var survey_wave "Survey Wave"

keep hhid hv000 hv001 hv002 hv003 hv005 hv024 hv025 hv104 hv105 hv106 ///
     hv107 hv108 hv109 hv110 hv111 hv112 hv115 hv116 hv117 hv118 hv120 hv121 hv122 ///
     hvidx sh13 ha54 survey_year survey_wave

rename sh13 work_status_raw
label var work_status_raw "Raw work status variable"

qui count
di "  N = " %12.0fc r(N) " household members"

append using `alldata'
save `alldata', replace

***********************************************************************
* 2017-18 SURVEY
***********************************************************************

di _newline "Loading 2017-18 Bangladesh DHS..."
use "data/raw_data/BD_2017-18_DHS_12292025_1722_237609/BDPR7RDT/BDPR7RFL.DTA", clear

gen survey_year = 2017
label var survey_year "DHS Survey Year"
gen survey_wave = 6
label var survey_wave "Survey Wave"

keep hhid hv000 hv001 hv002 hv003 hv005 hv024 hv025 hv104 hv105 hv106 ///
     hv107 hv108 hv109 hv110 hv111 hv112 hv115 hv116 hv117 hv118 hv120 hv121 hv122 ///
     hvidx sh13 ha54 survey_year survey_wave

rename sh13 work_status_raw
label var work_status_raw "Raw work status variable"

qui count
di "  N = " %12.0fc r(N) " household members"

append using `alldata'
save `alldata', replace

* Load complete appended dataset
use `alldata', clear

* Total sample size
qui count
di _newline(2) "Total household members across all waves: " %12.0fc r(N)

* Check distribution across waves
di _newline "Distribution by survey wave:"
tab survey_year, mi

***********************************************************************
* SECTION 2: LABEL AND HARMONIZE CORE VARIABLES
***********************************************************************

di _newline(3)
di "SECTION 2: Labeling and harmonizing core variables..."
di "--------------------------------------------------------"

* Household identifiers
label var hhid "Household ID (case identification)"
label var hv001 "Cluster number"
label var hv002 "Household number"
label var hv003 "Respondent's line number"
label var hvidx "Line number of household member"

* Sample weight
label var hv005 "Household sample weight (6 decimals)"

* Geographic variables
label var hv024 "Region/Division"
label var hv025 "Type of place of residence"

* Demographic variables
label var hv104 "Sex of household member"
label var hv105 "Age of household member"

* Education variables
label var hv106 "Highest educational level"
label var hv107 "Highest year of education"
label var hv108 "Education in single years"
label var hv109 "Educational attainment"

* Media exposure (note: variables differ by wave)
capture label var hv110 "Reads newspaper/magazine"
capture label var hv111 "Listens to radio"
capture label var hv112 "Watches television"

* Marital/pregnancy status
capture label var hv115 "Ever married"
capture label var hv116 "Currently pregnant"
capture label var hv117 "Months pregnant"
capture label var hv118 "Currently amenorrheic"
capture label var hv119 "Duration of amenorrhea"

* Other demographics
capture label var hv121 "Ever attended school"
capture label var hv122 "Currently attending school"

***********************************************************************
* SECTION 3: CONSTRUCT STANDARDIZED VARIABLES
***********************************************************************

di _newline(2)
di "SECTION 3: Constructing standardized analytical variables..."
di "--------------------------------------------------------"

***********************************************************************
* 3.1: DEMOGRAPHIC VARIABLES
***********************************************************************

di _newline "3.1: Creating demographic variables..."

* Sex (binary)
gen female = (hv104 == 2) if !missing(hv104)
label var female "Female (1=Yes, 0=No)"
label define female_lbl 0 "Male" 1 "Female"
label values female female_lbl

* Age groups
gen age = hv105
label var age "Age in years"

gen age_group = .
replace age_group = 1 if age >= 0 & age <= 4
replace age_group = 2 if age >= 5 & age <= 9
replace age_group = 3 if age >= 10 & age <= 14
replace age_group = 4 if age >= 15 & age <= 19
replace age_group = 5 if age >= 20 & age <= 24
replace age_group = 6 if age >= 25 & age <= 49
replace age_group = 7 if age >= 50 & !missing(age)
label var age_group "Age group"
label define age_group_lbl 1 "0-4" 2 "5-9" 3 "10-14" 4 "15-19" 5 "20-24" 6 "25-49" 7 "50+"
label values age_group age_group_lbl

* Child indicators
gen child = (age >= 0 & age <= 17) if !missing(age)
label var child "Child (age 0-17)"

gen child_5_17 = (age >= 5 & age <= 17) if !missing(age)
label var child_5_17 "Child age 5-17 (school age)"

gen adolescent = (age >= 10 & age <= 19) if !missing(age)
label var adolescent "Adolescent (age 10-19)"

gen teenager = (age >= 13 & age <= 19) if !missing(age)
label var teenager "Teenager (age 13-19)"

* Urban/rural
gen urban = (hv025 == 1) if !missing(hv025)
label var urban "Urban residence (1=Yes, 0=No)"
label define urban_lbl 0 "Rural" 1 "Urban"
label values urban urban_lbl

***********************************************************************
* 3.2: EDUCATION VARIABLES
***********************************************************************

di _newline "3.2: Creating education variables..."

* Years of education
gen educ_years = hv108
replace educ_years = 0 if educ_years == 99 | educ_years == 98 | educ_years > 20
label var educ_years "Years of education completed"

* Education level
gen educ_level = hv106
replace educ_level = . if hv106 == 8 | hv106 == 9
label var educ_level "Highest educational level"
label define educ_level_lbl 0 "No education" 1 "Primary" 2 "Secondary" 3 "Higher"
label values educ_level educ_level_lbl

* Educational attainment categories
gen no_education = (educ_level == 0) if !missing(educ_level)
label var no_education "No education (1=Yes, 0=No)"

gen primary_educ = (educ_level == 1) if !missing(educ_level)
label var primary_educ "Primary education (1=Yes, 0=No)"

gen secondary_educ = (educ_level == 2) if !missing(educ_level)
label var secondary_educ "Secondary education (1=Yes, 0=No)"

gen higher_educ = (educ_level == 3) if !missing(educ_level)
label var higher_educ "Higher education (1=Yes, 0=No)"

* Currently attending school (hv121: available 2007+)
* Note: hv121 = member attended school during current school year
gen in_school = (hv121 == 1 | hv122 >= 1) if !missing(hv121) | !missing(hv122)
label var in_school "Currently attending school (2007+ only, 1=Yes, 0=No)"

* Ever attended school (approximate from education level)
gen ever_school = (educ_level >= 1) if !missing(educ_level)
label var ever_school "Ever attended school (inferred from education level)"

***********************************************************************
* 3.3: CHILD LABOUR VARIABLES
***********************************************************************

di _newline "3.3: Creating child labour variables..."

* Harmonize work status across waves (accounting for different variable names/coding)
* 1996-97, 1999-00: sh14 (0=no, 1=yes)
* 2007: sh15 (0=no, 1=yes)
* 2011, 2014, 2017: sh13 (0=no, 1=yes)

* Create standardized child labour indicator
gen child_labour = .
replace child_labour = 0 if work_status_raw == 0
replace child_labour = 1 if work_status_raw == 1
replace child_labour = . if work_status_raw == 9 | work_status_raw == 8
replace child_labour = . if work_status_raw >= 97 & work_status_raw <= 99
label var child_labour "Currently working for money (all ages)"
label define child_labour_lbl 0 "No" 1 "Yes"
label values child_labour child_labour_lbl

* Child labour for school-age children (5-17)
gen child_labour_5_17 = child_labour if child_5_17 == 1
label var child_labour_5_17 "Child labour (ages 5-17)"
label values child_labour_5_17 child_labour_lbl

* Child labour by age groups
gen child_labour_5_9 = child_labour if age >= 5 & age <= 9
label var child_labour_5_9 "Child labour (ages 5-9)"
label values child_labour_5_9 child_labour_lbl

gen child_labour_10_14 = child_labour if age >= 10 & age <= 14
label var child_labour_10_14 "Child labour (ages 10-14)"
label values child_labour_10_14 child_labour_lbl

gen child_labour_15_17 = child_labour if age >= 15 & age <= 17
label var child_labour_15_17 "Child labour (ages 15-17)"
label values child_labour_15_17 child_labour_lbl

* Interaction: child labour by sex
gen child_labour_boy = child_labour if female == 0 & child_5_17 == 1
label var child_labour_boy "Child labour - boys (ages 5-17)"
label values child_labour_boy child_labour_lbl

gen child_labour_girl = child_labour if female == 1 & child_5_17 == 1
label var child_labour_girl "Child labour - girls (ages 5-17)"
label values child_labour_girl child_labour_lbl

***********************************************************************
* 3.4: TEEN PREGNANCY VARIABLES
***********************************************************************

di _newline "3.4: Creating teen pregnancy variables..."

* NOTE: Pregnancy data in PR files is LIMITED
* - ha54 (currently pregnant) available only from 2007+
* - For comprehensive teen pregnancy analysis, use Individual Recode (IR) files
* - IR files have full birth history, pregnancy status, and reproductive health data

* Currently pregnant (from ha54, available 2007+)
gen pregnant = (ha54 == 1) if !missing(ha54)
label var pregnant "Currently pregnant (available 2007+)"
label define preg_lbl 0 "No" 1 "Yes"
label values pregnant preg_lbl

* Teen pregnancy (ages 13-19)
gen teen_pregnant = pregnant if teenager == 1 & female == 1
label var teen_pregnant "Teen pregnancy (females ages 13-19, 2007+ only)"
label values teen_pregnant preg_lbl

* Adolescent pregnancy (ages 10-19)
gen adolescent_pregnant = pregnant if adolescent == 1 & female == 1
label var adolescent_pregnant "Adolescent pregnancy (females ages 10-19, 2007+ only)"
label values adolescent_pregnant preg_lbl

* Young pregnancy by age groups
gen pregnant_15_17 = pregnant if age >= 15 & age <= 17 & female == 1
label var pregnant_15_17 "Pregnancy among females ages 15-17 (2007+ only)"
label values pregnant_15_17 preg_lbl

gen pregnant_18_19 = pregnant if age >= 18 & age <= 19 & female == 1
label var pregnant_18_19 "Pregnancy among females ages 18-19 (2007+ only)"
label values pregnant_18_19 preg_lbl

gen pregnant_20_24 = pregnant if age >= 20 & age <= 24 & female == 1
label var pregnant_20_24 "Pregnancy among females ages 20-24 (2007+ only)"
label values pregnant_20_24 preg_lbl

***********************************************************************
* 3.5: MARRIAGE VARIABLES
***********************************************************************

di _newline "3.5: Creating marriage variables..."

* Marital status variable (hv115 coding varies by wave)
* Create binary ever married indicator
gen ever_married = .
* In early waves: hv115 is current marital status (0=never married, 1=married, 2=living together, etc.)
* In later waves: similar coding but check value labels
replace ever_married = 0 if hv115 == 0 | hv116 == 0  // never married
replace ever_married = 1 if hv115 >= 1 & hv115 <= 5 & !missing(hv115)  // currently/formerly married
replace ever_married = 1 if hv116 >= 1 & hv116 <= 2 & !missing(hv116)  // currently/formerly married
label var ever_married "Ever married"
label define married_lbl 0 "No" 1 "Yes"
label values ever_married married_lbl

* Teen marriage (ages 13-19)
gen teen_married = ever_married if teenager == 1 & female == 1
label var teen_married "Ever married - teen females (ages 13-19)"
label values teen_married married_lbl

* Child marriage indicators
gen married_15_17 = ever_married if age >= 15 & age <= 17 & female == 1
label var married_15_17 "Ever married - females ages 15-17"
label values married_15_17 married_lbl

gen married_18_19 = ever_married if age >= 18 & age <= 19 & female == 1
label var married_18_19 "Ever married - females ages 18-19"
label values married_18_19 married_lbl

***********************************************************************
* 3.6: FSSSP PROGRAM EXPOSURE VARIABLES
***********************************************************************

di _newline "3.6: Creating FSSSP program exposure variables..."

* FSSSP program launched in 1994
* Girls eligible if: in rural areas, attending grades 6-10 (roughly ages 11-16)

* Birth cohort
gen birth_year = survey_year - age
label var birth_year "Estimated birth year"

* Post-FSSSP cohort (born 1980 or later, would be age 14+ when program started)
* Children born 1980+ would be eligible for secondary school during program years
gen post_fsssp = (birth_year >= 1980) if !missing(birth_year)
label var post_fsssp "Born 1980+ (exposed to FSSSP during secondary school age)"
label define post_fsssp_lbl 0 "Pre-FSSSP cohort" 1 "Post-FSSSP cohort"
label values post_fsssp post_fsssp_lbl

* Treatment group: Rural females in post-FSSSP cohort
gen fsssp_eligible = (female == 1 & urban == 0 & post_fsssp == 1) if !missing(female, urban, post_fsssp)
label var fsssp_eligible "Eligible for FSSSP (rural females, post-1980 cohort)"
label define eligible_lbl 0 "Not eligible" 1 "Eligible"
label values fsssp_eligible eligible_lbl

* Age at program start (1994)
gen age_at_fsssp = 1994 - birth_year
label var age_at_fsssp "Age in 1994 when FSSSP started"

* Exposed during secondary school age (ages 11-16 in 1994)
gen fsssp_exposed = (age_at_fsssp >= 11 & age_at_fsssp <= 16) if !missing(age_at_fsssp)
label var fsssp_exposed "Age 11-16 in 1994 (secondary school age when FSSSP started)"
label values fsssp_exposed eligible_lbl

***********************************************************************
* 3.7: SAMPLING WEIGHTS
***********************************************************************

di _newline "3.7: Creating sampling weights..."

* Household weight (convert from 6 decimals to proportion)
gen hh_weight = hv005 / 1000000
label var hh_weight "Household sample weight"

***********************************************************************
* 3.8: GEOGRAPHIC VARIABLES
***********************************************************************

di _newline "3.8: Creating geographic variables..."

* Region/Division
gen division = hv024
label var division "Division/Region"

* Cluster ID
gen cluster = hv001
label var cluster "Primary sampling unit (cluster)"

***********************************************************************
* SECTION 4: DATA QUALITY CHECKS
***********************************************************************

di _newline(2)
di "SECTION 4: Data quality checks..."
di "--------------------------------------------------------"

* Check for duplicates
duplicates report hhid hvidx survey_year
qui duplicates tag hhid hvidx survey_year, gen(dup)
qui count if dup > 0
if r(N) > 0 {
    di as error "WARNING: " r(N) " duplicate observations found!"
    list hhid hvidx survey_year if dup > 0 in 1/10
}
drop dup

* Check missing values on key variables
di _newline "Missing values on key variables:"
foreach var in age female urban educ_years child_labour pregnant {
    qui count if missing(`var')
    local miss_n = r(N)
    qui count
    local total_n = r(N)
    local miss_pct = (`miss_n' / `total_n') * 100
    di "  `var': " %8.0fc `miss_n' " (" %5.2f `miss_pct' "%)"
}

* Summary statistics by survey wave
di _newline(2) "Sample sizes by survey wave:"
tab survey_year, mi

di _newline "Female vs. male distribution:"
tab survey_year female, mi row

di _newline "Urban vs. rural distribution:"
tab survey_year urban, mi row

***********************************************************************
* SECTION 5: DESCRIPTIVE STATISTICS
***********************************************************************

di _newline(2)
di "SECTION 5: Descriptive statistics for key outcomes..."
di "--------------------------------------------------------"

* Child labour rates by wave
di _newline "CHILD LABOUR RATES (Ages 5-17):"
di "By survey year:"
tab survey_year child_labour_5_17, mi row nofreq

di _newline "By sex (all waves combined):"
tab female child_labour_5_17 if child_5_17 == 1, mi row nofreq

di _newline "By urban/rural (all waves combined):"
tab urban child_labour_5_17 if child_5_17 == 1, mi row nofreq

* Teen pregnancy rates by wave
di _newline(2) "TEEN PREGNANCY RATES (Females ages 13-19):"
di "By survey year:"
tab survey_year teen_pregnant, mi row nofreq

di _newline "By urban/rural (all waves combined):"
tab urban teen_pregnant if teenager == 1 & female == 1, mi row nofreq

* Teen marriage rates
di _newline(2) "TEEN MARRIAGE RATES (Females ages 13-19):"
di "By survey year:"
tab survey_year teen_married, mi row nofreq

***********************************************************************
* SECTION 6: SAVE CLEANED DATA
***********************************************************************

di _newline(2)
di "SECTION 6: Saving cleaned dataset..."
di "--------------------------------------------------------"

* Order variables logically
order hhid hvidx survey_year survey_wave hv001 hv002 hv003 ///
      age female urban division cluster ///
      educ_years educ_level in_school ever_school ///
      child_labour* teen_pregnant adolescent_pregnant pregnant* ///
      ever_married teen_married married_* ///
      fsssp_eligible fsssp_exposed post_fsssp age_at_fsssp ///
      hh_weight

* Sort data
sort survey_year hhid hvidx

* Compress to save space
compress

* Save cleaned dataset
save "data/output/household_member_clean.dta", replace

* Export summary statistics
preserve
    collapse (count) N=age ///
             (mean) child_labour_5_17 teen_pregnant teen_married ///
             (sd) sd_child_labour=child_labour_5_17 ///
                  sd_teen_preg=teen_pregnant ///
                  sd_teen_married=teen_married, ///
             by(survey_year)

    format N %12.0fc
    format child_labour_5_17 teen_pregnant teen_married %6.4f
    format sd_* %6.4f

    list, clean noobs

    export delimited using "tables/household_member_summary_stats.csv", replace
restore

***********************************************************************
* SECTION 7: FINAL REPORT
***********************************************************************

di _newline(2)
di "========================================================================="
di "HOUSEHOLD MEMBER DATA CLEANING COMPLETE"
di "========================================================================="

qui count
di _newline "Total observations: " %12.0fc r(N)

qui distinct hhid survey_year
di "Total households: " %12.0fc r(ndistinct)

qui count if child_5_17 == 1
di "School-age children (5-17): " %12.0fc r(N)

qui count if teenager == 1 & female == 1
di "Female teenagers (13-19): " %12.0fc r(N)

di _newline "Output file: data/output/household_member_clean.dta"
di "Summary stats: tables/household_member_summary_stats.csv"

di _newline "Variables created:"
di "  - Child labour indicators (all ages, 5-17, by sex)"
di "  - Teen pregnancy indicators (ages 13-19, 15-17, 18-19)"
di "  - Marriage indicators (teen marriage, child marriage)"
di "  - FSSSP exposure/eligibility indicators"
di "  - Education variables (years, level, current attendance)"
di "  - Demographic variables (age groups, urban/rural)"
di "  - Sampling weights"

di _newline(2) "========================================================================="

log close

exit, clear
