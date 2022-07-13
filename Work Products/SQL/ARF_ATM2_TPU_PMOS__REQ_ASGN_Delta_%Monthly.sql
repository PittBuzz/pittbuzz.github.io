/* This table provides aggregated data of SMs by grade and skillset with specific unit caveats*/

Declare @rdt as datetime
set @rdt = '20210731'  

/*REQUIRED* Position data */
Select rtrim(d.rcms_PositionMOS_CD) as MOS, d.rcms_PositionGrade_CD as Grade , d.PositionMPC_CD as MPC, 1 as reqd
into #Temp_POS 


from [RCMSV3_DW].[dbo].[DimReservePosition] d
join RCMSV3_DW.dbo.DimUnitHierarchies c on c.UPC_CD = d.UPC_CD
--left join RCMS_ORSA.dbo.ARF_UnitList arf on arf.upc3 = left(d.upc_cd, 3)
left join RCMS_ORSA.dbo.ATM2andCSFUnitList atm on atm.UPC3 = left(d.upc_cd, 3)
Where Hierarchy_ID = '10' 
--and OF1UPC_CD = '8EDAA'
--and c.UPC_CD ='Z4LAA'  /* change to get MOS data for a UPC*/
and (c.Start_Dt <= @rdt and (c.End_dt > @rdt or c.End_Dt is null))
and d.Start_Dt <= @rdt and (d.End_Dt > @rdt or d.End_Dt is null) 
and rcms_positioncomponentcategory_cd in ('TPU'/*,'IMA','AGR'*/)
and Recode_CD in ('CU', 'PO', 'P0') 
and ReservePositionIndicator_CD in (' ', '1', '6')
--and arf.UIC is not null
and atm.RFXCat is not null
--and ReservePositionIndicator_CD in ('3') /** Use for AGR Required Numbers */ 
and Required_YN > 0 



/*ASSIGNED  Personnel data */

Select rtrim(b.rcms_PrimaryMOS_CD) as MOS, a.rcms_Grade_CD as Grade,  a.MPC_CD as MPC, 1 as Asgn 
into #temp_PER

from [RCMSV3_DW].[dbo].[FactReserveStrength] a
join [RCMSV3_DW].[dbo].[DimSoldierPersonnel] b on a.SoldierID = b.ID
 join RCMSV3_DW.dbo.DimUnitHierarchies x on a.UPC_CD = x.UPC_CD
-- left join rcms_orsa.dbo.ARF_UnitList arf on arf.upc3 = left(a.upc_cd, 3)
 left join RCMS_ORSA.dbo.ATM2andCSFUnitList atm on atm.UPC3 = left(a.upc_cd, 3)
Where x.Hierarchy_ID = '10'
--and OF1UPC_CD = '8EDAA'
--and x.UPC_CD = 'Z4LAA'  
and (x.Start_Dt <= @rdt and (x.End_dt > @rdt or x.End_Dt is null))
and Run_DT = @rdt 
and a.rcms_componentCategory_CD in ('TPU'/*,'IMA','AGR'*/)
and Assigned_CNT > 0
--and arf.UIC is not null
and atm.RFXCat is not null

/* Union req and asgn table into one table */
Declare @Asgn float;
Declare @reqd float;
  

