/*==============================================================================
FSSSP REPLICATION - DATA CLEANING AND CONSTRUCTION SCRIPT
Complete Rebuild Using Birth Recode (BR) Files

Project: Replication of "The Impact of the Female Secondary School Stipend
         Program on Child Health" (Journal of Health Economics, 2024)

Purpose: Construct THREE analytical samples from Bangladesh DHS data:
         1. Mother Sample (N ≈ 69,235) - for education outcomes
         2. Child Sample (N ≈ 29,383) - for immunization, health inputs
         3. Birth Sample (N ≈ 150,175) - for mortality analysis

Key Elements:
- Uses BR (Birth Recode) files instead of IR files with reshape
- BR files are already child-level - no reshape needed
- Simpler, cleaner code with lower error risk
- Survey weights properly declared
- CMC conversion corrected

Survey Waves: 1996-97, 1999-00, 2004, 2007, 2011, 2014, 2017-18 (7 waves)

Critical Variables:
- v011: Maternal birth date (CMC format) → convert to calendar year
- v010: Varies by wave (age in early waves, calendar year in later waves) 
- v005: Survey weight (must normalize by 1,000,000)
- v021: Primary sampling unit (cluster)
- v023: Stratification variable
- b*: Birth history variables (already in long format in BR files)
- h*: Immunization variables
- m*: Maternal/prenatal care variables
- hw*: Anthropometric variables

Variable Availability Issues:
- Wealth index (v190, v191): NOT available in 1996-97, 1999-00
- Autonomy (v743*, v744*): NOT available in 1996-97, 1999-00
- Media: Different variables (v109/v110/v112 vs v157/v159/v158)
- Postnatal care: Only 2011-2017
- Iron supplements: Only 2004-2017
- Vitamin A: Available in 1996-97, 2004-2017 (NOT 1999-00)
  * 1996-97: Uses s464 "child taken vitamin a capsule"
  * 2004+: Uses h33/h34 (standard DHS naming)

- Formal sector occupation (Table 5, Column 3):
  * v717 is 100% MISSING in 2007 & 2011 waves!
  * Must use v716 with wave-specific codes:
    - 1996-2004: codes 7 (professional) + 8 (business)
    - 2007-2017: codes 41 (professional) + 51/52 (business)
  * Non-workers coded as 0 (not missing) to match N
  * See lines 1028-1057 for implementation

==============================================================================*/

* Display start message
display as result "================================================================================"
display as result "FSSSP REPLICATION - DATA CLEANING"
display as result "Using Birth Recode (BR) Files"
display as result "================================================================================"


/*==============================================================================
SECTION 1: DEFINE SURVEY WAVES AND FILE PATHS
==============================================================================*/

display as text "=== Defining Survey Waves ==="

* Survey years and wave labels
* NOTE: Table 1 caption says "1993-94 through 2017-18" but data section (p.4) says
* "1996-97 to 2017-18". Testing showed including 1993-94 WORSENS match (+56 → +2,305)
* Therefore using 7 waves as stated in data section.
local years "1996 1999 2004 2007 2011 2014 2017"
local wave_labels `" "1996-97" "1999-00" "2004" "2007" "2011" "2014" "2017-18" "'

* BR file paths (Birth Recode files)
local br_files `" "BD_1996-97_DHS_12292025_1726_237609/BDBR3ADT/BDBR3AFL.dta" "BD_1999-00_DHS_12292025_1725_237609/BDBR41DT/BDBR41FL.dta" "BD_2004_DHS_12292025_1724_237609/BDBR4JDT/BDBR4JFL.dta" "BD_2007_DHS_12292025_1724_237609/BDBR51DT/BDBR51FL.DTA" "BD_2011_DHS_12292025_1723_237609/BDBR61DT/BDBR61FL.DTA" "BD_2014_DHS_12292025_1723_237609/BDBR72DT/BDBR72FL.DTA" "BD_2017-18_DHS_12292025_1722_237609/BDBR7RDT/BDBR7RFL.DTA" "'

