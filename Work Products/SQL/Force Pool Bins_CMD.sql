Declare @rdt as datetime 
set @rdt = '20201231'

Select 
DUH.OF1UPC_CD
,DUH.OF1UPC_NAME
,Count(DSP.SSNID) as ASGN
,Count(Case when (DSP.PersonnelDeployabilityLimitation_CD in ('TN', 'EC','SM')) then DSP.PersonnelDeployabilityLimitation_CD else null end) as TN
,Count(Case when (DSP.PersonnelDeployabilityLimitation_CD = 'DP') and (DSP.PersonnelDeployabilityLimitation_CD not in ('TN', 'EC','SM')) then DSP.PersonnelDeployabilityLimitation_CD else null end) as DEP
,Count(Case when (DUH.OF1UPC_CD in ('71TAA','72VAA','88DAA')) and (DSP.PersonnelDeployabilityLimitation_CD not in ('TN','DP', 'SM', 'EC')) then DSP.PersonnelDeployabilityLimitation_CD else null end) as GF
,Count(Case when (DUH.OF1UPC_CD in ('47AAA','00EAA')) and (DSP.PersonnelDeployabilityLimitation_CD not in ('TN','DP', 'SM', 'EC')) and (DUH.OF1UPC_CD not in ('71TAA','72VAA','88DAA')) 
 then DSP.PersonnelDeployabilityLimitation_CD else null end) as ABOVELINE
,Count(Case when (RF.UPC3 is not null) and (DSP.PersonnelDeployabilityLimitation_CD not in ('TN','DP', 'SM', 'EC')) and (dsp.rcms_DMOSQ_CD not in ('ND','NE','NF','NH','NJ','NN','NO','NP','NR', 'NT','NW')) 
 and (fsm.MODSAdjusted_CNT>0 or fsm.MRC_CD <> ('3')) and isnull(fss.SuspensionRsn_CD,'') not in ('%B%', '%W%') and (DUH.OF1UPC_CD not in ('71TAA','72VAA','88DAA''47AAA','00EAA')) 
 then DSP.PersonnelDeployabilityLimitation_CD else null end)as 'ARF'
,Count(Case when (RF.UPC3 is null)and (dsp.PersonnelDeployabilityLimitation_CD in ('AN','AW','CC', 'CO', 'CS', 'DL','DU', 'FP', 'LA', 'LD', 'LI', 'LR', 'LS', 'LZ', 'MP', 'PA', 'PD', 'SD', 'SS','UP')
					and DUH.OF1UPC_CD not in ('71TAA','72VAA','88DAA','47AAA','00EAA')and DSP.PersonnelDeployabilityLimitation_CD not in ('TN','DP', 'SM', 'EC')
						or (fsm.MODSAdjusted_CNT>0 and fsm.MRC_CD = '3' and FSM.CombatDeferment_YN = 'N') and DUH.OF1UPC_CD not in ('71TAA','72VAA','88DAA','47AAA','00EAA')) 
						or (dsp.rcms_DMOSQ_CD in ('ND','NE','NF','NH','NJ','NN','NO','NP','NR', 'NT','NW') and DUH.OF1UPC_CD not in ('71TAA','72VAA','88DAA','47AAA','00EAA') 
					and DSP.PersonnelDeployabilityLimitation_CD not in ('YY','RC','TN','DP', 'SM', 'EC')
						or (fss.SuspensionRsn_CD like'%B%'or fss.SuspensionRsn_CD like '%W%') and DUH.OF1UPC_CD not in ('71TAA','72VAA','88DAA','47AAA','00EAA') 
							and DSP.PersonnelDeployabilityLimitation_CD not in ('TN','DP', 'SM', 'EC'))then DSP.PersonnelDeployabilityLimitation_CD else null end) as NON_DEP
,Count(Case when (RF.UPC3 is null)and (DSP.PersonnelDeployabilityLimitation_CD in ('YY', 'RC') and  DSP.PersonnelDeployabilityLimitation_CD not in 
('TN','DP', 'SM', 'EC','AN','AW','CO','CS','DU','DL','ET','LD','RT','TC','PD','SD')) and (fsm.MODSAdjusted_CNT>0 or fsm.MRC_CD <> ('3')) 
 and (DUH.OF1UPC_CD not in ('71TAA','72VAA','88DAA','47AAA','00EAA')) and (dsp.rcms_DMOSQ_CD  not in ('ND','NE','NF','NH','NJ','NN','NO','NP','NR', 'NT','NW')) 
 and isnull(fss.SuspensionRsn_CD,'') not in ('B', 'W') then DSP.PersonnelDeployabilityLimitation_CD else null end) as AVAIL

--Else 'NON-DEPL' end
From RCMSV3_DW.dbo.FactReserveStrength FRS
JOIN RCMSV3_DW.dbo.DimSoldierPersonnel DSP on FRS.SoldierID = DSP.ID  and DSP.Start_DT <= @rdt and (DSP.End_DT > @rdt or DSP.End_DT IS NULL)
LEFT JOIN RCMS_ORSA.dbo.ArmyResponseForceUnitList RF on left(FRS.UPC_CD,3) = RF.UPC3
left join RCMSV3_DW.dbo.DimUnitHierarchies DUH on FRS.UPC_CD = DUH.UPC_CD and DUH.start_dt <= @rdt and (DUH.End_DT > @rdt  or DUH.End_DT is null) AND DUH.Hierarchy_CD ='OF10'
left join RCMSV3_DW.dbo.FactSelResMedical fsm on fsm.SSNID = FRS.SSNID and fsm.Run_Dt = @rdt
left join RCMSV3_DW.dbo.FactSelresSFPA fss on fss.SSNID = DSP.SSNID and fss.Run_DT = FRS.Run_DT

Where 
FRS.Run_DT = @rdt
AND DSP.[rcms_ComponentCategory_CD] in ('AGR','TPU','IMA')

Group by 
DUH.OF1UPC_CD
,DUH.[OF1UPC_NAME]

Order by 2