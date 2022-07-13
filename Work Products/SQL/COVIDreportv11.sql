--COVID VACCINE INFORMATION
	-- Is comprised of multiple temp tables that are joined
	-- TempSELRES, TempMILTECH, TempAFlags, TempePAT all are joined in to an aggregate G1 temptable called Tempagg. This was done to allow for these portions of the code to be added to CSMM to allow downtrace units see the same reports. The vantage data has hindered this effort
	


--DATES 
	-- RDT automates this report to run on the previous friday
	--EOMdt the Noval pay report needs to be run at the end of everymonth automates this process
	declare @rdt as datetime
	set @rdt = '20220608'
	--declare @rdt date = dateadd(weekday, -1*(datepart(WEEKDAY,getdate()+1)), getdate())
	declare @EOMdt date = eomonth(dateadd(mm, -1, eomonth(getdate())))


--HOW TO UPLOAD TO SANDBOX IN ONE LINE
	-- this will be edited once closer to a completed document and may move lower into the document
	--Select * Into RCMS_ORSA.dbo.tempselres from #TempSELRES

--#TempSELRES
	--Is the base temp table that everything is joined to.
	--case statements regarding demographics are the same as those used for offical reports
	--This file will generate a number of soldiers that do not have DODID this 
	--Those with out a DODID go in to the TEMPDODInull
	if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#TempSELRES')) drop table #TempSELRES

	SELECT
	--Personel Information
		 DSE.DOD_EDI_PN_ID as DODI
		,DSP.MPC_CD as MPC
		,DSP.rcms_grade_cd as Grade
		,DSP.GradeAbbreviation_CD as Grade_abbre
		,DSR.LastName as LastName
		,DSR.FirstName as FirstName
		,DSR.FullName as FullName
		,DSR.rcms_Gender_CD as Gender
		,DSR.HomeState_CD as HOR_state
		,case when DSP.MPC_CD = 'e' and rcms_ETSorMRD_DT <= '20220930' then 'FY22'  
				when DSP.MPC_CD = 'e' and rcms_ETSorMRD_DT <= '20230930' then 'FY23' else NULL end as 'ETS_Status'
		,DSP.rcms_ETS_DT as ETSDATE
		,DSP.rcms_ETSorMRD_DT as ETS_MRDDATE
	--SJA Board
		,DSP.rcms_PEBD_DT as PEBD_dt
		,DATEDIFF(YY,DSP.rcms_pebd_dt,GetDate()) as 'YRs_service'
		,DSP.YrsCreditableService as 'Federal_service'
		,CASE WHEN DSP.YrsCreditableService between 6 and 18 AND DSP.rcms_componentcategory_cd = 'AGR' AND DSP.MPC_CD = 'O' THEN 1 
				WHEN DSP.YrsCreditableService between 5 and 18 AND DSP.rcms_componentcategory_cd = 'TPU' AND DSP.MPC_CD = 'O' THEN 1
				WHEN DSP.YrsCreditableService between 6 and 18 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'E' THEN 1
				WHEN DSP.YrsCreditableService between 18 and 20 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'O' THEN 1
				WHEN DSP.YrsCreditableService between 18 and 20 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'E' THEN 1
				WHEN DSP.YrsCreditableService >= 20 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'O' THEN 1
				WHEN DSP.YrsCreditableService >= 20 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'E' THEN 1
				WHEN DSP.YrsCreditableService < 6 AND DSP.rcms_componentcategory_cd = 'AGR' AND DSP.MPC_CD = 'O' Then 0
				WHEN DSP.YrsCreditableService < 5 AND DSP.rcms_componentcategory_cd = 'TPU' AND DSP.MPC_CD = 'O' THEN 0
				WHEN DSP.YrsCreditableService < 5 AND DSP.rcms_componentcategory_cd IN ('AGR','TPU') AND DSP.MPC_CD = 'E' THEN 0
				ELSE NULL END AS SJA_Board
		,CASE WHEN DSP.YrsCreditableService between 6 and 18 AND DSP.rcms_componentcategory_cd = 'AGR' AND DSP.MPC_CD = 'O' THEN 'SA delegated to DASA-RB'  
				WHEN DSP.YrsCreditableService between 5 and 18 AND DSP.rcms_componentcategory_cd = 'TPU' AND DSP.MPC_CD = 'O' THEN 'CG, USARC'
				WHEN DSP.YrsCreditableService between 6 and 18 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'E' THEN 'GO CDR w/legal advisor'
				WHEN DSP.YrsCreditableService between 18 and 20 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'O' THEN 'ASA (M&RA)'
				WHEN DSP.YrsCreditableService between 18 and 20 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'E' THEN 'ASA (M&RA)'
				WHEN DSP.YrsCreditableService >= 20 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'O' THEN 'AGR: DASA-RB TPU:CG, USARC'
				WHEN DSP.YrsCreditableService >= 20 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'E' THEN 'GO CDR w/legal advisor'
				WHEN DSP.YrsCreditableService < 6 AND DSP.rcms_componentcategory_cd = 'AGR' AND DSP.MPC_CD = 'O' Then 'SA delegated to DASA-RB'
				WHEN DSP.YrsCreditableService < 5 AND DSP.rcms_componentcategory_cd = 'TPU' AND DSP.MPC_CD = 'O' THEN 'CG, USARC'
				WHEN DSP.YrsCreditableService < 5 AND DSP.rcms_componentcategory_cd IN ('AGR','TPU') AND DSP.MPC_CD = 'E' THEN 'CG, USARC'
				WHEN  DSP.rcms_componentcategory_cd = 'IMA'  THEN 'IMA'
				ELSE NULL END AS Separation_authority
		,CASE WHEN DSP.YrsCreditableService between 6 and 18 AND DSP.rcms_componentcategory_cd = 'AGR' AND DSP.MPC_CD = 'O' THEN '14-18 months'  
				WHEN DSP.YrsCreditableService between 5 and 18 AND DSP.rcms_componentcategory_cd = 'TPU' AND DSP.MPC_CD = 'O' THEN '14-18 months'
				WHEN DSP.YrsCreditableService between 6 and 18 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'E' THEN '14-18 months'
				WHEN DSP.YrsCreditableService between 18 and 20 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'O' THEN '18-22 months'
				WHEN DSP.YrsCreditableService between 18 and 20 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'E' THEN '18-22 months'
				WHEN DSP.YrsCreditableService >= 20 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'O' THEN '14-18 months'
				WHEN DSP.YrsCreditableService >= 20 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'E' THEN '14-18 months'
				WHEN DSP.YrsCreditableService < 6 AND DSP.rcms_componentcategory_cd = 'AGR' AND DSP.MPC_CD = 'O' Then '6-9 months'
				WHEN DSP.YrsCreditableService < 5 AND DSP.rcms_componentcategory_cd = 'TPU' AND DSP.MPC_CD = 'O' THEN '6-9 months'
				WHEN DSP.YrsCreditableService < 5 AND DSP.rcms_componentcategory_cd IN ('AGR','TPU') AND DSP.MPC_CD = 'E' THEN '6-9 months'
				WHEN  DSP.rcms_componentcategory_cd = 'IMA'  THEN 'IMA'
				ELSE NULL END AS Separation_Timeline

		,CASE WHEN DSP.YrsCreditableService between 6 and 18 AND DSP.rcms_componentcategory_cd = 'AGR' AND DSP.MPC_CD = 'O' THEN 'N/A'  
				WHEN DSP.YrsCreditableService between 5 and 18 AND DSP.rcms_componentcategory_cd = 'TPU' AND DSP.MPC_CD = 'O' THEN 'N/A'
				WHEN DSP.YrsCreditableService between 6 and 18 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'E' THEN 'ASA (M&RA) with new notice under plenary authority'
				WHEN DSP.YrsCreditableService between 18 and 20 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'O' THEN 'N/A'
				WHEN DSP.YrsCreditableService between 18 and 20 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'E' THEN 'ASA (M&RA) with new notice under plenary authority'
				WHEN DSP.YrsCreditableService >= 20 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'O' THEN 'N/A'
				WHEN DSP.YrsCreditableService >= 20 AND DSP.rcms_componentcategory_cd in ('TPU', 'AGR') AND DSP.MPC_CD = 'E' THEN 'ASA (M&RA) with new notice under plenary authority'
				WHEN  DSP.rcms_componentcategory_cd = 'IMA'  THEN 'IMA'
				ELSE NULL END AS Separation_appeal_Auth
	--Demographics
		,Case when DSR.rcms_race_cd in ('B', 'J', 'O', 'S', 'Y') then 'Hispanic'
			when DSR.rcms_race_cd in ('C', 'K', 'P', 'T','R', 'Z')  then 'Am.Indian or Alaskan Native'
			when DSR.rcms_race_cd in ('3', '5',  'D', 'H', 'L', 'U','E', 'M', 'Q', 'V', 'W')  then 'Asian or Pacific Islander'
			when DSR.rcms_race_cd = 'A' then 'White'
			when DSR.rcms_race_cd = 'N' then 'Black'
			when DSR.rcms_race_cd = 'X' then 'Oth/Unk' 
			ELSE NULL end as 'Race'
		,DSR.rcms_DOB_DT as DOB
		,DATEDIFF (YY,DSR.rcms_DOB_DT,GetDate()) as AGE
		,CASE WHEN DATEDIFF (YY,DSR.rcms_DOB_DT,GetDate()) between 16 and 19   THEN '16-19'
			  WHEN DATEDIFF (YY,DSR.rcms_DOB_DT,GetDate()) between 20 AND 24  THEN '20-24'
			  WHEN DATEDIFF (YY,DSR.rcms_DOB_DT,GetDate()) between 25 AND 29  THEN '25-29'
			  WHEN DATEDIFF (YY,DSR.rcms_DOB_DT,GetDate()) between 30 AND 34  THEN '30-34' 
			  WHEN DATEDIFF (YY,DSR.rcms_DOB_DT,GetDate()) between 35 AND 39  THEN '35-39'
			  WHEN DATEDIFF (YY,DSR.rcms_DOB_DT,GetDate()) between 40 AND 44  THEN '40-44'
			  WHEN DATEDIFF (YY,DSR.rcms_DOB_DT,GetDate()) >45 THEN '45+'
			  WHEN DATEDIFF (YY,DSR.rcms_DOB_DT,GetDate()) IS NULL THEN 'Data Error'
			  ELSE NULL END AS Age_Grouping
	--Branch Infomation
		,isnull(DSP.PrimaryMOS_CD,'') as PMOS
		,left(DSP.PrimaryMOS_CD,2) as CMF
		,case when left(DSP.PrimaryMOS_CD,2) = 42 then 'Adjutant General' 
				when left(DSP.PrimaryMOS_CD,2) = 14 then 'Air Defense Artillery'
				when left(DSP.PrimaryMOS_CD,2) = 89 then 'Ammunition'
				when left(DSP.PrimaryMOS_CD,2) = 19 then 'Amor'
				when left(DSP.PrimaryMOS_CD,2) = 65 then 'Army Medical Specialist Corps'
				when left(DSP.PrimaryMOS_CD,2) = 66 then 'Army Nurse Corps'
				when left(DSP.PrimaryMOS_CD,2) = 15 then 'Aviation'
				when left(DSP.PrimaryMOS_CD,2) = 73 then 'Behavioral Sciences'
				when left(DSP.PrimaryMOS_CD,2) = 56 then 'Chaplain'
				when left(DSP.PrimaryMOS_CD,2) = 74 then 'CBRN'
				when left(DSP.PrimaryMOS_CD,2) = 38 then 'Civil Affairs'
				when left(DSP.PrimaryMOS_CD,2) in (00,01) then 'CMF Immaterial'
				when left(DSP.PrimaryMOS_CD,2) in (12,21) then 'Corps of Engineers'
				when left(DSP.PrimaryMOS_CD,2) = 17 then 'Cyber'
				when left(DSP.PrimaryMOS_CD,2) = 63 then 'Dental Corps'
				when left(DSP.PrimaryMOS_CD,2) = 94 then 'Electronic Maintenance'
				when left(DSP.PrimaryMOS_CD,2) = 13 then 'Field Artillery'
				when left(DSP.PrimaryMOS_CD,2) in (36,44,36) then 'Financial Management'
				when left(DSP.PrimaryMOS_CD,2) = 50 then 'Force Management'
				when left(DSP.PrimaryMOS_CD,2) = 70 then 'Health Services'
				when left(DSP.PrimaryMOS_CD,2) = 11 then 'Infantry'
				when left(DSP.PrimaryMOS_CD,2) = 30 then 'Information Operations'
				when left(DSP.PrimaryMOS_CD,2) = 26 then 'Information Systems Engineer'
				when left(DSP.PrimaryMOS_CD,2) = 27 then 'Judge Advocate Generals Corps'
				when left(DSP.PrimaryMOS_CD,2) = 71 then 'Laboratory Sciences'
				when left(DSP.PrimaryMOS_CD,2) = 90 then 'Logistics'
				when left(DSP.PrimaryMOS_CD,2) in (91,63) then 'Mechanical Maintenance'
				when left(DSP.PrimaryMOS_CD,2) in (68,60,61,62,60,67) then 'Medical Corps'
				when left(DSP.PrimaryMOS_CD,2) = 35 then 'Military Intelligence'
				when left(DSP.PrimaryMOS_CD,2) = 31 then 'Military Police'
				when left(DSP.PrimaryMOS_CD,2) = 52 then 'Nuclear & Counterproliferation'
				when left(DSP.PrimaryMOS_CD,2) = 49 then 'Operations Research/Systems Analysis (ORSA)'
				when left(DSP.PrimaryMOS_CD,2) = 91 then 'Ordnance'
				when left(DSP.PrimaryMOS_CD,2) = 27 then 'Paralegal'
				when left(DSP.PrimaryMOS_CD,2) = 09 then 'Personnel Special Reporting Codes'
				when left(DSP.PrimaryMOS_CD,2) = 72 then 'Preventive Medicine Sciences'
				when left(DSP.PrimaryMOS_CD,2) = 37 then 'Psychological Operations'
				when left(DSP.PrimaryMOS_CD,2) = 46 then 'Public Affairs'
				when left(DSP.PrimaryMOS_CD,2) = 92 then 'Quartermaster Corps'
				when left(DSP.PrimaryMOS_CD,2) = 79 then 'Recruitment & Reenlistment'		
				when left(DSP.PrimaryMOS_CD,2) = 56 and DSP.MPC_CD = 'e' then 'Religious Support'
				when left(DSP.PrimaryMOS_CD,2) = 51 then 'Research, Development & Acquisition'
				when left(DSP.PrimaryMOS_CD,2) = 25 then 'Signal Corps'
				when left(DSP.PrimaryMOS_CD,2) = 57 then 'Simulations Operations'
				when left(DSP.PrimaryMOS_CD,2) = 40 then 'Space Operations'
				when left(DSP.PrimaryMOS_CD,2) = 18 then 'Special Forces'
				when left(DSP.PrimaryMOS_CD,2) = 34 then 'Strategic Intelligence'
				when left(DSP.PrimaryMOS_CD,2) = 59 then 'Strategist'
				when left(DSP.PrimaryMOS_CD,2) = 53 then 'Systems Automation Officer'
				when left(DSP.PrimaryMOS_CD,2) = 24 then 'Telecommunications Systems Engineers'
				when left(DSP.PrimaryMOS_CD,2) = 88 then 'Transportation Corps'
				when left(DSP.PrimaryMOS_CD,2) = 64 then 'Veterinary Corps'
				when left(DSP.PrimaryMOS_CD,2) = null then Null
				else left(DSP.PrimaryMOS_CD,2) end as Branch 
		,DSP.rcms_componentcategory_cd as RCC
	--MAVNAR and Pay information
		,DSP.PersonnelDeployabilityLimitation_CD as MVNAR
		,lkPDL.description as MVNAR_description
		,Isnull(PMARS.PMARS_NonPart_CNT,0) as Non_Part
		,Isnull(PMARS.PMARS_NPMonths_QY,0) as Non_part_months
		,DSP.TPC_CD as TrainingPayCat
		,lkTCP.Description as PayDescription
	--Unit Information
		,DUH.UPC_CD as UPC 
		,duh.rcms_UnitState_CD AS UnitST
		,DUH.MACOMUPC_NAME AS MACOM
		,DUH.OF1UPC_NAME AS 'MSC'
		,Duh.OF2UPC_NAME AS 'SubCMD'
		,Case when DUH.SUB1UPC_CD <> DUH.UPC_CD then DUH.SUB1UPC_NAME else NULL end AS'BDE_GP'
		,Case when DUH.SUB2UPC_CD <> DUH.UPC_CD then DUH.SUB2UPC_NAME else NULL end	AS 'BN_TRP'
		,(CASE WHEN DUH.rcms_UnitState_CD IN ('AE') THEN '7th MSC' 
					 WHEN DUH.rcms_UnitState_CD IN ('CT','DC','DE','MA','MD','ME','NH','NJ','NY','PA','RI','VA','VT','WV') THEN '99th RD'
					 WHEN DUH.rcms_UnitState_CD IN ('CO','IA','ID','IL','IN','KS','MI','MN','MO','MT','ND','NE','OH','OR','SD','UT','WA','WI','WY') THEN '88th RD'
					 WHEN DUH.rcms_UnitState_CD IN ('AK','AP','AS','GU','HI','MP') THEN '9th MSC'
					 WHEN DUH.rcms_UnitState_CD IN ('AL','FL','GA','KY','LA','MS','NC','SC','TN','VI') THEN '81st RD'
					 WHEN DUH.rcms_UnitState_CD IN ('AR','AZ','CA','NM','NV','OK','TX') THEN '63rd RD'
					 WHEN DUH.rcms_UnitState_CD IN ('PR') THEN '1st MSC'
					 WHEN DUH.rcms_UnitState_CD IN ('**','') THEN 
							(CASE WHEN DSR.HomeState_CD IN ('AE') THEN '7th MSC' 
								  WHEN DSR.HomeState_CD IN ('CT','DC','DE','MA','MD','ME','NH','NJ','NY','PA','RI','VA','VT','WV') THEN '99th RD'
								  WHEN DSR.HomeState_CD IN ('AK','AP','AS','GU','HI','MP') THEN '9th MSC'
								  WHEN DSR.HomeState_CD IN ('AL','FL','GA','KY','LA','MS','NC','SC','TN','VI') THEN '81st RD'
								  WHEN DSR.HomeState_CD IN ('AR','AZ','CA','NM','NV','OK','TX') THEN '63rd RD'
								  WHEN DSR.HomeState_CD IN ('PR') THEN '1st MSC' ELSE '88th RD' END)
					ELSE '88th RD' END) AS RD
		,DUH.Ed_UnitName as 'Unit_name'	
	
	INTO #TempSELRES

	FROM RCMSV3_DW.dbo.DimSoldierPersonnel DSP
		LEFT JOIN RCMSV3_DW_DP..DimSsnToEDIPIID DSE on DSE.SSNID = DSP.SSNID 
			AND DSE.Start_Dt <= @rdt 
			AND (DSE.End_DT > @rdt OR DSE.End_Dt IS NULL) 
		LEFT JOIN RCMSV3_DW.dbo.DimSoldierRestricted DSR on DSP.SoldierRestrictedID = DSR.ID 
			AND DSR.start_dt <= @rdt 
			AND  (DSR.End_DT is null or DSR.End_DT > @rdt)
		LEFT JOIN RCMSV3_DW.dbo.DimUnitHierarchies DUH on DSP.UPC_CD = DUH.UPC_CD 
			AND DUH.start_dt <= @rdt 
			AND  (DUH.End_DT is null or DUH.End_DT > @rdt) 
			AND DUH.Hierarchy_CD = 'OF10'	
		Left Join TCC_RCMSV3_DW_DP.dbo.FactSoldierPMARS PMARS on DSR.SSNID =PMARS.SSNID 
			AND Run_Dt = @EOMdt 
			AND PMARS_NonPart_CNT = 1

	--Look Up tables
		LEFT JOIN RCMSV3_LOOKUPS..Lkp_PersonnelDeployabilityLimitation_CD lkPDL on lkPDL.Code = DSP.PersonnelDeployabilityLimitation_CD
			 AND lkPDL.start_dt <= @rdt 
			 AND (lkPDL.End_DT is null or lkPDL.End_DT > @rdt)

		LEFT JOIN RCMSV3_LOOKUPS.dbo.Lkp_rcms_Race_CD lkRACE on lkRACE.code = DSR.rcms_Race_CD
			AND lkRACE.start_dt <= @rdt 
			 AND (lkRACE.End_DT is null or lkRACE.End_DT > @rdt)
		
		LEFT JOIN RCMSV3_LOOKUPS.dbo.Lkp_Ethnic_CD lkETH on lkETH.code = DSR.rcms_Ethnic_CD
			AND lkETH.start_dt <= @rdt 
			 AND (lkETH.End_DT is null or lkETH.End_DT > @rdt)

		LEFT JOIN RCMSV3_LOOKUPS.dbo.Lkp_CMF_CD lkCMF on (lkCMF.code = left(DSP.PrimaryMOS_CD,2) AND  lkCMF.MPC_CD = DSP.MPC_CD)
			AND lkCMF.start_dt <= @rdt
			AND (lkCMF.End_DT is null or lkCMF.End_DT > @rdt)

		LEFT JOIN RCMSV3_LOOKUPS.dbo.Lkp_TPC_CD lkTCP on (lkTCP.code = DSP.TPC_CD)
			AND lkTCP.start_dt <= @rdt
			AND (lkTCP.End_DT is null or lkTCP.End_DT > @rdt)


	where DSP.Start_DT<=@rdt and (DSP.End_DT is null or DSP.End_DT > @rdt) 
		and DSP.rcms_ComponentCategory_CD in ('TPU','AGR','IMA')
		--and DSE.DOD_EDI_PN_ID is not null