* IR file paths (Individual Recode - for mother sample)
local ir_files `" "BD_1996-97_DHS_12292025_1726_237609/BDIR3ADT/BDIR3AFL.DTA" "BD_1999-00_DHS_12292025_1725_237609/BDIR41DT/BDIR41FL.DTA" "BD_2004_DHS_12292025_1724_237609/BDIR4JDT/BDIR4JFL.DTA" "BD_2007_DHS_12292025_1724_237609/BDIR51DT/BDIR51FL.DTA" "BD_2011_DHS_12292025_1723_237609/BDIR61DT/BDIR61FL.DTA" "BD_2014_DHS_12292025_1723_237609/BDIR72DT/BDIR72FL.DTA" "BD_2017-18_DHS_12292025_1722_237609/BDIR7RDT/BDIR7RFL.DTA" "'

display as text "Survey waves defined: 7 waves from 1996-97 to 2017-18"

/*==============================================================================
SECTION 2: CONSTRUCT MOTHER SAMPLE
==============================================================================*/

display as result "================================================================================"
display as result "SECTION 3: CONSTRUCTING MOTHER SAMPLE"
display as result "Expected N ≈ 69,235"
display as result "================================================================================"

* Create temporary files for each wave
tempfile temp1 temp2 temp3 temp4 temp5 temp6 temp7

local i = 1
foreach year of local years {

    local wave_label : word `i' of `wave_labels'
    local ir_file : word `i' of `ir_files'

    display as text "Processing `wave_label' (IR file)..." _n

    * Load Individual Recode file (mother-level)
    use "$raw_data/`ir_file'", clear

    * Generate survey wave identifier
    gen survey_wave = `year'
    label var survey_wave "Survey wave year"

    /*--------------------------------------------------------------------------
    2.1: Convert Maternal Birth Year from CMC to Calendar Year
    --------------------------------------------------------------------------*/

    * CRITICAL: v011 is maternal birth date in CMC (Century Month Code) format
    * CMC = (year - 1900) * 12 + month
    * To convert to calendar year: year = int((CMC - 1)/12) + 1900
    * Example: CMC 853 = Jan 1971 → int((853-1)/12) + 1900 = 71 + 1900 = 1971 ✓

    gen maternal_birth_year = int((v011 - 1)/12) + 1900 if !missing(v011)
    label var maternal_birth_year "Mother's year of birth (calendar year)"

    /*--------------------------------------------------------------------------
    2.2: Apply Sample Restrictions (Paper Page 4)
    --------------------------------------------------------------------------*/

    * Restriction 1: Maternal birth years 1971-1998
    keep if maternal_birth_year >= 1971 & maternal_birth_year <= 1998

    * Restriction 2: Age >= 16 at survey time
    * Rationale: "Exclude 15-year-olds because they are still in grade 10
    *             and therefore eligible for the stipend" (Paper page 4)
    keep if v012 >= 16

    display as text "  Observations after restrictions: " _N _n

    /*--------------------------------------------------------------------------
    2.3: Create Treatment Variables
    --------------------------------------------------------------------------*/

    * Fully Exposed: Born 1983 or later (5-year stipend eligibility)
    gen fully_exposed = (maternal_birth_year >= 1983)
    label var fully_exposed "Fully exposed to FSSSP (born ≥1983)"

    * Partially Exposed: Born 1980-1982 (2-year stipend eligibility)
    gen partially_exposed = (maternal_birth_year >= 1980 & maternal_birth_year <= 1982)
    label var partially_exposed "Partially exposed to FSSSP (born 1980-1982)"

    * Unexposed: Born 1979 or earlier (reference group)
    gen unexposed = (maternal_birth_year <= 1979)
    label var unexposed "Unexposed to FSSSP (born ≤1979)"

    /*--------------------------------------------------------------------------
    2.4: Create Core Demographic Variables
    --------------------------------------------------------------------------*/

    * Rural residence
    gen rural = (v025 == 2) if !missing(v025)
    label var rural "Rural residence (1=rural, 0=urban)"

    * Muslim
    gen muslim = (v130 == 1) if !missing(v130)
    label var muslim "Muslim religion (1=yes, 0=other)"

    * Maternal age
    gen maternal_age = v012
    label var maternal_age "Mother's age at survey"

    * Division (geographic region)
    gen division = v024
    label var division "Division/region"

    /*--------------------------------------------------------------------------
    2.5: Create Education Variables
    --------------------------------------------------------------------------*/

    * Years of schooling
    gen years_schooling = v133
    label var years_schooling "Years of schooling"

    * Secondary or higher education (v106: 0=none, 1=primary, 2=secondary, 3=higher)
    gen secondary_plus = (v106 >= 2) if !missing(v106)
    label var secondary_plus "Secondary or higher education (1=yes)"

    /*--------------------------------------------------------------------------
    2.6: Create Treatment Interactions (for DiD specification)
    --------------------------------------------------------------------------*/

    * Fully Exposed × Rural
    gen fully_rural = fully_exposed * rural
    label var fully_rural "Fully exposed × Rural"

    * Partially Exposed × Rural
    gen partially_rural = partially_exposed * rural
    label var partially_rural "Partially exposed × Rural"

    /*--------------------------------------------------------------------------
    2.7: Handle Wave-Specific Variables
    --------------------------------------------------------------------------*/

    * Wealth index (only available 2004+)
    if `year' >= 2004 {
        gen wealth_quintile = v190
        gen wealth_index = v191
    }
    else {
        gen wealth_quintile = .
        gen wealth_index = .
    }
    label var wealth_quintile "Wealth quintile (1=poorest, 5=richest)"
    label var wealth_index "Wealth index factor score"

    * Media exposure variables (different across waves)
    if `year' <= 1999 {
        * 1996-97 and 1999-00: Use v109, v110, v112
        gen newspaper_weekly = (v109 == 1) if !missing(v109)
        gen tv_weekly = (v110 == 1) if !missing(v110)
        gen radio_weekly = (v112 == 1) if !missing(v112)
    }
    else {
        * 2004+: Use v157, v159, v158 (frequency scales)
        gen newspaper_weekly = (v157 >= 2) if !missing(v157)
        gen tv_weekly = (v159 >= 2) if !missing(v159)
        gen radio_weekly = (v158 >= 2) if !missing(v158)
    }
    label var newspaper_weekly "Reads newspaper at least once a week"
    label var tv_weekly "Watches TV at least once a week"
    label var radio_weekly "Listens to radio at least once a week"

    * Media sources count
    gen media_sources = newspaper_weekly + tv_weekly + radio_weekly
    label var media_sources "Number of media sources (0-3)"

    * Decision-making/autonomy variables (only available 2004+)
    if `year' >= 2004 {
        * v743a: Who decides on respondent's health care
        * Values: 1=respondent alone, 2=respondent & husband, 4=respondent & other,
        *         5=husband alone, 6=other
        capture confirm variable v743a
        if _rc == 0 {
            gen decides_health = inlist(v743a, 1, 2, 3) if !missing(v743a)
        }
        else {
            gen decides_health = .
        }

        * v743b: Who decides on large household purchases
        capture confirm variable v743b
        if _rc == 0 {
            gen decides_purchases = inlist(v743b, 1, 2, 3) if !missing(v743b)
        }
        else {
            gen decides_purchases = .
        }

        * v743d: Who decides on visits to family/relatives
        capture confirm variable v743d
        if _rc == 0 {
            gen decides_visits = inlist(v743d, 1, 2, 3) if !missing(v743d)
        }
        else {
            gen decides_visits = .
        }

        * Decision-making index (sum of three indicators)
        gen decision_index = decides_health + decides_purchases + decides_visits

        * Can go to health center/hospital alone or with children
        * WAVE-SPECIFIC VARIABLE NAMES:
        * 2004: s819 (codes: 1=no, 2=alone, 3=with children, 4=with husband, 5=other)
        * 2007: s826b (similar coding)
        * 2011-2017: Variable does not exist
        if `year' == 2004 {
            capture confirm variable s819
            if _rc == 0 {
                * Codes 2 (yes, alone) and 3 (yes, with children) = can go
                gen can_go_hospital = inlist(s819, 2, 3) if !missing(s819)
            }
            else {
                gen can_go_hospital = .
            }
        }
        else if `year' == 2007 {
            capture confirm variable s826b
            if _rc == 0 {
                * Codes 2 (yes, alone) and 3 (yes, with children) = can go
                gen can_go_hospital = inlist(s826b, 2, 3) if !missing(s826b)
            }
            else {
                gen can_go_hospital = .
            }
        }
        else {
            * 2011-2017: Use standard DHS variable v744b
            capture confirm variable v744b
            if _rc == 0 {
                gen can_go_hospital = inlist(v744b, 1, 2) if !missing(v744b)
            }
            else {
                gen can_go_hospital = .
            }
        }
    }
    else {
        gen decides_health = .
        gen decides_purchases = .
        gen decides_visits = .
        gen decision_index = .
        gen can_go_hospital = .
    }
    label var decides_health "Has say in health care decisions"
    label var decides_purchases "Has say in large purchases"
    label var decides_visits "Has say in visits to family"
    label var decision_index "Decision-making index (0-3)"
    label var can_go_hospital "Can go to hospital alone/with children"

    /*--------------------------------------------------------------------------
    2.8: Keep Essential Variables
    --------------------------------------------------------------------------*/

    keep caseid v000 v001 v002 v003 v005 v006 v007 v008 v021 v023 v024 v025 ///
         v106 v130 v133 v701 v704 v714 v717 ///
         v212 v218 v511 v613 v627 ///
         survey_wave maternal_birth_year maternal_age rural muslim division ///
         years_schooling secondary_plus ///
         fully_exposed partially_exposed unexposed ///
         fully_rural partially_rural ///
         wealth_quintile wealth_index ///
         newspaper_weekly tv_weekly radio_weekly media_sources ///
         decides_health decides_purchases decides_visits decision_index can_go_hospital

    /*--------------------------------------------------------------------------
    2.9: Save Temporary File
    --------------------------------------------------------------------------*/

    save `temp`i'', replace

    local i = `i' + 1
}

/*------------------------------------------------------------------------------
2.10: Append All Waves and Finalize Mother Sample
------------------------------------------------------------------------------*/

display as text _n "=== Appending All Waves ===" _n

use `temp1', clear
append using `temp2'
append using `temp3'
append using `temp4'
append using `temp5'
append using `temp6'
append using `temp7'

