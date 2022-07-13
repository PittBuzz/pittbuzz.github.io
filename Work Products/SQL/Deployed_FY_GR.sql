
-------Provides SELRES that are currently deployed.  It can be adapted to determine SELRES currently mobilized

With CTE as (Select distinct S.SSN  -- uses CTE rather than temp tables
					,primarymos_cd
					,M.rcms_Grade_CD as Grade
					,APCContingency_Cd 
                    ,Contingency 
			        ,m.rcms_ComponentCategory_CD 
			        ,TourStart_Dt 
			        ,Duration 
			        ,DateAdd(d,Duration-1,TourStart_Dt) as Expected_Tour_End
			        ,TourEnd_Dt as Actual_Tour_End 
					,m.End_Dt
from RCMSV3_DW.dbo.DimReserveTourMobilization M  
Left Join RCMSV3_DW.dbo.DimSSN S on M.SSNID = S.ID
left join rcmsv3_dw.dbo.dimsoldierpersonnel dsp on m.ssnid = dsp.ssnid and dsp.End_Dt is null  
where TourStart_Dt between '2016-10-01' and '2021-09-30' --can filter for mobliziation time frames by specifying start and end dates
and [MonthsHFPay] >='1'  -- activate this and clause to determine SELRES currently deployed.  Leave greened out for currently mobilized
and M.rcms_ComponentCategory_CD = 'TPU'
and M.Duration > 400

group by SSN, primarymos_cd,M.rcms_Grade_CD,APCContingency_Cd, Contingency,m.rcms_ComponentCategory_CD,
TourStart_Dt, Duration, tourEnd_Dt, m.End_dt
)

Select 
Grade
,count(*) as GR_Count
  
from CTE 

group by Grade