--MEDPROS & SELRES DATA IMPORT AND CLEANING
--When the MEDPROS Data is imported from vantage there are nearly 3000 soldiers without a DODID 
--TempSELRES has about 53 people who are missing DODI majority of these are those in training. 
-- The following steps 1) imports the Vantage data in to TempMEDPROs, 2) Checks the Selres to the medpros data to clean the 53 soldiers missing DODID approximatly 8 records are fixed, 3) Checks the Medpros data and recovers data for 1800 soldiers, 4) Creates a TempDODINULL which includes feilds to allow for rejoining to Tempcomplete 5) removes all soldiers with out a DODID from TempSELRES this is critical otherwise the NULLDODIC creates problems later in the code

--step 1) imports the Vantage data in to TempMEDPROs
	if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#tempMEDPRO')) drop table #tempMEDPRO
	Select *
	Into #tempMEDPRO
	From [RCMS_ORSA].[dbo].[COMPO 3 Vaccine Data20220609]

	-- TESTING FOR MEDPRO DATA

								/* 
								--179371

								Select  count(*) 
								from #tempMEDPRO
								--179371

								Select ISNULL(dod_edipi,'')
									, count(*) 
								from #tempMEDPRO group by ISNULL(dod_edipi,'') having count(*) > 1
								--There are no multiples except for blanks
								--1889
	
								Select Count(Distinct(name_individual))
								From #tempMEDPRO
								Where dod_edipi is null or  dod_edipi = ''

								Select count(*)
								--From #tempSELRES
								From #tempMEDPRO
								where name_individual = ''

								Select count(*)
								--From #tempSELRES
								From #tempMEDPRO
								Where dod_edipi is null or dod_edipi = ''



								-- This is just a test, remove it
								Select count(*) 
								from #tempMEDPRO MEDPRO
									left join #TempSELRES SELRES on SELRES.DODI = MEDPRO.dod_edipi and SELRES.DODI is not NULL and MEDPRO.dod_edipi <> ' '
								where SELRES.DODI is null --isnull(SELRES.DODI,'') = '' 
								--2752 number we can improve upon

								Select dod_edipi
									,DODI
									,MEDPRO.name_individual
									,Selres.FullName
								From #tempMEDPRO MEDPRO
								left join #TempSELRES SELRES on SELRES.DODI = MEDPRO.dod_edipi and SELRES.DODI is not NULL and MEDPRO.dod_edipi <> ' '
								where SELRES.DODI is null

								Select *
								from #tempMEDPRO 
								where dod_edipi = ''--in (1063125241,1464536058,1572749319)
								order by name_individual


								--1849 DODIDs replaced

								-- This is just a test remove it
								Select count(*) from #tempMEDPRO MEDPRO
								left join #TempSELRES SELRES on SELRES.DODI = MEDPRO.dod_edipi and SELRES.DODI is not NULL and MEDPRO.dod_edipi <> ' '
								where SELRES.DODI is null --isnull(SELRES.DODI,'') = '' --or ISNULL(COMPO3.dod_edipi,'') = ''
								--1011 remain missing.  1,849+903=2,752


								Select ISNULL(dod_edipi,'')
									, count(*) 
								from #tempMEDPRO group by ISNULL(dod_edipi,'') having count(*) > 1

								 select count(*) From #tempTEST
								--178576

								select count(*) From #tempAGG
								--178561
								*/
