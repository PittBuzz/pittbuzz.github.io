/*------ Current Vacancies Query ------*/

select DVA.ID
,ISNULL(DUI.rcms_SRC,'') as SRC
,Left(DVA.UPC_CD,3) as UPC3
,DVA.[UPC_CD] as UPC
,Case When Left(DVA.UPC_CD,1) = '5' then 'Mob'
	  When Left(DVA.UPC_CD,1) = 'N' then 'BL'
	  When Left(DVA.UPC_CD,1) < '7'  or Left(DVA.UPC_CD,1) between 'A' and 'P' then 'AL'
	  Else 'BL' end as AL_BL -- above/below the line status of the vacancy
,ISNULL(DUH.OF1UPC_Name,'') as Command
,ISNULL(DUH.OF2UPC_Name,'') as BDE
,ISNULL(DUI.RCMS_UnitName,'') as UnitName
,ISNULL(DUH.rcms_UnitAddress,'') as UnitAddress
,ISNULL(DUH.rcms_UnitCity,'') as UnitCity
,ISNULL(DUH.rcms_UnitState_CD,'') as UnitState
,ISNULL(DUH.rcms_UnitZip_Cd,'') as UnitZip
,DVA.VacancyControlNumber as 'Vacancy Control Number'
,DVA.VacancyStatus_CD + ',' + VSC.Description as VacancyStatus
,DVA.VacancyOverFillReason_CD + ',' + VOF.Description as 'Vacancy Over Fill Reason'
,DVA.VacancyFreeze_CD
,DVA.GenderRequirement_CD as 'Gender Requirement'
,DVA.Paragraph
,DVA.Line
,DVA.MilitaryPositionNumber as POSN
,DVA.MPC_CD as MPC
,DVA.rcms_Grade_CD as Grade
,DVA.rcms_DutyMOS_CD as MOS
,DVA.rcms_DutyMOS_CD + ',' + MOS.Description as MOS_Desc
,ISNULL(DVA.ASI_CD + ',' + ASI.Description,'') as ASI
,ISNULL(DVA.SQI_CD + ',' + SQI.Description,'') as SQI
,ISNULL(DVA.Language_CD + ',' + LAN.Description,'') as Lang
,DVA.UnitTraining_CD as WillTrain


FROM
	[RCMSV3_DW].[dbo].[DimVacancyAdvertised] DVA
	Left join dbo.DimUnitHierarchies DUH on DVA.upc_cd = DUH.UPC_CD and DUH.End_DT is null  and DUH.Hierarchy_CD = 'OF10'
	Left Join dbo.DimUnitInfo DUI on DVA.UPC_CD = DUI.UPC_CD and DUI.End_DT is null
		Left Join RCMSV3_LOOKUPS.dbo.Lkp_TAPDB_MOSTBLE_Base MOS on DVA.rcms_DutyMOS_CD  = MOS.code and DVA.MPC_CD = MOS.PS_MPC_CD and MOS.End_DT is null
		Left Join RCMSV3_LOOKUPS.dbo.Lkp_ASI_CD_Base ASI on DVA.ASI_CD = ASI.Code AND DVA.MPC_CD = ASI.PS_MPC_CD  AND ASI.End_DT is NULL
		Left Join RCMSV3_LOOKUPS.dbo.Lkp_SQI_CD_Base SQI on DVA.SQI_CD = SQI.Code AND DVA.MPC_CD = SQI.PS_MPC_CD AND SQI.End_DT is NULL
		Left Join RCMSV3_LOOKUPS.dbo.Lkp_Language_CD_Base LAN on DVA.Language_CD = LAN.Code AND LAN.End_DT is null
		Left Join RCMSV3_LOOKUPS.dbo.Lkp_VacancyStatus_CD_Base VSC on DVA.VacancyStatus_CD = VSC.Code and VSC.End_DT is null
		Left Join RCMSV3_LOOKUPS.dbo.Lkp_VacancyOverFillReason_CD_Base VOF on DVA.VacancyOverFillReason_CD = VOF.Code and VOF.End_DT is null

WHERE DVA.[end_dt] is null
AND DVA.[VacancyPurge_DT] is null
AND DVA.[VacancyDelete_DT] is null 
