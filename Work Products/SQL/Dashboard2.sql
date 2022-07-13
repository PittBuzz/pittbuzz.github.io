/* A summary query designed to provide summary data of specific readiness metrics by USARC DRU */

declare @rdt as date
set @rdt = '20220331'

/* Get vacancies by UPC */
Select 
	of1upc_name as GFC
	--[rcms_Grade_CD] as Grade
	,count(distinct vacancycontrolnumber) as Total_Vacancies
	,count(distinct case when vacancyoverfillreason_cd = 'P' then vacancycontrolnumber else null end) as Primary_Vacancies

Into #temp_vacs
From dimvacancyadvertised DVA
	Left Join Dimunithierarchies DUH on DVA.UPC_CD = DUH.UPC_CD and DUH.Hierarchy_id = 10 and DUH.start_dt <= @rdt and (DUH.end_dt > @rdt or DUH.end_dt is null)

Where DVA.end_dt is null and vacancypurge_dt is null and vacancydelete_dt is null and vacancystatus_cd = 'O'

Group by of1upc_name

/* Get authorizations*/

Select DUH.of1upc_name as GFC
	,Count (case when authorized_cnt = 1 then Reservepositionid else null end) as Authorized
	,Count (case when Required_cnt = 1 then Reservepositionid else null end) as Required

into #temp_pos
from RCMSV3_DW.dbo.FactReservePosition FRP
	Left Join Dimunithierarchies DUH on FRP.UPC_CD = DUH.UPC_CD and DUH.Hierarchy_id = 10 and DUH.start_dt <= @rdt and (DUH.end_dt > @rdt or DUH.end_dt is null)
where FRP.run_dt = @rdt
	and FRP.rcms_componentcategory_cd in ('TPU','IMA','AGR') -- ='TPU'  -- for TPU RFIs

Group by of1upc_name


/* Get strength */

Select 
	DUH.of1upc_name as GFC
	--FRS.[rcms_Grade_CD] as Grade -- to bin by grade for alternate RFIs
	,Count(case when assigned_cnt = 1 then positionid else null end) as Total_Assigned
	,Sum(case when FRS.Assigned_CNT = 1 and FRS.Required_CNT = 1 then 1 else 0 end) as TotalAsgAuthPsn
	,Count(case when FRS.[AssignedToValidAuthPos_CNT] = 1 then PositionID else null end) as Slotted
	,Count(Case when FRS.Assigned_CNT = 1 and FRS.Required_CNT = 0 then PositionID else null end) as Excess
	,Count(case when [NonDMOSQ_CNT] = 1 then PositionID else null end) as NonDMOSQ
	,Count(case when FRS.[RequiredOverstrength_CNT] = 1 then PositionID else null end) as OS
	,Count(case when tpu_cnt = 1 then positionid else null end) as TPU_Assigned
	,Count(case when agr_cnt = 1 then positionid else null end) as AGR_Assigned
	--,count(case when ima_cnt = 1 then positionid else null end) as IMA_Assigned
into #temp_str

From Factreservestrength FRS
	Left Join Dimunithierarchies DUH on FRS.UPC_CD = DUH.UPC_CD and DUH.Hierarchy_id = 10 and DUH.start_dt <= @rdt and (DUH.end_dt > @rdt or DUH.end_dt is null)
where FRS.run_dt = @rdt
	and FRS.rcms_componentcategory_cd in ('TPU','IMA','AGR') -- ='TPU'  -- for TPU RFIs

group by of1upc_name

/* Must union the authorized with assigned temp tables IOT provide a clean summary output table */

 Select 
 GFC, 
 Sum(Authorized) as Authorized, 
 0 as Asgn
 into #temp_sum
  from  #temp_pos
  Group by GFC
  union all
Select  
GFC, 
0 as Reqd, 
Sum(Total_Assigned) as Total_Assigned
  from #temp_str
 Group by GFC

 /* The output table fields from the #temp_tables */

Select distinct(S.GFC),
		--s.Grade ,
		P.Authorized
		,isnull(Total_Assigned, 0) as Total_Assigned
		,isnull(TotalAsgAuthPsn,0) as Slotted
		,isnull(Excess,0) as Excess, isnull(NonDMOSQ,0) as NonDMOSQ
		,TPU_Assigned, AGR_Assigned
		,isnull(Total_Vacancies, 0) as Total_Vacancies
		,isnull(Primary_Vacancies, 0) as Primary_Vacancies

from #temp_sum S
	Left JOIN #temp_pos p on s.gfc = p.gfc
	Left JOIN #temp_str st on s.gfc = st.gfc
	Left Join #temp_vacs v on s.gfc = v.gfc
					  --on s.grade = v.grade

order by S.gfc

drop table #temp_vacs
drop table #temp_str
drop table #temp_pos
drop table #temp_sum