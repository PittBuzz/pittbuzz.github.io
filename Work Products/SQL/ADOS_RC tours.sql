/* Provides tabular and summary data of SMs on a ADOS-RC tour by FY */

/*-----------------------------By Name-------------------------------------*/
select dsad.ssnid as SSNID
	,dsr.FullName
	,dsp.mpc_cd as MPC
	,dsp.rcms_Grade_CD as GR
	,duh.[OF1UPC_CD] as CMD_UPC
	,duh.[OF1UPC_NAME] as CMD
	,duh.[UPC_CD] as Unit_UPC
	,duh.[rcms_UnitName] as Unit
	,tourstart_dt
	,tourend_dt
	,tourduration
	,dsp.rcms_primarymos_cd as PMOS
	,DSP.PrimaryASI_CD as ASI
	,DSP.PrimarySQI_CD as SQI
	,[ADOSTour_YN]
	,[ADOSType]
	,case when(dsad.tourstart_dt between '20141001' and '20150930') then '2015'
		when(dsad.tourstart_dt between '20151001' and '20160930') then '2016'
		when(dsad.tourstart_dt between '20161001' and '20170930') then '2017'
		when(dsad.tourstart_dt between '20171001' and '20180930') then '2018'
		when(dsad.tourstart_dt between '20181001' and '20190930') then '2019'
		when(dsad.tourstart_dt between '20191001' and '20200930') then '2020'
		when(dsad.tourstart_dt between '20201001' and '20210930') then '2021'
		end as ADOS_RC_FY
 
FROM [RCMSV3_DW].[dbo].[DimSoldierActiveDuty] dsad
left join dimsoldierpersonnel dsp on dsad.ssnid = dsp.ssnid and dsp.end_dt is null
left join [dbo].[DimSoldierRestricted] dsr on dsp.[SoldierRestrictedID] = dsr.id and dsr.end_dt is null
left join [dbo].[DimUnitHierarchies] duh on dsp.upc_cd = duh.upc_cd and duh.end_dt is null and [Hierarchy_ID] = 10

where dsad.end_dt is null
and tourstart_dt between '20141001' and '20210930'
and adostour_yn = 1 
and [ADOSType] = 'ADOS-RC'

order by 1


/*-------------------------------Summary Data------------------------*/
SELECT x.SSNID, x.MPC, x.GR, x.CMD, x.PMOS, x.ADOS_RC_FY
INTO #ADOS_RC
FROM
(
	select dsad.ssnid as SSNID
		,dsr.FullName
		,dsp.mpc_cd as MPC
		,dsp.rcms_Grade_CD as GR
		,duh.[OF1UPC_CD] as CMD_UPC
		,duh.[OF1UPC_NAME] as CMD
		,duh.[UPC_CD] as Unit_UPC
		,duh.[rcms_UnitName] as Unit
		,tourstart_dt
		,tourend_dt
		,tourduration
		,dsp.rcms_primarymos_cd as PMOS
		,DSP.PrimaryASI_CD as ASI
		,DSP.PrimarySQI_CD as SQI
		,[ADOSTour_YN]
		,[ADOSType]
		,case when(dsad.tourstart_dt between '20141001' and '20150930') then '2015'
			when(dsad.tourstart_dt between '20151001' and '20160930') then '2016'
			when(dsad.tourstart_dt between '20161001' and '20170930') then '2017'
			when(dsad.tourstart_dt between '20171001' and '20180930') then '2018'
			when(dsad.tourstart_dt between '20181001' and '20190930') then '2019'
			when(dsad.tourstart_dt between '20191001' and '20200930') then '2020'
			when(dsad.tourstart_dt between '20201001' and '20210930') then '2021'
			end as ADOS_RC_FY
 
	FROM [RCMSV3_DW].[dbo].[DimSoldierActiveDuty] dsad
	left join dimsoldierpersonnel dsp on dsad.ssnid = dsp.ssnid and dsp.end_dt is null
	left join [dbo].[DimSoldierRestricted] dsr on dsp.[SoldierRestrictedID] = dsr.id and dsr.end_dt is null
	left join [dbo].[DimUnitHierarchies] duh on dsp.upc_cd = duh.upc_cd and duh.end_dt is null and [Hierarchy_ID] = 10

	where dsad.end_dt is null
	and tourstart_dt between '20141001' and '20210930'
	and adostour_yn = 1 
	and [ADOSType] = 'ADOS-RC'
	)x

--MPC
SELECT 'E' as MPC, COUNT(GR) as ADOS_RC
FROM #ADOS_RC
WHERE GR in ('E1', 'E2', 'E3','E4', 'E5', 'E6', 'E7', 'E8', 'E9')
UNION ALL
SELECT 'O' as MPC, COUNT(GR) as ADOS_RC
FROM #ADOS_RC
WHERE GR in ('O1', 'O2', 'O3','O4', 'O5', 'O6', 'O7', 'O8', 'O9')
UNION ALL
SELECT 'W' as MPC, COUNT(GR) as ADOS_RC
FROM #ADOS_RC
WHERE GR in ('W1', 'W2', 'W3','W4', 'W5')

--FY
SELECT '2015' as ADOS_RC_FY, COUNT(SSNID) as Soldier
FROM #ADOS_RC
WHERE ADOS_RC_FY = 2015
UNION ALL
SELECT '2016' as ADOS_RC_FY, COUNT(SSNID) as Soldier
FROM #ADOS_RC
WHERE ADOS_RC_FY = 2016
UNION ALL
SELECT '2017' as ADOS_RC_FY, COUNT(SSNID) as Soldier
FROM #ADOS_RC
WHERE ADOS_RC_FY = 2017
UNION ALL
SELECT '2018' as ADOS_RC_FY, COUNT(SSNID) as Soldier
FROM #ADOS_RC
WHERE ADOS_RC_FY = 2018
UNION ALL
SELECT '2019' as ADOS_RC_FY, COUNT(SSNID) as Soldier
FROM #ADOS_RC
WHERE ADOS_RC_FY = 2019
UNION ALL
SELECT '2020' as ADOS_RC_FY, COUNT(SSNID) as Soldier
FROM #ADOS_RC
WHERE ADOS_RC_FY = 2020
UNION ALL
SELECT '2021' as ADOS_RC_FY, COUNT(SSNID) as Soldier
FROM #ADOS_RC
WHERE ADOS_RC_FY = 2021

--Grade
SELECT GR
,Count(*) as Grade_COUNT
FROM #ADOS_RC 
GROUP BY GR
ORDER BY 1 

--MOS
SELECT PMOS 
,Count (*) as MOS_Count
FROM #ADOS_RC
Group By PMOS
ORDER BY 1

--CMD
SELECT CMD 
,Count (*) as CMD_Count
FROM #ADOS_RC
Group By CMD
ORDER BY 1

DROP TABLE #ADOS_RC