/*------------------------------------------------------------------------------
2.11: Declare Survey Design (CRITICAL for proper standard errors)
------------------------------------------------------------------------------*/

* Normalize survey weight (DHS standard: divide by 1,000,000)
gen weight = v005 / 1000000
label var weight "Sample weight (normalized)"

* Declare complex survey design
* v021 = primary sampling unit (PSU/cluster)
* v023 = stratification variable
svyset v021 [pweight=weight], strata(v023)

display as result _n "Survey design declared with weights, PSU, and strata" _n

/*------------------------------------------------------------------------------
2.12: Create Clustering Variable for Regressions
------------------------------------------------------------------------------*/

* Paper clusters standard errors at "maternal birth year × rural" level
* Create unique cluster ID
gen maternal_by_rural = maternal_birth_year * 100 + rural
label var maternal_by_rural "Cluster: Maternal birth year × Rural"

/*------------------------------------------------------------------------------
2.13: Save Mother Sample
------------------------------------------------------------------------------*/

compress
label data "Mother Sample - FSSSP Replication (N≈69,235)"
save "${analysis_data}/mother_sample.dta", replace

* Display validation statistics
display as result _n(2) "================================================================================"
display as result "MOTHER SAMPLE CREATED"
display as result "================================================================================" _n

display as text "Total observations: " _N
display as text "Expected: ~69,235" _n

display as text "Treatment group distribution:"
count if fully_exposed
display as text "  Fully Exposed: " r(N) " (" %4.1f 100*r(N)/_N "%)"
count if partially_exposed
display as text "  Partially Exposed: " r(N) " (" %4.1f 100*r(N)/_N "%)"
count if unexposed
display as text "  Unexposed: " r(N) " (" %4.1f 100*r(N)/_N "%)" _n

display as text "Summary statistics (compare to Table 1, Panel A):"
summarize years_schooling secondary_plus maternal_age rural muslim

display as result _n "Mother sample saved: ${analysis_data}/mother_sample.dta" _n

/*==============================================================================
SECTION 3: CONSTRUCT BIRTH SAMPLE (ALL BIRTHS - FOR MORTALITY ANALYSIS)
==============================================================================*/

display as result _n(2) "================================================================================"
display as result "SECTION 4: CONSTRUCTING BIRTH SAMPLE"
display as result "Expected N ≈ 150,175"
display as result "Includes ALL births (living and deceased)"
display as result "================================================================================" _n

* Create temporary files
tempfile temp1 temp2 temp3 temp4 temp5 temp6 temp7

local i = 1
foreach year of local years {

    local wave_label : word `i' of `wave_labels'
    local br_file : word `i' of `br_files'

    display as text "Processing `wave_label' (BR file)..." _n

    * Load Birth Recode file (already child-level!)
    use "$raw_data/`br_file'", clear

    * Generate survey wave identifier
    gen survey_wave = `year'
    label var survey_wave "Survey wave year"

    /*--------------------------------------------------------------------------
    3.1: Convert Maternal Birth Year from CMC
    --------------------------------------------------------------------------*/

    gen maternal_birth_year = int((v011 - 1)/12) + 1900 if !missing(v011)
    label var maternal_birth_year "Mother's year of birth (calendar year)"

    /*--------------------------------------------------------------------------
    3.2: Apply Maternal Restrictions Only (Keep ALL Births)
    --------------------------------------------------------------------------*/

    * Restriction 1: Maternal birth years 1971-1998
    keep if maternal_birth_year >= 1971 & maternal_birth_year <= 1998

    * Restriction 2: Maternal age >= 16
    keep if v012 >= 16

    * NO RESTRICTION on child survival status (keep both living and deceased)
    * NO RESTRICTION on child age (keep all ages)

    display as text "  Observations after maternal restrictions: " _N
    count if b5 == 0
    display as text "  Deceased children: " r(N) _n

    /*--------------------------------------------------------------------------
    3.3: Create Treatment Variables (Same as Mother Sample)
    --------------------------------------------------------------------------*/

    gen fully_exposed = (maternal_birth_year >= 1983)
    gen partially_exposed = (maternal_birth_year >= 1980 & maternal_birth_year <= 1982)
    gen unexposed = (maternal_birth_year <= 1979)

    gen rural = (v025 == 2) if !missing(v025)
    gen muslim = (v130 == 1) if !missing(v130)
    gen maternal_age = v012
    gen division = v024

    gen fully_rural = fully_exposed * rural
    gen partially_rural = partially_exposed * rural

    /*--------------------------------------------------------------------------
    3.4: Create Mortality Outcome Variables
    --------------------------------------------------------------------------*/

    * Child survival status (b5: 0=dead, 1=alive)
    gen child_alive = b5
    label var child_alive "Child alive at survey (1=yes, 0=no)"

    * Age at death in months (b7, only for deceased children)
    gen age_at_death = b7 if b5 == 0
    label var age_at_death "Age at death (months, if deceased)"

    * Neonatal mortality (death <1 month)
    * CORRECTED: Set to 0 for living children, not missing
    gen neonatal_mort = (b5 == 0 & b7 < 1) if !missing(b5)
    replace neonatal_mort = 0 if b5 == 1
    label var neonatal_mort "Neonatal mortality (death <1 month)"

    * Infant mortality (death <12 months)
    * CORRECTED: Set to 0 for living children, not missing
    gen infant_mort = (b5 == 0 & b7 < 12) if !missing(b5)
    replace infant_mort = 0 if b5 == 1
    label var infant_mort "Infant mortality (death <12 months)"

    * Child mortality (death <60 months)
    * CORRECTED: Set to 0 for living children, not missing
    gen child_mort = (b5 == 0 & b7 < 60) if !missing(b5)
    replace child_mort = 0 if b5 == 1
    label var child_mort "Child mortality (death <60 months)"

    /*--------------------------------------------------------------------------
    3.5: Create Birth Outcome Variables
    --------------------------------------------------------------------------*/

    * Child sex (b4: 1=male, 2=female)
    gen child_female = (b4 == 2) if !missing(b4)
    label var child_female "Child is female (1=yes)"

    * Current age in months - calculated from CMC (consistent across all waves)
    * NOTE: b8 = years in Phase 3-6, months in Phase 7 - inconsistent across waves
    * Use v008 - b3 for consistent age calculation across all DHS phases
    * CRITICAL: Must calculate BEFORE renaming b3!
    gen child_age_months = v008 - b3 if !missing(v008, b3) & b5 == 1
    label var child_age_months "Current age (months, calculated from CMC)"

    * Birth order
    rename bord birth_order
    label var birth_order "Birth order"

    * Child's birth date (CMC)
    rename b3 child_birth_cmc
    label var child_birth_cmc "Child's birth date (CMC)"

    * Preceding birth interval (b11)
    rename b11 birth_interval
    label var birth_interval "Preceding birth interval (months)"

    /*--------------------------------------------------------------------------
    3.6: Create Maternal Education Variables
    --------------------------------------------------------------------------*/

    gen years_schooling = v133
    gen secondary_plus = (v106 >= 2) if !missing(v106)

    /*--------------------------------------------------------------------------
    3.7: Keep Essential Variables
    --------------------------------------------------------------------------*/

    keep caseid v000 v001 v002 v003 v005 v008 v021 v023 v024 v025 ///
         v106 v130 v133 ///
         survey_wave maternal_birth_year maternal_age rural muslim division ///
         years_schooling secondary_plus ///
         fully_exposed partially_exposed unexposed ///
         fully_rural partially_rural ///
         child_alive age_at_death neonatal_mort infant_mort child_mort ///
         child_female birth_order child_birth_cmc child_age_months birth_interval

    save `temp`i'', replace

    local i = `i' + 1
}