--step 2) Checks the Selres to the medpros data to clean the 53 soldiers missing DODID approximatly 8 records are fixed
	Update #tempSELRES
	set DODI = MEDPRO.dod_edipi
	From #TempSELRES SELRES
	-- first join is a hard join because you only need to keep people who match on name so you can use their DODID
	join #TempMEDPRO MEDPRO on ltrim(rtrim(SELRES.FullName)) = ltrim(rtrim(MEDPRO.name_individual)) and SELRES.Grade = MEDPRO.fms_rank_code and 'W'+SELRES.UPC = MEDPRO.uic
	-- next join is a left join because you will use the DODID from the match on name above to replace the existing bad DODI
	where SELRES.DODI is null and ISNULL(MEDPRO.dod_edipi,'') <> ''
--step 3) Checks the Medpros data and recovers data for 1800 soldiers
	Update #tempMEDPRO
	set dod_edipi = SELRES.DODI
	From #tempMEDPRO MEDPRO
	-- first join is a hard join because you only need to keep people who match on name so you can use their DODID
	join #TempSELRES SELRES on ltrim(rtrim(SELRES.FullName)) = ltrim(rtrim(MEDPRO.name_individual)) and SELRES.Grade = MEDPRO.fms_rank_code and 'W'+SELRES.UPC = MEDPRO.uic
	-- next join is a left join because you will use the DODID from the match on name above to replace the existing bad DODI
	left join #TempSELRES SELRESx on SELRESx.DODI = MEDPRO.dod_edipi and SELRESx.DODI is not NULL and MEDPRO.dod_edipi <> ' ' 
	where SELRESx.DODI is null and SELRES.DODI is not null

	
--Step 4) Creates a TempDODINULL which includes feilds to allow for rejoining to Tempcomplete
	if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#tempDODInull')) drop table #tempDODInull
	Select *
		,cast('' as VARCHAR (50)) as TrkStat 
		,Cast(0 as int) as PotLoss 
		,cast('' as VARCHAR (50)) as EPATStatus 
		,cast('' as VARCHAR (2)) as unvacpop 
		,cast('' as VARCHAR (2)) as partvacpop 
		,cast('' as VARCHAR (50)) as FY24R 
		,cast('' as VARCHAR (50)) as FY23R 
		,cast('' as VARCHAR (50)) as CdrNotes 
		,cast('' as VARCHAR (2)) as Refuse 
	into #tempDODInull
	from #TempSELRES
	where DODI is null

	
--Step 5) 5) removes all soldiers with out a DODID from TempSELRES this is critical otherwise the NULLDODIC creates problems later in the code
	Delete from #TempSELRES
	
	where DODI is null

--TESTING FOR TEMPNULL
					/*			
					select * From #tempDODInull
					select * from #TempSELRES
					where Non_Part <> 0
					*/

--TESTING FOR tempSELRES
					/*					
					Select * 
					From #TempSELRES
					where Grade_abbre in ('CDT','CSR')
					--Select count(*)
					--From #tempSELRES
					--where GradeAbbreviation_CD in ('CSR','CDT')

					Select Count(*)
					From #tempSELRES
					Where DODI is not null

					Select count(*)
					From #tempSELRES
					Where DODI is null 
					*/
--CREATES TempMILTECH
--This temp table contains information for those who are MILTECHS this will be joined to Tempagg
	if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#TempMILTEC')) drop table #TempMILTEC

	 select DSE.DOD_EDI_PN_ID as DODI
 		 ,dmt.TechnicianStatus_CD
		 ,dmt.PayPlan_CD
		 ,dmt.PayGradeLevel_CD
		,case when TechnicianStatus_CD = '1'  then 'MT1'
			when TechnicianStatus_CD = '2'  then 'MT2'
			when TechnicianStatus_CD = '3' THEN 'MT3'
			when TechnicianStatus_CD = '9'  then 'MT9' end as 'MILTech'
		,lkTS.Description
	INTO #TempMILTEC
	FROM RCMSV3_DW.dbo.DimMilTechs dmt
		LEFT JOIN RCMSV3_DW_DP..DimSsnToEDIPIID DSE on DSE.SSNID = DMT.SSNID 
			AND DSE.Start_Dt <= @rdt 
			AND (DSE.End_DT > @rdt OR DSE.End_Dt IS NULL) 

		Left Join RCMSV3_LOOKUPS.dbo.Lkp_TechnicianStatus_CD lkTS on lkTS.Code  = dmt.TechnicianStatus_CD
			AND lkTS.start_dt <= @rdt 
			AND (lkTS.End_DT is null or lkTS.End_DT > @rdt)

	Where TechnicianStatus_CD in ('1','2','3','9') and DSE.DOD_EDI_PN_ID is not null
			AND DMT.Start_Dt <= @rdt AND (DMT.End_DT > @rdt OR DMT.End_Dt IS NULL) 
  
 --Miltech TESTING
 /*
				  SELECT *
				  FROM #TempMILTEC
				  order by DODI
  
				  Select *
				  From RCMSV3_LOOKUPS.dbo.Lkp_TechnicianStatus_CD
  */

