
Select H.OF1UPC_CD as "CMDs", H.OF1UPC_NAME,
Sum( Case When RFL.TPU_Loss_CNT>0 and RFL.LossReason_CD in ( 'BF' , 'EG' , 'GA' , 'FE' , 'DX' , 'AA', 'AL', 'AG', 'GE', 'GN') --end) as 'Controllable Losses'
Then RFL.TPU_Loss_CNT Else 0 End) as "Current Contollable losses", 
Sum( Case When RFL.TPU_Loss_CNT>0 and RFL.LossReason_CD = 'BF' -- Expir Of Arng Or Usar Tos With No Remaining Mil Svc Oblg
Then RFL.TPU_Loss_CNT Else 0 End) as "BF", 
Sum( Case When RFL.TPU_Loss_CNT>0 and RFL.LossReason_CD = 'EG' -- Unsatisfactory Participation
Then RFL.TPU_Loss_CNT Else 0 End) as "EG", 
Sum( Case When RFL.TPU_Loss_CNT>0 and RFL.LossReason_CD = 'GA' -- Unsatisfactory Entry Level Status Performance Or Conduct
Then RFL.TPU_Loss_CNT Else 0 End) as "GA", 
Sum( Case When RFL.TPU_Loss_CNT>0 and RFL.LossReason_CD = 'FE' -- Voluntary Request
Then RFL.TPU_Loss_CNT Else 0 End) as "FE", 
Sum( Case When RFL.TPU_Loss_CNT>0 and RFL.LossReason_CD = 'DX' --  Cogent Personal Reasons
Then RFL.TPU_Loss_CNT Else 0 End) as "DX", 
Sum( Case When RFL.TPU_Loss_CNT>0 and RFL.LossReason_CD = 'AA' -- Enlistment
Then RFL.TPU_Loss_CNT Else 0 End) as "AA", 
Sum( Case When RFL.TPU_Loss_CNT>0 and RFL.LossReason_CD = 'AL' -- Appointment
Then RFL.TPU_Loss_CNT Else 0 End) as "AL", 
Sum( Case When RFL.TPU_Loss_CNT>0 and RFL.LossReason_CD = 'AG' -- To Enter U.S. Military Academy (USMA)
Then RFL.TPU_Loss_CNT Else 0 End) as "AG",
Sum( Case When RFL.TPU_Loss_CNT>0 and RFL.LossReason_CD = 'GE' -- Apptd in Ano Uniform Svc (U.S. PH, Env Sci, Etc)
Then RFL.TPU_Loss_CNT Else 0 End) as "GE",
Sum( Case When RFL.TPU_Loss_CNT>0 and RFL.LossReason_CD = 'GN' -- Enl/Appt in Reg/Res Comp of an AF o/t U.S. Army
Then RFL.TPU_Loss_CNT Else 0 End) as "GN"   

--into #SQL9 

From RCMSV3_DW.dbo.RollupFactSoldierLoss RFL  
inner join RCMSV3_DW.dbo.DimUnitHierarchies H on H.Start_DT <= RFL.Run_DT 
and (H.End_DT > RFL.Run_DT or H.End_DT is null) and RFL.UPC_CD = H.UPC_CD 
inner join RCMSV3_DW.dbo.DimDate D on RFL.Run_DT = D.FullDayName_DT 
Where ([H].[Hierarchy_CD] = 'OF10' ) AND (RFL.[Run_DT] BETWEEN '20211001' and '20220331' )
 
Group by [H].[OF1UPC_CD], H.OF1UPC_NAME
Order by H.OF1UPC_CD; --** this gives the TPU controllable losses---



------------------------------------------------Assigned AVG FYTD TPU Strength--------------------------

