/* Creates a table identifying instructors and drill sgts for the gen force */

Declare @rdt as datetime
 set @rdt = '20220331'

SELECT  SSNID,GFC,RCC,ETS,GRADE,PMOS,DSQI,SQI, S_SQI,A_SQI,PULHES,Profile,DEPL,FLAG -- the output from the query table free of dupes
into #tempover
FROM

(SELECT 
DSP. ssnid
,DUH.OF1UPC_NAME as GFC
,DSP.rcms_PrimaryMOS_CD as PMOS 
,DSP.DutySQI_CD as DSQI
,DSP.PrimarySQI_CD as SQI
,DSP.SecondarySQI_CD as S_SQI
,DSP.AdditionalSQI_CD as A_SQI
,DSP.rcms_ComponentCategory_CD as RCC
,DSP.PhysicalProfileSerial as PULHES
,case when (DSP.PhysicalProfileSerial  <> '1') then 1 else 0 end as 'Profile'
,case when (dsp.PersonnelDeployabilityLimitation_CD not in ('AN','LR','LD','LZ','LI','EC','FP','PA','PD','LA','UP','SM','SS','CO','CS','LS','DP','TN','AW','MP') and 
            dsm.mrc_cd <>'3') then 'Deployable' else LKDEPL.Description end as DEPL
,DSP.rcms_ETS_DT as ETS
,DSP.MilitaryEducation_CD + ' - ' + LKMIL.Description as MILED
,DSP.rcms_Grade_CD as GRADE
,DSP.YrsCreditableService
,DSP.SuspensionRsn_CD + ' - ' + LKSUSP.Description as FLAG

, ROW_NUMBER () OVER(PARTITION BY dsp.ssnid ORDER BY 'W'+dsp.rcms_grade_cd DESC) AS RN


FROM rcmsv3_dw.dbo.DimSoldierPersonnel DSP
JOIN rcmsv3_dw.dbo.DimSoldierRestricted DSR on DSP.SoldierRestrictedID = DSR.ID and dsr.start_dt <= @rdt and  (dsr.End_DT is null or dsr.End_DT > @rdt)
JOIN rcmsv3_dw.dbo.DimUnitHierarchies DUH on DSP.UPC_CD = DUH.UPC_CD and DUH.Hierarchy_CD = 'OF10' and duh.start_dt <= @rdt and  (duh.End_DT is null or duh.End_DT > @rdt) 
left join dimselresmedical dsm on dsm.ssnid=dsp.ssnid and dsm.start_dt <= @rdt and (dsm.end_dt is null or dsm.end_dt > @rdt) 
left join [RCMSV3_DW].[dbo].[DimReservePosition] POS on DSP.upc_cd= POS.UPC_CD and pos.start_dt <= @rdt and  (pos.End_DT is null or pos.End_DT > @rdt)
	LEFT JOIN RCMSV3_LOOKUPS..Lkp_SFPAReason_CD LKSUSP on DSP.SuspensionRsn_CD = LKSUSP.Code and LKSUSP.End_DT is null
	LEFT JOIN RCMSV3_LOOKUPS..Lkp_PersonnelDeployabilityLimitation_CD LKDEPL on DSP.PersonnelDeployabilityLimitation_CD = LKDEPL.Code and LKDEPL.End_DT is null
	LEFT JOIN RCMSV3_LOOKUPS..Lkp_ASI_CD_Base LKASI on DSP.PrimaryASI_CD = LKASI.Code and LKASI.End_DT is null
	LEFT JOIN RCMSV3_LOOKUPS..Lkp_SQI_CD_Base LKSQI on DSP.PrimarySQI_CD = LKSQI.Code and LKSQI.End_DT is null
	LEFT JOIN RCMSV3_LOOKUPS..Lkp_MilitaryEducation_CD LKMIL on DSP.MilitaryEducation_CD = LKMIL.Code and LKMIL.End_DT is null
WHERE 
DSP.rcms_ComponentCategory_CD In('TPU', 'agr','IMA')
AND (DSP.PrimarySQI_CD = 'X' OR DSP.SecondarySQI_CD = 'X' or DSP.AdditionalSQI_CD = 'X')
--and pos.OverStrength_YN = '1'
and dsp.start_dt <= @rdt and  (dsp.End_DT is null or dsp.End_DT > @rdt) 
 
)x

where RN = '1'

SELECT SSNID,GFC,RCC,ETS,GRADE,PMOS,DSQI,SQI, S_SQI,A_SQI,PULHES,Profile,DEPL,FLAG
FROM #tempover

--drop table #tempover