--TEMP A FLAGS
-- This code identifies all that have AFlags. This may be changes to also include Bflags as this project contuines
	if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#TempAFlagsONLY')) drop table #TempAFlagsONLY
	SELECT dse.DOD_EDI_PN_ID as DODID
		  ,DSR.FirstName As 'First_name'
		  ,DSR.LastName As 'Last_name'
		  ,DSR.FullName As 'Full_name'
		  ,RLASFLag_CD as 'A_flag'
		  ,DURF.RLASFlag_DT as 'A_Flag_dt'
		  ,lr.Description as 'Flag_Description'
		  ,AllRLASFlag_CD as 'All_Flags'
		  ,DUSRF.AllRLASFlag_TXT 'All_Flags_Desc'
		  ,DUSRF.MinRLASFlag_DT as 'Oldest_Flag_dt'
	INTO #TempAFlagsONLY	  

	  FROM TCC_RCMSV3_DW_DP.dbo.DimUnitRLASFlag DURF
		Left Join RCMSV3_DW.dbo.DimSoldierPersonnel DSP on DSP.SSNID = DURF.SSNID 
			and DSP.start_dt <= @rdt 
			and  (DSp.End_DT is null or DSP.End_DT > @rdt) 
		Left join rcmsv3_lookups.[dbo].[Lkp_SFPAReason_CD] lr on DURF.RLASFLag_CD = lr.code
			AND lr.End_DT is null
		left join RCMSV3_DW_DP..DimSsnToEDIPIID dse on dse.SSNID=dsp.SSNID 
			and dse.Start_Dt <= @rdt 
			AND (dse.End_DT > @rdt OR dse.End_Dt IS NULL)
		join RCMSV3_DW.dbo.DimSoldierRestricted DSR on dsp.SoldierRestrictedID=DSR.ID 
		left join RCMSV3_DW.dbo.DimUnithierarchies DUH ON DSP.UPC_CD = DUH.UPC_CD 
				and DUH.Hierarchy_CD = 'OF10' 
				AND DUH.Start_Dt <= @rdt AND (DUH.End_DT > @rdt OR DUH.End_Dt IS NULL)
		Left Join TCC_RCMSV3_DW_DP.dbo.DimUnitSoldierRLASFlag DUSRF on DUSRF.SSNID = DSP.SSNID 
			and DUSRF.start_dt <= @rdt 
			and  (DUSRF.End_DT is null or DUSRF.End_DT > @rdt) 

	  Where DURF.start_dt <= @rdt and (DURF.End_DT is null or DURF.end_dt >@rdt) And RLASFLag_CD = 'A' and DSE.DOD_EDI_PN_ID is not null
	  Order by DURF.RLASFlag_DT
--TESTING A FLAGS
					/*
					  Select Count(*)
					From #TempAFlagsONLY
					Where DODID is not null

					Select Count(*)
					From #TempAFlagsONLY
					Where DODID is null
					*/

--CREATES THE Epat DATA
-- EPAT data is pulled in live this means it will be current as of the data pull regardless of run date
-- This data however will have multiple entries for each DODID. Upon writing this code a soldier could have up to four different epat in different locations
-- to overcome this a n row partition was used in the creation of tempepatflat then data was matched to each dodid. TempEpatFlat will then be joioned to the tempagg
-- Steps 1) Intial data pull to create TempEpat
-- Steps 1) Intial data pull to create TempEpat, 2) Creation of tempEpatFlat to use N row partition
	if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#TempePAT')) drop table #TempePAT
	  Select --[a].Code [ActionCode], [a].[Description] [Action],
		dod.DOD_EDI_PN_ID [DODID]
		,c.[Code] [CaseCode]
		,sms.[Name] [CaseStatus]
		,[cr].[InitialRouteTo] as [InitiatorActionLocation]
		,[cr].[CurrentRouteTo] as [CurrentActionLocation]
		,isnull(ePatRole.RoleName,'Ua/Co/HHC') [CurrentActionLocationGroup]
		,[cda].[CreatedDt] as [CreatedDate]
		,[days].[DateSinceCreation] as [DayssinceCreation]
		,[days].[DateSinceLastTransition] as [DaysinQueue]
		,ROW_NUMBER() Over (partition by dod.DOD_EDI_PN_ID Order by [cda].[CreatedDt])as RN
	INTO #TempePAT
	From [RCMSV3_EACTIONS].[casemgr].[Case] [c]
 		INNER JOIN [RCMSV3_EACTIONS].[sm].[EntityStateMember] [esm] ON [c].CaseEntityStateMemberID = [esm].ID
		INNER JOIN [RCMSV3_EACTIONS].[sm].[StateMachineState] sms on sms.ID = esm.StateMachineStateID_Current
		INNER JOIN [RCMSV3_EACTIONS].[hrpass].[CaseDetailAttributes] [cda] ON [cda].caseid = [c].caseid
		INNER JOIN [RCMSV3_EACTIONS].[hrpass].[vw_CurrentInitialCaseRouting] [cr] ON [cda].caseid = [cr].CaseID
		INNER JOIN RCMSV3_EACTIONS.hrpass.DaysSinceCreationAndLastTransition [days] on [days].caseID = [c].CaseID
		LEFT JOIN RCMSV3_EACTIONS.hrpass.lkp_ActionType a on [cda].ActionTypeID = a.Id
		LEFT JOIN RCMSV3_DW_DP.dbo.DimSsnToEDIPIID dod on c.CaseTargetID = dod.SSNID
		LEFT JOIN RCMSV3_eActions.eActions.vw_eActionsePATRole ePatRole on ePatRole.ePATRoleID = cr.CurrentRouteToRole
	WHERE a.id = 390
--Testing Tempepat
									/* 
									Select * from #TempePAT order by DODID, RN
									*/
--Step2) Creation of tempEpatFlat to use N row partition
	if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#TempEpatFlat')) drop table #TempEpatFlat
	Create table #TempEpatFlat
		( DODID int not null
		,CaseCode_1 Varchar(50)  null
		,CaseStatus_1 Varchar(50)  null
		,InitiatorActionLocation_1 varchar(10) null 
		,CurrentActionLocation_1 varchar(10) null
		,CreatedDate_1 datetime2(7)  null
		,CurrentActionLocationGroup_1 varchar(100) Null 
		,DayssinceCreation_1 int null
		,DaysinQueue_1 int null
		,CaseCode_2 Varchar(50)  null
		,CaseStatus_2 Varchar(50)  null
		,InitiatorActionLocation_2 varchar(10) null
		,CurrentActionLocation_2 varchar(10) null
		,CreatedDate_2 datetime2(7) null
		,CurrentActionLocationGroup_2 varchar(100) Null
		,DayssinceCreation_2 int null
		,DaysinQueue_2 int null
		,CaseCode_3 Varchar(50)  null
		,CaseStatus_3 Varchar(50)  null
		,InitiatorActionLocation_3 varchar(10) null
		,CurrentActionLocation_3 varchar(10) null
		,CreatedDate_3 datetime2(7)  null
		,CurrentActionLocationGroup_3 varchar(100) Null
		,DayssinceCreation_3 int null
		,DaysinQueue_3 int  null
		,CaseCode_4 Varchar(50) null
		,CaseStatus_4 Varchar(50) null
		,InitiatorActionLocation_4 varchar(10) null 
		,CurrentActionLocation_4 varchar(10) null
		,CreatedDate_4 datetime2(7) null
		,CurrentActionLocationGroup_4 varchar(100) Null
		,DayssinceCreation_4 int null
		,DaysinQueue_4 int null
		)

	Insert into #TempEpatFlat
	(DODID)
	Select Distinct DODID from #TempePAT
	Where DODID is not null

	Update #TempEpatFlat
	Set CaseCode_1 = TE1.CaseCode
		,CaseStatus_1 = TE1.CaseStatus
		,InitiatorActionLocation_1 = TE1.InitiatorActionLocation
		,CurrentActionLocation_1 = TE1.CurrentActionLocation
		,CreatedDate_1 = TE1.CreatedDate
		,CurrentActionLocationGroup_1 = TE1.CurrentActionLocationGroup
		,DayssinceCreation_1 = TE1.DayssinceCreation
		,DaysinQueue_1 = TE1.DaysinQueue

	from #TempEpatFlat as TEF
		join #TempEpat TE1 on TEF.DODID = TE1.DODID and TE1.RN = 1


	Update #TempEpatFlat
	Set CaseCode_2 = TE2.CaseCode
		,CaseStatus_2 = TE2.CaseStatus
		,InitiatorActionLocation_2 = TE2.InitiatorActionLocation
		,CurrentActionLocation_2 = TE2.CurrentActionLocation
		,CreatedDate_2 = TE2.CreatedDate
		,CurrentActionLocationGroup_2 = TE2.CurrentActionLocationGroup
		,DayssinceCreation_2 = TE2.DayssinceCreation
		,DaysinQueue_2 = TE2.DaysinQueue
	from #TempEpatFlat as TEF
		join #TempEpat TE2 on TEF.DODID = TE2.DODID and TE2.RN = 2

	Update #TempEpatFlat
	Set CaseCode_3 = TE3.CaseCode
		,CaseStatus_3 = TE3.CaseStatus
		,InitiatorActionLocation_3 = TE3.InitiatorActionLocation
		,CurrentActionLocation_3 = TE3.CurrentActionLocation
		,CreatedDate_3 = TE3.CreatedDate
		,CurrentActionLocationGroup_3 = TE3.CurrentActionLocationGroup
		,DayssinceCreation_3 = TE3.DayssinceCreation
		,DaysinQueue_3 = TE3.DaysinQueue
	from #TempEpatFlat as TEF
		join #TempEpat TE3 on TEF.DODID = TE3.DODID and TE3.RN = 3

	Update #TempEpatFlat
	Set CaseCode_4 = TE4.CaseCode
		,CaseStatus_4 = TE4.CaseStatus
		,InitiatorActionLocation_4 = TE4.InitiatorActionLocation
		,CurrentActionLocation_4 = TE4.CurrentActionLocation
		,CreatedDate_4 = TE4.CreatedDate
		,CurrentActionLocationGroup_4 = TE4.CurrentActionLocationGroup
		,DayssinceCreation_4 = TE4.DayssinceCreation
		,DaysinQueue_4 = TE4.DaysinQueue
	from #TempEpatFlat as TEF
		join #TempEpat TE4 on TEF.DODID = TE4.DODID and TE4.RN = 4