Select MPC, MOS, Grade, Sum(reqd) as Reqd, 0 as Asgn
into #temp_num
from  #Temp_POS
Group by  MPC, MOS, Grade
union all
Select  MPC, MOS, Grade, 0 as Reqd, Sum(Asgn) as Asgn
from #temp_PER
Group by  MPC, MOS, Grade

 Select MOS, mlk.Description as MOS_DESC,

 Sum(case when Grade in ('E1', 'E2','E3','E4', 'E5', 'E6','E7', 'E8', 'E9') and Reqd > = 0 then Reqd else 0 end) as [R_ET],
 Sum(case when Grade in ('E1', 'E2','E3','E4', 'E5', 'E6','E7', 'E8', 'E9') and Asgn > = 0 then Asgn else 0 end) as [A_ET],
 Round((cast(Sum(case when Grade in  ('E1', 'E2','E3','E4', 'E5', 'E6','E7', 'E8', 'E9') and Asgn > = 0 then Asgn else 0 end) as float)/
 Nullif(cast(Sum(case when Grade in  ('E1', 'E2', 'E3','E4', 'E5', 'E6','E7', 'E8', 'E9') and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [%fill_ET],
 Sum(case when Grade in ('E1', 'E2','E3','E4', 'E5', 'E6','E7', 'E8', 'E9') and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade in  ('E1', 'E2', 'E3','E4', 'E5', 'E6','E7', 'E8', 'E9')   and Reqd > = 0 then Reqd else 0 end) as [Delta_ET],


  Sum(case when Grade in ('E1','E2', 'E3') and Reqd > = 0 then Reqd else 0 end) as R_E3, 
  Sum(case when Grade in ('E1','E2', 'E3') and Asgn > = 0 then Asgn else 0 end) as A_E3,
  Round((cast(Sum(case when Grade in ('E1','E2', 'E3') and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade in ('E1','E2', 'E3') and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [%fill_E3],
  Sum(case when Grade in ('E1','E2', 'E3') and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade in ('E1','E2', 'E3') and Reqd > = 0 then Reqd else 0 end) as Delta_E3,
  
  Sum(case when Grade = 'E4' and Reqd > = 0 then Reqd else 0 end) as R_E4,
  Sum(case when Grade = 'E4' and Asgn > = 0 then Asgn else 0 end) as A_E4,
  Round((cast(Sum(case when Grade = 'E4' and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade = 'E4' and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [%fill_E4],
  Sum(case when Grade = 'E4' and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade = 'E4' and Reqd > = 0 then Reqd else 0 end) as Delta_E4,  
  
  Sum(case when Grade = 'E5' and Reqd > = 0 then Reqd else 0 end) as R_E5,
  Sum(case when Grade = 'E5' and Asgn > = 0 then Asgn else 0 end) as A_E5,
  Round((cast(Sum(case when Grade = 'E5' and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade = 'E5' and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [%fill_E5],
  Sum(case when Grade = 'E5' and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade = 'E5' and Reqd > = 0 then Reqd else 0 end) as Delta_E5,
  
  
  Sum(case when Grade = 'E6' and Reqd > = 0 then Reqd else 0 end) as R_E6,
  Sum(case when Grade = 'E6' and Asgn > = 0 then Asgn else 0 end) as A_E6,
  Round((cast(Sum(case when Grade = 'E6' and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade = 'E6' and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [%fill_E6],
  Sum(case when Grade = 'E6' and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade = 'E6' and Reqd > = 0 then Reqd else 0 end) as Delta_E6,
 
  Sum(case when Grade = 'E7' and Reqd > = 0 then Reqd else 0 end) as R_E7,
  Sum(case when Grade = 'E7' and Asgn > = 0 then Asgn else 0 end) as A_E7, 
  Round((cast(Sum(case when Grade = 'E7' and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade = 'E7' and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [%fill_E7],
  Sum(case when Grade = 'E7' and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade = 'E7' and Reqd > = 0 then Reqd else 0 end) as Delta_E7,
  
 
  Sum(case when Grade = 'E8' and Reqd > = 0 then Reqd else 0 end) as R_E8,
  Sum(case when Grade = 'E8' and Asgn > = 0 then Asgn else 0 end) as A_E8,
  Round((cast(Sum(case when Grade = 'E8' and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade = 'E8' and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [%fill_E8],
  Sum(case when Grade = 'E8' and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade = 'E8' and Reqd > = 0 then Reqd else 0 end) as Delta_E8,
  
  Sum(case when Grade = 'E9' and Reqd > = 0 then Reqd else 0 end) as R_E9,
  Sum(case when Grade = 'E9' and Asgn > = 0 then Asgn else 0 end) as A_E9,        
  Round((cast(Sum(case when Grade = 'E9' and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade = 'E9' and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [%fill_E9],
  Sum(case when Grade = 'E9' and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade = 'E9' and Reqd > = 0 then Reqd else 0 end) as Delta_E9
  
into #temp_ENLA   
from #temp_num

left join RCMSV3_LOOKUPS.dbo.Lkp_TAPDB_MOSTBLE_Base mlk on MOS = mlk.code and mlk.mpc_cd = 'E' and mlk.End_dt is null
where mpc = 'E'
group by MOS, mlk.Description
order by  MOS 


 Select MOS as W_MOS,   
 case when MOS = 'INV' then 'Invalid Raw MOS-Old or out of Grade Range' else  mlk.Description end as WMOS_DESC,

  Sum(case when Grade in ('W1','W2', 'W3', 'W4', 'W5') and Reqd > = 0 then Reqd else 0 end) as REQ_WT,
  Sum(case when Grade in ('W1','W2' ,'W3', 'W4', 'W5')  and Asgn > = 0 then Asgn else 0 end) as  ASGN_WT,
  Sum(case when Grade in ('W1','W2','W3', 'W4', 'W5')  and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade in ('W1','W2','W3', 'W4', 'W5') and Reqd > = 0 then Reqd else 0 end) as Delta_WT,
  Round((cast(Sum(case when Grade in ('W1','W2','W3', 'W4', 'W5')  and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade in ('W1','W2','W3', 'W4', 'W5') and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [%ASGN_WT],


  Sum(case when Grade in ('W1','W2') and Reqd > = 0 then Reqd else 0 end) as REQ_W2,
  Sum(case when Grade in ('W1','W2') and Asgn > = 0 then Asgn else 0 end) as ASGN_W2,
  Round((cast(Sum(case when Grade in ('W1','W2') and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade in ('W1','W2') and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [%ASGN_W2],
  Sum(case when Grade in ('W1','W2') and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade in ('W1','W2') and Reqd > = 0 then Reqd else 0 end) as Delta_W2,
  

  Sum(case when Grade = 'W3' and Reqd > = 0 then Reqd else 0 end) as REQ_W3,
  Sum(case when Grade = 'W3' and Asgn > = 0 then Asgn else 0 end) as ASGN_W3,
  Round((cast(Sum(case when Grade = 'W3' and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade = 'W3' and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [%ASGN_W3],
  Sum(case when Grade = 'W3' and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade = 'W3' and Reqd > = 0 then Reqd else 0 end) as Delta_W3,
  
  
  
  Sum(case when Grade = 'W4' and Reqd > = 0 then Reqd else 0 end) as REQ_W4,
  Sum(case when Grade = 'W4' and Asgn > = 0 then Asgn else 0 end) as ASGN_W4,
  Round((cast(Sum(case when Grade = 'W4' and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade = 'W4' and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [%ASGN_W4],
  Sum(case when Grade = 'W4' and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade = 'W4' and Reqd > = 0 then Reqd else 0 end) as Delta_W4,
  
  
  Sum(case when Grade = 'W5' and Reqd > = 0 then Reqd else 0 end) as REQ_W5,
  Sum(case when Grade = 'W5' and Asgn > = 0 then Asgn else 0 end) as ASGN_W5,
  Round((cast(Sum(case when Grade = 'W5' and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade = 'W5' and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [%ASGN_W5],
  Sum(case when Grade = 'W5' and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade = 'W5' and Reqd > = 0 then Reqd else 0 end) as Delta_W5
  

into #temp_WOA   
from #temp_num
left join RCMSV3_LOOKUPS.dbo.Lkp_TAPDB_MOSTBLE_Base mlk on MOS = mlk.code and mlk.mpc_cd = 'W' and mlk.End_dt is null
where mpc = 'W'
group by MOS, case when MOS = 'INV' then 'Invalid Raw MOS-Old or out of Grade Range' else  mlk.Description end
order by  MOS 

Select  MOS as AOC, case when MOS = 'INV' then 'Invalid Raw MOS-Old or out of Grade Range' else  mlk.Description end as AOC_DESC,


  Sum(case when Grade in  ('O1', 'O2', 'O3', 'O4', 'O5', 'O6','O7') and Reqd > = 0 then Reqd else 0 end) as R_OT,
  Sum(case when Grade in  ('O1', 'O2', 'O3', 'O4', 'O5', 'O6', 'O7')and Asgn > = 0 then Asgn else 0 end) as A_OT,
  Sum(case when Grade in  ('O1', 'O2', 'O3', 'O4', 'O5', 'O6', 'O7') and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade in  ('O1', 'O2', 'O3', 'O4', 'O5', 'O6', 'O7')  and Reqd > = 0 then Reqd else 0 end) as Delta_OT,
  Round((cast(Sum(case when Grade in  ('O1', 'O2', 'O3', 'O4', 'O5', 'O6', 'O7')  and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade in  ('O1', 'O2', 'O3', 'O4', 'O5', 'O6', 'O7')  and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [Fill%_OT],

  Sum(case when Grade in ('O1','O2')and Reqd > = 0 then Reqd else 0 end) as R_O2,
  Sum(case when Grade in ('O1','O2') and Asgn > = 0 then Asgn else 0 end) as A_O2,
  Round((cast(Sum(case when Grade in ('O1','O2') and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade in ('O1','O2') and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [Fill%_O2],
  Sum(case when Grade in ('O1','O2') and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade in ('O1','O2') and Reqd > = 0 then Reqd else 0 end) as Delta_O2,
  
  Sum(case when Grade = 'O3' and Reqd > = 0 then Reqd else 0 end) as R_O3,
  Sum(case when Grade = 'O3' and Asgn > = 0 then Asgn else 0 end) as A_O3,
  Round((cast(Sum(case when Grade = 'O3' and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade = 'O3' and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [Fill%_O3],
  Sum(case when Grade = 'O3' and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade = 'O3' and Reqd > = 0 then Reqd else 0 end) as Delta_O3,

  Sum(case when Grade = 'O4' and Reqd > = 0 then Reqd else 0 end) as R_O4,
  Sum(case when Grade = 'O4' and Asgn > = 0 then Asgn else 0 end) as A_O4,
  Round((cast(Sum(case when Grade = 'O4' and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade = 'O4' and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [Fill%_O4],
  Sum(case when Grade = 'O4' and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade = 'O4' and Reqd > = 0 then Reqd else 0 end) as Delta_O4,
  
  Sum(case when Grade = 'O5' and Reqd > = 0 then Reqd else 0 end) as R_O5,
  Sum(case when Grade = 'O5' and Asgn > = 0 then Asgn else 0 end) as A_O5,
  Round((cast(Sum(case when Grade = 'O5' and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade = 'O5' and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [Fill%_O5],
  Sum(case when Grade = 'O5' and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade = 'O5' and Reqd > = 0 then Reqd else 0 end) as Delta_O5,

  Sum(case when Grade = 'O6' and Reqd > = 0 then Reqd else 0 end) as R_O6,
  Sum(case when Grade = 'O6' and Asgn > = 0 then Asgn else 0 end) as A_O6,
  Round((cast(Sum(case when Grade = 'O6' and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade = 'O6' and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [Fill%_O6],
  Sum(case when Grade = 'O6' and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade = 'O6' and Reqd > = 0 then Reqd else 0 end) as Delta_O6

into #temp_num2            
from #temp_num
left join RCMSV3_LOOKUPS.dbo.Lkp_TAPDB_MOSTBLE_Base mlk on MOS = mlk.code and mlk.mpc_cd = 'O' and mlk.End_dt is null
where mpc = 'O' and MOS not in ('26A', '26B', '26Z', '29A', '30A','34A','40A','40C','46A','46X','48B','48C','48D','48E','48F',
'48G','48H','48I','48J','48X','49A','49W','49X','50A','51A','51C','51R','51S','51T','51Z','52B','57A','59A')
--and MOS in ('60J','60K','60N','60W','61F','61H','61J','61K','61M','61R','61Z','62A','63N','65D','66E','66S','66T')

group by MOS,
case when MOS = 'INV' then 'Invalid Raw MOS-Old or out of Grade Range' else  mlk.Description end 

 Select  MOS as FA, 
 --case when MOS = 'INV' then 'Invalid Raw MOS-Old or out of Grade Range' else  mlk.Description end as AOC_DESC,

  Sum(case when Grade in  ('O1', 'O2', 'O3', 'O4', 'O5', 'O6') and Reqd > = 0 then Reqd else 0 end) as R_OT,
  Sum(case when Grade in  ('O1', 'O2', 'O3', 'O4', 'O5', 'O6')and Asgn > = 0 then Asgn else 0 end) as A_OT,
  Sum(case when Grade in  ('O1', 'O2', 'O3', 'O4', 'O5', 'O6') and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade in  ('O1', 'O2', 'O3', 'O4', 'O5', 'O6')  and Reqd > = 0 then Reqd else 0 end) as Delta_OT,
  Round((cast(Sum(case when Grade in  ('O1', 'O2', 'O3', 'O4', 'O5', 'O6')  and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade in  ('O1', 'O2', 'O3', 'O4', 'O5', 'O6')  and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [Fill%_OT],

  Sum(case when Grade in ('O1','O2') and Reqd > = 0 then Reqd else 0 end) as R_O2,
  Sum(case when Grade  in ('O1','O2')and Asgn > = 0 then Asgn else 0 end) as A_O2,
  Round((cast(Sum(case when Grade in ('O1','O2')and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade in ('O1','O2') and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [Fill%_O2],
  Sum(case when Grade in ('O1','O2') and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade in ('O1','O2') and Reqd > = 0 then Reqd else 0 end) as Delta_O2,
  
  Sum(case when Grade = 'O3' and Reqd > = 0 then Reqd else 0 end) as R_O3,
  Sum(case when Grade = 'O3' and Asgn > = 0 then Asgn else 0 end) as A_O3,
  Round((cast(Sum(case when Grade = 'O3' and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade = 'O3' and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [Fill%_O3],
  Sum(case when Grade = 'O3' and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade = 'O3' and Reqd > = 0 then Reqd else 0 end) as Delta_O3,

  Sum(case when Grade = 'O4' and Reqd > = 0 then Reqd else 0 end) as R_O4,
  Sum(case when Grade = 'O4' and Asgn > = 0 then Asgn else 0 end) as A_O4,
  Round((cast(Sum(case when Grade = 'O4' and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade = 'O4' and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [Fill%_O4],
  Sum(case when Grade = 'O4' and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade = 'O4' and Reqd > = 0 then Reqd else 0 end) as Delta_O4,
  
  Sum(case when Grade = 'O5' and Reqd > = 0 then Reqd else 0 end) as R_O5,
  Sum(case when Grade = 'O5' and Asgn > = 0 then Asgn else 0 end) as A_O5,
  Round((cast(Sum(case when Grade = 'O5' and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade = 'O5' and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [Fill%_O5],
  Sum(case when Grade = 'O5' and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade = 'O5' and Reqd > = 0 then Reqd else 0 end) as Delta_O5,

  Sum(case when Grade = 'O6' and Reqd > = 0 then Reqd else 0 end) as R_O6,
  Sum(case when Grade = 'O6' and Asgn > = 0 then Asgn else 0 end) as A_O6,
  Round((cast(Sum(case when Grade = 'O6' and Asgn > = 0 then Asgn else 0 end) as float)/
  Nullif(cast(Sum(case when Grade = 'O6' and Reqd > = 0 then Reqd else 0 end) as float),0))*100,2) AS [Fill%_O6],
  Sum(case when Grade = 'O6' and Asgn > = 0 then Asgn else 0 end)-Sum(case when Grade = 'O6' and Reqd > = 0 then Reqd else 0 end) as Delta_O6
 
into #temp_FUNC
from #temp_num
left join RCMSV3_LOOKUPS.dbo.Lkp_TAPDB_MOSTBLE_Base mlk on MOS = mlk.code and mlk.mpc_cd = 'O' and mlk.End_dt is null
where mpc = 'O' and MOS in  ('26A', '26B', '26Z', '29A', '30A','34A','40A','40C','46A','46X','48B','48C','48D','48E','48F',
'48G','48H','48I','48J','48X','49A','49W','49X','50A','51A','51C','51R','51S','51T','51Z','52B','57A','59A')
group by MOS,  case when MOS = 'INV' then 'Invalid Raw MOS-Old or out of Grade Range' else  mlk.Description end
order by  MOS 

 
 select MOS,
             R_ET, [A_ET], cast([%fill_ET]  as varchar) as [%fill_ET], Delta_ET,
			 R_E3, [A_E3], cast([%fill_E3]  as varchar) as [%fill_E3], Delta_E3,   
             R_E4, [A_E4], cast([%fill_E4]  as varchar) as [%fill_E4], Delta_E4, 
             R_E5, [A_E5], cast([%fill_E5]  as varchar) as [%fill_E5], Delta_E5,
             R_E6, [A_E6], cast([%fill_E6]  as varchar) as [%fill_E6], Delta_E6,
             R_E7, [A_E7], cast([%fill_E7]  as varchar) as [%fill_E7], Delta_E7,
             R_E8, [A_E8], cast([%fill_E8]  as varchar) as [%fill_E8], Delta_E8,
			 R_E9, [A_E9], cast([%fill_E9]  as varchar) as [%fill_E9], Delta_E9

into #temp_ENLB
from #temp_ENLA

 select MOS, Description, 
             R_ET as [REQ_ET], [A_ET]as [OH_ET],Delta_ET, isnull([%fill_ET],'--')+ '%' as [%OH_ET],
			 R_E3 as [REQ_E3], [A_E3]as [OH_E3],Delta_E3, isnull([%fill_E3],'--')+ '%' as [%OH_E3], 
			 R_E4 as [REQ_E4], [A_E4]as [OH_E4],Delta_E4, isnull([%fill_E4],'--')+ '%' as [%OH_E4], 
			 R_E5 as [REQ_E5], [A_E5]as [OH_E5],Delta_E5, isnull([%fill_E5],'--')+ '%' as [%OH_E5], 
		     R_E6 as [REQ_E6], [A_E6]as [OH_E6],Delta_E6, isnull([%fill_E6],'--')+ '%' as [%OH_E6], 
			 R_E7 as [REQ_E7], [A_E7]as [OH_E7],Delta_E7, isnull([%fill_E7],'--')+ '%' as [%OH_E7], 
             R_E8 as [REQ_E8], [A_E8]as [OH_E8],Delta_E8, isnull([%fill_E8],'--')+ '%' as [%OH_E8], 
			 R_E9 as [REQ_E9], [A_E9]as [OH_E9],Delta_E9, isnull([%fill_E9],'--')+ '%' as [%OH_E9]

from #temp_ENLB
join RCMSV3_LOOKUPS.dbo.Lkp_TAPDB_MOSTBLE_Base mlk 
on MOS = mlk.code 
and mlk.End_dt is null
and mlk.mpc_cd = 'E' 
Order by MOS 


 Select W_MOS, 
        REQ_WT, ASGN_WT as ASGN_WT, cast([%ASGN_WT] as varchar) as [Fill%_WT], Delta_WT,
		REQ_W2, ASGN_W2 as ASGN_W2, cast([%ASGN_W2] as varchar) as [Fill%_W2], Delta_W2,
		REQ_W3, ASGN_W3 as ASGN_W3, cast([%ASGN_W3] as varchar) as [Fill%_W3], Delta_W3,
		REQ_W4, ASGN_W4 as ASGN_W4, cast([%ASGN_W4] as varchar) as [Fill%_W4], Delta_W4,
		REQ_W5, ASGN_W5 as ASGN_W5, cast([%ASGN_W5] as varchar) as [Fill%_W5], Delta_W5
into #temp_WOB
from #temp_WOA

 Select W_MOS, Description,
    REQ_WT, ASGN_WT AS OH_WT, Delta_WT, isnull([Fill%_WT],'--')+ '%' as [%OH_WT],
	REQ_W2, ASGN_W2 AS OH_W2, Delta_W2, isnull([Fill%_W2],'--')+ '%' as [%OH_W2],
	REQ_W3, ASGN_W3 AS OH_W3, Delta_W3,isnull([Fill%_W3],'--')+ '%' as [%OH_W3],
	REQ_W4, ASGN_W4 AS OH_W4, Delta_W4, isnull([Fill%_W4],'--')+ '%' as [%OH_W4], 
	REQ_W5, ASGN_W5, Delta_W5, isnull([Fill%_W5],'--')+ '%'as [%OH_W5]
from #temp_WOB
join RCMSV3_LOOKUPS.dbo.Lkp_TAPDB_MOSTBLE_Base mlk 
on W_MOS = mlk.code 
and mlk.End_dt is null
and mlk.mpc_cd = 'W' 

 select AOC, 
    R_OT, A_OT, cast([Fill%_OT] as varchar) as [Fill%_OT], Delta_OT,
	R_O2, A_O2, cast([Fill%_O2] as varchar) as [Fill%_O2], Delta_O2,
	R_O3, A_O3, cast([Fill%_O3] as varchar) as [Fill%_O3], Delta_O3,
	R_O4, A_O4, cast([Fill%_O4] as varchar) as [Fill%_O4], Delta_O4,
	R_O5, A_O5, cast([Fill%_O5] as varchar) as [Fill%_O5], Delta_O5,
	R_O6, A_O6, cast([Fill%_O6] as varchar) as [Fill%_O6], Delta_O6
 into #temp_num3
 from #temp_num2
 
 select AOC,  Description,
 	R_OT as [REQ OT], A_OT as [ASGN OT], Delta_OT ,isnull([Fill%_OT],'--') +'%'as [%OH OT],
	R_O2 as [REQ O2], A_O2 as [ASGN O2], Delta_O2 ,isnull([Fill%_O2],'--') +'%'as [%OH O2],
	R_O3 as [REQ O3], A_O3 as [ASGN O3], Delta_O3 ,isnull([Fill%_O3],'--') +'%'as [%OH O3], 
	R_O4 as [REQ O4], A_O4 as [ASGN O4], Delta_O4 ,isnull([Fill%_O4],'--') +'%'as [%OH O4], 
	R_O5 as [REQ O5], A_O5 as [ASGN O5], Delta_O5 ,isnull([Fill%_O5],'--') +'%'as [%OH O5], 
	R_O6 as [REQ O6], A_O6 as [ASGN O6], Delta_O6 ,isnull([Fill%_O6],'--') +'%'as [%OH O6]
from #temp_num3
join RCMSV3_LOOKUPS.dbo.Lkp_TAPDB_MOSTBLE_Base 
on AOC = code 
and End_dt is null
and mpc_cd = 'O' 
			 
 select FA, 
    R_OT, A_OT, cast([Fill%_OT] as varchar) as [Fill%_OT], Delta_OT,
	R_O2, A_O2, cast([Fill%_O2] as varchar) as [Fill%_O2], Delta_O2,
	R_O3, A_O3, cast([Fill%_O3] as varchar) as [Fill%_O3], Delta_O3,
	R_O4, A_O4, cast([Fill%_O4] as varchar) as [Fill%_O4], Delta_O4,
	R_O5, A_O5, cast([Fill%_O5] as varchar) as [Fill%_O5], Delta_O5,
	R_O6, A_O6, cast([Fill%_O6] as varchar) as [Fill%_O6], Delta_O6
into #temp_FA2
from #temp_FUNC
 
 select FA ,  Description,
    R_OT as [REQ OT], A_OT as [OH  OT], Delta_OT ,isnull([Fill%_OT],'--') +'%'as [%OH OT],
	R_O2 as [REQ O2], A_O2 as [OH O2], Delta_O2 ,isnull([Fill%_O2],'--') +'%'as [%OH O2],
	R_O3 as [REQ O3], A_O3 as [OH O3], Delta_O3 ,isnull([Fill%_O3],'--') +'%'as [%OH O3], 
	R_O4 as [REQ O4], A_O4 as [OH O4], Delta_O4 ,isnull([Fill%_O4],'--') +'%'as [%OH O4], 
	R_O5 as [REQ O5], A_O5 as [OH O5], Delta_O5 ,isnull([Fill%_O5],'--') +'%'as [%OH O5], 
	R_O6 as [REQ O6], A_O6 as [OH O6], Delta_O6 ,isnull([Fill%_O6],'--') +'%'as [%OH O6] 
from  #temp_FA2
join RCMSV3_LOOKUPS.dbo.Lkp_TAPDB_MOSTBLE_Base 
on FA = code 
and End_dt is null
and mpc_cd = 'O' 

 


 
 drop table #Temp_POS
 Drop table #temp_PER
 drop table #temp_NUM 
 drop table #temp_num2
 drop table #temp_num3
 drop table #temp_ENLA
 drop table #temp_ENLB
 drop table #temp_WOA
 drop table #temp_WOB
 drop table #temp_FA2
 drop table #temp_FUNC
