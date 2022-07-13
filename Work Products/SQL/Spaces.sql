/* -----This provides a by position table for all USAR positions and includes tertiary Soldier data---*/

DECLARE @rdt date
SET @rdt = '20220121'
  
Select ISNULL(FRP.SSNID,'') as SSNID
,ISNULL(DUI.rcms_SRC,'') as SRC
,Left (FRP.UPC_CD,3) as UPC3
,FRP.UPC_CD as UPC
,Case When Left(FRP.UPC_CD,1) = '5' then 'Mob'
	  When Left(FRP.UPC_CD,1) = 'N' then 'BL'
	  When Left(FRP.UPC_CD,1) < '7'  or Left(FRP.UPC_CD,1) between 'A' and 'P' then 'AL'
	  Else 'BL' end as AL_BL -- determines if the position is Above the Line, Below the Line, or a mobilization slot
,DUI.RCMS_UnitName as UnitName
,DUH.OF1UPC_Name as Command
,DUH.OF2UPC_Name as BDE
,DUH.rcms_UnitAddress as UnitAddress
,DUH.rcms_UnitCity as UnitCity
,DUH.rcms_UnitState_CD as UnitState
,DUH.rcms_UnitZip_Cd as UnitZip
,FRP.PositionAuthorized_CNT as AUTH
,FRP.PositionRequired_CNT as REQ
,FRP.PositionSoldierAssigned_CNT as ASGN
,FRP.AssignedStructuredPosition_CNT as Slotted
,FRP.AssignedNotInRequiredPosition_CNT as Excess
,FRP.PositionDoubleSlotted_CNT as DblSlot
,DRP.PS_RCMS_ComponentCategory_CD as POS_RCC
,FRP.TPU_CNT
,FRP.AGR_CNT
,FRP.IMA_CNT
,FRP.SELRES_CNT
,DRP.PositionMPC_CD as POS_MPC
,DRP.ID
,DRP.Paragraph as Para
,DRP.Line
,DRP.PositionNumber as Number
,DRP.PositionTitle as POS_Title
,DRP.PositionGrade_CD as POS_Grade
,DRP.RCMS_PositionGradeGroup_CD as POS_GRDPlate
,DRP.RCMS_PositionMOS_CD as POS_MOS
,ISNULL(DRP.RCMS_PositionMOS_CD + ', ' + MOS.Description,'') as POS_MOS_Desc
,DRP.RCMS_PositionLongDutyMOS_CD as POS_Long_MOS
,ISNULL(DRP.PositionASI_CD + ', ' + ASI.Description,'') as POS_ASI
,ISNULL(DRP.RCMS_PositionSQI_CD + ', ' + SQI.Description,'') as POS_SQI
,ISNULL(DRP.PositionLIC_CD + ', ' + LAN.Description,'') as POS_Lang


From FactSelResPosition FRP
  Join DimSelResPosition DRP on FRP.SelResPositionID = DRP.ID
  Left Join dbo.DimUnitHierarchies DUH on DRP.upc_cd = DUH.UPC_CD and DUH.End_DT is null  and DUH.Hierarchy_CD = 'OF10'
  Left Join dbo.DimUnitInfo DUI on DRP.UPC_CD = DUI.UPC_CD and DUI.End_DT is null
	Left Join RCMSV3_LOOKUPS.dbo.Lkp_TAPDB_MOSTBLE_Base MOS on DRP.RCMS_PositionMOS_CD = mos.code and DRP.PositionMPC_CD = MOS.PS_MPC_CD and MOS.End_DT is null
	Left Join RCMSV3_LOOKUPS.dbo.Lkp_ASI_CD_Base ASI on DRP.PositionASI_CD = ASI.Code AND DRP.PositionMPC_CD = ASI.PS_MPC_CD  AND ASI.End_DT is NULL
	Left Join RCMSV3_LOOKUPS.dbo.Lkp_SQI_CD_Base SQI on DRP.RCMS_PositionSQI_CD = SQI.Code AND DRP.PositionMPC_CD = SQI.PS_MPC_CD AND SQI.End_DT is NULL
	Left Join RCMSV3_LOOKUPS.dbo.Lkp_Language_CD_Base LAN on DRP.PositionLIC_CD = LAN.Code AND LAN.End_DT is null

where FRP.Run_Dt = @rdt 

