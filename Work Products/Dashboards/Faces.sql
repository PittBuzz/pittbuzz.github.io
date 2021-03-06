/*-----By name Soldier information with position info. Multiple calculated fields built into a Temp table---*/

Declare @rdt as datetime
set @rdt = '20211130'

SELECT SSNID
,SSN
,FullName
,Gender
,DOB
,Age
,RCC
,MPC
,Rank
,Grade
,DutyMOS
,PMOS
,PMOS_Desc
,DMOSQ
,DMOSQ_YN
,Skill_Level
,SMOS
,AMOS
,ASI
,ASI2
,SQI
,SQI2
,Clearance
,Language
,PEBD
,[Time in Service]
,[Time in Rank]
,ETS
,[MOs Until ETS]
,[ETS Eligible]
,[MRD Code]
,MRD
,[MOs Until MRD]
,[Last Mob DT]
,[Dwell Time]
,MILED
,MRCGO
,MRC3
,MRC4
,DRCGo
,DRC3
,DRC4
,"PHA>15 Mo"
,DLC1
,DLC2
,DLC3
,DLC4
,DLC5
,DLC6
,DLC7
,DEPL
,Flag
,Flag_YN
,UNSAT
,LTNP
,Available
,CivED
,HomeAddress
,HomeCity
,HomeState
,HomeZip
,HomePhone
,Email
,Email_Alt
,DistHometoUnit
,DistanceBins
,CMD_UPC
,Command
,UPC
,UIC
,AL_BL
,Unit
,UnitAddress
,UnitCity
,UnitState
,UnitZip
,TotalAsgAuthPsn
,Excess
,ASGN


INTO #SELRES --This is the output table the internal calcualtions and row partitions are below to prevent duplicates

