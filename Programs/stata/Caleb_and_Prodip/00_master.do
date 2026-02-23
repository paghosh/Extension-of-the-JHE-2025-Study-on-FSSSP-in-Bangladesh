********************************************************************************
* FSSSP REPLICATION - MASTER DO-FILE
*
* Purpose: Replicates "The Impact of the Female Secondary School Stipend
*          Program on Child Health" (Journal of Health Economics, 2025)
*
* Authors: Md Shahjahan, Giulia La Mattina, Padmaja Ayyagari
*
* Data: Bangladesh Demographic and Health Survey (BDHS) 1996-97 through 2017-18
*
* Created: 
* Software: 
********************************************************************************

clear all
set maxvar 32000
version 16

* Install required packages if not already installed
foreach pkg in estout ietoolkit {
    capture which `pkg'
    if _rc {
        display as text "Installing `pkg'..."
        ssc install `pkg', replace
    }
}

** GUIDELINE **
********************************************************************************
* 1- Create a directory on your computer and name it FSSSP_Replication

* 2- Update the main directory global path

* 3- Run this master dofile from the begining up to the end of "END OF MAIN 
* SECTINGS SECTION" (Line 43)

* 4- Save this do-file

* 5- Put all do-files inside the sub-folder "code"

* 6- Finally this master do-file and you should get all relevant data (in sub-folder "data/analysis_data"), tables (in sub-folder "tables"), and figures (in sub-folder "figures")
********************************************************************************

** MAIN SETTINGS SECTION
* Set main directory global path
global fsssp "/Users/calebdohou/Library/CloudStorage/GoogleDrive-cjdohou@gmail.com/My Drive/Econ_PhD_University_of_Oklahoma/Dr Pallab Ghosh/FSSSP_Replication"

* Set sub-folders global path
global raw_data "${fsssp}/data/raw_data"
global analysis_data "${fsssp}/data/analysis_data"
global code "${fsssp}/code"
global tables "${fsssp}/tables"
global figures "${fsssp}/figures"

* Creating relevant folders
capture mkdir "${raw_data}"
capture mkdir "${analysis_data}"
capture mkdir "${code}"
capture mkdir "${tables}"
capture mkdir "${figures}"

* END OF MAIN SETTINGS SECTION
***********************************************

* Set random seed for reproducibility
*set seed 12345

********************************************************************************
* EXECUTE REPLICATION SCRIPTS
********************************************************************************

display as text "=========================================="
display as text " FSSSP REPLICATION - STARTED"
display as text "=========================================="
display as text ""

* 1. Data Cleaning and Construction
display as result "Data Cleaning and Preparation"
do "$code/01_data_construction.do"
display as text ""

* 2. Descriptive Statistics (Table 1)
display as result "Replicating Table 1 (Summary Statistics)"
do "$code/02_table1.do"
display as text ""

* 3. Main Results - Education and Immunization (Table 2)
display as result "Replicating Table 2 (Education & Immunization)"
do "$code/03_table2.do"
display as text ""

* 4. Health Inputs (Table 3)
display as result "Replicating Table 3 (Other Health Inputs)"
do "$code/04_table3.do"
display as text ""

* 5. Mortality and Anthropometrics (Table 4)
display as result "Replicating Table 4 (Mortality & Anthropometrics)"
do "$code/05_table4.do"
display as text ""

* 6. Husband Education and Labor Supply (Table 5)
display as result "Replicating Table 5 (Husband Education & Labor)"
do "$code/06_table5.do"
display as text ""

* 7. Fertility (Table 6)
display as result "Replicating Table 6 (Fertility)"
do "$code/07_table6.do"
display as text ""

* 8. Marriage, Autonomy, Decision Making (Table 7)
display as result "Replicating Table 7 (Marriage & Autonomy)"
do "$code/08_table7.do"
display as text ""

* 9. Media Exposure (Table 8)
display as result "Replicating Table 8 (Media Exposure)"
do "$code/09_table8.do"
display as text ""

* 10. Additional Figures (Figure 1)
display as result "Step 12: Generating Figure 1 (FSSSP Exposure)"
do "$code/10_figure1.do"
display as text ""

* 11. Event Study Graphs (Figure 2)
display as result "Step 11: Generating Event Study Graphs"
do "$code/11_figure2.do"
display as text ""

display as text "=========================================="
display as text " FSSSP REPLICATION - COMPLETED"
display as text "=========================================="
display as text ""
display as text "Tables saved in: $tables"
display as text "Figures saved in: $figures"
display as text ""

********************************************************************************
* END OF MASTER DO-FILE
********************************************************************************