--Testing epatflat		
							/*	
							
							  Select Count(*)
							From #TempEpatFlat
							Where DODID is not null

							Select Count(*)
							From #TempEpatFlat
							Where DODID is null
							*/

--Aggregating G1 data from the following tables; SELRES, AFlags, ePATflat, miltech


	if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#TempAGG')) drop table #TempAGG
	Select SELRES.DODI
		,SELRES.MPC
		,SELRES.Grade
		,selres.Grade_abbre
		,SELRES.LastName
		,Selres.FirstName
		,Selres.FullName
		,SELRES.Gender
		,SELRES.HOR_state
		,SELRES.ETS_Status
		,SELRES.ETSDATE
		,SELRES.ETS_MRDDATE
		,SELRES.PEBD_dt
		,SELRES.YRs_service
		,SELRES.Federal_service
		,SELRES.SJA_Board
		,SELRES.Separation_authority
		,SELRES.Separation_Timeline
		,SELRES.Separation_appeal_Auth
		,SELRES.Race
		,SELRES.DOB
		,SELRES.AGE
		,SELRES.Age_Grouping
		,SELRES.PMOS
		,Selres.CMF
		,SELRES.Branch
		,SELRES.RCC
		,SELRES.MVNAR
		,SELRES.MVNAR_description
		,SELRES.Non_Part
		,SELRES.Non_part_months
		,SELRES.TrainingPayCat
		,SELRES.PayDescription
		--Unit Information
		,SELRES.UPC 
		,SELRES.UnitST
		,SELRES.MACOM
		,SELRES.MSC
		,SELRES.SubCMD
		,SELRES.[BDE_GP]
		,SELRES.[BN_TRP]
		,SELRES.RD
		,SELRES.Unit_name
	
		--FLAG ONLY 
		,Aflagsonly.A_flag
		  ,Aflagsonly.A_Flag_dt
		  ,Aflagsonly.Flag_Description
		  ,Aflagsonly.All_Flags
		  ,Aflagsonly.All_Flags_Desc
		  ,Aflagsonly.Oldest_Flag_dt
		  --Epat
		  ,Epatflat.CaseCode_1 
		,Epatflat.CaseStatus_1 
		,Epatflat.InitiatorActionLocation_1 
		,Epatflat.CurrentActionLocation_1 
		,Epatflat.CreatedDate_1 
		,Epatflat.CurrentActionLocationGroup_1
		,Epatflat.DayssinceCreation_1
		,Epatflat.DaysinQueue_1 
		 ,Epatflat.CaseCode_2 
		,Epatflat.CaseStatus_2 
		,Epatflat.InitiatorActionLocation_2 
		,Epatflat.CurrentActionLocation_2 
		,Epatflat.CreatedDate_2
		,Epatflat.CurrentActionLocationGroup_2
		,Epatflat.DayssinceCreation_2
		,Epatflat.DaysinQueue_2
		 ,Epatflat.CaseCode_3 
		,Epatflat.CaseStatus_3 
		,Epatflat.InitiatorActionLocation_3 
		,Epatflat.CurrentActionLocation_3 
		,Epatflat.CreatedDate_3 
		,Epatflat.CurrentActionLocationGroup_3
		,Epatflat.DayssinceCreation_3
		,Epatflat.DaysinQueue_3
		 ,Epatflat.CaseCode_4 
		,Epatflat.CaseStatus_4 
		,Epatflat.InitiatorActionLocation_4 
		,Epatflat.CurrentActionLocation_4 
		,Epatflat.CreatedDate_4
		,Epatflat.CurrentActionLocationGroup_4
		,Epatflat.DayssinceCreation_4
		,Epatflat.DaysinQueue_4 
		,Case when Epatflat.CaseStatus_1 = 'Awaiting External Approval Authority Feedback' or Epatflat.CaseStatus_2 = 'Awaiting External Approval Authority Feedback' or Epatflat.CaseStatus_3 = 'Awaiting External Approval Authority Feedback' or Epatflat.CaseStatus_4 = 'Awaiting External Approval Authority Feedback' then 'Awaiting External Approval Authority Feedback' 
			
				when Epatflat.CaseStatus_1 ='In Progress' or Epatflat.CaseStatus_2 = 'In Progress' or Epatflat.CaseStatus_3 = 'In Progress' or Epatflat.CaseStatus_4 = 'In Progress' then 'In Progress' 				
				when Epatflat.CaseStatus_1 = 'Returned for Correction' or Epatflat.CaseStatus_2 ='Returned for Correction' or Epatflat.CaseStatus_3 = 'Returned for Correction' or Epatflat.CaseStatus_4 = 'Returned for Correction' Then 'Returned for Correction' 
						 
				when Epatflat.CaseStatus_1 = 'Initiated' or Epatflat.CaseStatus_2 = 'Initiated' or Epatflat.CaseStatus_3 = 'Initiated' or Epatflat.CaseStatus_4 = 'Initiated' THEN 'Initiated'  						
				when Epatflat.CaseStatus_1 in ('Closed','Canceled') or Epatflat.CaseStatus_2 in ('Closed','Canceled') or Epatflat.CaseStatus_3 in ('Closed','Canceled') or Epatflat.CaseStatus_4 in ('Closed','Canceled') Then 'Closed/Canceled' 
				else NULL end as 'EPAT_Status'
		,MILTEC.MILTech as MilTech
		,MILTEC.Description as MilTech_desc

	into #TempAGG
	From #TempSELRES SELRES
		Left Join #TempAFlagsONLY AFlagsONLY on AFLagsONLY.DODID = SELRES.DODI
		Left Join #TempEpatFlat EpatFlat on SELRES.DODI = EpatFlat.DODID
		left join #TempMILTEC MILTEC on MILTEC.DODI = SELRES.DODI


--Testing Temp AGG


											/*

											select count (*) 
										From #TempSELRES
										select count(*)
										from #tempAGG
											Select Count(Distinct (DODI))
										--From #TempSELRES
										From #tempAGG

										Select count(*)
										--From #tempSELRES
										From #tempAGG

										Select Count(*)
										--From #tempSELRES
										From #tempAGG
										Where DODI is not null


										Select count(*)
										--From #tempSELRES
										From #TempAGG
										Where DODI is null

										Select Count(*)
										from #TempePAT
										*/



 

--ARMMC DATA
--THis creates the temptable for the ARMMC DATA 
--When  importing this data set absolutly deleted unused feilds

		if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#tempARMMC')) drop table #tempARMMC
		Select
		(CASE WHEN (isnumeric(EDI) = 1) THEN CAST(EDI AS bigint) ELSE 0 END) AS EDI
			,[Status]
			INto #TempARMMC
			From [RCMS_ORSA].[dbo].[ARMMC COVID-19 Vaccine Exemption Tracker 20220609]
			where [status] <> '' or status not in ('Closed - Partially vaccinated', 'Expired - Partially vaccinated', 'Disapproved - vaccinate', 'Disapproved - Partially vaccinated', 'Closed - vaccinate', 'Fully vaccinated','Expired - vaccinate')

--TESTING FOR ARMMC DATA
							/* 
							Select distinct(status)
							From #TempARMMC */


--TEMPCTC creates a the infomation that will be used for the readiness analysis
--THIS DATA SET NEEDS A N ROW PARTION BECAUSE THERE ARE MULTIPLE ENTRIES FOR UIC

		if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#tempCTC')) drop table #tempCTC
		Select fy AS CTC_FY
			  ,[Event Name] as CTCEventName
			  ,[UIC] As CTC_UIC
			  ,[Unit Number] As CTC_Unit_name
			  ,[Unit Description] as CTC_Unit_des
			  ,[Event PAX Requirement] as CTC_Event_pax_req
			INto #TempCTC
			From RCMS_ORSA.dbo.COVID_CTC_23_24 CTC

--TEMPCDR brings in the data that has the commanders notes and joins on the DODID there have been instances of records not joining because of dublicates and not exsiting in the temp agg
		if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#tempCDR')) drop table #tempCDR
		Select[DODI] As DODI   
			  ,[CDR Notes] As CDR_Notes
		Into #tempCDR
		From [RCMS_ORSA].[dbo].[COL Wilkerson unknown breakout] 

