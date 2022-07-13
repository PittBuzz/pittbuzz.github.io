/* Provides a summary rollup of auth/assgn by grade by RCC. Note AGR AL positions are not accounted for */

declare @rdt as datetime
set @rdt = '20220331'  

/* Authorized Positions by Grade: TPU */
 select p.rcms_PositionGrade_CD as Grade 
	    ,1 as Auth_H
into #Temp_POSTPU
   from     RCMSV3_DW.dbo.DimReservePosition p 
	where    (p.start_dt <= @rdt and  (p.End_DT is null or p.End_DT > @rdt))
	and p.Authorized_YN > 0
	and  P.PS_rcms_componentCategory_CD  = 'TPU'

 /* Assigned by Grade: TPU*/
select  a.rcms_grade_cd as Grade
  ,1 as Asgn_H
into #Temp_ASGTPU  
	from     RCMSV3_DW.dbo.DimSoldierPersonnel a 
	join RCMSV3_DW.dbo.DimSoldierRestricted r on a.SoldierRestrictedID=r.ID 
	join RCMSV3_DW.dbo.FactReserveStrength rs on rs.SSNID = a.ssnid
	 where (a.start_dt <= @rdt and  (a.End_DT is null or a.End_DT > @rdt))
	and rs.Run_DT = @rdt 
	and a.rcms_ComponentCategory_CD = 'TPU' 

-- order by 2

/*---------------------------------------------------------------------------------------------------*/
/* Authorized Positions by Grade: AGR */
 select p.Grade 
		,1 as Auth_J
into #Temp_POSAGR
   from     [RCMS_ORSA].[dbo].['jkv_AGRpos']p 
	where    AUTHSTR > 0
	and RMK1 = 92

 
/* Assigned by Grade: AGR*/
select  a.rcms_grade_cd as Grade,
  1 as Asgn_J
into #Temp_ASGAGR  
	from     RCMSV3_DW.dbo.DimSoldierPersonnel a 
	join RCMSV3_DW.dbo.DimSoldierRestricted r on a.SoldierRestrictedID=r.ID 
	join RCMSV3_DW.dbo.FactReserveStrength rs on rs.SSNID = a.ssnid
	 where (a.start_dt <= @rdt and  (a.End_DT is null or a.End_DT > @rdt))
	and rs.Run_DT = @rdt 
	and a.rcms_ComponentCategory_CD = 'AGR' 

 --order by 2

/*---------------------------------------------------------------------------------------------*/
/* Authorized Positions by Grade: IMA */
 select    p.rcms_PositionGrade_CD as Grade 
			, 1 as Auth_I
into #Temp_POSIMA
   from     RCMSV3_DW.dbo.DimReservePosition p 
	where    (p.start_dt <= @rdt and  (p.End_DT is null or p.End_DT > @rdt))
	and p.Authorized_YN > 0
	and  P.PS_rcms_componentCategory_CD  = 'IMA'

 
/* Assigned by Grade: IMA*/
select  a.rcms_grade_cd as Grade,
  1 as Asgn_I

into #Temp_ASGIMA  
	from     RCMSV3_DW.dbo.DimSoldierPersonnel a 
	join RCMSV3_DW.dbo.DimSoldierRestricted r on a.SoldierRestrictedID=r.ID 
	join RCMSV3_DW.dbo.FactReserveStrength rs on rs.SSNID = a.ssnid
	 where (a.start_dt <= @rdt and  (a.End_DT is null or a.End_DT > @rdt))
	and rs.Run_DT = @rdt 
	and a.rcms_ComponentCategory_CD = 'IMA' 

 --order by 2

