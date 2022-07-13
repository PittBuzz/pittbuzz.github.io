declare @rdt as datetime
 set @rdt = '20220630'  

 /* This query provides required and assigned SMs by grade by USARC DRU */

/* Get Position Data  and write into #temp_pos temporary table */

Select   
	DUH.OF1UPC_NAME as GFC
	,DRP.rcms_PositionGrade_CD as Grade
	,DRP.PositionMPC_CD  as MPC, 1 as Reqd

into #Temp_POS

FROM RCMSV3_DW.dbo.DimReservePosition DRP 
Left Join rcmsv3_dw.dbo.DimUnitHierarchies DUH on DRP.upc_cd = DUH.upc_cd and DUH.start_dt <= @rdt and  (DUH.End_DT is null or DUH.End_DT > @rdt) and DUH.Hierarchy_CD = 'OF10'

Where DRP.start_dt <= @rdt and  (DRP.End_DT is null or DRP.End_DT > @rdt)
And DRP.Required_YN > 0
And DRP.PS_rcms_componentCategory_CD  IN ( 'agr','ima','tpu') --and Recode_CD in ('CU', 'PO', 'P0')) --and ReservePositionIndicator_CD in ('3') )-- (' ', '1', '6') )  -- addiitonal filters

--drop table #temp_pos 

/* Get Personnel Data  and write into #temp_per temporary table */

Select  
	DSP.MPC_CD as MPC
	,DUH.OF1UPC_NAME as GFC
    ,DSP.rcms_Grade_CD as Grade 
    ,1 as Asgn

into #Temp_PER   
FROM RCMSV3_DW.dbo.DimSoldierPersonnel DSP 
   Join RCMSV3_DW.dbo.DimSoldierRestricted DSR on DSP.SoldierRestrictedID = DSR.ID 
   Join RCMSV3_DW.dbo.FactReserveStrength FRS on FRS.SSNID = DSP.ssnid
   Left Join rcmsv3_dw.dbo.DimUnitHierarchies DUH on DSP.upc_cd = DUH.upc_cd and DUH.start_dt <= @rdt and (DUH.End_DT is null or DUH.End_DT > @rdt) and DUH.Hierarchy_CD = 'of10'
  
 Where (DSP.start_dt <= @rdt and  (DSP.End_DT is null or DSP.End_DT > @rdt))
 And FRS.Run_DT = @rdt 
 And DSP.rcms_ComponentCategory_CD in('agr','ima','tpu')

 Order by 2

 --drop table #temp_per 

 /* Sum Required and Assigned Strength and Union the two temporary tables together into the #Temp_sum table  */

 Select MPC, 
 GFC, 
 Grade, 
 Sum(Reqd) as Reqd, 
 0 as Asgn
 into #temp_sum
  From  #temp_pos
  Group by  MPC, GFC, Grade
  Union all