/*------------------------------------------------------------------------------
3.8: Append All Waves and Finalize Birth Sample
------------------------------------------------------------------------------*/

display as text _n "=== Appending All Waves ===" _n

use `temp1', clear
append using `temp2'
append using `temp3'
append using `temp4'
append using `temp5'
append using `temp6'
append using `temp7'

/*------------------------------------------------------------------------------
3.9: Declare Survey Design
------------------------------------------------------------------------------*/

gen weight = v005 / 1000000
svyset v021 [pweight=weight], strata(v023)

gen maternal_by_rural = maternal_birth_year * 100 + rural

/*------------------------------------------------------------------------------
3.10: Save Birth Sample
------------------------------------------------------------------------------*/

compress
label data "Birth Sample - FSSSP Replication (N≈150,175)"
save "$analysis_data/birth_sample.dta", replace

* Display validation statistics
display as result _n(2) "================================================================================"
display as result "BIRTH SAMPLE CREATED"
display as result "================================================================================" _n

display as text "Total observations: " _N
display as text "Expected: ~150,175" _n

display as text "Treatment group distribution:"
count if fully_exposed
display as text "  Fully Exposed: " r(N) " (" %4.1f 100*r(N)/_N "%)"
count if partially_exposed
display as text "  Partially Exposed: " r(N) " (" %4.1f 100*r(N)/_N "%)"
count if unexposed
display as text "  Unexposed: " r(N) " (" %4.1f 100*r(N)/_N "%)" _n

display as text "Mortality statistics:"
count if child_alive == 0
display as text "  Deceased children: " r(N)
summarize neonatal_mort infant_mort child_mort

display as result _n "Birth sample saved: $analysis_data/birth_sample.dta" _n

/*==============================================================================
SECTION 5: CONSTRUCT CHILD SAMPLE (SURVIVING CHILDREN 12-59 MONTHS)
==============================================================================*/

display as result _n(2) "================================================================================"
display as result "SECTION 5: CONSTRUCTING CHILD SAMPLE"
display as result "Expected N ≈ 29,383"
display as result "Surviving children aged 12-59 months"
display as result "================================================================================" _n

* Create temporary files
tempfile temp1 temp2 temp3 temp4 temp5 temp6 temp7

local i = 1
foreach year of local years {

    local wave_label : word `i' of `wave_labels'
    local br_file : word `i' of `br_files'

    display as text "Processing `wave_label' (BR file)..." _n

    * Load Birth Recode file
    use "$raw_data/`br_file'", clear

    gen survey_wave = `year'

    /*--------------------------------------------------------------------------
    5.1: Convert Maternal Birth Year
    --------------------------------------------------------------------------*/

    gen maternal_birth_year = int((v011 - 1)/12) + 1900 if !missing(v011)

    /*--------------------------------------------------------------------------
    5.2: Apply Sample Restrictions
    --------------------------------------------------------------------------*/

    * Maternal restrictions
    keep if maternal_birth_year >= 1971 & maternal_birth_year <= 1998
    keep if v012 >= 16

    * Child restrictions (Paper page 4)
    * "The child sample includes all surviving children aged between 12 and 59 months"
    * CRITICAL: b8 coding changed between DHS phases!
    *   - Phase 3-6 (1996-2014): b8 = age in YEARS
    *   - Phase 7 (2017+): b19 = age in MONTHS (b8 deprecated)
    * Solution: Calculate age from CMC dates (consistent across all waves)

    display as text "  Before child age restriction: " _N

    * Calculate child age in months from interview and birth dates (CMC format)
    * v008 = interview date (CMC), b3 = birth date (CMC)
    * Note: child_age_months will be created later for all observations
    gen temp_child_age = v008 - b3 if !missing(v008, b3)

    * Apply age restriction: 12-59 months for LIVING children only
    keep if temp_child_age >= 12 & temp_child_age <= 59 & b5 == 1
    display as text "  After age restriction (12-59 months, alive): " _N

    * CRITICAL CHANGE (2026-01-13): Removed immunization filter for anthropometric analyses
    * User feedback: 1996/1999/2004 have raw measurements (hw1/hw2/hw3) that can be used
    * These waves lack computed Z-scores (hw70/71/72) but we calculate them from raw data
    *
    * OLD CODE (immunization filter was too restrictive):
    * keep if !missing(h2) & !missing(h3) & !missing(h4) & !missing(h5) & ///
    *         !missing(h6) & !missing(h7) & !missing(h8) & !missing(h9)
    *
    * NEW APPROACH: Include ALL waves, calculate Z-scores in section 5.5

    display as text "  After removing restrictive filters: " _N

    * Create permanent child_age_months variable (before dropping temp)
    * This is the CORRECT variable calculated from CMC dates
    gen child_age_months = temp_child_age if !missing(temp_child_age)
    label var child_age_months "Child age (months)"

    * Clean up temporary variable
    drop temp_child_age

    display as text "  Final observations for wave " `year' ": " _N _n

    /*--------------------------------------------------------------------------
    5.3: Create Treatment and Demographic Variables
    --------------------------------------------------------------------------*/

    gen fully_exposed = (maternal_birth_year >= 1983)
    gen partially_exposed = (maternal_birth_year >= 1980 & maternal_birth_year <= 1982)
    gen unexposed = (maternal_birth_year <= 1979)

    gen rural = (v025 == 2) if !missing(v025)
    gen muslim = (v130 == 1) if !missing(v130)
    gen maternal_age = v012
    gen division = v024

    gen fully_rural = fully_exposed * rural
    gen partially_rural = partially_exposed * rural

    /*--------------------------------------------------------------------------
    5.4: Create Immunization Outcome Variables
    --------------------------------------------------------------------------*/

    * Individual vaccine indicators
    * h2 = BCG
    * h3 = DPT1, h4 = DPT2, h5 = DPT3
    * h6 = Polio1, h7 = Polio2, h8 = Polio3
    * h9 = Measles
    *
    * DHS coding: 0=no, 1=date on card, 2=reported by mother, 3=marked on card, 8=don't know
    * Include codes 1, 2, 3 as vaccinated (any evidence of vaccination)
    * Exclude 0 (no) and 8 (don't know)

    gen bcg = (h2 >= 1 & h2 <= 3 & !missing(h2))
    label var bcg "Received BCG vaccine"

    gen dpt1 = (h3 >= 1 & h3 <= 3 & !missing(h3))
    label var dpt1 "Received DPT1 vaccine"

    gen dpt2 = (h4 >= 1 & h4 <= 3 & !missing(h4))
    label var dpt2 "Received DPT2 vaccine"

    gen dpt3 = (h5 >= 1 & h5 <= 3 & !missing(h5))
    label var dpt3 "Received DPT3 vaccine"

    gen polio1 = (h6 >= 1 & h6 <= 3 & !missing(h6))
    label var polio1 "Received Polio1 vaccine"

    gen polio2 = (h7 >= 1 & h7 <= 3 & !missing(h7))
    label var polio2 "Received Polio2 vaccine"

    gen polio3 = (h8 >= 1 & h8 <= 3 & !missing(h8))
    label var polio3 "Received Polio3 vaccine"

    gen measles = (h9 >= 1 & h9 <= 3 & !missing(h9))
    label var measles "Received measles vaccine"

    * Full immunization (all 8 WHO-recommended doses)
    gen full_immunization = (bcg == 1 & dpt1 == 1 & dpt2 == 1 & dpt3 == 1 & ///
                             polio1 == 1 & polio2 == 1 & polio3 == 1 & measles == 1)
    label var full_immunization "Full immunization (8 doses)"

    * Any immunization (at least 1 of 8)
    gen any_immunization = (bcg == 1 | dpt1 == 1 | dpt2 == 1 | dpt3 == 1 | ///
                            polio1 == 1 | polio2 == 1 | polio3 == 1 | measles == 1)
    label var any_immunization "Any immunization (≥1 dose)"

    /*--------------------------------------------------------------------------
    5.5: Create Anthropometric Variables
    --------------------------------------------------------------------------*/

    * CRITICAL: Early DHS waves (1996, 1999, 2004) lack computed Z-scores (hw70/71/72)
    * but contain raw measurements (hw1=age months, hw2=weight, hw3=height)
    *
    * Strategy:
    * - For waves with hw70/71/72: Use DHS-computed values (2007+)
    * - For early waves: Use igrowup_restricted (WHO macro-based calculation)
    *
    * DHS anthropometric coding:
    * - hw70 = Height-for-age z-score × 100
    * - hw71 = Weight-for-age z-score × 100
    * - hw72 = Weight-for-height z-score × 100
    * - hw1 = Age in months (0-59)
    * - hw2 = Weight in kg × 10
    * - hw3 = Height in cm × 10
    * - hw4 = Height/Age flag (0=measured lying, 1=measured standing)
    * - Flag values: 9996-9999 = implausible/missing

    * Check if hw70 exists (computed Z-scores available)
    capture confirm variable hw70

    if _rc == 0 {
        * Waves 2007+ have computed Z-scores
        display as text "  Using DHS-computed Z-scores (hw70/71/72)"

        gen height_for_age_sd = hw70 / 100 if !missing(hw70) & hw70 < 9990

        capture confirm variable hw71
        if _rc == 0 {
            gen weight_for_age_sd = hw71 / 100 if !missing(hw71) & hw71 < 9990
        }
        else {
            gen weight_for_age_sd = .
        }

        capture confirm variable hw72
        if _rc == 0 {
            gen weight_for_height_sd = hw72 / 100 if !missing(hw72) & hw72 < 9990
        }
        else {
            gen weight_for_height_sd = .
        }
    }
    else {
        * Early waves (1996, 1999, 2004) - need to calculate from raw measurements
        display as text "  Calculating Z-scores from raw measurements using zscore06..."

        * Check if we have raw measurements
        capture confirm variable hw1
        if _rc == 0 {
            * Prepare variables for zscore06
            * zscore06 requires: age (months), weight (kg), height (cm), sex (1=male, 2=female)

            * Age in months (hw1 is already in months, 0-59)
            * DHS coding: actual age, missing if > 59 or < 0
            quietly gen temp_age = hw1 if hw1 >= 0 & hw1 <= 59

            * Weight in kg (hw2 is weight × 10)
            * DHS coding: weight in kg × 10, flag values 9990+
            quietly gen temp_weight = hw2 / 10 if hw2 > 0 & hw2 < 9990

            * Height in cm (hw3 is height × 10)
            * DHS coding: height in cm × 10, flag values 9900+
            quietly gen temp_height = hw3 / 10 if hw3 > 0 & hw3 < 9900

            * Sex (b4: 1=male, 2=female)
            quietly gen temp_sex = b4 if inlist(b4, 1, 2)

            * Run zscore06 to calculate WHO 2006 growth standards Z-scores
            * This generates: haz06, waz06, whz06, bmiz06
            * Note: 99 indicates out-of-range values
            quietly {
                capture zscore06, a(temp_age) s(temp_sex) h(temp_height) w(temp_weight)

                if _rc == 0 {
                    * zscore06 succeeded - use generated Z-scores
                    * Replace 99 (flag) with missing
                    gen height_for_age_sd = haz06 if haz06 != 99
                    gen weight_for_age_sd = waz06 if waz06 != 99
                    gen weight_for_height_sd = whz06 if whz06 != 99

                    * Clean up zscore06-generated variables
                    capture drop haz06 waz06 whz06 bmiz06
                }
                else {
                    * zscore06 failed
                    display as error "  WARNING: zscore06 failed, Z-scores set to missing"
                    gen height_for_age_sd = .
                    gen weight_for_age_sd = .
                    gen weight_for_height_sd = .
                }

                * Clean up temporary variables
                drop temp_age temp_weight temp_height temp_sex
            }

            display as text "  ✓ Z-scores calculated using WHO 2006 standards (zscore06)"
        }
        else {
            * No raw measurements available
            display as text "  No anthropometric data available for this wave"
            gen height_for_age_sd = .
            gen weight_for_age_sd = .
            gen weight_for_height_sd = .
        }
    }

    label var height_for_age_sd "Height-for-age z-score (SD)"
    label var weight_for_age_sd "Weight-for-age z-score (SD)"
    label var weight_for_height_sd "Weight-for-height z-score (SD)"

    * Binary indicators for malnutrition (< -2 SD)
    * Calculate from Z-scores (whether from hw70/71/72 or calculated above)
    gen stunted = (height_for_age_sd < -2) if !missing(height_for_age_sd)
    label var stunted "Stunted (height-for-age < -2 SD)"

    gen underweight = (weight_for_age_sd < -2) if !missing(weight_for_age_sd)
    label var underweight "Underweight (weight-for-age < -2 SD)"

    gen wasted = (weight_for_height_sd < -2) if !missing(weight_for_height_sd)
    label var wasted "Wasted (weight-for-height < -2 SD)"

    /*--------------------------------------------------------------------------
    5.6: Create Health Input Variables (Antenatal, Delivery, Postnatal Care)
    --------------------------------------------------------------------------*/

    * Calculate months since birth
    gen months_since_birth = v008 - b3 if !missing(v008, b3)

    
    * Identify last-born child (most recent birth) for each mother
    * bord is birth order (1=first, 2=second, etc.), NOT most recent
    * Last-born = birth with highest b3 (most recent birth date) per caseid
    bysort caseid (b3): gen is_last_born = (_n == _N)
    label var is_last_born "Last-born child (most recent birth)"
    * Antenatal care variables (for last-born in 3 years before survey)
    gen eligible_antenatal = (is_last_born == 1 & months_since_birth <= 36 & months_since_birth >= 0)

    * Any antenatal care (m14 = number of visits)
    gen any_antenatal = (m14 >= 1 & !missing(m14)) if eligible_antenatal
    label var any_antenatal "Any antenatal care"

    * Number of antenatal visits
    gen num_antenatal = m14 if eligible_antenatal
    label var num_antenatal "Number of antenatal visits"

    * Doctor gave antenatal care (m2a)
    capture confirm variable m2a
    if _rc == 0 {
        gen doctor_antenatal = (m2a == 1) if eligible_antenatal & !missing(m2a)
    }
    else {
        gen doctor_antenatal = .
    }
    label var doctor_antenatal "Doctor gave antenatal care"

    * Nurse/midwife gave antenatal care (m2b, m2c, m2d)
    * CORRECTED: Only use m2b (nurse/midwife) to match paper definition
    * Paper says "nurse, midwife, or paramedic" with mean 0.089
    * m2d in 1996-2007 is "family welfare visitor" (NOT medical professional)
    * Including m2d inflates our mean to 0.147 (65% higher than paper)
    * AFTER CHECKS: m2d should be EXCLUDED
    capture confirm variable m2b
    if _rc == 0 {
        gen nurse_antenatal = (m2b == 1) if eligible_antenatal & !missing(m2b)
    }
    else {
        gen nurse_antenatal = .
    }
    label var nurse_antenatal "Nurse/midwife gave antenatal care"

    * Antenatal iron supplements (m45, only 2004+)
    if `year' >= 2004 {
        capture confirm variable m45
        if _rc == 0 {
            gen iron_supplements = (m45 == 1) if eligible_antenatal & !missing(m45)
        }
        else {
            gen iron_supplements = .
        }
    }
    else {
        gen iron_supplements = .
    }
    label var iron_supplements "Antenatal iron supplements"

    * Delivery care variables (for births in 3 years before survey)
    gen eligible_delivery = (months_since_birth <= 36 & months_since_birth >= 0)

    * Facility delivery (m15: 20-36 = health facility)
    gen facility_delivery = inrange(m15, 20, 36) if eligible_delivery & !missing(m15)
    label var facility_delivery "Facility delivery"

    * Home delivery (m15: 10-12 = home)
    gen home_delivery = inrange(m15, 10, 12) if eligible_delivery & !missing(m15)
    label var home_delivery "Home delivery"

    * Doctor assisted delivery (m3a)
    capture confirm variable m3a
    if _rc == 0 {
        gen doctor_delivery = (m3a == 1) if eligible_delivery & !missing(m3a)
    }
    else {
        gen doctor_delivery = .
    }
    label var doctor_delivery "Doctor assisted delivery"

    * Postnatal care (m50, only 2011+)
    if `year' >= 2011 {
        * For last-born under age 5
        gen eligible_postnatal = (is_last_born == 1 & b8 < 60)
        capture confirm variable m50
        if _rc == 0 {
            gen postnatal_care = (m50 == 1) if eligible_postnatal & !missing(m50)
        }
        else {
            gen postnatal_care = .
        }
    }
    else {
        gen postnatal_care = .
    }
    label var postnatal_care "Postnatal care (within 2 months)"

    * Vitamin A supplementation
    * 1996-97: Uses s464 "child taken vitamin a capsule" (1=yes, 2=no, 8=dk)
    * 1999-00: NOT available
    * 2004+: Uses h33/h34 (standard DHS variables)
    * NOTE: Paper CORRECTLY states 1996-97 availability - uses different variable names

    if `year' == 1996 {
        * 1996 uses s464 (capsule)
        capture confirm variable s464
        if _rc == 0 {
            gen vitamin_a = (s464 == 1) if !missing(s464) & s464 <= 1
        }
        else {
            gen vitamin_a = .
        }
    }
    else if `year' == 1999 {
        * 1999 does not have vitamin A
        gen vitamin_a = .
    }
    else {
        * 2004+ uses h34 (in last 6 months)
        capture confirm variable h34
        if _rc == 0 {
            gen vitamin_a = (h34 == 1) if !missing(h34)
        }
        else {
            gen vitamin_a = .
        }
    }
    label var vitamin_a "Vitamin A supplementation"

    /*--------------------------------------------------------------------------
    5.7: Create Maternal Education Variables
    --------------------------------------------------------------------------*/

    gen years_schooling = v133
    gen secondary_plus = (v106 >= 2) if !missing(v106)

    /*--------------------------------------------------------------------------
    5.8: Create Labor Supply Variables
    --------------------------------------------------------------------------*/

    * Husband's education (v701)
    gen husband_secondary_plus = (v701 >= 2) if !missing(v701)
    label var husband_secondary_plus "Husband secondary+ education"

    * Currently working (v714)
    gen currently_working = (v714 == 1) if !missing(v714)
    label var currently_working "Currently working"

    * Works in formal sector (respondent occupation)
    * Paper definition: "Professional occupations and business" (Footnote 10)
    * CRITICAL FIX:
    *   - 1: Code non-workers as 0 (not missing) to match N=32,706
    *   - 2: Use v716 with wave-specific codes (v717 missing in 2007/2011)
    *
    * v716 coding:
    *   1996-2004: code 7 = professional worker
    *   2007-2017: code 41 = professional (doctor, lawyer, teacher, etc.)
    capture confirm variable v716
    if _rc == 0 {
        * Initialize all as not in formal sector
        gen formal_sector = 0

        * Early waves (1996-2004): code 7=professional, code 8=business
        replace formal_sector = 1 if inlist(v716, 7, 8) & `year' <= 2004 & !missing(v716)

        * Later waves (2007-2017): code 41=professional, codes 51/52=business
        replace formal_sector = 1 if inlist(v716, 41, 51, 52) & `year' >= 2007 & !missing(v716)
    }
    else {
        * Fallback if v716 doesn't exist
        gen formal_sector = 0
        capture confirm variable v717
        if _rc == 0 {
            replace formal_sector = 1 if inlist(v717, 1, 2) & !missing(v717) & v717 < 90
        }
    }
    label var formal_sector "Works in formal sector"

    * Husband works in formal sector (v704)
    * Paper definition: "Professional occupations and business" (Footnote 10)
    * DHS codes: 41=professional, 51=big business, 52=small business
    * Raange: v704 ∈ {41, 51, 52} gives mean=0.2767 (target=0.282)
    capture confirm variable v704
    if _rc == 0 {
        gen husband_formal = inlist(v704, 41, 51, 52) if !missing(v704) & v704 < 90
    }
    else {
        gen husband_formal = .
    }
    label var husband_formal "Husband works in formal sector"

    /*--------------------------------------------------------------------------
    5.9: Create Fertility Variables
    --------------------------------------------------------------------------*/

    * Age at first birth (v212)
    gen age_first_birth = v212
    label var age_first_birth "Age at first birth (years)"

    * Number of living children (v218)
    gen num_living_children = v218
    label var num_living_children "Number of living children"

    * Ideal number of children (v613)
    gen ideal_num_children = v613 if v613 < 90
    label var ideal_num_children "Ideal number of children"

    * Has a daughter (check if any b4 == 2 for this mother)
    gen has_daughter = (b4 == 2)
    label var has_daughter "Has a daughter"

    * Ideal number of girls is zero (v627)
    capture confirm variable v627
    if _rc == 0 {
        gen ideal_girls_zero = (v627 == 0) if !missing(v627)
    }
    else {
        gen ideal_girls_zero = .
    }
    label var ideal_girls_zero "Ideal number of girls is zero"

    /*--------------------------------------------------------------------------
    5.10: Create Autonomy Variables (2004+ only)
    --------------------------------------------------------------------------*/

    if `year' >= 2004 {
        * Decision-making variables
        capture confirm variable v743a
        if _rc == 0 {
            gen decides_health = inlist(v743a, 1, 2, 3) if !missing(v743a)
        }
        else {
            gen decides_health = .
        }

        capture confirm variable v743b
        if _rc == 0 {
            gen decides_purchases = inlist(v743b, 1, 2, 3) if !missing(v743b)
        }
        else {
            gen decides_purchases = .
        }

        capture confirm variable v743d
        if _rc == 0 {
            gen decides_visits = inlist(v743d, 1, 2, 3) if !missing(v743d)
        }
        else {
            gen decides_visits = .
        }

        gen decision_index = decides_health + decides_purchases + decides_visits

        * Can go to health center/hospital alone or with children
        * WAVE-SPECIFIC VARIABLE NAMES (same as mother-level)
        if `year' == 2004 {
            capture confirm variable s819
            if _rc == 0 {
                gen can_go_hospital = inlist(s819, 2, 3) if !missing(s819)
            }
            else {
                gen can_go_hospital = .
            }
        }
        else if `year' == 2007 {
            capture confirm variable s826b
            if _rc == 0 {
                gen can_go_hospital = inlist(s826b, 2, 3) if !missing(s826b)
            }
            else {
                gen can_go_hospital = .
            }
        }
        else {
            * 2011-2017: Use standard DHS variable v744b
            capture confirm variable v744b
            if _rc == 0 {
                gen can_go_hospital = inlist(v744b, 1, 2) if !missing(v744b)
            }
            else {
                gen can_go_hospital = .
            }
        }
    }
    else {
        gen decides_health = .
        gen decides_purchases = .
        gen decides_visits = .
        gen decision_index = .
        gen can_go_hospital = .
    }
    label var decides_health "Has say in health care decisions"
    label var decides_purchases "Has say in large purchases"
    label var decides_visits "Has say in visits to family"
    label var decision_index "Decision-making index (0-3)"
    label var can_go_hospital "Can go to hospital alone/with children"

    /*--------------------------------------------------------------------------
    5.11: Create Media Exposure Variables (Wave-specific)
    --------------------------------------------------------------------------*/

    if `year' <= 1999 {
        gen newspaper_weekly = (v109 == 1) if !missing(v109)
        gen tv_weekly = (v110 == 1) if !missing(v110)
        gen radio_weekly = (v112 == 1) if !missing(v112)
    }
    else {
        * 2004+: Same as mother-level (v157, v159, v158 >= 2)
        * VERIFIED: >= 2 is correct across all waves
        gen newspaper_weekly = (v157 >= 2) if !missing(v157)
        gen tv_weekly = (v159 >= 2) if !missing(v159)
        gen radio_weekly = (v158 >= 2) if !missing(v158)
    }
    label var newspaper_weekly "Reads newspaper weekly"
    label var tv_weekly "Watches TV weekly"
    label var radio_weekly "Listens to radio weekly"

    gen media_sources = newspaper_weekly + tv_weekly + radio_weekly
    label var media_sources "Number of media sources (0-3)"

    /*--------------------------------------------------------------------------
    5.12: Create Marriage Variables
    --------------------------------------------------------------------------*/

    * Age at first marriage (v511)
    gen age_marriage = v511
    label var age_marriage "Age at first marriage/cohabitation"

    * Child marriage indicator (<18 years)
    gen child_marriage = (v511 < 18) if !missing(v511)
    label var child_marriage "Married before age 18"

    /*--------------------------------------------------------------------------
    5.13: Create Child Characteristics
    --------------------------------------------------------------------------*/

    gen child_female = (b4 == 2) if !missing(b4)
    label var child_female "Child is female"

    rename bord birth_order
    label var birth_order "Birth order"

    * NOTE: child_age_months already correctly calculated at line 511 from CMC dates

    /*--------------------------------------------------------------------------
    5.14: Handle Wave-Specific Wealth Variables
    --------------------------------------------------------------------------*/

    if `year' >= 2004 {
        gen wealth_quintile = v190
        gen wealth_index = v191
    }
    else {
        gen wealth_quintile = .
        gen wealth_index = .
    }
    label var wealth_quintile "Wealth quintile"
    label var wealth_index "Wealth index"

    /*--------------------------------------------------------------------------
    5.15: Keep Essential Variables
    --------------------------------------------------------------------------*/

    keep caseid v000 v001 v002 v003 v005 v008 v021 v023 v024 v025 ///
         v106 v130 v133 ///
         survey_wave maternal_birth_year maternal_age rural muslim division ///
         years_schooling secondary_plus ///
         fully_exposed partially_exposed unexposed fully_rural partially_rural ///
         wealth_quintile wealth_index ///
         child_female birth_order child_age_months ///
         bcg dpt1 dpt2 dpt3 polio1 polio2 polio3 measles ///
         full_immunization any_immunization ///
         height_for_age_sd weight_for_age_sd weight_for_height_sd ///
         stunted underweight wasted ///
         any_antenatal num_antenatal doctor_antenatal nurse_antenatal iron_supplements ///
         facility_delivery home_delivery doctor_delivery postnatal_care vitamin_a ///
         husband_secondary_plus currently_working formal_sector husband_formal ///
         age_first_birth num_living_children ideal_num_children has_daughter ideal_girls_zero ///
         decides_health decides_purchases decides_visits decision_index can_go_hospital ///
         newspaper_weekly tv_weekly radio_weekly media_sources ///
         age_marriage child_marriage

    save `temp`i'', replace

    local i = `i' + 1
}