/* Sums Assigned, Required, and Match by Grade and Unions them into a temporary table */

   Select Grade
   ,Sum(Auth_H) as Auth_H
   ,0 as Asgn_H
   ,0 as Auth_J
   ,0 as Asgn_J
   ,0 as Auth_I
   ,0 as Asgn_I
   into #temp_sum
   from  #temp_POSTPU
   Group by  Grade
   union all

   Select  Grade
   ,0 as Auth_H
   ,Sum(Asgn_H) as Asgn_H
   ,0 as Auth_J
   ,0 as Asgn_J
   ,0 as Auth_I
   ,0 as Asgn_I
   from #TEMP_ASGTPU
   Group by  Grade
   union all

   Select  Grade
   ,0 as Auth_H
   ,0 as Asgn_H
   ,Sum(Auth_J) as Auth_J
   ,0 as Asgn_J
   ,0 as Auth_I
   ,0 as Asgn_I
   from #TEMP_POSAGR
   Group by  Grade
   union all

   Select  Grade
   ,0 as Auth_H
   ,0 as Asgn_H
   ,0 as Auth_J
   ,Sum(Asgn_J) as Asgn_J
   ,0 as Auth_I
   ,0 as Asgn_I
   from #TEMP_ASGAGR
   Group by  Grade
   union all

   Select  Grade
   ,0 as Auth_H
   ,0 as Asgn_H
   ,0 as Auth_J
   ,0 as Asgn_J
   ,Sum(Auth_I) as Auth_I
   ,0 as Asgn_I
   from #TEMP_POSIMA
   Group by  Grade
   union all

   Select  Grade
   ,0 as Auth_H
   ,0 as Asgn_H
   ,0 as Auth_J
   ,0 as Asgn_J
   ,0 as Auth_I
   ,Sum(Asgn_I) as Asgn_I
   from #TEMP_ASGIMA
   Group by  Grade
  

/* Grade Rollups for Grade match report */
Select Grade
,Sum(Auth_H) + Sum(Auth_J) + Sum(Auth_I) as Auth_SELRES
,Sum(Asgn_H) + Sum(Asgn_J) + Sum(Asgn_I) as Asgn_SELRES
,(Sum(Auth_H) + Sum(Auth_J) + Sum(Auth_I)) - (Sum(Asgn_H) + Sum(Asgn_J) + Sum(Asgn_I)) as Delta_SELRES
--,Round((cast(Sum(case when (sum(Asgn_H) + sum(asgn_j) + sum(asgn_i)) > = 0 then Asgn_H + asgn_j + asgn_i else 0 end)  as float) /
 --Nullif(cast(Sum(case when (sum(Auth_H) + sum(auth_j) + sum(auth_i)) > = 0 then Auth_H + auth_j + auth_i else 0 end) as float),0)),4) AS [%fill_SELRES]
,Sum(Auth_H) as Auth_H
,Sum(Asgn_H) as Asgn_H
,sum(asgn_h) - sum(auth_h) as Delta_H
,Round((cast(Sum(case when Asgn_H > = 0 then Asgn_H else 0 end) as float)/
 Nullif(cast(Sum(case when Auth_H > = 0 then Auth_H else 0 end) as float),0)),4) AS [%fill_H]
,Sum(Auth_J) as Auth_J
,Sum(Asgn_J) as Asgn_J
,sum(asgn_J) - sum(auth_J) as Delta_J
,Round((cast(Sum(case when Asgn_J > = 0 then Asgn_J else 0 end) as float)/
 Nullif(cast(Sum(case when Auth_J > = 0 then Auth_J else 0 end) as float),0)),4) AS [%fill_J]
,Sum(Auth_I) as Auth_I
,Sum(Asgn_I) as Asgn_I
,sum(asgn_I) - sum(auth_I) as Delta_I
,Round((cast(Sum(case when Asgn_I > = 0 then Asgn_I else 0 end) as float)/
 Nullif(cast(Sum(case when Auth_I > = 0 then Auth_I else 0 end) as float),0)),4) AS [%fill_I]

from #temp_sum
group by grade



 drop table #temp_POSTPU
 drop table #temp_ASGTPU
 drop table #Temp_POSAGR
 drop table #Temp_ASGAGR
 drop table #Temp_POSIMA
 drop table #Temp_ASGIMA 
 drop table #temp_sum