--TEMPCOMPLETE is the Final aggregation of all above temptables this table will be uploaded to the standbox
		if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#tempComplete')) drop table #tempComplete
		Select
			AGG.*
			,ARMMC.Status as 'MED_exempt'
			,MEDPRO.name_individual
			,MEDPRO.vaccine_status
			,MEDPRO.first_shot_in_series
			,MEDPRO.date_of_most_recent_shot_in_series
			,MEDPRO.date_of_next_shot_due
			,MEDPRO.vaccine_series_name
			,MEDPRO.component as COMPO3COMPONENT --delete
			,MEDPRO.age_bracket --delete
			,MEDPRO.exception_code --delete
			,Case when vaccine_Status in ('Unvaccinated','Exempt (Permanent)', 'Exempt (Temporary)','', Null) then 1 else 0 end as 'unvac_pop'
			,Case when vaccine_Status in ( 'Partially Vaccinated - Overdue','Partially Vaccinated - Scheduled') then 1 else 0 end as 'partial_unvac_pop'
			,Case when (agg.grade_abbre in ('CSR','CDT') or agg.MVNAR = 'SM') then '1-Cadet'
				WHen ARMMC.Status in ('Approved','Approved (extended)','at RHC-A','at USARC','Disapproved - Appeal to OTSG','Returned - No medical') then '2-ME_exempt'
				when agg.EPAT_Status in ('Awaiting External Approval Authority Feedback','In Progress', 'Returned for Correction','Initiated') then '3-Religious_exemption'
				when (agg.A_flag = 'A') THEN  '4-A_flag'
				when agg.MVNAR = 'UP'  then '5-UNSAT' 
				When agg.MVNAR = 'TN'OR (agg.MVNAR = '' and agg.RCC = 'tpu')or agg.DODI in ('',null) then '6-Training'
				When agg.MVNAR in ('RT','LS') then '7-Retiring'
				when agg.MVNAR = 'ET' then '8-ETS Process'		
				When agg.MVNAR = 'LR' Then '9-Arrest And Confinement'
				when agg.MVNAR in ('LA','LD') Then '10-Pending Administrative/Legal Discharge or Separation'
				WHEN agg.MVNAR = 'AN' Then '11-Assigned/notjoined'
				When agg.DODI in ('',null) then '6-Training' --THIS IS NOT WORKING WITH
				When Agg.Non_Part > 0 then '12-NVP'
				else null end as   'USARC_Tracking_Status'	
			,Case when (agg.A_flag = 'A' or agg.MVNAR = 'UP') 
				AND ((agg.grade_abbre not IN ('CSR','CDT')or agg.MVNAR <> 'SM') OR agg.EPAT_Status NOT in ('Awaiting External Approval Authority Feedback','In Progress', 'Returned for Correction','Initiated'))  then 1 
				else 0 end as 'Pot_Loss'
			--,Case when  (AGG.MPC = 'e' and AGG.ETS_MRDDATE <= '20230930' and MEDPRO.vaccine_status in ('Unvaccinated','Exempt (Permanent)', 'Exempt (Temporary)','', Null)) then 1 else 0 end as ETS_Status --remove null id after you add tempdodinull WHY IS THIS NOT PULLING IN THE NULL VALUES
			,Case when ('W'+ Agg.upc) in ('W76DAA','W841AA','W85LAA','W866AA','W86FAA','W86VAA','W86XAA','W870AA','W87AAA','W87EAA','W88TAA','W8DJAA','W8G802','W8G804','W8HHAA','W8HNAA','W8J6AA','W8J8AA','W8KCAA','W950AA','W958AA','W95NAA','W969AA','W96DAA','W96FAA','W97JAA','WNBUAA','WNDXAA','WNGLAA','WNGMAA','WQ07AA','WQ1TAA','WQ5YAA','WQ62AA','WQ6BAA','WQ7VAA','WQ8BAA','WQ8ZAA','WQ92A1','WQ9DAA','WQ9TA2','WQ9ZAA','WQWQAA','WQWYAA','WQX7AA','WQXKAA','WQY8AA','WQZEAA','WR0RA1','WR0RA2','WR0RA4','WR75AA','WR7SAA','WR7TAA','WRBBAA','WRBMAA','WRBQAA','WRBTAA','WRC0AA','WRCEAA','WRCFAA','WRCMAA','WRDNAA','WRJAAA','WRN6A5','WRN7A1','WRN7A3','WRN7T1','WRNDAA','WRNGAA','WRR3AA','WRR7AA','WRRXAA','WRT2AA','WRT3AA','WRTUAA','WRUDAA','WRUFAA','WRUHAA','WRUVAA','WRVYAA','WRY7AA','WRZLAA','WRZMAA','WRZUAA','WS0AAA','WS1PAA','WS3KAA','WS46AA','WS50AA','WS6ZAA','WSBWAA','WSD5AA','WSKMAA','WSKTAA','WSLJAA','WSMDAA','WSNBT1','WSP3AA','WSP7AA','WSPZAA','WSQMAA','WSQQAA','WSRFAA','WSRUAA','WSTMA1','WSV8AA','WSX7AA','WSYDAA','WSYEAA','WSZ2AA','WSZ7AA','WTE3AA','WTE6AA','WTEHAA','WTFNAA','WTGMAA','WTK3A2','WTKPA1','WTKPT1','WTL1AA','WTL8A1','WTMDA1','WTTKAA','WTVCAA','WTWFA1','WTWFA3','WTWFA4','WTWFT1','WUA8AA','WV3FAA','WV4LAA','WV7BAA','WVDYAA','WVH0AA','WVHMAA','WVKAAA','WVLSAA','WVMGAA','WVPRAA','WVQ8A1','WVQ8A2','WVQDA3','WYATAA','WYBJAA','WYF6AA','WYGGAA','WYGZAA','WYSQAA','WZ2BAA','WZ2CAA','WZ2TAA','WZ3CFF','WZ57AA','WZ5BAA','WZ5DAA','WZ6AAA','WZ6FAA','WZ75FF','WZA8AA','WZAZAA','WZBHAA','WZD0AA','WZDMAA','WZDZAA','WZKHAA','WZKLAA','WZP4AA','WZPEA1','WZPEA2','WZPLAA','WZPOAA','WZTUAA','WZU3AA','WZU6AA','WZV2AA','WZVTAA','WZW3AA','WZW7AA','WZWAAA','WZWPAA','WZWTAA','WZWVAA','WZXBAA','WZXFAA','WZXPAA','WZZ1AA','WZZ6AA','WZZ9AA','WZZGAA','WZZHAA') then 'GFMAP_FY23' 
					WHEN 'W'+ Agg.upc in ('WS50AA','WV7BAA','WS46AA','WSRFAA','WS0AAA','WZD0AA','WZPLAA','WYGZAA','WZWVAA','WSZ7AA','WQ7VAA','WS6ZAA','WVHMAA','WVH0AA','WRNDAA','WRZLAA','WZ5DAA','WQY8AA','WSMDAA','WZ4GAA','WZW7AA','WZXBAA','WZXFAA','WVKAAA','WZV2AA') then 'CRF_FY23' else '' end as FY23_Readiness
			 ,Case when ('W'+Agg.upc) in ('WSH0AA','WZGAAA','WSQ4AA','WZBNAA','WR8QAA','WQ4PAA','WR0TA1','WR0TA2','WR0TA3','WR0TA4','WQ1VA2','WVDFAA','WVP5AA','WUA7AA','WSD7AA','WTEDAA','WS5JAA','WRJ4AA','WQWUAA','WSFSAA','WRJRAA','WZFJAA','WSKBAA','WQ7KA1','WSMVA1','WSMVT1','WSMXA1','WSMXT1','WZ4GAA','WQ28AA','WSP6AA','WQ1UAA','WS2EAA','WZYDAA','WZ4MAA','WZP7AA','W8DJAA','W8G806','WZTPAA','WQ7HAA','WSMEAA','WSSQAA','WRC4AA','WVK1AA','WRCNAA','WQ1VA5','WQWZA4','WRD4AA','WSCFAA','WZ4VAA','WZJKAA','WRA5AA','WRAZAA','WZW7AA','WSP8AA','WZ2EAA','WQ1VA6','WQ1VA3','WRZUAA','WSPPAA','WZYYAA','WS46AA','WS47AA','WRZNAA','WSAYAA','WSMXA2','WSMXA3','WZXBAA','WZXCAA','WQ1VA4','WZ3WAA','WRZKAA','WR0TA5','WRN6A1','WRQAA2','WSMVA2','WSMVA3','WQ4RAA','WRQAT1','WTK0A1','WRN6A2','WRQAA4','WQ0AAA','WRBUAA','WRZVAA','WRBHAA','WQ0BAA','WQ8XAA','WQZ7AA','WR0TA6','WZT1AA','WQ2EAA','WTHLAA','WTHMAA','WRQAA5','WQ2JAA','WQ0UAA','WQ6TAA','WS23A3','WYF8AA','WSK4AA','WTEAAA','WQ35AA','WS4XAA','WTE8AA','WRQAA3','WZJZAA','WZKUAA','WNGLAA','WRC6AA','WRZMAA','WZ6XAA','WZXFAA','WZBAAA','WZV2AA','WZ6AAA','WZ6FAA','W8JJAA','WZVPAA','WSRKAA','WNGMAA','WSQFAA','WSD0AA','WRJAAA','WV4LAA','W841AA','WRUVAA','WQ7XAA','WQ7KA5','WTGMAA','WQ58AA','WQ7YAA','WSTLA1','WS0WAA','WS2KAA','WQ1TAA','W7Z5AA','WSZGAA','WYGZAA','WNBUAA','WZ2FAA') then 'GFMAP_FY24'
					when ('W'+Agg.upc) in('WQ3KAA','WQ47AA','WYAEAA','WSXTAA','WRZPAA','WRCWAA','WRKLAA','WRZSAA','WZ3QAA','WSYVAA','WQWEAA','WZYZAA','WZFTAA','WZV9AA','WZVUAA','WZWVAA','WS11AA','WQ6FAA','WS0CAA','WS1KAA','WS1QAA','WSY9AA','WSZUAA','WQ3GAA','WS0KAA','WZPPAA','WQ0VAA','WVGQAA','WQ7DAA','WV8GAA','WRJHAA','WQ7VAA','WQ1FAA','WS63AA','WSBCAA','WYFUAA','WTTNAA','WSD1AA','WZXHAA','WZW6AA','WZXDAA','WQ4LAA','WZH0AA','WQ4EAA' )then 'CRF_FY24' else '' end as FY24_Readiness
			,CDR.CDR_Notes		
		INTO #tempComplete
		From #tempAgg AGG
			 left join #tempMEDPRO MEDPRO on agg.DODI = MEDPRO.dod_edipi and ISNULL(AGG.DODI,'') <> '' and ISNULL(MEDPRO.dod_edipi,'') <> ''	 
			 left join #TempARMMC ARMMC on ARMMC.EDI = AGG.DODI

			 Left Join #tempCDR CDR on CDR.DODI = AGG.DODI



		--READINESS TABLES FOR RFI
		if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#TEMPCriticalUICagg')) drop table #TEMPCriticalUICagg
		Select *
		INto #TEMPCriticalUICagg
		from #tempComplete 
		where ('W'+ upc) in ('W76DAA','W841AA','W85LAA','W866AA','W86FAA','W86VAA','W86XAA','W870AA','W87AAA','W87EAA','W88TAA','W8DJAA','W8G802','W8G804','W8HHAA','W8HNAA','W8J6AA','W8J8AA','W8KCAA','W950AA','W958AA','W95NAA','W969AA','W96DAA','W96FAA','W97JAA','WNBUAA','WNDXAA','WNGLAA','WNGMAA','WQ07AA','WQ1TAA','WQ5YAA','WQ62AA','WQ6BAA','WQ7VAA','WQ8BAA','WQ8ZAA','WQ92A1','WQ9DAA','WQ9TA2','WQ9ZAA','WQWQAA','WQWYAA','WQX7AA','WQXKAA','WQY8AA','WQZEAA','WR0RA1','WR0RA2','WR0RA4','WR75AA','WR7SAA','WR7TAA','WRBBAA','WRBMAA','WRBQAA','WRBTAA','WRC0AA','WRCEAA','WRCFAA','WRCMAA','WRDNAA','WRJAAA','WRN6A5','WRN7A1','WRN7A3','WRN7T1','WRNDAA','WRNGAA','WRR3AA','WRR7AA','WRRXAA','WRT2AA','WRT3AA','WRTUAA','WRUDAA','WRUFAA','WRUHAA','WRUVAA','WRVYAA','WRY7AA','WRZLAA','WRZMAA','WRZUAA','WS0AAA','WS1PAA','WS3KAA','WS46AA','WS50AA','WS6ZAA','WSBWAA','WSD5AA','WSKMAA','WSKTAA','WSLJAA','WSMDAA','WSNBT1','WSP3AA','WSP7AA','WSPZAA','WSQMAA','WSQQAA','WSRFAA','WSRUAA','WSTMA1','WSV8AA','WSX7AA','WSYDAA','WSYEAA','WSZ2AA','WSZ7AA','WTE3AA','WTE6AA','WTEHAA','WTFNAA','WTGMAA','WTK3A2','WTKPA1','WTKPT1','WTL1AA','WTL8A1','WTMDA1','WTTKAA','WTVCAA','WTWFA1','WTWFA3','WTWFA4','WTWFT1','WUA8AA','WV3FAA','WV4LAA','WV7BAA','WVDYAA','WVH0AA','WVHMAA','WVKAAA','WVLSAA','WVMGAA','WVPRAA','WVQ8A1','WVQ8A2','WVQDA3','WYATAA','WYBJAA','WYF6AA','WYGGAA','WYGZAA','WYSQAA','WZ2BAA','WZ2CAA','WZ2TAA','WZ3CFF','WZ57AA','WZ5BAA','WZ5DAA','WZ6AAA','WZ6FAA','WZ75FF','WZA8AA','WZAZAA','WZBHAA','WZD0AA','WZDMAA','WZDZAA','WZKHAA','WZKLAA','WZP4AA','WZPEA1','WZPEA2','WZPLAA','WZPOAA','WZTUAA','WZU3AA','WZU6AA','WZV2AA','WZVTAA','WZW3AA','WZW7AA','WZWAAA','WZWPAA','WZWTAA','WZWVAA','WZXBAA','WZXFAA','WZXPAA','WZZ1AA','WZZ6AA','WZZ9AA','WZZGAA','WZZHAA')

		Select UIC, total_pop, total_unvac, round((cast(total_unvac as float)/cast(total_pop as float)),1,1) as Unvac_per 
		From 
		(
			Select 'W'+ upc as UIC
				,Count(*) As Total_pop
				,sum(unvac_pop) as Total_unvac	
			From #TEMPCriticalUICagg
			Group by 'W'+ upc 
		) x

		if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#TEMPCriticalUICCRF_fy23')) drop table #TEMPCriticalUICCRF_fy23
		Select *
		INto #TEMPCriticalUICCRF_fy23
		from #tempComplete 
		where ('W'+ upc) in ('WS50AA','WV7BAA','WS46AA','WSRFAA','WS0AAA','WZD0AA','WZPLAA','WYGZAA','WZWVAA','WSZ7AA','WQ7VAA','WS6ZAA','WVHMAA','WVH0AA','WRNDAA','WRZLAA','WZ5DAA','WQY8AA','WSMDAA','WZ4GAA','WZW7AA','WZXBAA','WZXFAA','WVKAAA','WZV2AA')

		Select UIC, total_pop, total_unvac, round((cast(total_unvac as float)/cast(total_pop as float)),1,1) as Unvac_per 
		From 
		(
			Select 'W'+ upc as UIC
				,Count(*) As Total_pop
				,sum(unvac_pop) as Total_unvac	
			From #TEMPCriticalUICCRF_fy23
			Group by 'W'+ upc 
		) x

		if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#TEMPCriticalUICGFMAP_fy24')) drop table #TEMPCriticalUICGFMAP_FY24
		Select *
		INto #TEMPCriticalUICGFMAP_FY24
		from #tempComplete 
		where ('W'+ upc) in ('WSH0AA','WZGAAA','WSQ4AA','WZBNAA','WR8QAA','WQ4PAA','WR0TA1','WR0TA2','WR0TA3','WR0TA4','WQ1VA2','WVDFAA','WVP5AA','WUA7AA','WSD7AA','WTEDAA','WS5JAA','WRJ4AA','WQWUAA','WSFSAA','WRJRAA','WZFJAA','WSKBAA','WQ7KA1','WSMVA1','WSMVT1','WSMXA1','WSMXT1','WZ4GAA','WQ28AA','WSP6AA','WQ1UAA','WS2EAA','WZYDAA','WZ4MAA','WZP7AA','W8DJAA','W8G806','WZTPAA','WQ7HAA','WSMEAA','WSSQAA','WRC4AA','WVK1AA','WRCNAA','WQ1VA5','WQWZA4','WRD4AA','WSCFAA','WZ4VAA','WZJKAA','WRA5AA','WRAZAA','WZW7AA','WSP8AA','WZ2EAA','WQ1VA6','WQ1VA3','WRZUAA','WSPPAA','WZYYAA','WS46AA','WS47AA','WRZNAA','WSAYAA','WSMXA2','WSMXA3','WZXBAA','WZXCAA','WQ1VA4','WZ3WAA','WRZKAA','WR0TA5','WRN6A1','WRQAA2','WSMVA2','WSMVA3','WQ4RAA','WRQAT1','WTK0A1','WRN6A2','WRQAA4','WQ0AAA','WRBUAA','WRZVAA','WRBHAA','WQ0BAA','WQ8XAA','WQZ7AA','WR0TA6','WZT1AA','WQ2EAA','WTHLAA','WTHMAA','WRQAA5','WQ2JAA','WQ0UAA','WQ6TAA','WS23A3','WYF8AA','WSK4AA','WTEAAA','WQ35AA','WS4XAA','WTE8AA','WRQAA3','WZJZAA','WZKUAA','WNGLAA','WRC6AA','WRZMAA','WZ6XAA','WZXFAA','WZBAAA','WZV2AA','WZ6AAA','WZ6FAA','W8JJAA','WZVPAA','WSRKAA','WNGMAA','WSQFAA','WSD0AA','WRJAAA','WV4LAA','W841AA','WRUVAA','WQ7XAA','WQ7KA5','WTGMAA','WQ58AA','WQ7YAA','WSTLA1','WS0WAA','WS2KAA','WQ1TAA','W7Z5AA','WSZGAA','WYGZAA','WNBUAA','WZ2FAA') 

		Select UIC, total_pop, total_unvac, round((cast(total_unvac as float)/cast(total_pop as float)),1,1) as Unvac_per 
		From 
		(
			Select 'W'+ upc as UIC
				,Count(*) As Total_pop
				,sum(unvac_pop) as Total_unvac	
			From #TEMPCriticalUICGFMAP_FY24
			Group by 'W'+ upc 
		) x

		if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#TEMPCriticalUICCRF_FY24')) drop table #TEMPCriticalUICCRF_FY24
		Select *
		INto #TEMPCriticalUICCRF_FY24
		from #tempComplete 
		where ('W'+ upc) in ('WQ3KAA','WQ47AA','WYAEAA','WSXTAA','WRZPAA','WRCWAA','WRKLAA','WRZSAA','WZ3QAA','WSYVAA','WQWEAA','WZYZAA','WZFTAA','WZV9AA','WZVUAA','WZWVAA','WS11AA','WQ6FAA','WS0CAA','WS1KAA','WS1QAA','WSY9AA','WSZUAA','WQ3GAA','WS0KAA','WZPPAA','WQ0VAA','WVGQAA','WQ7DAA','WV8GAA','WRJHAA','WQ7VAA','WQ1FAA','WS63AA','WSBCAA','WYFUAA','WTTNAA','WSD1AA','WZXHAA','WZW6AA','WZXDAA','WQ4LAA','WZH0AA','WQ4EAA' )

		Select UIC, total_pop, total_unvac, round((cast(total_unvac as float)/cast(total_pop as float)),1,1) as Unvac_per 
		From 
		(
			Select 'W'+ upc as UIC
				,Count(*) As Total_pop
				,sum(unvac_pop) as Total_unvac	
			From #TEMPCriticalUICCRF_FY24
			Group by 'W'+ upc 
		) x
		select * from #tempComplete

		select count(*) from #tempComplete
		select count(*) from #tempDODInull
		select distinct dodi from #tempCDR