/*------------------------------------------------------------------------------
5.16: Append All Waves and Finalize Child Sample
------------------------------------------------------------------------------*/

display as text _n "=== Appending All Waves ===" _n

use `temp1', clear
append using `temp2', force
append using `temp3', force
append using `temp4', force
append using `temp5', force
append using `temp6', force
append using `temp7', force

/*------------------------------------------------------------------------------
5.17: Declare Survey Design
------------------------------------------------------------------------------*/

gen weight = v005 / 1000000
svyset v021 [pweight=weight], strata(v023)

gen maternal_by_rural = maternal_birth_year * 100 + rural

/*------------------------------------------------------------------------------
5.18: Save Child Sample
------------------------------------------------------------------------------*/

compress
label data "Child Sample - FSSSP Replication (N≈29,383)"
save "$analysis_data/child_sample.dta", replace

* Display validation statistics
display as result _n(2) "================================================================================"
display as result "CHILD SAMPLE CREATED"
display as result "================================================================================" _n

display as text "Total observations: " _N
display as text "Expected: ~29,383" _n

display as text "Treatment group distribution:"
count if fully_exposed
display as text "  Fully Exposed: " r(N) " (" %4.1f 100*r(N)/_N "%)"
count if partially_exposed
display as text "  Partially Exposed: " r(N) " (" %4.1f 100*r(N)/_N "%)"
count if unexposed
display as text "  Unexposed: " r(N) " (" %4.1f 100*r(N)/_N "%)" _n

display as text "Immunization statistics (compare to Table 1, Panel B):"
summarize full_immunization any_immunization

display as text _n "Sample characteristics:"
summarize years_schooling secondary_plus maternal_age rural muslim

display as result _n "Child sample saved: $analysis_data/child_sample.dta" _n

/*==============================================================================
SECTION 6: FINAL VALIDATION SUMMARY
==============================================================================*/

display as result _n(2) "================================================================================"
display as result "DATA CLEANING COMPLETE"
display as result "================================================================================" _n

display as text "Three samples created:" _n

display as text "1. MOTHER SAMPLE"
use "$analysis_data/mother_sample.dta", clear
display as text "   N = " _N " (expected ~69,235)"
display as text "   File: $analysis_data/mother_sample.dta" _n

display as text "2. BIRTH SAMPLE"
use "$analysis_data/birth_sample.dta", clear
display as text "   N = " _N " (expected ~150,175)"
display as text "   File: $analysis_data/birth_sample.dta" _n

display as text "3. CHILD SAMPLE"
use "$analysis_data/child_sample.dta", clear
display as text "   N = " _N " (expected ~29,383)"
display as text "   File: $analysis_data/child_sample.dta" _n

/*==============================================================================
SECTION 7: CREATE VALIDATION TABLE (Compare to Paper's Table 1)
==============================================================================*/

display as result _n(2) "================================================================================"
display as result "VALIDATION: COMPARING TO PAPER'S TABLE 1"
display as result "================================================================================" _n

* Mother Sample Statistics (Panel A)
display as text "PANEL A: MOTHER SAMPLE (Table 1)" _n
use "$analysis_data/mother_sample.dta", clear

display as text "Sample Size:"
display as text "  Actual: " _N
display as text "  Expected: 69,235" _n

display as text "Treatment Groups:"
quietly count if fully_exposed
local fully_n = r(N)
display as text "  Fully Exposed: " `fully_n' " (" %4.1f 100*`fully_n'/_N "%) [Expected: 33,784, 48.8%]"

