gain_loss_asg_cmd <- function(fy, mo){
  library(odbc)
  library(DBI)
  library(data.table)
  sql <- paste0("
                declare @yr char(4) = '",fy,"'
                declare @md char(4) = '",mo,"'
                declare @fs char(4) = '1001'
                declare @end_dt date
                declare @strt_dt date = dateadd(yy, 0, concat(@yr, @fs))
                set @end_dt = case when month(eomonth(concat(@yr, @md))) <= 9 then eomonth(concat(@yr, @md)) else dateadd(mm, 0, eomonth(concat(@yr, @md))) end
                
                -- Sums by OF1
                Select 
                DUH.OF1UPC_NAME as CMD, DUH.OF1UPC_CD
                ,Sum(Case when rcms_Grade_CD in ('E1', 'E2', 'E3','E4', 'E5', 'E6', 'E7', 'E8', 'E9') then  SELRES_Gain_CNT else 0 end) as E_Gain
                ,Sum(Case when rcms_Grade_CD in ('O1', 'O2', 'O3','O4', 'O5', 'O6', 'O7', 'O8', 'O9') then  SELRES_Gain_CNT else 0 end) as O_Gain
                ,Sum(Case when rcms_Grade_CD in ('W1', 'W2', 'W3','W4', 'W5') then  SELRES_Gain_CNT else 0 end) as W_Gain
                ,Sum(FSG.SELRES_Gain_CNT) as SELRES_Gain_CNT

                into ##g
                From RCMSV3_DW.dbo.FactSoldierGain FSG 
                Left Join RCMSV3_DW.dbo.DimUnitHierarchies DUH on DUH.Start_DT <= FSG.Run_DT and (DUH.End_DT > FSG.Run_DT or DUH.End_DT is null) and FSG.UPC_CD = DUH.UPC_CD and Hierarchy_CD = 'OF10'
                
                where FSG.Run_DT between @strt_dt and @end_dt
                and DUH.OF1UPC_CD <> 'ATMAA'
                
                Group by DUH.OF1UPC_CD, DUH.OF1UPC_NAME
                
                Order by DUH.OF1UPC_CD
                
                -- Total SELRES Gains
                Select 	
                Sum(Case when rcms_Grade_CD in ('E1', 'E2', 'E3','E4', 'E5', 'E6', 'E7', 'E8', 'E9') then  SELRES_Gain_CNT else 0 end) as E_Gain
                ,Sum(Case when rcms_Grade_CD in ('O1', 'O2', 'O3','O4', 'O5', 'O6', 'O7', 'O8', 'O9') then  SELRES_Gain_CNT else 0 end) as O_Gain
                ,Sum(Case when rcms_Grade_CD in ('W1', 'W2', 'W3','W4', 'W5') then  SELRES_Gain_CNT else 0 end) as W_Gain
                ,Sum(FSG.SELRES_Gain_CNT) as SELRES_Gain_CNT
                
                into ##tg
                From RCMSV3_DW.dbo.FactSoldierGain FSG 
                
                where FSG.Run_DT  between @strt_dt and @end_dt
                /*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
                
                --SELRES LOSSES BY CMD QUERY 
                
                -- Sums by OF1
                Select 
                DUH.OF1UPC_NAME as CMD, DUH.OF1UPC_CD
                
                ,Sum(Case when rcms_Grade_CD in ('E1', 'E2', 'E3','E4', 'E5', 'E6', 'E7', 'E8', 'E9') then  SELRES_Loss_CNT else 0 end) as E_Loss
                ,Sum(Case when rcms_Grade_CD in ('O1', 'O2', 'O3','O4', 'O5', 'O6', 'O7', 'O8', 'O9') then  SELRES_Loss_CNT else 0 end) as O_Loss
                ,Sum(Case when rcms_Grade_CD in ('W1', 'W2', 'W3','W4', 'W5') then  SELRES_Loss_CNT else 0 end) as W_Loss
                ,Sum(FSL.SELRES_Loss_CNT) as SELRES_Loss_CNT
                
                into ##l
                From RCMSV3_DW.dbo.FactSoldierLoss FSL 
                Left Join RCMSV3_DW.dbo.DimUnitHierarchies DUH on DUH.Start_DT <= FSL.Run_DT and (DUH.End_DT > FSL.Run_DT or DUH.End_DT is null) and FSL.UPC_CD = DUH.UPC_CD and Hierarchy_CD = 'OF10'
                
                where FSL.Run_DT between @strt_dt and @end_dt and DUH.OF1UPC_CD <> 'ATMAA' 
                
                Group by DUH.OF1UPC_CD, DUH.OF1UPC_NAME
                
                Order by DUH.OF1UPC_CD
                
                -- Total SELRES Losses
                Select 
                Sum(Case when rcms_Grade_CD in ('E1', 'E2', 'E3','E4', 'E5', 'E6', 'E7', 'E8', 'E9') then  SELRES_Loss_CNT else 0 end) as E_Loss
                ,Sum(Case when rcms_Grade_CD in ('O1', 'O2', 'O3','O4', 'O5', 'O6', 'O7', 'O8', 'O9') then  SELRES_Loss_CNT else 0 end) as O_Loss
                ,Sum(Case when rcms_Grade_CD in ('W1', 'W2', 'W3','W4', 'W5') then  SELRES_Loss_CNT else 0 end) as W_Loss
                ,Sum(FSL.SELRES_Loss_CNT) as SELRES_Loss_CNT
                
                into ##tl
                From RCMSV3_DW.dbo.FactSoldierLoss FSL  
                
                where FSL.Run_DT between @strt_dt and @end_dt
                /*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
                
                --SELRES ASSIGNED BY CMD QUERY
                
                -- Sums by OF1
                Select 
                DUH.OF1UPC_NAME as CMD, DUH.OF1UPC_CD
                
                ,Sum(Case when rcms_Grade_CD in ('E1', 'E2', 'E3','E4', 'E5', 'E6', 'E7', 'E8', 'E9') then  Assigned_CNT else 0 end) as E_Asgn
                ,Sum(Case when rcms_Grade_CD in ('O1', 'O2', 'O3','O4', 'O5', 'O6', 'O7', 'O8', 'O9') then  Assigned_CNT else 0 end) as O_Asgn
                ,Sum(Case when rcms_Grade_CD in ('W1', 'W2', 'W3','W4', 'W5') then  Assigned_CNT else 0 end) as W_Asgn
                ,Sum(RFRS.Assigned_CNT) as SELRES_ASGN
                
                into ##a
                From RCMSV3_DW.dbo.RollupFactReserveStrengthAllWithUpc RFRS
                inner join RCMSV3_DW.dbo.DimUnitHierarchies DUH on DUH.Start_DT <= RFRS.Run_DT and (DUH.End_DT > RFRS.Run_DT or DUH.End_DT is null) and RFRS.UPC_CD = DUH.UPC_CD and Hierarchy_CD = 'OF10'
                
                where RFRS.Run_DT = @end_dt and DUH.OF1UPC_CD <> 'ATMAA' and RFRS.rcms_componentCategory_CD in ('AGR','TPU','IMA')
                
                Group by DUH.OF1UPC_CD, DUH.OF1UPC_NAME
                
                Order by DUH.OF1UPC_CD
                
                -- Total SELRES Assigned
                Select 
                
                Sum(Case when rcms_Grade_CD in ('E1', 'E2', 'E3','E4', 'E5', 'E6', 'E7', 'E8', 'E9') then  SELRES_CNT else 0 end) as E_OH
                ,Sum(Case when rcms_Grade_CD in ('O1', 'O2', 'O3','O4', 'O5', 'O6', 'O7', 'O8', 'O9') then  SELRES_CNT else 0 end) as O_OH
                ,Sum(Case when rcms_Grade_CD in ('W1', 'W2', 'W3','W4', 'W5') then  SELRES_CNT else 0 end) as W_OH
                ,Sum(RFRS.Assigned_CNT) as SELRES_ASGN
                
                into ##ta
                From RCMSV3_DW.dbo.RollupFactReserveStrengthAllWithUpc RFRS
                
                where RFRS.Run_DT = @end_dt and RFRS.rcms_componentCategory_CD in ('AGR','TPU','IMA')
                ")
  ## Connect to RCMS 
  con <- dbConnect(odbc(),"rcms")
  
  dbExecute(con, sql)
  
  ## Get the results
  l <- data.table(dbGetQuery(con, "select * from ##l"))
  tl <- data.table(dbGetQuery(con, "select * from ##tl"))
  g <- data.table(dbGetQuery(con, "select * from ##g"))
  tg <- data.table(dbGetQuery(con, "select * from ##tg"))
  a <- data.table(dbGetQuery(con, "select * from ##a"))
  ta <- data.table(dbGetQuery(con, "select * from ##ta"))
  
  ## Remove the temporary tables from the database
  dbRemoveTable(con, "##l")
  dbRemoveTable(con, "##tl")
  dbRemoveTable(con, "##g")
  dbRemoveTable(con, "##tg")
  dbRemoveTable(con, "##a")
  dbRemoveTable(con, "##ta")
  
  ## Disconnect from RCMS
  dbDisconnect(con)
  return(list(l, tl, g, tg, a, ta))
}
gains_onestop <- function(fy, mo){
  library(odbc)
  library(DBI)
  library(data.table)
  sql <- paste0("
                declare @yr char(4) = '",fy,"'
                declare @md char(4) = '",mo,"'
                declare @fs char(4) = '1001'
                declare @end_dt date
                declare @strt_dt date = dateadd(yy, 0, concat(@yr, @fs))
                set @end_dt = case when month(eomonth(concat(@yr, @md))) <= 9 then eomonth(concat(@yr, @md)) else dateadd(mm, 0, eomonth(concat(@yr, @md))) end
                
                select fsg.MPAGain_DT
                ,fsg.SSNID 
                ,dsr.rcms_Gender_CD as Gender
                ,dsp.rcms_PrimaryMOS_CD as PMOS
                ,dsp.rcms_SecondaryMOS_CD as SMOS
                ,dsp.rcms_AdditionalMOS_CD as AMOS
                ,dsp.PrimarySQI_CD as SM_PSQI
                ,dsp.PrimaryASI_CD as SM_PASI
                ,fsg.Rcms_Grade_Cd as Grade
                ,fsg.mpc_cd as MPC
                ,fsg.rcms_ComponentCategory_CD as RCC
                ,fsg.AccessionCategory_CD
                ,fsg.SoldierGain_CD
                ,fsg.SourceAgency
                ,case when fsg.[previous_rcms_ComponentCategory_CD] is null then ' ' else fsg.[previous_rcms_ComponentCategory_CD] end as Previous_RCC
                ,case when fsg.GainReason_CD is null then '  ' else fsg.GainReason_CD end as Gain_Rsn
                ,case when left(D.description,65) is null then '  ' else left(D.description,65) end as Reason_Desc
                ,case when fsg.GainType_CD is null then '  ' else fsg.GainType_CD end as Gain_Type
                ,case when left(T.description,65) is null then '   ' else left(T.description,65) end as Type_Desc
                ,fsg.[rcms_PSNPS_CD]
                ,fsg.[CurOrg_CD]
                ,fsg.[PreviousCurOrg_CD]
                ,case when c.Description = 'Blank' then ' ' else c.Description end as PreviousOrg
                ,fsg.[UPC_CD] as UPC
                ,[PreviousUPC_CD] as Previous_UPC
                into ##g
                from factsoldiergain fsg  
                left join RCMSV3_DW.dbo.DimSoldierPersonnel dsp on dsp.SSNID = fsg.SSNID and dsp.End_DT is null
                left join RCMSV3_DW.dbo.DimSoldierRestricted dsr on dsp.SoldierRestrictedID=dsr.ID 
                left join rcmsv3_dw.dbo.dimunithierarchies duh on dsp.upc_cd = duh.upc_cd and duh.End_Dt is null and DUH.Hierarchy_CD = 'OF10'
                left join rcmsv3_lookups.dbo.Lkp_MilPersonnelActionRsn_CD_Base D on fsg.GainReason_CD = D.code
                left  join rcmsv3_lookups.dbo.Lkp_MilPersonnelActionType_CD_Base T on fsg.GainType_CD = T.code
                left join [RCMSV3_LOOKUPS].[dbo].[Lkp_CurrentOrganization_CD] c on c.Code = fsg.PreviousCurOrg_CD 
                where  run_dt between @strt_dt and @end_dt 
                and fsg.rcms_ComponentCategory_CD in ('tpu','agr', 'ima')
                
                
                order by 3,4
                
                SELECT x.Grade, x.MPC, x.RCC, x.Previous_RCC,x.CurOrg_CD,x.PreviousCurOrg_CD
                into #GAIN 
                FROM    
                (
                select g.SSNID 
                ,g.Rcms_Grade_Cd as Grade
                ,[SoldierGain_CD]
                ,g.mpc_cd as MPC
                ,g.rcms_ComponentCategory_CD as RCC
                ,case when g.[previous_rcms_ComponentCategory_CD] is null then ' ' else g.[previous_rcms_ComponentCategory_CD] end as Previous_RCC
                ,case when g.GainReason_CD is null then '  ' else g.GainReason_CD end as Gain_Rsn
                ,case when left(D.description,65) is null then '  ' else left(D.description,65) end as Reason_Desc
                ,case when g.GainType_CD is null then '  ' else g.GainType_CD end as Gain_Type
                ,case when left(T.description,65) is null then '   ' else left(T.description,65) end as Type_Desc
                ,[rcms_PSNPS_CD]
                ,[CurOrg_CD]
                ,[PreviousCurOrg_CD]
                ,[UPC_CD]
                ,[PreviousUPC_CD]
                from factsoldiergain g  
                left join rcmsv3_lookups.dbo.Lkp_MilPersonnelActionRsn_CD_Base D on g.GainReason_CD = D.code
                left  join rcmsv3_lookups.dbo.Lkp_MilPersonnelActionType_CD_Base T on g.GainType_CD = T.code
                where  run_dt between @strt_dt and @end_dt and g.rcms_ComponentCategory_CD in ('tpu','agr','ima')) x
                
                SELECT 'E' as MPC, COUNT(Grade) as Gain
                into ##ggrdall
                FROM #GAIN
                WHERE Grade in ('E1', 'E2', 'E3','E4', 'E5', 'E6', 'E7', 'E8', 'E9')
                UNION ALL
                SELECT 'O' as MPC, COUNT(Grade) as Gain
                FROM #GAIN
                WHERE Grade in ('O1', 'O2', 'O3','O4', 'O5', 'O6', 'O7', 'O8', 'O9')
                UNION ALL
                SELECT 'W' as MPC, COUNT(Grade) as Gain
                FROM #GAIN
                WHERE Grade in ('W1', 'W2', 'W3','W4', 'W5')
                
                SELECT [PreviousCurOrg_CD] AS CURORG
                ,Count(*) as CURORG_COUNT
                into ##gcurcnt
                FROM #GAIN
                GROUP BY PreviousCurOrg_CD
                ORDER BY 1 
                
                SELECT Grade
                ,Count(*) as Grade_COUNT
                into ##ggrdcnt
                FROM #GAIN
                GROUP BY Grade
                ORDER BY 1 
                
                SELECT RCC
                ,Count(*) as RCC_COUNT
                into ##grcccnt
                FROM #GAIN 
                GROUP BY RCC
                ORDER BY 1 
                
                drop table #gain
                ")
  ## Connect to RCMS 
  con <- dbConnect(odbc(),"rcms")
  
  dbExecute(con, sql)
  
  ## Get the results
  g <- data.table(dbGetQuery(con, "select * from ##g"))
  gal <- data.table(dbGetQuery(con, "select * from ##ggrdall"))
  gcu <- data.table(dbGetQuery(con, "select * from ##gcurcnt"))
  grd <- data.table(dbGetQuery(con, "select * from ##ggrdcnt"))
  grc <- data.table(dbGetQuery(con, "select * from ##grcccnt"))
  
  ## Remove the temporary tables from the database
  dbRemoveTable(con, "##g")
  dbRemoveTable(con, "##ggrdall")
  dbRemoveTable(con, "##gcurcnt")
  dbRemoveTable(con, "##ggrdcnt")
  dbRemoveTable(con, "##grcccnt")
  
  ## Disconnect from RCMS
  dbDisconnect(con)
  return(list(g, gal, gcu, grd, grc))
}
losses_onestop <- function(fy, mo){
  library(odbc)
  library(DBI)
  library(data.table)
  sql <- paste0("
                declare @yr char(4) = '",fy,"'
                declare @md char(4) = '",mo,"'
                declare @fs char(4) = '1001'
                declare @end_dt date
                declare @strt_dt date = dateadd(yy, 0, concat(@yr, @fs))
                set @end_dt = case when month(eomonth(concat(@yr, @md))) <= 9 then eomonth(concat(@yr, @md)) else dateadd(mm, 0, eomonth(concat(@yr, @md))) end
                
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
                
                into ##l
                From TCC_RCMSV3_DW_DP.dbo.factsoldierloss fsl  
                left join RCMSV3_DW.dbo.DimSoldierPersonnel dsp on dsp.SSNID = fsl.SSNID and dsp.End_DT = fsl.Run_DT
                left join RCMSV3_DW.dbo.DimSoldierRestricted dsr on dsp.SoldierRestrictedID = dsr.ID --and dsr.End_DT = fsl.MPALoss_DT
                left join rcmsv3_dw.dbo.dimunithierarchies duh on dsp.upc_cd = duh.upc_cd and duh.End_Dt = fsl.Run_DT and DUH.Hierarchy_CD = 'OF10'
                left join rcmsv3_lookups.dbo.Lkp_MPAReason_CD_Base d on fsl.LossReason_CD = D.code
                left  join rcmsv3_lookups.dbo.Lkp_MPAType_CD_Base t on fsl.LossType_CD = T.code
                
                Where  run_dt between @strt_dt and @end_dt and fsl.rcms_ComponentCategory_CD in ('tpu','agr','ima')
                
                Order by 3,4
                
                SELECT x.Grade, x.MPC, x.MOS, x.RCC, x.Loss_Rsn, x.Reason_Desc,x.[CurOrg_CD],x.[Destination_CurOrg_CD],x.[UPC_CD],x.[CMD],x.[Destination_UPC_CD] 
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
                ,duh.OF1UPC_NAME as CMD
                ,[Destination_UPC_CD]
                ,l.FirstTermLoss_CNT
                ,l.CareeristLoss_CNT
                
                from TCC_RCMSV3_DW_DP.dbo.factsoldierloss L 
                left join RCMSV3_DW.dbo.DimSoldierPersonnel dsp on dsp.SSNID = L.SSNID and dsp.End_DT is null 
                left join rcmsv3_dw.dbo.dimunithierarchies duh on dsp.upc_cd = duh.upc_cd and duh.End_Dt = l.Run_DT and DUH.Hierarchy_CD = 'OF10'
                left join rcmsv3_lookups.dbo.Lkp_MPAReason_CD_Base D on L.LossReason_CD = D.code
                left join rcmsv3_lookups.dbo.Lkp_MPAType_CD_Base T on L.LossType_CD = T.code
                
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
                into ##lrsn
                FROM #LOSS
                Group by Reason_Desc
                Order by 2 desc
                
                SELECT [Destination_CurOrg_CD] AS CURORG
                ,Count(*) as CURORG_COUNT
                into ##lc
                FROM #LOSS 
                GROUP BY Destination_CurOrg_CD
                ORDER BY 1 
                
                SELECT Grade
                ,Count(*) as Grade_COUNT
                into ##lg
                FROM #LOSS 
                GROUP BY Grade
                ORDER BY 1 
                
                SELECT MOS 
                ,Count (*) as MOS_Count
                into ##ls
                FROM #LOSS
                Group By MOS
                ORDER BY 1
                
                SELECT RCC
                ,Count(*) as RCC_COUNT
                into ##lrcc
                FROM #LOSS 
                GROUP BY RCC
                with rollup
                ORDER BY 1 
                
                drop table #LOSS
                ")
  ## Connect to RCMS 
  con <- dbConnect(odbc(),"rcms")
  
  dbExecute(con, sql)
  
  ## Get the results
  l <- data.table(dbGetQuery(con, "select * from ##l"))
  lrsn <- data.table(dbGetQuery(con, "select * from ##lrsn"))
  lc <- data.table(dbGetQuery(con, "select * from ##lc"))
  lg <- data.table(dbGetQuery(con, "select * from ##lg"))
  ls <- data.table(dbGetQuery(con, "select * from ##ls"))
  lrcc <- data.table(dbGetQuery(con, "select * from ##lrcc"))
  
  ## Remove the temporary tables from the database
  dbRemoveTable(con, "##l")
  dbRemoveTable(con, "##lrsn")
  dbRemoveTable(con, "##lc")
  dbRemoveTable(con, "##lg")
  dbRemoveTable(con, "##ls")
  dbRemoveTable(con, "##lrcc")
  
  ## Disconnect from RCMS
  dbDisconnect(con)
  return(list(l, lrsn, lc, lg, ls, lrcc))
}

str_fys <- function(fy){
  library(DBI)
  sql <- paste0("
               if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.##s')) drop table ##s
               use RCMSV3_DW

                declare @yr char(4) = '",fy,"'
                declare @fs char(4) = '1001'
          
                --retrieve strength as the beginning of the year and end of the year
                declare @rdt date = dateadd(yy, -1, concat(@yr, @fs))
         
                select frs.SSNID
                ,frs.PositionID
                ,frs.rcms_componentCategory_CD as RCC
                ,dsp.MPC_CD as MPC
                ,dsp.GradeAbbreviation_CD as Rank
                ,dsp.rcms_Grade_CD as Grade
                ,dsp.PrimaryMOS_CD as PMOS
                ,dsr.raw_Gender as Gender
                ,DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766 as Age
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) <18 then 1 else 0 end as '16-17'
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) between 18 and 21 then 1 else 0 end as '18-21'
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) between 22 and 29 then 1 else 0 end as '22-29'
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) between 30 and 39 then 1 else 0 end as '30-39'
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) between 40 and 49 then 1 else 0 end as '40-49'
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) >49 then 1 else 0 end as '50+'
                ,duh.UPC_CD as UPC
                ,left(duh.UPC_CD,3) as UPC3
                ,duh.RCMS_UnitName as UnitName
                ,duh.OF1UPC_Name as Command
                ,duh.OF2UPC_Name as BDE
                ,duh.rcms_UnitAddress as UnitAddress
                ,duh.rcms_UnitCity as UnitCity
                ,duh.rcms_UnitState_CD as UnitState
                ,duh.rcms_UnitZip_Cd as UnitZip
                ,CASE WHEN DUH.rcms_UnitState_CD = 'PR' THEN '1 MSC'
                WHEN DUH.rcms_UnitState_CD = 'AE' THEN '7 MSC'
                WHEN DUH.rcms_UnitState_CD = 'HI' THEN '9 MSC'
                WHEN DUH.rcms_UnitState_CD IN ('WA','OR','ID','MT','UT','WY','CO','ND','SD','NE','KS','MN','IA','MO','MI','WI','IL','IN','OH') THEN '88 DIV (R)'
                WHEN DUH.rcms_UnitState_CD IN ('CA','NV','AZ','NM','TX','OK','AR') THEN '63 DIV (R)'
                WHEN DUH.rcms_UnitState_CD IN ('LA','MS','AL','TN','KY','GA','FL','SC','NC') THEN '81 DIV (R)'
                WHEN DUH.rcms_UnitState_CD IN ('ME','NH','VT','NY','MA','RI','CT','NJ','PA','NJ','DE','MD','DC','VA','WV') THEN '99 DIV (R)'
                WHEN (DUH.rcms_UnitState_CD IS NULL OR DUH.rcms_UnitState_CD = '') THEN 'UNKNOWN'
                WHEN DUH.rcms_UnitState_CD = 'AK' THEN 'ALASKA'
                WHEN DUH.rcms_UnitState_CD = 'AP' THEN 'AMERICAN PACIFIC'
                WHEN DUH.rcms_UnitState_CD = 'AS' THEN 'AMERICAN SAMOA'
                WHEN DUH.rcms_UnitState_CD = 'GU' THEN 'GUAM'
                WHEN DUH.rcms_UnitState_CD = 'MP' THEN 'NORTHERN MARIANA ISLANDS'
                WHEN DUH.rcms_UnitState_CD = 'VI' THEN 'VIRGIN ISLANDS'
                ELSE '' END AS RD
                ,frp.AssignedStructuredPosition_CNT as Slotted
                ,frp.AssignedNotInRequiredPosition_CNT as Excess
                ,frp.PositionDoubleSlotted_CNT as DblSlot
                ,frp.TPU_CNT as TPU
                ,frp.AGR_CNT as AGR
                ,frp.IMA_CNT as IMA
                ,frp.SELRES_CNT as SELRES
                ,Case When Left(duh.UPC_CD,1) = '5' then 'Mob'
                When Left(duh.UPC_CD,1) = 'N' then 'BL'
                When Left(duh.UPC_CD,1) < '7'  or Left(duh.UPC_CD,1) between 'A' and 'P' or (SUBSTRING(duh.upc_cd,4,2) = '99' and frs.rcms_componentCategory_CD in ('ima','agr')) then 'AL'
                Else 'BL' end as AL_BL
                ,Case When dsp.RCMS_Grade_CD >= 'E5'  then 1 else 0 end as SrGrd
                ,Case When dsp.rcms_FirstTerm_YN = 1 then 1 else 0 end as FirstTerm
                ,frs.Required_YN as Reqd
                ,frs.Authorized_YN as Auth
                ,Commander_CNT as Cmdr
                
                into ##s
                from FactReserveStrength frs 
                join DimSoldierPersonnel dsp on dsp.ID=frs.SoldierID and dsp.Start_DT<=@rdt and (dsp.End_DT is null or dsp.End_DT>@rdt) and dsp.rcms_ComponentCategory_CD in ('agr','ima','tpu')
                join DimSoldierRestricted DSR on dsp.SoldierRestrictedID = dsr.ID AND dsr.Start_DT <= @rdt AND  (dsr.End_DT > @rdt or dsr.End_DT is null)
                left join FactSelResPosition frp on frp.SSNID=frs.SSNID and frp.Run_DT=@rdt
                left join DimUnitHierarchies duh on frs.upc_cd = duh.UPC_CD and duh.end_dt is null and duh.Hierarchy_ID=10
                
                where frs.Run_DT=@rdt and frs.SelRes_CNT=1
                ")
  ## Connect to RCMS 
  con <- dbConnect(odbc::odbc(),"rcms")
  ## Execute SQL statement, wait until R completes before proceeding
  dbExecute(con, sql)
  ## Get the results
  l <- dbGetQuery(con, "Select * from  ##l")
  ## Disconnect from RCMS
  dbDisconnect(con)
  return(l)
}

str_fye <- function(fy){
  library(DBI)
  sql <- paste0("
                if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.##s')) drop table ##s
                use RCMSV3_DW
                
                declare @yr char(4) = '",fy,"'
                declare @fe char(4) = '0930'
                
                --retrieve strength as the beginning of the year and end of the year
                declare @rdt date = dateadd(yy, 0, concat(@yr, @fe))
                
                select frs.SSNID
                ,frs.PositionID
                ,frs.rcms_componentCategory_CD as RCC
                ,dsp.MPC_CD as MPC
                ,dsp.GradeAbbreviation_CD as Rank
                ,dsp.rcms_Grade_CD as Grade
                ,dsp.PrimaryMOS_CD as PMOS
                ,dsr.raw_Gender as Gender
                ,DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766 as Age
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) <18 then 1 else 0 end as '16-17'
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) between 18 and 21 then 1 else 0 end as '18-21'
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) between 22 and 29 then 1 else 0 end as '22-29'
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) between 30 and 39 then 1 else 0 end as '30-39'
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) between 40 and 49 then 1 else 0 end as '40-49'
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) >49 then 1 else 0 end as '50+'
                ,duh.UPC_CD as UPC
                ,left(duh.UPC_CD,3) as UPC3
                ,duh.RCMS_UnitName as UnitName
                ,duh.OF1UPC_Name as Command
                ,duh.OF2UPC_Name as BDE
                ,duh.rcms_UnitAddress as UnitAddress
                ,duh.rcms_UnitCity as UnitCity
                ,duh.rcms_UnitState_CD as UnitState
                ,duh.rcms_UnitZip_Cd as UnitZip
                ,CASE WHEN DUH.rcms_UnitState_CD = 'PR' THEN '1 MSC'
                WHEN DUH.rcms_UnitState_CD = 'AE' THEN '7 MSC'
                WHEN DUH.rcms_UnitState_CD = 'HI' THEN '9 MSC'
                WHEN DUH.rcms_UnitState_CD IN ('WA','OR','ID','MT','UT','WY','CO','ND','SD','NE','KS','MN','IA','MO','MI','WI','IL','IN','OH') THEN '88 DIV (R)'
                WHEN DUH.rcms_UnitState_CD IN ('CA','NV','AZ','NM','TX','OK','AR') THEN '63 DIV (R)'
                WHEN DUH.rcms_UnitState_CD IN ('LA','MS','AL','TN','KY','GA','FL','SC','NC') THEN '81 DIV (R)'
                WHEN DUH.rcms_UnitState_CD IN ('ME','NH','VT','NY','MA','RI','CT','NJ','PA','NJ','DE','MD','DC','VA','WV') THEN '99 DIV (R)'
                WHEN (DUH.rcms_UnitState_CD IS NULL OR DUH.rcms_UnitState_CD = '') THEN 'UNKNOWN'
                WHEN DUH.rcms_UnitState_CD = 'AK' THEN 'ALASKA'
                WHEN DUH.rcms_UnitState_CD = 'AP' THEN 'AMERICAN PACIFIC'
                WHEN DUH.rcms_UnitState_CD = 'AS' THEN 'AMERICAN SAMOA'
                WHEN DUH.rcms_UnitState_CD = 'GU' THEN 'GUAM'
                WHEN DUH.rcms_UnitState_CD = 'MP' THEN 'NORTHERN MARIANA ISLANDS'
                WHEN DUH.rcms_UnitState_CD = 'VI' THEN 'VIRGIN ISLANDS'
                ELSE '' END AS RD
                ,frp.AssignedStructuredPosition_CNT as Slotted
                ,frp.AssignedNotInRequiredPosition_CNT as Excess
                ,frp.PositionDoubleSlotted_CNT as DblSlot
                ,frp.TPU_CNT as TPU
                ,frp.AGR_CNT as AGR
                ,frp.IMA_CNT as IMA
                ,frp.SELRES_CNT as SELRES
                ,Case When Left(duh.UPC_CD,1) = '5' then 'Mob'
                When Left(duh.UPC_CD,1) = 'N' then 'BL'
                When Left(duh.UPC_CD,1) < '7'  or Left(duh.UPC_CD,1) between 'A' and 'P' or (SUBSTRING(duh.upc_cd,4,2) = '99' and frs.rcms_componentCategory_CD in ('ima','agr')) then 'AL'
                Else 'BL' end as AL_BL
                ,Case When dsp.RCMS_Grade_CD >= 'E5'  then 1 else 0 end as SrGrd
                ,Case When dsp.rcms_FirstTerm_YN = 1 then 1 else 0 end as FirstTerm
                ,frs.Required_YN as Reqd
                ,frs.Authorized_YN as Auth
                ,Commander_CNT as Cmdr
                
                into ##s
                from FactReserveStrength frs 
                join DimSoldierPersonnel dsp on dsp.ID=frs.SoldierID and dsp.Start_DT<=@rdt and (dsp.End_DT is null or dsp.End_DT>@rdt) and dsp.rcms_ComponentCategory_CD in ('agr','ima','tpu')
                join DimSoldierRestricted DSR on dsp.SoldierRestrictedID = dsr.ID AND dsr.Start_DT <= @rdt AND  (dsr.End_DT > @rdt or dsr.End_DT is null)
                left join FactSelResPosition frp on frp.SSNID=frs.SSNID and frp.Run_DT=@rdt
                left join DimUnitHierarchies duh on frs.upc_cd = duh.UPC_CD and duh.end_dt is null and duh.Hierarchy_ID=10
                
                where frs.Run_DT=@rdt and frs.SelRes_CNT=1
                ")
  ## Connect to RCMS 
  con <- dbConnect(odbc::odbc(),"rcms")
  ## Execute SQL statement, wait until R completes before proceeding
  dbExecute(con, sql)
  ## Get the results
  s <- dbGetQuery(con, "Select * from  ##s")
  ## Disconnect from RCMS
  dbDisconnect(con)
  return(s)
}

str_fym <- function(fy, mo){
  library(DBI)
  sql <- paste0("
                if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.##s')) drop table ##s
                use RCMSV3_DW
                
                declare @md char(4) = '",mo,"'
                declare @yr char(4) = '",fy,"'
                
                --retrieve strength from the end of the month
                declare @rdt date = case when month(eomonth(concat(@yr, @md))) <= 9 then eomonth(concat(@yr, @md)) else dateadd(yy, -1, eomonth(concat(@yr, @md))) end
                
                select frs.SSNID
                ,frs.PositionID
                ,frs.rcms_componentCategory_CD as RCC
                ,dsp.MPC_CD as MPC
                ,dsp.GradeAbbreviation_CD as Rank
                ,dsp.rcms_Grade_CD as Grade
                ,dsp.PrimaryMOS_CD as PMOS
                ,dsr.raw_Gender as Gender
                ,DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766 as Age
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) <18 then 1 else 0 end as '16-17'
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) between 18 and 21 then 1 else 0 end as '18-21'
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) between 22 and 29 then 1 else 0 end as '22-29'
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) between 30 and 39 then 1 else 0 end as '30-39'
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) between 40 and 49 then 1 else 0 end as '40-49'
                ,Case when (DATEDIFF(hour,dsr.rcms_DOB_DT,GETDATE())/8766) >49 then 1 else 0 end as '50+'
                ,duh.UPC_CD as UPC
                ,left(duh.UPC_CD,3) as UPC3
                ,duh.RCMS_UnitName as UnitName
                ,duh.OF1UPC_Name as Command
                ,duh.OF2UPC_Name as BDE
                ,duh.rcms_UnitAddress as UnitAddress
                ,duh.rcms_UnitCity as UnitCity
                ,duh.rcms_UnitState_CD as UnitState
                ,duh.rcms_UnitZip_Cd as UnitZip
                ,CASE WHEN DUH.rcms_UnitState_CD = 'PR' THEN '1 MSC'
                WHEN DUH.rcms_UnitState_CD = 'AE' THEN '7 MSC'
                WHEN DUH.rcms_UnitState_CD = 'HI' THEN '9 MSC'
                WHEN DUH.rcms_UnitState_CD IN ('WA','OR','ID','MT','UT','WY','CO','ND','SD','NE','KS','MN','IA','MO','MI','WI','IL','IN','OH') THEN '88 DIV (R)'
                WHEN DUH.rcms_UnitState_CD IN ('CA','NV','AZ','NM','TX','OK','AR') THEN '63 DIV (R)'
                WHEN DUH.rcms_UnitState_CD IN ('LA','MS','AL','TN','KY','GA','FL','SC','NC') THEN '81 DIV (R)'
                WHEN DUH.rcms_UnitState_CD IN ('ME','NH','VT','NY','MA','RI','CT','NJ','PA','NJ','DE','MD','DC','VA','WV') THEN '99 DIV (R)'
                WHEN (DUH.rcms_UnitState_CD IS NULL OR DUH.rcms_UnitState_CD = '') THEN 'UNKNOWN'
                WHEN DUH.rcms_UnitState_CD = 'AK' THEN 'ALASKA'
                WHEN DUH.rcms_UnitState_CD = 'AP' THEN 'AMERICAN PACIFIC'
                WHEN DUH.rcms_UnitState_CD = 'AS' THEN 'AMERICAN SAMOA'
                WHEN DUH.rcms_UnitState_CD = 'GU' THEN 'GUAM'
                WHEN DUH.rcms_UnitState_CD = 'MP' THEN 'NORTHERN MARIANA ISLANDS'
                WHEN DUH.rcms_UnitState_CD = 'VI' THEN 'VIRGIN ISLANDS'
                ELSE '' END AS RD
                ,frp.AssignedStructuredPosition_CNT as Slotted
                ,frp.AssignedNotInRequiredPosition_CNT as Excess
                ,frp.PositionDoubleSlotted_CNT as DblSlot
                ,frp.TPU_CNT as TPU
                ,frp.AGR_CNT as AGR
                ,frp.IMA_CNT as IMA
                ,frp.SELRES_CNT as SELRES
                ,Case When Left(duh.UPC_CD,1) = '5' then 'Mob'
                When Left(duh.UPC_CD,1) = 'N' then 'BL'
                When Left(duh.UPC_CD,1) < '7'  or Left(duh.UPC_CD,1) between 'A' and 'P' or (SUBSTRING(duh.upc_cd,4,2) = '99' and frs.rcms_componentCategory_CD in ('ima','agr')) then 'AL'
                Else 'BL' end as AL_BL
                ,Case When dsp.RCMS_Grade_CD >= 'E5'  then 1 else 0 end as SrGrd
                ,Case When dsp.rcms_FirstTerm_YN = 1 then 1 else 0 end as FirstTerm
                ,frs.Required_YN as Reqd
                ,frs.Authorized_YN as Auth
                ,Commander_CNT as Cmdr
                
                into ##s
                from FactReserveStrength frs 
                join DimSoldierPersonnel dsp on dsp.ID=frs.SoldierID and dsp.Start_DT<=@rdt and (dsp.End_DT is null or dsp.End_DT>@rdt) and dsp.rcms_ComponentCategory_CD in ('agr','ima','tpu')
                join DimSoldierRestricted DSR on dsp.SoldierRestrictedID = dsr.ID AND dsr.Start_DT <= @rdt AND  (dsr.End_DT > @rdt or dsr.End_DT is null)
                left join FactSelResPosition frp on frp.SSNID=frs.SSNID and frp.Run_DT=@rdt
                left join DimUnitHierarchies duh on frs.upc_cd = duh.UPC_CD and duh.end_dt is null and duh.Hierarchy_ID=10
                
                where frs.Run_DT=@rdt and frs.SelRes_CNT=1
                ")
  ## Connect to RCMS 
  con <- dbConnect(odbc::odbc(),"rcms")
  ## Execute SQL statement, wait until R completes before proceeding
  dbExecute(con, sql)
  ## Get the results
  s <- dbGetQuery(con, "Select * from  ##s")
  ## Disconnect from RCMS
  dbDisconnect(con)
  return(s)
}

losses_a <- function(fy, mo){
  library(DBI)
  sql <- paste0("
                if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.##l')) drop table ##l
                use rcmsv3_dw

                --update FY and month as needed
                declare @md char(4) = '",mo,"' --needs to be in a 1101 format
                declare @yr char(4) = '",fy,"' --needs to be in a 2021 format
                declare @fs char(4) = '1001'
                declare @fe char(4) = '0930'

                --pass in fy variable for annual losses
                declare @sd date = dateadd(yy, -1, concat(@yr, @fs))
                declare @ed date = dateadd(yy, 0, concat(@yr, @fe))

                select distinct SSNID
                ,fsl.Run_DT
                ,MPALoss_DT
                ,MonthName
                ,FiscalWeek as F
                ,FiscalMonth as FM
                ,FiscalQuarter as FQ
                ,FiscalYear as FY
                ,Destination_rcms_componentCategory_CD as Dest_RCC
                ,MPC_CD as MPC
                ,rcms_Grade_CD as Grade
                ,LossReason_CD + '-' + lk.Description as LossReason
                ,case when fsl.lossreason_cd in ('KK','PC','PD','PE') then 'Drug or Alcohol'
                --when fsl.lossreason_cd in () then 'APFT Failure'
                when fsl.lossreason_cd in ('KB','KD','KF','KM','KN','KO','KT','SD') then 'Misconduct'
                when fsl.lossreason_cd in ('EI','EJ','EK','EM','EO','FD','FI','FJ','FK','FL','FN','FO','FP','FQ','FR','GI','GK','GJ','HE','HI','HY','SB') then 'Disability'
                --when fsl.lossreason_cd in () then 'Disability Retire' -- FORSCOM's list but not ours
                when fsl.lossreason_cd in ('FH') then 'Physical not Disability'
                when fsl.lossreason_cd in ('DF','DG') then 'Parenthood/Pregnancy'
                when fsl.lossreason_cd in ('EG','HJ','SG') then 'Unsat/Non-Participant'
                when fsl.lossreason_cd in ('FV') then 'Weight Control'
                when fsl.lossreason_cd in ('FS','NE','JC','JD') then 'Court-Martial or ILO C-M'
                when fsl.lossreason_cd in ('GA') then 'Entry-Level Separation' -- our list but not FORSCOM's
                when fsl.lossreason_cd in ('AJ','EZ','FT','JA') then 'Medical not Physical/Disability' -- our list but not FORSCOM's
                when fsl.LossReason_CD in ('AA','AG','AL','GE','GN') then 'Release to Other Compo/Service'
                when fsl.lossreason_cd in ('BF','BK') then 'ETS'
                else 'Other'
                end as Loss_Bin
                ,FirstTermLoss_CNT
                ,CareeristLoss_CNT
                ,ObligorLoss_CNT
                ,TPU_Loss_CNT
                ,IMA_Loss_CNT
                ,AGR_Loss_CNT
                ,ROW_NUMBER() over(partition by ssnid order by fsl.run_dt desc) as rn
                
                into ##losses
                from factsoldierloss fsl
                left join DimDate dd on dd.FullDayName_DT=fsl.Run_DT
                left join RCMSV3_LOOKUPS.dbo.Lkp_MPAReason_CD_Base lk on lk.Code = fsl.LossReason_CD
                
                where fsl.Run_DT between @sd and @ed and MPALoss_DT between @sd and @ed
                and rcms_componentCategory_CD in ('tpu','agr','ima') and Destination_rcms_componentCategory_CD not in ('tpu','agr','ima')
                
                select * 
                into ##l
                from ##losses where rn=1
                ")
  ## Connect to RCMS 
  con <- dbConnect(odbc::odbc(),"rcms")
  ## Execute SQL statement, wait until R completes before proceeding
  dbExecute(con, sql)
  ## Get the results
  l <- dbGetQuery(con, "Select * from  ##l")
  ## Disconnect from RCMS
  dbDisconnect(con)
  return(l)
}

losses_m <- function(fy, mo){
  library(DBI)
  sql <- paste0("
                if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.##l')) drop table ##l
                use rcmsv3_dw
                
                --update FY and month as needed
                declare @md char(4) = '",mo,"' --needs to be in a 1101 format
                declare @yr char(4) = '",fy,"' --needs to be in a 2021 format
                
                --pass in mo variable for monthly losses
                declare @sd date = case when month(dateadd(yy, 0, concat(@yr, @md))) <= 9 then dateadd(yy, 0, concat(@yr, @md)) else dateadd(yy, -1, concat(@yr, @md)) end
                declare @ed date = case when month(eomonth(concat(@yr, @md))) <= 9 then eomonth(concat(@yr, @md)) else dateadd(yy, -1, eomonth(concat(@yr, @md))) end
                
                select distinct SSNID
                ,fsl.Run_DT
                ,MPALoss_DT
                ,MonthName
                ,FiscalWeek as F
                ,FiscalMonth as FM
                ,FiscalQuarter as FQ
                ,FiscalYear as FY
                ,Destination_rcms_componentCategory_CD as Dest_RCC
                ,MPC_CD as MPC
                ,rcms_Grade_CD as Grade
                ,LossReason_CD + '-' + lk.Description as LossReason
                ,case when fsl.lossreason_cd in ('KK','PC','PD','PE') then 'Drug or Alcohol'
                --when fsl.lossreason_cd in () then 'APFT Failure'
                when fsl.lossreason_cd in ('KB','KD','KF','KM','KN','KO','KT','SD') then 'Misconduct'
                when fsl.lossreason_cd in ('EI','EJ','EK','EM','EO','FD','FI','FJ','FK','FL','FN','FO','FP','FQ','FR','GI','GK','GJ','HE','HI','HY','SB') then 'Disability'
                --when fsl.lossreason_cd in () then 'Disability Retire' -- FORSCOM's list but not ours
                when fsl.lossreason_cd in ('FH') then 'Physical not Disability'
                when fsl.lossreason_cd in ('DF','DG') then 'Parenthood/Pregnancy'
                when fsl.lossreason_cd in ('EG','HJ','SG') then 'Unsat/Non-Participant'
                when fsl.lossreason_cd in ('FV') then 'Weight Control'
                when fsl.lossreason_cd in ('FS','NE','JC','JD') then 'Court-Martial or ILO C-M'
                when fsl.lossreason_cd in ('GA') then 'Entry-Level Separation' -- our list but not FORSCOM's
                when fsl.lossreason_cd in ('AJ','EZ','FT','JA') then 'Medical not Physical/Disability' -- our list but not FORSCOM's
                when fsl.LossReason_CD in ('AA','AG','AL','GE','GN') then 'Release to Other Compo/Service'
                when fsl.lossreason_cd in ('BF','BK') then 'ETS'
                else 'Other'
                end as Loss_Bin
                ,FirstTermLoss_CNT
                ,CareeristLoss_CNT
                ,ObligorLoss_CNT
                ,TPU_Loss_CNT
                ,IMA_Loss_CNT
                ,AGR_Loss_CNT
                ,ROW_NUMBER() over(partition by ssnid order by fsl.run_dt desc) as rn
                
                into ##losses
                from factsoldierloss fsl
                left join DimDate dd on dd.FullDayName_DT=fsl.Run_DT
                left join RCMSV3_LOOKUPS.dbo.Lkp_MPAReason_CD_Base lk on lk.Code = fsl.LossReason_CD
                
                where fsl.Run_DT between @sd and @ed and MPALoss_DT between @sd and @ed
                and rcms_componentCategory_CD in ('tpu','agr','ima') and Destination_rcms_componentCategory_CD not in ('tpu','agr','ima')
                
                select * 
                into ##l
                from ##losses where rn=1
                ")
  ## Connect to RCMS 
  con <- dbConnect(odbc::odbc(),"rcms")
  ## Execute SQL statement, wait until R completes before proceeding
  dbExecute(con, sql)
  ## Get the results
  l <- dbGetQuery(con, "Select * from  ##l")
  ## Disconnect from RCMS
  dbDisconnect(con)
  return(l)
}

gains_a <- function(fy, mo){
  library(DBI)
  sql <- paste0("
                if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.##g')) drop table ##g
                use rcmsv3_dw

                --update FY and month as needed
                declare @md char(4) = '",mo,"'
                declare @yr char(4) = '",fy,"'
                declare @fs char(4) = '1001'
                declare @fe char(4) = '0930'
                
                --pass in mo variable for monthly gains
                --declare @sd date = case when month(dateadd(yy, 0, concat(@yr, @md))) <= 9 then dateadd(yy, 0, concat(@yr, @md)) else dateadd(yy, -1, concat(@yr, @md)) end
                --declare @ed date = case when month(eomonth(concat(@yr, @md))) <= 9 then eomonth(concat(@yr, @md)) else dateadd(yy, -1, eomonth(concat(@yr, @md))) end
                
                --pass in fy variable for annual gains
                declare @sd date = dateadd(yy, -1, concat(@yr, @fs))
                declare @ed date = dateadd(yy, 0, concat(@yr, @fe))
                
                --retrieve last month's results
                --declare @eom date = (select max(EOMONTH(run_dt, -1)) from FactSoldierGain) 
                
                select distinct fsg.SSNID
                ,fsg.Run_DT
                ,MPAGain_DT
                ,MonthName
                ,FiscalWeek as FW
                ,FiscalMonth as FM
                ,FiscalQuarter as FQ
                ,FiscalYear as FY
                ,fsg.rcms_ComponentCategory_CD as RCC
                ,fsg.MPC_CD as MPC
                ,dsp.rcms_PrimaryMOS_CD as PMOS
                ,dsp.rcms_SecondaryMOS_CD as SMOS
                ,dsp.rcms_AdditionalMOS_CD as AMOS
                ,dsp.PrimarySQI_CD as SM_PSQI
                ,dsp.PrimaryASI_CD as SM_PASI
                ,dsr.rcms_Gender_CD as Gender
                ,dsp.rcms_Grade_CD as Grade
                ,GainReason_CD + '-' + lk.Description as GainReason
                ,AccessionCategory_CD as AccessionCat
                ,fsg.SoldierGain_CD
                ,fsg.SourceAgency
                ,TPU_Gain_CNT
                ,AGR_Gain_CNT
                ,IMA_Gain_CNT
                ,row_number() over(partition by fsg.ssnid order by fsg.run_dt desc) as rn
                
                into ##gains
                from FactSoldierGain fsg
                left join RCMSV3_DW.dbo.DimSoldierPersonnel dsp on dsp.SSNID = fsg.SSNID and dsp.End_DT is null
                left join RCMSV3_DW.dbo.DimSoldierRestricted dsr on dsp.SoldierRestrictedID=dsr.ID 
                left join DimDate dd on dd.FullDayName_DT=fsg.Run_DT
                left join RCMSV3_LOOKUPS.dbo.Lkp_MPAReason_CD_Base lk on lk.Code = fsg.GainReason_CD
                
                where fsg.rcms_ComponentCategory_CD in ('tpu','ima','agr') and previous_rcms_ComponentCategory_CD not in ('agr','ima','tpu')
                and fsg.Run_DT between @sd and @ed and MPAGain_DT between @sd and @ed
                
                select *
                into ##g
                from ##gains where rn=1
                ")
  ## Connect to RCMS 
  con <- dbConnect(odbc::odbc(),"rcms")
  ## Execute SQL statement, wait until R completes before proceeding
  dbExecute(con, sql)
  ## Get the results
  g <- dbGetQuery(con, "Select * from  ##g")
  ## Disconnect from RCMS
  dbDisconnect(con)
  return(g)
}

gains_m <- function(fy, mo){
  library(DBI)
  sql <- paste0("
                if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.##g')) drop table ##g
                use rcmsv3_dw
                
                --update FY and month as needed
                declare @md char(4) = '",mo,"'
                declare @yr char(4) = '",fy,"'

                --pass in mo variable for monthly gains
                declare @sd date = case when month(dateadd(yy, 0, concat(@yr, @md))) <= 9 then dateadd(yy, 0, concat(@yr, @md)) else dateadd(yy, -1, concat(@yr, @md)) end
                declare @ed date = case when month(eomonth(concat(@yr, @md))) <= 9 then eomonth(concat(@yr, @md)) else dateadd(yy, -1, eomonth(concat(@yr, @md))) end
                
                select distinct fsg.SSNID
                ,fsg.Run_DT
                ,MPAGain_DT
                ,MonthName
                ,FiscalWeek as FW
                ,FiscalMonth as FM
                ,FiscalQuarter as FQ
                ,FiscalYear as FY
                ,fsg.rcms_ComponentCategory_CD as RCC
                ,fsg.MPC_CD as MPC
                ,dsp.rcms_PrimaryMOS_CD as PMOS
                ,dsp.rcms_SecondaryMOS_CD as SMOS
                ,dsp.rcms_AdditionalMOS_CD as AMOS
                ,dsp.PrimarySQI_CD as SM_PSQI
                ,dsp.PrimaryASI_CD as SM_PASI
                ,dsr.rcms_Gender_CD as Gender
                ,dsp.rcms_Grade_CD as Grade
                ,GainReason_CD + '-' + lk.Description as GainReason
                ,AccessionCategory_CD as AccessionCat
                ,fsg.SoldierGain_CD
                ,fsg.SourceAgency
                ,TPU_Gain_CNT
                ,AGR_Gain_CNT
                ,IMA_Gain_CNT
                ,row_number() over(partition by fsg.ssnid order by fsg.run_dt desc) as rn
                
                into ##gains
                from FactSoldierGain fsg
                left join RCMSV3_DW.dbo.DimSoldierPersonnel dsp on dsp.SSNID = fsg.SSNID and dsp.End_DT is null
                left join RCMSV3_DW.dbo.DimSoldierRestricted dsr on dsp.SoldierRestrictedID=dsr.ID 
                left join DimDate dd on dd.FullDayName_DT=fsg.Run_DT
                left join RCMSV3_LOOKUPS.dbo.Lkp_MPAReason_CD_Base lk on lk.Code = fsg.GainReason_CD
                
                where fsg.rcms_ComponentCategory_CD in ('tpu','ima','agr') and previous_rcms_ComponentCategory_CD not in ('agr','ima','tpu')
                and fsg.Run_DT between @sd and @ed and MPAGain_DT between @sd and @ed
                
                select *
                into ##g
                from ##gains where rn=1
                ")
  ## Connect to RCMS 
  con <- dbConnect(odbc::odbc(),"rcms")
  ## Execute SQL statement, wait until R completes before proceeding
  dbExecute(con, sql)
  ## Get the results
  g <- dbGetQuery(con, "Select * from  ##g")
  ## Disconnect from RCMS
  dbDisconnect(con)
  return(g)
}