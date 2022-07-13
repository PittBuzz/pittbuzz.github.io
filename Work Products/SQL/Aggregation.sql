--THis is the Aggregation filr
-- At this time SELRES is the base files that will have left join Aflagsonly and left join epat
--testing is located at the bottom of the file


declare @rdt as datetime
set @rdt = '20220524'
--declare @rdt date = dateadd(weekday, -1*(datepart(WEEKDAY,getdate()+1)), getdate()) ---gets previous fridays data

if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#TempSELRES')) drop table #TempSELRES
SELECT
	--Personel Information
	 DSE.DOD_EDI_PN_ID as DODI
	,DSP.MPC_CD as MPC
	,DSP.rcms_grade_cd as Grade
	,DSR.LastName as LastName
	,DSR.FirstName as FirstName
	,DSR.FullName as FullName
	,DSR.rcms_Gender_CD as Gender
	,DSP.rcms_PEBD_DT as PEBD_dt
	,DATEDIFF(YY,DSP.rcms_pebd_dt,GetDate()) as 'YRs_service'
	,CASE WHEN DATEDIFF(YY,DSP.rcms_pebd_dt,GetDate())>=6 AND DSP.rcms_componentcategory_cd = 'AGR' AND DSP.MPC_CD = 'O' THEN 1  
		   WHEN DATEDIFF(YY,DSP.rcms_pebd_dt,GetDate()) >=5  AND DSP.rcms_componentcategory_cd = 'TPU' AND DSP.MPC_CD = 'O' THEN 1
		   WHEN DATEDIFF(YY,DSP.rcms_pebd_dt,GetDate()) >=6  AND DSP.rcms_componentcategory_cd = 'AGR' AND DSP.MPC_CD = 'E' THEN 1
		   WHEN DATEDIFF(YY,DSP.rcms_pebd_dt,GetDate()) >=5  AND DSP.rcms_componentcategory_cd = 'TPU' AND DSP.MPC_CD = 'E' THEN 1
		   ELSE 0 END AS [SJA_Board]
	,DSR.rcms_Ethnic_CD as Ethnic
	,lkETH.Description as Ethnic_Description
	,DSR.rcms_Race_CD as Race
	,lkRACE.Description as Race_Description
	,DSR.rcms_DOB_DT as DOB
	,isnull(DSP.PrimaryMOS_CD,'') as PMOS
	,DSP.rcms_componentcategory_cd as RCC
	,DSP.PersonnelDeployabilityLimitation_CD as MVNAR
	,lkPDL.description as MVNAR_description
	--Unit Information
	,DUH.UPC_CD as UPC 
	,DUH.MACOMUPC_NAME AS MACOM
	,DUH.OF1UPC_NAME AS 'MSC'
	,Duh.OF2UPC_NAME AS 'SubCMD'
	,Case when DUH.SUB1UPC_CD <> DUH.UPC_CD then DUH.SUB1UPC_NAME else '' end AS'BDE/GP'
	,Case when DUH.SUB2UPC_CD <> DUH.UPC_CD then DUH.SUB2UPC_NAME else '' end	AS 'BN/TRP'
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
	LEFT JOIN DimUnitHierarchies DUH on DSP.UPC_CD = DUH.UPC_CD 
		AND DUH.start_dt <= @rdt 
		AND  (DUH.End_DT is null or DUH.End_DT > @rdt) 
		AND DUH.Hierarchy_CD = 'OF10'
	

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
		


where DSP.Start_DT<=@rdt and (DSP.End_DT is null or DSP.End_DT>@rdt) 
	and DSP.rcms_ComponentCategory_CD in ('TPU','AGR','IMA')
	and DSE.DOD_EDI_PN_ID is not null




Select *
From #tempSELRES


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

  FROM [TCC_RCMSV3_DW_DP].[dbo].[DimUnitRLASFlag] DURF
	Left Join DimSoldierPersonnel DSP on DSP.SSNID = DURF.SSNID 
		and DSP.start_dt <= @rdt 
		and  (DSp.End_DT is null or DSP.End_DT > @rdt) 
	Left join rcmsv3_lookups.[dbo].[Lkp_SFPAReason_CD] lr on DURF.RLASFLag_CD = lr.code
		AND lr.End_DT is null
	left join RCMSV3_DW_DP..DimSsnToEDIPIID dse on dse.SSNID=dsp.SSNID 
		and dse.Start_Dt <= @rdt 
		AND (dse.End_DT > @rdt OR dse.End_Dt IS NULL)
	join DimSoldierRestricted DSR on dsp.SoldierRestrictedID=DSR.ID 
	left join DimUnithierarchies DUH ON DSP.UPC_CD = DUH.UPC_CD 
			and DUH.Hierarchy_CD = 'OF10' 
			AND DUH.Start_Dt <= @rdt AND (DUH.End_DT > @rdt OR DUH.End_Dt IS NULL)
	Left Join TCC_RCMSV3_DW_DP.dbo.DimUnitSoldierRLASFlag DUSRF on DUSRF.SSNID = DSP.SSNID 
		and DUSRF.start_dt <= @rdt 
		and  (DUSRF.End_DT is null or DUSRF.End_DT > @rdt) 

  Where DURF.start_dt <= @rdt and (DURF.End_DT is null or DURF.end_dt >@rdt) And RLASFLag_CD = 'A' and DSE.DOD_EDI_PN_ID is not null
  Order by DURF.RLASFlag_DT

---Epat

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

--Select * from #TempePAT order by DODID, RN
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
join #TempEpat TE1
on TEF.DODID = TE1.DODID and TE1.RN = 1


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
join #TempEpat TE2
on TEF.DODID = TE2.DODID and TE2.RN = 2

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
join #TempEpat TE3
on TEF.DODID = TE3.DODID and TE3.RN = 3

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
join #TempEpat TE4
on TEF.DODID = TE4.DODID and TE4.RN = 4

--Aggregating




--Testing

if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.#TempAGG')) drop table #TempAGG
Select SELRES.DODI
	,SELRES.MPC
	,SELRES.Grade
	,SELRES.LastName
	,Selres.FirstName
	,Selres.FullName
	,SELRES.Gender
	,SELRES.PMOS
	,SELRES.Ethnic
	,SELRES.Ethnic_Description
	,SELRES.Race
	,SELRES.Race_Description
	,SELRES.DOB
	,SELRES.RCC
	,SELRES.MVNAR
	,SELRES.MVNAR_description
	,SELRES.PEBD_dt
	,SELRES.YRs_service
	,SELRES.SJA_Board
	--Unit Information
	,SELRES.UPC 
	,SELRES.MACOM
	,SELRES.MSC
	,SELRES.SubCMD
	,SELRES.[BDE/GP]
	,SELRES.[BN/TRP]
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
						else '' end as 'EPAT_Status'

into #tempAGG
From #TempSELRES SELRES
	Left Join #TempAFlagsONLY AFlagsONLY on AFLagsONLY.DODID = SELRES.DODI
	Left Join #TempEpatFlat EpatFlat on SELRES.DODI = EpatFlat.DODID
	


Select *
from #tempAGG


Select 
	count(*) as Cnt --179494
	,count(distinct DODI) as DISSELRESDODI --179395 there is 99 with NUll For DODID
	,count(DODI) as SELRESDODI --179395
	,count(distinct DODID)as DISAFLAGSONLYDODID--8618	
	,count(DODID) as AFLAGSONLYDODID --8628
From #tempAGG

	