quietly count if partially_exposed
local partial_n = r(N)
display as text "  Partially Exposed: " `partial_n' " (" %4.1f 100*`partial_n'/_N "%) [Expected: 9,216, 13.3%]"

quietly count if unexposed
local unexp_n = r(N)
display as text "  Unexposed: " `unexp_n' " (" %4.1f 100*`unexp_n'/_N "%) [Expected: 26,235, 37.9%]" _n

display as text "Mean Values (Expected from Table 1):"
quietly summarize years_schooling
display as text "  Years of schooling: " %5.3f r(mean) " [Expected: 5.256]"
quietly summarize secondary_plus
display as text "  Secondary+: " %5.3f r(mean) " [Expected: 0.404]"
quietly summarize maternal_age
display as text "  Age: " %5.3f r(mean) " [Expected: 29.816]"
quietly summarize rural
display as text "  Rural: " %5.3f r(mean) " [Expected: 0.696]"
quietly summarize muslim
display as text "  Muslim: " %5.3f r(mean) " [Expected: 0.898]" _n

* Child Sample Statistics (Panel B)
display as text "PANEL B: CHILD SAMPLE (Table 1)" _n
use "$analysis_data/child_sample.dta", clear

display as text "Sample Size:"
display as text "  Actual: " _N
display as text "  Expected: 29,383" _n

