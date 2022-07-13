## Query the rcms database
setFYweek <- function(w){
  library(dplyr)
  x <- case_when(
    w == 40 ~ 1,
    w == 41 ~ 2,
    w == 42 ~ 3,
    w == 43 ~ 4,
    w == 44 ~ 5,
    w == 45 ~ 6,
    w == 46 ~ 7,
    w == 47 ~ 8,
    w == 48 ~ 9,
    w == 49 ~ 10,
    w == 50 ~ 11,
    w == 51 ~ 12,
    w == 52 ~ 13,
    w == 1 ~ 14,
    w == 2 ~ 15,
    w == 3 ~ 16,
    w == 4 ~ 17,
    w == 5 ~ 18,
    w == 6 ~ 19,
    w == 7 ~ 20,
    w == 8 ~ 21,
    w == 9 ~ 22,
    w == 10 ~ 23,
    w == 11 ~ 24,
    w == 12 ~ 25,
    w == 13 ~ 26,
    w == 14 ~ 27,
    w == 15 ~ 28,
    w == 16 ~ 29,
    w == 17 ~ 30,
    w == 18 ~ 31,
    w == 19 ~ 32,
    w == 20 ~ 33,
    w == 21 ~ 34,
    w == 22 ~ 35,
    w == 23 ~ 36,
    w == 24 ~ 37,
    w == 25 ~ 38,
    w == 26 ~ 39,
    w == 27 ~ 40,
    w == 28 ~ 41,
    w == 29 ~ 42,
    w == 30 ~ 43,
    w == 31 ~ 44,
    w == 32 ~ 45,
    w == 33 ~ 46,
    w == 34 ~ 47,
    w == 35 ~ 48,
    w == 36 ~ 49,
    w == 37 ~ 50,
    w == 38 ~ 51,
    w == 39 ~ 52,
    TRUE ~ as.double(w)
  )
  return(x)
}

chkRundate <- function(x){
  library(stringr)
  library(dplyr)
  
  dy <- str_pad(1:30, 2,"left", "0")
  mo <- str_pad(1:12, 2,"left", "0")
  yr <- as.character(2020:2030)
  
  msg1 <- case_when(
    !str_sub(x, 7, 8) %in% dy ~ "bad dy",
    !str_sub(x, 5, 6) %in% mo ~ "bad mo",
    !str_sub(x, 1, 4) %in% yr ~ "bad yr",
    TRUE ~ "Run date all good"
  )
  return(msg1)
}

