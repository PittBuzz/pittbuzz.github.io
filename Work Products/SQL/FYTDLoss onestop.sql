------Loss Report in several different reports, by name and summary-------

 declare @strt_dt as datetime
 declare @end_Dt as datetime    --determines loss ranges weeks, months, years

 set @strt_dt = '20211001'
 set @end_dt = '20220331'

 Select fsl.MPALoss_DT
,fsl.SSNID
,duh.OF1UPC_NAME as GFC
,fsl.[UPC_CD] as UPC
,dsp.PrimaryMOS_CD as PMOS
,dsp.SecondaryMOS_CD as SMOS
,dsp.AdditionalMOS_CD as AMOS
,dsp.PrimarySQI_CD as SM_PSQI
,dsp.PrimaryASI_CD as SM_PASI
,fsl.Rcms_Grade_Cd as Grade
,fsl.mpc_cd as MPC
,fsl.rcms_ComponentCategory_CD as RCC
,case when fsl.LossReason_CD is null then '  ' else fsl.LossReason_CD end as Loss_Rsn
,case when left(D.description,65) is null then '                   ' else   left(d.description,65) end as Reason_Desc
,fsl.[CurOrg_CD] 
,fsl.[Destination_CurOrg_CD] as Destination_CURORG
,fsl.[Destination_UPC_CD] as Destination
,fsl.FirstTermLoss_CNT
,fsl.CareeristLoss_CNT

From TCC_RCMSV3_DW_DP.dbo.factsoldierloss fsl  
left join RCMSV3_DW.dbo.DimSoldierPersonnel dsp on dsp.SSNID = fsl.SSNID and dsp.End_DT = fsl.Run_DT
left join RCMSV3_DW.dbo.DimSoldierRestricted dsr on dsp.SoldierRestrictedID = dsr.ID --and dsr.End_DT = fsl.MPALoss_DT
left join rcmsv3_dw.dbo.dimunithierarchies duh on dsp.upc_cd = duh.upc_cd and duh.End_Dt = fsl.Run_DT and DUH.Hierarchy_CD = 'OF10'
	left join rcmsv3_lookups.dbo.Lkp_MPAReason_CD_Base d on fsl.LossReason_CD = D.code
	left  join rcmsv3_lookups.dbo.Lkp_MPAType_CD_Base t on fsl.LossType_CD = T.code
Where  run_dt between @strt_dt and @end_dt and fsl.rcms_ComponentCategory_CD in ('tpu','agr','ima')

Order by 3,4

 SELECT x.Grade, x.MPC, x.MOS, x.RCC, x.Loss_Rsn, x.Reason_Desc,x.[CurOrg_CD],x.[Destination_CurOrg_CD],x.[UPC_CD],x.[Destination_UPC_CD] 
 into #LOSS 
 FROM    
(
Select l.SSNID 
,l.Rcms_Grade_Cd as Grade
,dsp.rcms_PrimaryMOS_CD as MOS
,l.mpc_cd as MPC
,l.rcms_ComponentCategory_CD as RCC
,case when L.LossReason_CD is null then '  ' else L.LossReason_CD end as Loss_Rsn
,case when left(D.description,65) is null then '                   ' else   left(D.description,65) end as Reason_Desc
,L.[CurOrg_CD] 
,[Destination_CurOrg_CD]
,L.[UPC_CD]
,[Destination_UPC_CD]
from TCC_RCMSV3_DW_DP.dbo.factsoldierloss L 
left join RCMSV3_DW.dbo.DimSoldierPersonnel dsp on dsp.SSNID = L.SSNID and dsp.End_DT is null 
left join rcmsv3_lookups.dbo.Lkp_MPAReason_CD_Base D on L.LossReason_CD = D.code
left  join rcmsv3_lookups.dbo.Lkp_MPAType_CD_Base T on L.LossType_CD = T.code
where  run_dt between @strt_dt and @end_dt and l.rcms_ComponentCategory_CD in ('tpu','agr','ima')) x

SELECT 'E' as MPC, COUNT(Grade) as Loss
FROM #LOSS
WHERE Grade in ('E1', 'E2', 'E3','E4', 'E5', 'E6', 'E7', 'E8', 'E9')
UNION ALL
SELECT 'O' as MPC, COUNT(Grade) as Loss
FROM #LOSS
WHERE Grade in ('O1', 'O2', 'O3','O4', 'O5', 'O6', 'O7', 'O8', 'O9')
UNION ALL
SELECT 'W' as MPC, COUNT(Grade) as Loss
FROM #LOSS
WHERE Grade in ('W1', 'W2', 'W3','W4', 'W5')

SELECT
Reason_Desc
,Count(Loss_Rsn) as Count
FROM #LOSS
Group by Reason_Desc
Order by 2 desc

SELECT [Destination_CurOrg_CD] AS CURORG
,Count(*) as CURORG_COUNT
FROM #LOSS 
GROUP BY Destination_CurOrg_CD
ORDER BY 1 

SELECT Grade
,Count(*) as Grade_COUNT
FROM #LOSS 
GROUP BY Grade
ORDER BY 1 

SELECT MOS 
,Count (*) as MOS_Count
FROM #LOSS
Group By MOS
ORDER BY 1

SELECT RCC
,Count(*) as RCC_COUNT
FROM #LOSS 
GROUP BY RCC
with rollup
ORDER BY 1 

drop table #LOSS