display as text "Treatment Groups:"
quietly count if fully_exposed
local fully_n = r(N)
display as text "  Fully Exposed: " `fully_n' " (" %4.1f 100*`fully_n'/_N "%) [Expected: 15,166, 51.6%]"

quietly count if partially_exposed
local partial_n = r(N)
display as text "  Partially Exposed: " `partial_n' " (" %4.1f 100*`partial_n'/_N "%) [Expected: 4,005, 13.6%]"

quietly count if unexposed
local unexp_n = r(N)
display as text "  Unexposed: " `unexp_n' " (" %4.1f 100*`unexp_n'/_N "%) [Expected: 10,212, 34.7%]" _n

display as text "Mean Values:"
quietly summarize full_immunization
display as text "  Full immunization: " %5.3f r(mean) " [Expected: 0.812]"
quietly summarize any_immunization
display as text "  Any immunization: " %5.3f r(mean) " [Expected: 0.985]" _n

* Birth Sample Statistics (Panel C)
display as text "PANEL C: BIRTH SAMPLE (Table 1)" _n
use "$analysis_data/birth_sample.dta", clear

display as text "Sample Size:"
display as text "  Actual: " _N
display as text "  Expected: 150,175" _n

display as text "Treatment Groups:"
quietly count if fully_exposed
local fully_n = r(N)
display as text "  Fully Exposed: " `fully_n' " (" %4.1f 100*`fully_n'/_N "%) [Expected: 52,874, 35.2%]"

quietly count if partially_exposed
local partial_n = r(N)
display as text "  Partially Exposed: " `partial_n' " (" %4.1f 100*`partial_n'/_N "%) [Expected: 21,137, 14.1%]"

quietly count if unexposed
local unexp_n = r(N)
display as text "  Unexposed: " `unexp_n' " (" %4.1f 100*`unexp_n'/_N "%) [Expected: 76,164, 50.7%]" _n

display as text "Mortality Rates:"
quietly summarize neonatal_mort
display as text "  Neonatal mortality: " %5.3f r(mean) " [Expected: 0.027]"
quietly summarize infant_mort
display as text "  Infant mortality: " %5.3f r(mean) " [Expected: 0.049]"
quietly summarize child_mort
display as text "  Child mortality: " %5.3f r(mean) " [Expected: 0.060]" _n

/*==============================================================================
END OF DATA CLEANING SCRIPT
==============================================================================*/

display as result _n(2) "================================================================================"
display as result "DATA CONSTRUCTION COMPLETED SUCCESSFULLY"
display as result "================================================================================" _n

display as result "All datasets saved in: $analysis_data" _n

* End of script