sixMoLoss <- function(mm, ed){
library(DBI)
sql <- paste0("
if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.##wg')) drop table ##wg
------Weekly Gain Count Report-------------------------------------------------------------------------------
---By Reason, weekly
declare @strt_dt as datetime
declare @end_Dt as datetime
set @strt_dt = '",sd,"'
set @end_dt = '",ed,"'--Day of Dans report
select mpc_cd as MPC
,rcms_ComponentCategory_CD as RCC, 
case when G.GainReason_CD is null then '  ' else G.GainReason_CD end as Gain_Rsn,
case when left(D.description,65) is null then '  ' else   left(D.description,65) end as Reason_Desc, 
sum(SELRES_Gain_CNT) Cnt
--from TCC_RCMSV3_DW_DP.dbo.factsoldiergain G  
into ##wg
from RCMSV3_DW.dbo.factsoldiergain G  
left join rcmsv3_lookups.dbo.Lkp_MPAReason_CD_Base D on G.GainReason_CD = D.code
left  join rcmsv3_lookups.dbo.Lkp_MPAType_CD_Base T on G.GainType_CD = T.code
where  run_dt between @strt_dt and @end_dt 
and rcms_ComponentCategory_CD = 'TPU'
and tpu_Gain_CNT > '0'
group by mpc_cd, rcms_ComponentCategory_CD, G.GainReason_CD, 
left(D.description,65) 
order by 1,5 desc
")
## Connect to RCMS 
con <- dbConnect(odbc::odbc(),"rcms")
## Execute SQL statement, wait until R completes before proceeding
dbExecute(con, sql)
## Get the results
wg <- dbGetQuery(con, "Select * from  ##wg")
## Disconnect from RCMS
dbDisconnect(con)
return(wg)
}

wkSelresL <- function(sd, ed){
library(DBI)  

sql <- paste0("
if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.##sl')) drop table ##sl
------Weekly SELRES Loss Summary-------------------------------------------------------------------------------
---  weekly
declare @strt_dt as datetime
declare @end_Dt as datetime
set @strt_dt = '",sd,"'
set @end_dt = '",ed,"' 
select mpc_cd as MPC, 
--rcms_ComponentCategory_CD as RCC, 
sum(AGR_Loss_CNT) as AGR_Loss,
sum(TPU_Loss_CNT) as TPU_Loss,
sum(IMA_Loss_CNT) as IMA_Loss,
sum(SELRES_Loss_CNT) SELRES_Loss
into ##sl
from RCMSV3_DW.dbo.factsoldierloss L  
where  run_dt between @strt_dt and @end_dt 
and rcms_ComponentCategory_CD in ('AGR', 'TPU', 'IMA')
and SELRES_Loss_CNT > '0'
group by mpc_cd --, rcms_ComponentCategory_CD 
with rollup
")
## Connect to RCMS 
con <- dbConnect(odbc::odbc(),"rcms")
## Execute SQL statement, wait until R completes before proceeding
dbExecute(con, sql)

## Get the results
sl <- dbGetQuery(con, "Select * from  ##sl")

## Disconnect from RCMS
dbDisconnect(con)
return(sl)
}

wkSelresG <- function(sd, ed){
library(DBI)    
  
sql <- paste0("
if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.##sg')) drop table ##sg
------Weekly SELRES Gain Summary-------------------------------------------------------------------------------
declare @strt_dt as datetime
declare @end_Dt as datetime
set @strt_dt = '",sd,"'
set @end_dt = '",ed,"' 
select mpc_cd as MPC,
--, rcms_ComponentCategory_CD as RCC, 
sum(AGR_Gain_CNT) as AGR_Gain,
sum(TPU_Gain_CNT) as TPU_Gain,
sum(IMA_Gain_CNT) as IMA_Gain,
sum(SELRES_Gain_CNT) SELRES_Gain
into ##sg
from RCMSV3_DW.dbo.factsoldiergain G  
where  run_dt between @strt_dt and @end_dt 
and rcms_ComponentCategory_CD in ('AGR', 'TPU', 'IMA')
and selres_Gain_CNT > '0'
group by mpc_cd--, rcms_ComponentCategory_CD
with rollup
")
## Connect to RCMS 
con <- dbConnect(odbc::odbc(),"rcms")
## Execute SQL statement, wait until R completes before proceeding
dbExecute(con, sql)

## Get the results
sg <- dbGetQuery(con, "Select * from  ##sg")

## Disconnect from RCMS
dbDisconnect(con)
return(sg)
}

wkSelresStr <- function(sd, ed){
library(DBI)    
  
sql <- paste0("
if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.##ss')) drop table ##ss
------Weekly SELRES Strength Summary-------------------------------------------------------------------------------
declare @strt_dt as datetime
declare @end_Dt as datetime
set @strt_dt = '",sd,"'
set @end_dt = '",ed,"' 
select mpc_cd as MPC
, --rcms_ComponentCategory_CD as RCC, 
sum(AGR_CNT) as AGR_Str,
sum(TPU_CNT) as TPU_Str,
sum(IMA_CNT) as IMA_Str,
sum(SELRES_CNT) SELRES_Strength
into ##ss
from RCMSV3_DW.dbo.factreservestrength  R
where  run_dt = @end_dt 
and rcms_ComponentCategory_CD in ('AGR', 'TPU', 'IMA')
and selres_CNT > '0'
group by mpc_cd--, rcms_ComponentCategory_CD
with rollup
")
## Connect to RCMS 
con <- dbConnect(odbc::odbc(),"rcms")
## Execute SQL statement, wait until R completes before proceeding
dbExecute(con, sql)

## Get the results
ss <- dbGetQuery(con, "Select * from  ##ss")

## Disconnect from RCMS
dbDisconnect(con)
return(ss)
}

sixMoGain <- function(ed, mm){
library(DBI)

sql <- paste0("
if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.##mg')) drop table ##mg
declare @end_Dt as datetime
declare @strt_dt_6mo as datetime
set @end_dt = '",ed,"'--Day of Dans report
set @strt_dt_6mo = '",mm,"'
------Six Month Gain Count Report-------------------------------------------------------------------------------
---By Reason
select mpc_cd as MPC, rcms_ComponentCategory_CD as RCC, 
case when left(G.GainReason_CD,2) is null then '  ' else left(G.GainReason_CD,2)  end as Gain_Rsn,
case when left(D.description,65) is null then '                   ' else  left(D.description,65) end as Reason_Desc, 
sum(SELRES_Gain_CNT) Cnt
into ##mg
--from TCC_RCMSV3_DW_DP.dbo.factsoldiergain G 
from RCMSV3_DW.dbo.factsoldiergain G 
left join rcmsv3_lookups.dbo.Lkp_MPAReason_CD_Base D on G.GainReason_CD = D.code 
left  join rcmsv3_lookups.dbo.Lkp_MPAType_CD_Base T on G.GainType_CD = T.code 
where  run_dt between @strt_dt_6mo and @end_dt 
and  rcms_ComponentCategory_CD = 'tpu'
and tpu_Gain_CNT > '0'
group by mpc_cd, rcms_ComponentCategory_CD, left(G.GainReason_CD,2), left(D.description,65) 
order by 1,3--desc
")
## Connect to RCMS 
con <- dbConnect(odbc::odbc(),"rcms")
## Execute SQL statement, wait until R completes before proceeding
dbExecute(con, sql)

## Get the results
mg <- dbGetQuery(con, "Select * from  ##mg")

## Disconnect from RCMS
dbDisconnect(con)
return(mg)
}
weeklyLoss <- function(sd, ed){
  library(DBI)
  
  sql <- paste0("
                if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.##wl')) drop table ##wl
                ------Weekly Loss Count Report-------------------------------------------------------------------------------
                ---  By Reason, weekly
                declare @strt_dt as datetime
                declare @end_Dt as datetime
                declare @strt_dt_6mo as datetime
                set @strt_dt = '",sd,"'
                set @end_dt = '",ed,"' --Day of Dan's report
                select mpc_cd as MPC
                , rcms_ComponentCategory_CD as RCC, 
                case when L.LossReason_CD is null then '  ' else L.LossReason_CD end as Loss_Rsn,
                case when left(D.description,65) is null then '  ' else   left(D.description,65) end as Reason_Desc, 
                sum(SELRES_Loss_CNT) Cnt
                --from TCC_RCMSV3_DW_DP.dbo.factsoldierloss L
                into ##wl
                from RCMSV3_DW.dbo.factsoldierloss L  
                left join rcmsv3_lookups.dbo.Lkp_MPAReason_CD_Base D on L.LossReason_CD = D.code
                left  join rcmsv3_lookups.dbo.Lkp_MPAType_CD_Base T on L.LossType_CD = T.code
                where  run_dt between @strt_dt and @end_dt 
                and rcms_ComponentCategory_CD = 'TPU'
                and tpu_Loss_CNT > '0'
                group by mpc_cd, rcms_ComponentCategory_CD, L.LossReason_CD, 
                left(D.description,65) 
                order by 1,5 desc
                ")
  ## Connect to RCMS 
  con <- dbConnect(odbc::odbc(),"rcms")
  ## Execute SQL statement, wait until R completes before proceeding
  dbExecute(con, sql)
  ## Get the results
  wl <- dbGetQuery(con, "Select * from  ##wl")
  ## Disconnect from RCMS
  dbDisconnect(con)
  return(wl)
}

sixMoLoss <- function(mm, ed){
  library(DBI)
  sql <- paste0("
                if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.##ml')) drop table ##ml
                ------Six Month Loss Count Report-------------------------------------------------------------------------------
                ---By Reason
                declare @strt_dt_6mo as datetime
                declare @end_Dt as datetime
                set @end_dt = '",ed,"'--Day of Dans report
                set @strt_dt_6mo = '",mm,"'
                select mpc_cd as MPC, rcms_ComponentCategory_CD as RCC,
                case when left(L.LossReason_CD,2) is null then '  ' else left(L.LossReason_CD,2)  end as Loss_Rsn,
                case when left(D.description,65) is null then '                   ' else  left(D.description,65) end as Reason_Desc,
                sum(SELRES_Loss_CNT) Cnt
                into ##ml
                --from TCC_RCMSV3_DW_DP.dbo.factsoldierloss L
                from RCMSV3_DW.dbo.factsoldierloss L
                left join rcmsv3_lookups.dbo.Lkp_MPAReason_CD_Base D on L.LossReason_CD = D.code
                left  join rcmsv3_lookups.dbo.Lkp_MPAType_CD_Base T on L.LossType_CD = T.code
                where  run_dt between @strt_dt_6mo and @end_dt
                and  rcms_ComponentCategory_CD = 'tpu'
                and tpu_Loss_CNT > '0'
                group by mpc_cd, rcms_ComponentCategory_CD, left(L.LossReason_CD,2), left(D.description,65)
                order by 1,3 --desc
                ")
  ## Connect to RCMS 
  con <- dbConnect(odbc::odbc(),"rcms")
  ## Execute SQL statement, wait until R completes before proceeding
  dbExecute(con, sql)
  ## Get the results
  ml <- dbGetQuery(con, "Select * from  ##ml")
  ## Disconnect from RCMS
  dbDisconnect(con)
  return(ml)
}
sixMoGain <- function(mm, ed){
  library(DBI)
  sql <- paste0("
if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.##mg')) drop table ##mg
declare @end_Dt as datetime
declare @strt_dt_6mo as datetime
set @end_dt = '",ed,"'--Day of Dans report
set @strt_dt_6mo = '",mm,"'
------Six Month Gain Count Report-------------------------------------------------------------------------------
---By Reason
select mpc_cd as MPC, rcms_ComponentCategory_CD as RCC, 
case when left(G.GainReason_CD,2) is null then '  ' else left(G.GainReason_CD,2)  end as Gain_Rsn,
case when left(D.description,65) is null then '                   ' else  left(D.description,65) end as Reason_Desc, 
sum(SELRES_Gain_CNT) Cnt
into ##mg
--from TCC_RCMSV3_DW_DP.dbo.factsoldiergain G 
from RCMSV3_DW.dbo.factsoldiergain G 
left join rcmsv3_lookups.dbo.Lkp_MPAReason_CD_Base D on G.GainReason_CD = D.code 
left  join rcmsv3_lookups.dbo.Lkp_MPAType_CD_Base T on G.GainType_CD = T.code 
where  run_dt between @strt_dt_6mo and @end_dt 
and  rcms_ComponentCategory_CD = 'tpu'
and tpu_Gain_CNT > '0'
group by mpc_cd, rcms_ComponentCategory_CD, left(G.GainReason_CD,2), left(D.description,65) 
order by 1,3--desc
")
  ## Connect to RCMS 
  con <- dbConnect(odbc::odbc(),"rcms")
  ## Execute SQL statement, wait until R completes before proceeding
  dbExecute(con, sql)
  ## Get the results
  mg <- dbGetQuery(con, "Select * from  ##mg")
  ## Disconnect from RCMS
  dbDisconnect(con)
  return(mg)
}
weeklyGain <- function(sd, ed){
  library(DBI)
  sql <- paste0("
------Weekly Gain Count Report-------------------------------------------------------------------------------
---  By Reason, weekly
if exists (select * from tempdb.dbo.sysobjects where id = object_id(N'tempdb.dbo.##wg')) drop table ##wg
declare @strt_dt as datetime
declare @end_Dt as datetime
set @strt_dt = '",sd,"'
set @end_dt = '",ed,"'--Day of Dans report
select mpc_cd as MPC
, rcms_ComponentCategory_CD as RCC, 
case when G.GainReason_CD is null then '  ' else G.GainReason_CD end as Gain_Rsn,
case when left(D.description,65) is null then '  ' else   left(D.description,65) end as Reason_Desc, 
sum(SELRES_Gain_CNT) Cnt
--from TCC_RCMSV3_DW_DP.dbo.factsoldiergain G
into ##wg
from RCMSV3_DW.dbo.factsoldiergain G  
left join rcmsv3_lookups.dbo.Lkp_MPAReason_CD_Base D on G.GainReason_CD = D.code
left  join rcmsv3_lookups.dbo.Lkp_MPAType_CD_Base T on G.GainType_CD = T.code
where  run_dt between @strt_dt and @end_dt 
and rcms_ComponentCategory_CD = 'TPU'
and tpu_Gain_CNT > '0'
group by mpc_cd, rcms_ComponentCategory_CD, G.GainReason_CD, 
left(D.description,65) 
order by 1,5 desc
")
  ## Connect to RCMS 
  con <- dbConnect(odbc::odbc(),"rcms")
  ## Execute SQL statement, wait until R completes before proceeding
  dbExecute(con, sql)
  ## Get the results
  wg <- dbGetQuery(con, "Select * from  ##wg")
  ## Disconnect from RCMS
  dbDisconnect(con)
  return(wg)
}