Select  MPC, 
GFC, 
Grade, 
0 as Reqd, 
Sum(Asgn) as Asgn
  From #temp_per
  Group by  MPC, GFC, Grade

 --drop table #temp_sum 

 /* Enlisted Report */

 Select GFC
 ,Sum(case when  Reqd > = 0 then Reqd else 0 end) as REQ
 ,Sum(case when  Asgn > = 0 then Asgn else 0 end) as ASG

 from #temp_sum a
 Group by GFC
 Order by  GFC 

 Select GFC, 
 Sum(case when Grade = 'E1' and Reqd > = 0 then Reqd else 0 end) as R_E1,
  Sum(case when Grade = 'E1' and Asgn > = 0 then Asgn else 0 end) as A_E1,
  Sum(case when Grade = 'E2' and Reqd > = 0 then Reqd else 0 end) as R_E2,
  Sum(case when Grade = 'E2' and Asgn > = 0 then Asgn else 0 end) as A_E2,
  Sum(case when Grade = 'E3' and Reqd > = 0 then Reqd else 0 end) as R_E3,
  Sum(case when Grade = 'E3' and Asgn > = 0 then Asgn else 0 end) as A_E3,
  Sum(case when Grade = 'E4' and Reqd > = 0 then Reqd else 0 end) as R_E4,
  Sum(case when Grade = 'E4' and Asgn > = 0 then Asgn else 0 end) as A_E4,
  Sum(case when Grade = 'E5' and Reqd > = 0 then Reqd else 0 end) as R_E5,
  Sum(case when Grade = 'E5' and Asgn > = 0 then Asgn else 0 end) as A_E5,
  Sum(case when Grade = 'E6' and Reqd > = 0 then Reqd else 0 end) as R_E6,
  Sum(case when Grade = 'E6' and Asgn > = 0 then Asgn else 0 end) as A_E6,
  Sum(case when Grade = 'E7' and Reqd > = 0 then Reqd else 0 end) as R_E7,
  Sum(case when Grade = 'E7' and Asgn > = 0 then Asgn else 0 end) as A_E7, 
  Sum(case when Grade = 'E8' and Reqd > = 0 then Reqd else 0 end) as R_E8,
  Sum(case when Grade = 'E8' and Asgn > = 0 then Asgn else 0 end) as A_E8,
  Sum(case when Grade = 'E9' and Reqd > = 0 then Reqd else 0 end) as R_E9,
  Sum(case when Grade = 'E9' and Asgn > = 0 then Asgn else 0 end) as A_E9        
 from #temp_sum a

 where mpc = 'E'
 group by GFC
 order by  GFC 

 /* Warrant Officer Report     */

 Select GFC as WMOS,   
 
  Sum(case when Grade = 'W1' and Reqd > = 0 then Reqd else 0 end) as R_W1,
  Sum(case when Grade = 'W1' and Asgn > = 0 then Asgn else 0 end) as A_W1,
  Sum(case when Grade = 'W2' and Reqd > = 0 then Reqd else 0 end) as R_W2,
  Sum(case when Grade = 'W2' and Asgn > = 0 then Asgn else 0 end) as A_W2,
  Sum(case when Grade = 'W3' and Reqd > = 0 then Reqd else 0 end) as R_W3,
  Sum(case when Grade = 'W3' and Asgn > = 0 then Asgn else 0 end) as A_W3,
  Sum(case when Grade = 'W4' and Reqd > = 0 then Reqd else 0 end) as R_W4,
  Sum(case when Grade = 'W4' and Asgn > = 0 then Asgn else 0 end) as A_W4,
  Sum(case when Grade = 'W5' and Reqd > = 0 then Reqd else 0 end) as R_W5,
  Sum(case when Grade = 'W5' and Asgn > = 0 then Asgn else 0 end) as A_W5
   from #temp_sum a
 
 where mpc = 'W'
 group by GFC
 order by  GFC 

 /* Officer AOC Report     */

  Select GFC , 
  
  Sum(case when Grade = 'O1' and Reqd > = 0 then Reqd else 0 end) as R_O1,
  Sum(case when Grade = 'O1' and Asgn > = 0 then Asgn else 0 end) as A_O1,
  Sum(case when Grade = 'O2' and Reqd > = 0 then Reqd else 0 end) as R_O2,
  Sum(case when Grade = 'O2' and Asgn > = 0 then Asgn else 0 end) as A_O2,
  Sum(case when Grade = 'O3' and Reqd > = 0 then Reqd else 0 end) as R_O3,
  Sum(case when Grade = 'O3' and Asgn > = 0 then Asgn else 0 end) as A_O3,
  Sum(case when Grade = 'O4' and Reqd > = 0 then Reqd else 0 end) as R_O4,
  Sum(case when Grade = 'O4' and Asgn > = 0 then Asgn else 0 end) as A_O4,
  Sum(case when Grade = 'O5' and Reqd > = 0 then Reqd else 0 end) as R_O5,
  Sum(case when Grade = 'O5' and Asgn > = 0 then Asgn else 0 end) as A_O5,
  Sum(case when Grade = 'O6' and Reqd > = 0 then Reqd else 0 end) as R_O6,
  Sum(case when Grade = 'O6' and Asgn > = 0 then Asgn else 0 end) as A_O6,
  Sum(case when Grade = 'O7' and Reqd > = 0 then Reqd else 0 end) as R_O7,
  Sum(case when Grade = 'O7' and Asgn > = 0 then Asgn else 0 end) as A_O7, 
  Sum(case when Grade = 'O8' and Reqd > = 0 then Reqd else 0 end) as R_O8,
  Sum(case when Grade = 'O8' and Asgn > = 0 then Asgn else 0 end) as A_O8 
  from #temp_sum a
 
 where mpc = 'O' 
 group by GFC
 order by  GFC 


 drop table #temp_pos 
 drop table #temp_per 
 drop table #temp_sum 



 