------------------------------------add column for USARC Tracking Status called TrkStat and Pot_Loss called PotLoss
--alter table #tempDODInull
--add
--TrkStat VARCHAR (50),
--PotLoss int,
--EPATStatus varchar(50)
--,unvacpop varchar(2)
--,partvacpop varchar(2)
--,FY24R varchar(50)
--,FY23R varchar(50)
--,CdrNotes varchar(50)
--,Refuse varchar(2)
----------------------------------assigned all SMs w/o DODID as part of Training bucket and not potential losses
UPDATE #tempDODInull
SET
TrkStat = '6-Training'
,PotLoss = 0
,EPATStatus =''
,unvacpop = 1
,partvacpop = 0
,FY24R = ''
,FY23R = ''
,CdrNotes =''
,Refuse = 1



--select count(*)
--from #tempDODInull
--------------------------------how to remove columns from an existing table-------------------------------------------------
--alter table #tempDODInull
--drop column
-- TrkStat
-- ,PotLoss
-- ,EPATStatus
-- ,unvacpop
-- ,partvacpop
--,FY24R 
--,FY23R 
--,CdrNotes 
--,Refuse 
---------------------------------ADD rows with blank DODI back into #tempComplete---------------------------------------------
insert into #TempComplete (
DODI, MPC, Grade, Grade_abbre, LastName, FirstName, FullName, Gender, HOR_state, ETS_Status, ETSDATE, ETS_MRDDATE, PEBD_dt
, YRs_service, Federal_service, SJA_Board, Separation_Timeline, Separation_authority, Separation_appeal_Auth
, Race, DOB, AGE, Age_Grouping, PMOS, CMF, Branch, RCC, MVNAR, MVNAR_description, UPC, UnitST, MACOM, MSC, SubCMD
, [BDE_GP], [BN_TRP], RD, Unit_name, Non_Part, Non_part_months
, USARC_Tracking_Status, Pot_Loss, EPAT_Status, unvac_pop, partial_unvac_pop, FY24_Readiness,FY23_Readiness--,refuser
)
select
DODI, MPC, Grade, Grade_abbre, LastName, FirstName, FullName, Gender, HOR_state, ETS_Status, ETSDATE, ETS_MRDDATE, PEBD_dt
, YRs_service, Federal_service, SJA_Board, Separation_Timeline, Separation_authority, Separation_appeal_Auth
, Race, DOB, AGE, Age_Grouping, PMOS, CMF, Branch, RCC, MVNAR, MVNAR_description, UPC, UnitST, MACOM, MSC, SubCMD
, [BDE_GP], [BN_TRP], RD, Unit_name, Non_Part, Non_part_months
,TrkStat, PotLoss, EPATStatus, unvacpop, partvacpop, fy24R, fy23R
from #tempDODInull