FROM
	(SELECT DSP.SSNID 
	,SSN.SSN
	,DSP.rcms_ComponentCategory_CD as RCC
	,DSP.MPC_CD as MPC
	,DSP.GradeAbbreviation_CD as Rank
	,DSP.rcms_Grade_CD as Grade
	,Case When DSP.RCMS_Grade_CD >= 'E5'  then 1 else 0 end as SrGrd
	,Case When DSP.rcms_FirstTerm_YN = 1 then 1 else 0 end as FirstTerm
	,DSR.FullName
	,DSR.raw_Gender as Gender
	,DSR.rcms_DOB_DT as DOB
	,Case when Datepart(DY,DSR.rcms_dob_Dt) <= DATEPART(DY,@rdt) then DateDiff(YY,DSR.rcms_DOB_DT,@rdt)
		   when Datediff(YY,DSR.rcms_dob_Dt, DATEADD(yY,-1,@rdt) )= -1 then 0
		   else DateDiff(yy,DSR.rcms_dob_Dt,DateAdd(yy,-1,@rdt)) end as Age -- there is alternate age formula
	,DSP.rcms_PEBD_DT as PEBD
	,DATEDIFF (YY,dsp.rcms_pebd_dt,GetDate()) as [Time in Service] -- calculated in years
	,DSP.rcms_Rank_DT as DOR
	,DATEDIFF (MM,dsp.rcms_rank_dt,GetDate()) as [Time in Rank] -- calculated in months
	,ISNULL(DSP.MandatoryRemoval_CD + ' ' + MRD.Description,'') as [MRD Code]
	,Case When DSP.MandatoryRemoval_DT = '1900-01-01' then '' else DSP.MandatoryRemoval_DT end  as MRD
	,ISNULL(ABS(DATEDIFF (MM,dsp.MandatoryRemoval_DT,GetDate())),'') as [MOs Until MRD] -- calculated in months
	,Case When DSP.rcms_ETS_DT = '1900-01-01' then '' else DSP.rcms_ETS_DT end as ETS
	,ISNULL(ABS(DATEDIFF (MM,DSP.rcms_ETS_DT,GetDate())),'') as [MOs Until ETS] -- calculated in months
	,Case when DSP.PersonnelDeployabilityLimitation_CD  not in ('AN','AW', 'CO', 'CS', 'DP', 'DU', 'DL', 'LA', 'LD', 'LI', 'LR', 'LS', 'LZ', 'MP', 
                                                       'SD', 'SM', 'SS', 'TN', 'UP', 'EC', 'FP', 'PA', 'PD', 'PF') 
 		AND FSM.[SELRESDeploymentLimitingCatFY16_1_CNT] <> '1' --Temporary Profile Greater than 30 days
	    AND FSM.[SELRESDeploymentLimitingCatFY16_2_CNT] <> '1' --Dental Readiness Class 3
		AND FSM.[SELRESDeploymentLimitingCatFY16_3_CNT] <> '1' --Pregnancy
		AND FSM.[SELRESDeploymentLimitingCatFY16_4_CNT] <> '1' --Permanent Profile indicating MAR2 needed
		AND FSM.[SELRESDeploymentLimitingCatFY16_5_CNT] <> '1' --Permanent Profile indicating MEB needed
		AND FSM.[SELRESDeploymentLimitingCatFY16_6_CNT] <> '1' --Permanent Profile indicating non-duty related action needed
		AND FSM.[SELRESDeploymentLimitingCatFY16_7_CNT] <> '1' --Permanent Profile with a deployment/assignment restrction (F, V, or X)
	   	AND DSP.suspensionrsn_cd is null
		AND DSP.TwentyYrCertification_DT is null
       		AND DSP.rcms_Grade_CD in ('e4', 'e5', 'e6', 'e7') 
		AND DSP.rcms_ETS_DT between '20211001' and '20220930'
	   	AND DSP.rcms_PEBD_DT >= '20071001' then 1 else 0 end as "ETS Eligible"  -- Soldier Eligibility
	,Case When M.TourEnd_dt = '1900-01-01' then '' else M.TourEnd_dt end as [Last Mob DT]
	,ISNULL(DATEDIFF (MM,M.TourEnd_dt,GetDate()),'') as [Dwell Time] -- calcuated in months
	,ISNULL(DSP.MilitaryEducation_CD + ', ' + MIL.Description,'') as MILED
	,Left(DSP.rcms_DutyMOS_CD,3) as DutyMOS 
	,RTRIM(DSP.rcms_PrimaryMOS_CD) as PMOS
	,DSP.rcms_PrimaryMOS_CD + ', ' + MOS.Description  as PMOS_Desc
	,DSP.RCMS_DMOSQ_CD +', ' + DMQ.Description as DMOSQ 
	,Case when Left(DSP.RCMS_DMOSQ_CD,1) = 'Q' then 1 else 0 end as DMOSQ_YN
	,Case when FRP.Assigned_CNT = 1 and Left(DSP.RCMS_DMOSQ_CD,1) = 'Q' and FRP.Required_CNT = 1 then 1 else 0 end as DMOSQinReqPsn
	,ISNULL(DSP.PrimarySkillLevel_CD,'') as Skill_Level
	,ISNULL(DSP.rcms_SecondaryMOS_CD,'') as SMOS
	,ISNULL(DSP.rcms_AdditionalMOS_CD,'') as AMOS
	,ISNULL(DSP.PrimaryASI_CD + ', ' + ASI.Description,'') as ASI
	,ISNULL(DSP.SecondaryASI_CD,'') as ASI2
	,ISNULL(DSP.PrimarySQI_CD + ', ' + SQI.Description,'')  as SQI
	,ISNULL(DSP.SecondarySQI_CD,'') as SQI2
	,ISNULL(DSP.Language_CD + ', ' + LAN.Description,'') as Language 
	,DSP.SecurityClearance_CD +', ' + SEC.Description  as Clearance  
	,Case When FSM.MODSAdjusted_CNT>0 and FSM.MRC_CD in ( '1' , '2') Then FSM.MODSAdjusted_CNT Else 0 End as MRCGo
	,Case When FSM.MODSAdjusted_CNT>0 and FSM.MRC_CD = '3' Then FSM.MODSAdjusted_CNT Else 0 End as MRC3
	,Case When FSM.MODSAdjusted_CNT>0 and FSM.MRC_CD = '4' Then FSM.MODSAdjusted_CNT Else 0 End as MRC4
	,Case When FSM.MODSAdjusted_CNT>0 and FSM.DentalClass_CD in ( '1' , '2') Then FSM.MODSAdjusted_CNT Else 0 End as DRCGo
	,Case When FSM.MODSAdjusted_CNT>0 and FSM.DentalClass_CD = '3' Then FSM.MODSAdjusted_CNT Else 0 End as DRC3
	,Case When FSM.MODSAdjusted_CNT>0 and FSM.DentalClass_CD = '4' Then FSM.MODSAdjusted_CNT Else 0 End as DRC4
	,Case When FSM.MODSAdjusted_CNT>0 and FSM.PHYSState_CD = 'O' Then FSM.MODSAdjusted_CNT Else 0 End as "PHA>15 Mo"
	,Case When fsm.SELRESDeploymentLimitingCatFY16_1_CNT >0 then fsm.SELRESDeploymentLimitingCatFY16_1_CNT else 0 End as DLC1
    ,Case When fsm.SELRESDeploymentLimitingCatFY16_2_CNT >0 then fsm.SELRESDeploymentLimitingCatFY16_2_CNT else 0 End as DLC2
    ,Case When fsm.SELRESDeploymentLimitingCatFY16_3_CNT >0 then fsm.SELRESDeploymentLimitingCatFY16_3_CNT else 0 End as DLC3
	,Case When fsm.SELRESDeploymentLimitingCatFY16_4_CNT >0 then fsm.SELRESDeploymentLimitingCatFY16_4_CNT else 0 End as DLC4
	,Case When fsm.SELRESDeploymentLimitingCatFY16_5_CNT >0 then fsm.SELRESDeploymentLimitingCatFY16_5_CNT else 0 End as DLC5
	,Case When fsm.SELRESDeploymentLimitingCatFY16_6_CNT >0 then fsm.SELRESDeploymentLimitingCatFY16_6_CNT else 0 End as DLC6
	,Case When fsm.SELRESDeploymentLimitingCatFY16_7_CNT >0 then fsm.SELRESDeploymentLimitingCatFY16_7_CNT else 0 End as DLC7
	,DSP.PersonnelDeployabilityLimitation_CD + ' ' + DPL.Description as DEPL
	,ISNULL(DSP.SuspensionRsn_CD + ' ' + SPA.Description,'') as Flag
	,Case When DSP.SuspensionRsn_CD is not null then 1 else 0 End as Flag_YN
	,Case When NP.MonthsWithoutPay_QY >= 12 then 1 else 0 end as LTNP 
	,Case When UN.ADARSUnsatparticipant_CNT =1 then 1 else 0 end as UNSAT 
	,Case when fsm.MODSAdjusted_CNT>0 and fsm.MRC_CD = '3' and FSM.CombatDeferment_YN = 'N' and fsm.SELRESDeploymentLimitingCatFY16_2_CNT>0 or fsm.SELRESDeploymentLimitingCatFY16_3_CNT>0 or
						fsm.SELRESDeploymentLimitingCatFY16_4_CNT>0 or fsm.SELRESDeploymentLimitingCatFY16_5_CNT>0 or fsm.SELRESDeploymentLimitingCatFY16_6_CNT>0 or fsm.SELRESDeploymentLimitingCatFY16_7_CNT>0
						or DSP.PersonnelDeployabilityLimitation_CD in ('AN','AW','CC', 'CO', 'CS', 'DL', 'DP', 'DU', 'EC', 'FP', 'LA', 'LD', 'LI', 'LR', 'LS', 'LZ', 'MP', 'PA', 'PD', 'SD', 'SM', 'SS', 'TN', 'UP') 
						or DSP.rcms_DMOSQ_CD in ('ND','NE','NF','NH','NJ','NN','NO','NP','NR', 'NT','NW')
						or fss.SuspensionRsn_CD like'%B%'or fss.SuspensionRsn_CD like '%W%' then 0 else 1 end as Available
	,CEI.SRB_CivEd_Level_CD  + ', ' + CIV.Description as CivED 
	,DSR.HomeAddress
	,DSR.HomeCity
	,DSR.HomeState_CD as HomeState
	,Left(DSR.HomeZip_CD, 5) + '-' + Right(DSR.HomeZip_CD, 4) as HomeZip
	,ISNULL(DSR.HomePhoneNumber, '') as HomePhone
	,ISNULL(DSR.Email, '') as Email
	,ISNULL(DSR.Email_Alt, '') as Email_Alt
	,DUH.OF1UPC_CD as CMD_UPC
	,DUH.OF1UPC_NAME as Command
	,'W' + DUH.UPC_CD as UIC
	,DSP.UPC_CD as UPC
	,Case When Left(DSP.UPC_CD,1) = '5' then 'Mob'
		  When Left(DSP.UPC_CD,1) = 'N' then 'BL'
		  When Left(DSP.UPC_CD,1) < '7'  or Left(DSP.UPC_CD,1) between 'A' and 'P' then 'AL'
		  Else 'BL' end as AL_BL -- position above or below the line
	,DUH.rcms_UnitName as Unit
	,DUH.rcms_UnitAddress as UnitAddress
	,DUH.rcms_UnitCity as UnitCity
	,DUH.rcms_UnitState_CD as UnitState
	,DUH.rcms_UnitZip_Cd as UnitZip
	,DSR.DistanceFromHomeToUnit as DistHometoUnit
	,case when DSR.DistanceFromHomeToUnit <= 50 then '<= 50 miles'
		when DSR.DistanceFromHomeToUnit <= 75 then '51 to 75 miles'
		when DSR.DistanceFromHomeToUnit <= 100 then '76 to 100 miles'
		else 'Over 100 miles'  
		end as DistanceBins -- unit to Soldier distance bins
	,Case when FRP.Assigned_CNT = 1 and FRP.Required_CNT = 1 then 1 else 0 end as TotalAsgAuthPsn
	,Case when FRP.Assigned_CNT = 1 and FRP.Required_CNT = 0 then 1 else 0 end as Excess
	,Case when DSP.SSNID is not null then 1 else 0 end as ASGN
	,Row_Number() over(partition by dsp.ssnid order by DSP.MilitaryEducation_CD desc) as RN

	FROM [RCMSV3_DW].[dbo].DimSoldierPersonnel DSP
	Left Join RCMSV3_DW.dbo.FactReservePosition FRP on DSP.ID = FRP.SoldierID and FRP.Run_Dt = @rdt
	Left Join RCMSV3_DW.dbo.DimSSN SSN on DSP.SSNID = SSN.ID
	Left Join RCMSV3_DW.dbo.DimSoldierRestricted DSR on DSP.SoldierRestrictedID = DSR.ID AND DSR.Start_DT <= @rdt AND  (DSR.End_DT > @rdt or DSR.End_DT is null)
	Left Join RCMSV3_DW.dbo.DimReserveTourMobilization M on dsp.ssnid = M.ssnid 
	Left Join RCMSV3_DW.dbo.DimUnitHierarchies DUH on DSP.UPC_CD = DUH.UPC_CD AND DUH.Start_Dt < @rdt AND (DUH.End_Dt >= @rdt or DUH.End_DT is null) AND DUH.Hierarchy_CD = 'OF10'
	left join RCMSV3_DW.dbo.FactSelResMedical FSM on DSP.SSNID = FSM.SSNID and FSM.Run_Dt = @rdt
	left join RCMSV3_DW.dbo.FactNonParticipant NP on DSP.SSNID = NP.SSNID and NP.Run_DT = @rdt
    Left Join RCMSV3_DW.dbo.FactADARSUnsatisfactoryAttendance UN on DSP.SSNID = UN.SSNID and UN.Run_DT = @rdt
	Left Join RCMSV3_DW.dbo.FactSelresSFPA FSS on DSP.SSNID = FSS.SSNID and FSS.Run_DT = @rdt
	Left Join RCMSV3_DW.dbo.DimSRBCivilianEducation CEI on DSP.SSNID = CEI.SSNID AND CEI.Start_DT <= @rdt AND  (CEI.End_DT > @rdt or CEI.End_DT is null)
		Left Join RCMSV3_LOOKUPS.dbo.Lkp_MandatoryRemoval_CD MRD on DSP.MandatoryRemoval_CD = MRD.Code and MRD.End_DT is null
		Left Join RCMSV3_LOOKUPS.[dbo].[Lkp_PersonnelDeployabilityLimitation_CD] DPL on DSP.PersonnelDeployabilityLimitation_CD = DPL.Code and DPL.End_DT is null
		Left Join RCMSV3_LOOKUPS.[dbo].[Lkp_SFPAReason_CD] SPA on DSP.SuspensionRsn_CD = SPA.Code and SPA.End_DT is null
		Left Join RCMSV3_LOOKUPS.[dbo].[Lkp_TAPDB_MOSTBLE_Base] MOS on DSP.rcms_primarymos_cd = mos.code and DSP.mpc_cd = MOS.MPC_CD and MOS.End_DT is null
		Left Join RCMSV3_LOOKUPS.dbo.Lkp_CIV_ED_DSG_CD CIV on CEI.SRB_CivEd_Level_CD = CIV.Code AND CIV.End_DT is null
		Left Join RCMSV3_LOOKUPS.dbo.Lkp_MilitaryEducation_CD MIL on DSP.MilitaryEducation_CD = MIL.Code and MIL.End_DT is null
		Left Join RCMSV3_LOOKUPS.dbo.Lkp_Language_CD_Base LAN on DSP.Language_CD = LAN.Code AND LAN.End_DT is null
		Left Join RCMSV3_LOOKUPS.dbo.Lkp_rcms_DMOSQ_CD DMQ on DSP.RCMS_DMOSQ_CD = DMQ.Code AND DMQ.End_DT is NULL
		Left Join RCMSV3_LOOKUPS.dbo.Lkp_SecurityClearance_CD SEC on DSP.SecurityClearance_CD = SEC.Code AND SEC.End_DT is NULL
		Left Join RCMSV3_LOOKUPS.dbo.Lkp_SQI_CD_Base SQI on DSP.PrimarySQI_CD = SQI.Code AND DSP.MPC_CD = SQI.MPC_CD AND SQI.End_DT is NULL
		Left Join RCMSV3_LOOKUPS.dbo.Lkp_ASI_CD_Base ASI on DSP.PrimaryASI_CD = ASI.Code AND DSP.MPC_CD = ASI.MPC_CD AND ASI.End_DT is NULL

	WHERE DSP.Start_DT <= @rdt AND  (DSP.End_DT > @rdt or DSP.End_DT is null)
	AND  DSP.rcms_ComponentCategory_CD in ('TPU','AGR','IMA') -- = 'TPU' switch from SELRES to TPU

)x

WHERE RN = 1

SELECT *
FROM #SELRES

DROP TABLE #SELRES


