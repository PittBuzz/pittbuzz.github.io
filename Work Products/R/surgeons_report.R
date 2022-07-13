rm(list = ls())

#################################################################################################
## Surgeon's Report for COL Bullock, Deputy Surgeon - Clinical Operations
## Pulls all the DODI for the SELRES and matches on those who have a pending
## Religious exemption (EPAT data from LTC Misty Jones) and those who are being tracked as ADOS
## from Mr. George Damour (ADOS data).
## All recent EPAT and ADOS data is here: I:\AG_Division\SAB\10- Religious Accommodations\DATA pulls
## Enusre that EPAT data is recent and the file is named "epat"
## By: MAJ Androff, J
#################################################################################################

library(jpeg)
library(DBI)
library(openxlsx)
library(tidyverse)

## SQL query takes the last Friday run date
query <- paste0("
                use RCMSV3_DW
                declare @rdt date = (select max(run_dt) from factreservestrength)
                select dse.DOD_EDI_PN_ID as DODI
                ,SSN
                ,dsp.MPC_CD as MPC
                ,dsp.rcms_grade_cd as Grade
                ,r.LastName as Last
                ,r.FirstName as First
                ,r.FullName as [Full]
                ,r.rcms_Gender_CD as Gender
                ,isnull(dsp.PrimaryMOS_CD,'') as PMOS
                ,dsp.rcms_componentcategory_cd as RCC
                ,duh.UPC_CD as UPC 
                ,duh.Ed_UnitName as [Unit Name]
                ,duh.OF1UPC_NAME as MSC
                ,dsp.PersonnelDeployabilityLimitation_CD as MVNAR -- +'-'+pdl.description as MVNAR
                ,isnull(fss.[AllRLASFlag_CD],'') as [SFPA Codes]
                ,fss.[MinRLASFlag_DT] as [Earliest SFPA Dt]
                --,fss.Suspension_DT as [SFPA Dt]
                --truncate from here for Surgeons report
                ,[SelResAdverseActionOther_SFPA_CNT] as AdverseActionOther
                ,[SelResAdverseAction_SFPA_CNT] as AdverseAction
                ,[SelResReferredOfficerEvaluationReport_SFPA_CNT] as OfficerEvaluationReport
                ,[SelResSecurityViolation_SFPA_CNT] as SecurityViolation
                ,[SelResRemovalFromSelectionListHQDA_SFPA_CNT] as RemovalFromSelectionListHQDA
                ,[SelResDirectedReassignmentAAHQDA_SFPA_CNT] as DirectedReassignmentAAHQDA
                ,[SelResPunishmentPhaseAA_SFPA_CNT] as PunishmentPhaseAA
                ,[SelResAPFTFailure_SFPA_CNT] as APFTFailure
                ,[SelResWeightControlProgram_SFPA_CNT] as WeightControlProgram
                ,[SelResCDRInvestigation_SFPA_CNT] as CDRInvestigation
                ,[SelResLawEnforcementInvestigation_SFPA_CNT] as LawEnforcementInvestigation
                ,[SelResCDRBlockAutoPromotionE2toE4_SFPA_CNT] as CDRBlockAutoPromotionE2toE4
                ,[SelResCDRArmySubstanceAbuseProgram_SFPA_CNT] as CDRArmySubstanceAbuseProgram
                ,[SelResBlockAutoPromotionO2orCW2_SFPA_CNT] as BlockAutoPromotionO2orCW2
                ,[SelResDrugAbuseAA_SFPA_CNT] as DrugAbuseAA
                ,[SelResAlcoholAbuseAA_SFPA_CNT] as AlcoholAbuseAA
                ,[SelResInvoluntarySeparationHQDA_SFPA_CNT] as InvoluntarySeparationHQDA
                --,[rcms_Flag_TXT]
                --,lr.[Description] as 'Flag'
                into ##dodi
                from DimSoldierPersonnel dsp
                join dimssn dsn on dsn.ID=dsp.SSNID
                join DimSoldierRestricted r on dsp.SoldierRestrictedID=r.ID and r.start_dt <= @rdt and  (r.End_DT is null or r.End_DT > @rdt)
                join RCMSV3_DW.dbo.FactReserveStrength rs on rs.SSNID = dsp.SSNID and rs.Run_DT =  @rdt and rs.rcms_componentCategory_CD in ('agr','tpu')
                left join RCMSV3_DW_DP..DimSsnToEDIPIID dse on dse.SSNID=dsp.SSNID and dse.Start_Dt <= @rdt AND (dse.End_DT > @rdt OR dse.End_Dt IS NULL) 
                left join RCMSV3_LOOKUPS..Lkp_PersonnelDeployabilityLimitation_CD pdl on pdl.Code = dsp.PersonnelDeployabilityLimitation_CD and pdl.start_dt <= @rdt and (pdl.End_DT is null or pdl.End_DT > @rdt)
                left join DimUnitHierarchies DUH on dsp.UPC_CD = DUH.UPC_CD and duh.start_dt <= @rdt and  (duh.End_DT is null or duh.End_DT > @rdt) and DUH.Hierarchy_CD = 'OF10'
                left join rcmsv3_lookups..[Lkp_SFPAReason_CD] lr on dsp.suspensionrsn_cd = lr.code and lr.End_DT is null
                left join RCMSV3_DW.dbo.FactSelresSFPA fss on fss.SoldierID = dsp.ID and fss.Run_DT=@rdt
                
                where dsp.Start_DT<=@rdt and (dsp.End_DT is null or dsp.End_DT>@rdt) and dsp.rcms_ComponentCategory_CD in ('tpu','agr')
                  ")

## Connect to RCMS 
con <- dbConnect(odbc::odbc(),"rcms")

## Execute SQL statement, wait until R completes before proceeding
dbExecute(con, query)

## Get the results
##dodi <- dbGetQuery(con, query)
dodi <- dbGetQuery(con, "Select * from  ##dodi")


## Disconnect from RCMS
dbDisconnect(con)

### bring in EPAT and ADOS data with the correct columns
### sometimes SAB likes to change the order of the columns
ados <- read.xlsx("I:/AG_Division/SAB/10- Religious Accommodations/DATA pulls/ados.xlsx", sheet = 1, cols = c(2,6:10), skipEmptyRows = TRUE, skipEmptyCols = TRUE) 
epat <- read.xlsx("I:/AG_Division/SAB/10- Religious Accommodations/DATA pulls/epat.xlsx", sheet = 1, cols = c(5:10), skipEmptyRows = TRUE, skipEmptyCols = TRUE)

a <- as.data.frame(apply(ados, 2 ,function(x)gsub('\\s+', '',x))) %>% select(c(1,4)) %>% 
  rename(ADOS = RLAS.AMSCO.Type)
e <- as.data.frame(apply(epat, 2 ,function(x)gsub('\\s+', '',x))) %>% select(1:6) %>% 
  rename(Vac_Exemption = Action.Status)
d <- as.data.frame(apply(dodi, 2 ,function(x)gsub('\\s+', '',x))) %>% select(!c(17:33))

x <- left_join(d, a, by = c("Full" = "Soldier.Name")) 
x <- left_join(x, e, by = c("Full" = "Soldier.Name")) 

SSN <- x %>% select(!'DODI')
DOD <- x %>% select(!'SSN')

##colnames(x)[which(names(x) == "RLAS.AMSCO.Type")] <- "ADOS"
##colnames(x)[which(names(x) == "Action.Status")] <- "Vac_Exemption"

## create the excel workbook and sheets
wb <- createWorkbook(creator = Sys.getenv("USERNAME"))
addWorksheet(wb, "Privacy Act")
addWorksheet(wb, "data")

## grab the privacy act picture and put it into Excel

img2 <- "O:/ORSA_Workflow/36 Reports/Surgeons_report/privacy_act.jpeg"

insertImage(wb = wb, sheet = "Privacy Act", file = img2, startRow = 1, startCol = 1, width = 6, height = 8)

modifyBaseFont(wb, fontSize = 10, fontColour = "black", fontName = "Arial")

## set the col widths to 12
setColWidths(wb, 2, cols = 1:ncol(x), widths = 12)

## Apply header style
hs1 <- createStyle(fontName = "Arial", fontSize = 10, textDecoration = "bold", border = "Bottom", borderColour="black", borderStyle="thin",fgFill = "gray")

writeData(wb, "data", DOD, startCol = 1, startRow = 1, headerStyle = hs1, colNames = TRUE,
          rowNames = FALSE, 
          borders = "all",
          borderColour = getOption("openxlsx.borderColour", "black"),
          borderStyle = getOption("openxlsx.borderStyle", "thin"),
          withFilter = TRUE)

## sets the current date to today's date and saves it to the ORSA folder
setwd("O:/ORSA_Workflow/36 Reports/Surgeons_report/reports")
filedodi <- paste0("Surgeons_report_",format(Sys.Date(), format="%Y%m%d"),".xlsx")
saveWorkbook(wb, file=filedodi, overwrite = TRUE)

## if someone asks for SSN here it is....
# writeData(wb, "data", SSN, startCol = 1, startRow = 1, headerStyle = hs1, colNames = TRUE,
#           rowNames = FALSE, 
#           borders = "all",
#           borderColour = getOption("openxlsx.borderColour", "black"),
#           borderStyle = getOption("openxlsx.borderStyle", "thin"),
#           withFilter = TRUE)
# 
# filessn <- paste0("Surgeons_report_ssn",format(Sys.Date(), format="%Y%m%d"),".xlsx")
# saveWorkbook(wb, file=filessn, overwrite = TRUE)

## save the report to Special Actions Branch directory
#setwd("I:/AG_Division/SAB/10- Religious Accommodations")
#fileNm <- paste0("Surgeons_report_",format(Sys.Date(), format="%Y%m%d"),".xlsx")
#saveWorkbook(wb, file=fileNm, overwrite = TRUE)

rm(list = ls())