select *
from #tempComplete
where unvac_pop = 1 and USARC_Tracking_Status is null
and CDR_Notes is null
--and (CDR_Notes in ('CDR: A FLAG','CDR: RA','CDR: ME','CDR: No Comment'))


select count(*)
from #tempComplete
--where CDR_Notes is null and unvac_pop = 1 and 
where (USARC_Tracking_Status is null or USARC_Tracking_Status = ' ')

--ANSWERS RFIS
Select 
--BASIC query infomation
	(select count(*) FROM #tempComplete where DODI is not null ) as Total_pop	
	,(select count(*) FROM #tempDODInull where DODI is null ) as Null_pop
	,(select sum(unvac_pop) FROM #tempComplete where unvac_pop = 1) as unvacpopsum
	,(select sum(partial_unvac_pop) FROM #tempComplete where partial_unvac_pop = 1) as partialvacpopsum
	,(select count(*) FROM #tempComplete where partial_unvac_pop = 0 and unvac_pop = 0 ) as vacpopsum
	,(select AVG(AGE) from #tempcomplete WHERE unvac_pop =1) AS AVEAGE_AGE_UNVAC
	,(
		(SELECT MAX(AGE) FROM
		(SELECT TOP 50 PERCENT AGE FROM #tempComplete WHERE unvac_pop =1 ORDER BY AGE) AS BottomHalf)
	+
		(SELECT MIN(AGE) FROM
		(SELECT TOP 50 PERCENT AGE FROM #tempComplete WHERE unvac_pop =1 ORDER BY AGE DESC) AS TopHalf)
	) / 2 AS Median_AGE_UNVAC
	,(select count(*) from #tempComplete where (unvac_pop=1 and FY23_Readiness = 'GFMAP_FY23')) As UNVC_GFMAP_FY23
	,(select count(*) from #tempComplete where (unvac_pop=1 and FY23_Readiness = 'CRF_FY23')) As UNVC_CRF_FY23
	,(select count(*) from #tempComplete where (FY23_Readiness = 'GFMAP_FY23')) As total_GFMAP_FY23
	,(select count(*) from #tempComplete where (FY23_Readiness = 'CRF_FY23')) As Total_CRF_FY23

	,(select count(*) from #tempComplete where (unvac_pop=1 and FY23_Readiness = 'GFMAP_FY24')) As UNVC_GFMAP_FY24
	,(select count(*) from #tempComplete where (unvac_pop=1 and FY23_Readiness = 'CRF_FY24')) As UNVC_CRF_FY24
	,(select count(*) from #tempComplete where (FY24_Readiness = 'GFMAP_FY24')) As total_GFMAP_FY24
	,(select count(*) from #tempComplete where (FY24_Readiness = 'CRF_FY24')) As Total_CRF_FY24

	
--readiness

	
select count(*)
From #tempComplete COMPLETE
WHERE unvac_pop =1

select sum(unvac_pop) FROM #tempComplete where unvac_pop = 1



-- RUN THIS FOR THE FINAL TABLES--
Select sum(case when unvac_pop='1' then 1 else 0 end) as unvac
		,sum(case when partial_unvac_pop = 1 then 1 else 0 end) as partialvac
	,Sum(Case when unvac_pop = 1 and USARC_Tracking_Status = '4-A_flag' then 1 else 0 end) as testing1 --good
	 ,Sum(Case when unvac_pop = 1 and (USARC_Tracking_Status IS NULL and CDR_Notes in ('CDR: A FLAG','CDR: No Comment','','CDR: ME','CDR: RA',null)) then 1 else 0 end) as testing2
	,Sum(Case when (CDR_Notes in ('CDR: A FLAG','CDR: No Comment','','CDR: ME','CDR: RA',null)) then 1 else 0 end) as testing3
	,Sum(Case when (unvac_pop = 1 or partial_unvac_pop = 1) and ((USARC_Tracking_Status = '4-A_flag' ) or (unvac_pop = 1 and (USARC_Tracking_Status = null and CDR_Notes in ('CDR: A FLAG','CDR: No Comment','','CDR: ME','CDR: RA',null))))then 1 else 0 end) as refuser
From #tempComplete
	

Select count(*)
From #tempSELRES
where DODI is null  
--where vaccine_status <> 'Unvaccinated'

--where RCC='IMA' and (unvac_pop =1 or partial_unvac_pop =1)

Select *
From #tempDODInull INULL
select * 
From #tempDODInull INULL
  join #tempMEDPRO MEDPRO on ltrim(rtrim(INULL.FullName)) = ltrim(rtrim(MEDPRO.name_individual)) and 'w'+INULL.UPC = MEDPRO.uic and INULL.Grade=MEDPRO.fms_rank_code--and INULL.Grade = MEDPRO.fms_rank_code --and 'W'+INULL.UPC = MEDPRO.uic

-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
/*
add blank dodid records back into #tempcomplete

select count(*) from #TempSELRES
select count(*) from #tempDODInull
select count(*) from #tempComplete

select * from #tempDODInull

*/
------------------------------------Demographic Info



--count by catgories
Select
count(*) as Tot_Assigned
,count(case when unvac_pop = 1 then 1 end) as UnVac
,count(case when partial_unvac_pop = 1 then 1 end) as PartVac
,count(case when (unvac_pop = 0 and partial_unvac_pop = 0) then 1 end) as Vac --- doesn't work
from #tempComplete

select
Gender
,count(case when unvac_pop = 1 then 1 end) as UnVac
,count(case when unvac_pop = 0 or unvac_pop = 1 then 1 end) as USAR
--round((cast(total_unvac as float)/cast(total_pop as float)),1,1) as Unvac_per 
from #tempComplete
group by Gender
order by Gender

select
Grade
,count(case when unvac_pop = 1 then 1 end) as UnVac
,count(case when unvac_pop = 0 or unvac_pop = 1 then 1 end) as USAR
from #tempComplete
group by Grade
order by Grade

select
Race
,count(case when unvac_pop = 1 then 1 end) as UnVac
,count(case when unvac_pop = 0 or unvac_pop = 1 then 1 end) as USAR
from #tempComplete
group by Race
order by Race

select
age_bracket
,count(case when unvac_pop = 1 then 1 end) as UnVac
,count(case when unvac_pop = 0 or unvac_pop = 1 then 1 end) as USAR
from #tempComplete
group by age_bracket
order by age_bracket

select
HOR_state
,count(case when unvac_pop = 1 then 1 end) as UnVac
,count(case when unvac_pop = 0 or unvac_pop = 1 then 1 end) as USAR
from #tempComplete
group by HOR_state
order by HOR_state

select
Branch
,count(case when unvac_pop = 1 then 1 end) as UnVac
,count(case when unvac_pop = 0 or unvac_pop = 1 then 1 end) as USAR
from #tempComplete
group by Branch
order by Branch

select
MSC
,count(case when unvac_pop = 1 then 1 end) as UnVac
,count(case when unvac_pop = 0 or unvac_pop = 1 then 1 end) as USAR
from #tempComplete
group by MSC
order by MSC





