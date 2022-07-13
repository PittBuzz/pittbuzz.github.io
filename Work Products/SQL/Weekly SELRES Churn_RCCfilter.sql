------Weekly SELRES Loss Summary-------------------------------------------------------------------------------
---  weekly
 declare @strt_dt as datetime
 declare @end_Dt as datetime
 

 set @strt_dt = '20220102'
 set @end_dt = '20220108' 

 select mpc_cd as MPC, 
 --rcms_ComponentCategory_CD as RCC, 
	sum(AGR_Loss_CNT) as AGR_Loss,
	sum(TPU_Loss_CNT) as TPU_Loss,
	sum(IMA_Loss_CNT) as IMA_Loss,
	sum(SELRES_Loss_CNT) "SELRES_Loss"
	
from RCMSV3_DW.dbo.factsoldierloss L  
where  run_dt between @strt_dt and @end_dt 
	and rcms_ComponentCategory_CD in ('AGR', 'TPU', 'IMA')
	and [Destination_rcms_componentCategory_CD] not in ('AGR', 'TPU', 'IMA')
	--and SELRES_Loss_CNT > '0'
group by mpc_cd --, rcms_ComponentCategory_CD 
with rollup
   


------Weekly SELRES Gain Summary-------------------------------------------------------------------------------
 select mpc_cd as MPC,
--, rcms_ComponentCategory_CD as RCC, 
    sum(AGR_Gain_CNT) as AGR_Gain,
	sum(TPU_Gain_CNT) as TPU_Gain,
	sum(IMA_Gain_CNT) as IMA_Gain,
	sum(SELRES_Gain_CNT) "SELRES_Gain"
from RCMSV3_DW.dbo.factsoldiergain G  
where  run_dt between @strt_dt and @end_dt 
	and rcms_ComponentCategory_CD in ('AGR', 'TPU', 'IMA')
	and [previous_rcms_ComponentCategory_CD] not in ('AGR', 'TPU', 'IMA')
	--and selres_Gain_CNT > '0'
group by mpc_cd--, rcms_ComponentCategory_CD
with rollup


------Weekly SELRES Strength Summary-------------------------------------------------------------------------------
 select mpc_cd as MPC
, --rcms_ComponentCategory_CD as RCC, 
    sum(AGR_CNT) as AGR_Str,
	sum(TPU_CNT) as TPU_Str,
	sum(IMA_CNT) as IMA_Str,
	sum(SELRES_CNT) "SELRES_Strength"
from RCMSV3_DW.dbo.factreservestrength  R
where  run_dt = @end_dt 
	and rcms_ComponentCategory_CD in ('AGR', 'TPU', 'IMA')
	and selres_CNT > '0'
group by mpc_cd--, rcms_ComponentCategory_CD
with rollup
