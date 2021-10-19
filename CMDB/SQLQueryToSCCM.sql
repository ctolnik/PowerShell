USE CM_MMZ
SELECT vcm.SiteCode AS SiteCode,
	cs.[timestamp] AS tm,
	cs.ResourceID,
	cs.Name0 AS deviceName,
	CASE WHEN cs.Manufacturer0 = 'INTEL_' THEN 'INTEL' WHEN cs.Manufacturer0 = 'MICRO-STAR INTERNATIONAL CO.,LTD' THEN 'MSI' WHEN cs.Manufacturer0 = 'System manufacturer' THEN 'Custom' WHEN cs.Manufacturer0 like '%ASUS%' THEN 'ASUS' WHEN cs.Manufacturer0 like '%Hewlett-Packard%' THEN 'HP' WHEN cs.Manufacturer0 like '%GIGABYTE%' THEN 'GIGABYTE' WHEN cs.Manufacturer0 like '%O%E%M%' THEN 'OEM'  ELSE cs.Manufacturer0  END AS deviceVENDor,
	CASE WHEN cs.Model0 like '%O%E%M%' THEN 'N\A' WHEN cs.Model0 = 'System Product Name' THEN 'N\A' ELSE cs.Model0 END  AS deviceModel,
	cs.NumberOfProcessors0 AS CPUCount,REPLACE(cs.UserName0, 'npo\', '') AS [owner],
	CASE LEN(csp.IdentifyingNumber0) WHEN 0 THEN 'N\A' ELSE csp.IdentifyingNumber0 END AS serialNumber,
	p.Name0 AS CPUModel,
	p.NormSpeed0 AS CPUSpeed,
	CASE WHEN cs.Model0 like '%book%' THEN 'Notebook' ELSE 'Office station' END AS  DeviceType,

	p.NumberOfCores0 AS CPUCore,

	pmv.Capacity0/1024 AS MemoryCapacity,

	
	
	
	
	LEFT(pmv.modelMemory, len(pmv.modelMemory)-1) AS modelMemory,

	LEFT(phd.HDDModel, len(phd.HDDModel) - 1) AS HDDModel,
	LEFT(vc.Description0, CHARINDEX(',', vc.Description0) - 1) AS VGAModel,
	LEFT(ea.ipEhernet, CHARINDEX(',', ea.ipEhernet) - 1) AS ipEthernet,
	REPLACE(LEFT(ea.macEhternet, len(ea.macEhternet) - 1), ':', '-') AS macEthernet,
	LEFT(ea.descriptionEhternet, CHARINDEX(',', ea.descriptionEhternet) - 1) AS descriptionEhternet,
	LEFT(wa.ipWIreless, CHARINDEX(',', wa.ipWIreless) - 1) AS ipWIreless,
	REPLACE(LEFT(wa.macWIreless, len(wa.macWIreless) - 1), ':', '-') AS macWIreless,
	wa.descriptionWIreless,
	CASE WHEN os.Caption0 like '%Windows 10%' THEN CONCAT('Windows 10 (',REPLACE(REPLACE(left(cs.SystemType0,'3'),'x',''),'86','32'),'-bit)') WHEN os.Caption0 like '%Windows 8%' THEN  CONCAT('Windows 8.x (',REPLACE(REPLACE(left(cs.SystemType0,'3'),'x',''),'86','32'),'-bit)') WHEN os.Caption0 like '%Windows 7%' THEN  CONCAT('Windows 7 (',REPLACE(REPLACE(left(cs.SystemType0,'3'),'x',''),'86','32'),'-bit)')  WHEN os.Caption0 like '%Windows XP%' THEN  CONCAT('Windows XP (',REPLACE(REPLACE(left(cs.SystemType0,'3'),'x',''),'86','32'),'-bit)')  WHEN os.Caption0 like '%Windows vista%' THEN 'Windows vista' ELSE '' END AS OS

FROM v_GS_COMPUTER_SYSTEM cs
  JOIN v_ClientMachines vcm
    ON cs.ResourceID = vcm.ResourceID

  LEFT JOIN v_GS_COMPUTER_SYSTEM_PRODUCT csp
    ON cs.ResourceID = csp.ResourceID

  LEFT JOIN v_GS_PROCESSOR p 
	ON cs.ResourceID = p.ResourceID

  LEFT JOIN v_GS_OPERATING_SYSTEM os 
	ON cs.ResourceID = os.ResourceID
	 
  LEFT JOIN ((SELECT pmc.ResourceID AS ResourceID, 
					SUM(pmc.Capacity0) AS Capacity0, 
					STUFF((SELECT '' + pm1.Manufacturer0 +'-' + pm1.PartNumber0 +  '|'+CAST((pm1.Capacity0/1024) AS varchar(8))+ ','
							FROM v_GS_PHYSICAL_MEMORY pm1
							WHERE pmc.ResourceID = pm1.ResourceID
							FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,0,'') AS modelMemory 
			-- sum(pm.Capacity0) AS Capacity0, pm.ResourceID
			FROM v_GS_PHYSICAL_MEMORY pmc
			--where pmc.ResourceID = 33554744
			GROUP BY pmc.ResourceID
			)) pmv
    ON cs.ResourceID = pmv.ResourceID

  LEFT JOIN (SELECT DISTINCT d.ResourceID,        
				STUFF((SELECT DISTINCT REPLACE(REPLACE(dv.Model0,' ATA Device',''),' SCSI Disk Device','')+'|' + (CASE dv.MediaType0 WHEN 4 THEN 'SSD' ELSE 'HDD' END) + '|'+dv.Size0+ +','
							FROM (SELECT d1.ResourceID AS ResourceID,d1.Model0 AS Model0,cASt(d1.Size0/1024 AS varchar(max)) AS Size0, CASE WHEN d1.Model0 like '%SanDisk%' THEN 4 WHEN d1.Model0 like '%SAMSUNG%' THEN 4 WHEN d1.Model0 like '%Crucial%' THEN 4 ELSE isnull(pd1.MediaType0,'3') END AS MediaType0, d1.GroupID AS GroupID                
									FROM v_GS_DISK d1
										LEFT JOIN v_GS_PHYSICAL_DISK pd1 
											ON d1.ResourceID = pd1.ResourceID and d1.Model0 = pd1.Model0 
									WHERE d1.InterfaceType0 not in ('USB')) dv 
							WHERE d.ResourceID = dv.ResourceID --and d.GroupID = dv.GroupID 
								FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,0,'') HDDModel
			FROM v_GS_DISK d
				LEFT JOIN v_GS_PHYSICAL_DISK pd 
					ON d.ResourceID = pd.ResourceID and d.Model0 = pd.Model0 
			WHERE 1=1
		   -- and d.ResourceID = 16777948
			 AND d.InterfaceType0 NOT IN ('USB')) phd
	ON cs.ResourceID = phd.ResourceID

  LEFT JOIN (SELECT DISTINCT vcs.ResourceID,
				STUFF((SELECT '' + vc1.Description0 + ', '
					FROM v_GS_VIDEO_CONTROLLER vc1
					WHERE vcs.ResourceID = vc1.ResourceID 
						AND vc1.AdapterDACType0 IS NOT NULL
					FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,0,'') AS Description0
			FROM v_GS_VIDEO_CONTROLLER vcs 
			WHERE  vcs.AdapterDACType0 IS NOT NULL 
				AND vcs.AdapterDACType0 IS NOT NULL) vc
	ON cs.ResourceID = vc.ResourceID
   
  LEFT JOIN (SELECT DISTINCT na.ResourceID AS ResourceID,
				STUFF((SELECT '' + nac1.IPAddress0 + ', '
						FROM v_GS_NETWORK_ADAPTER_CONFIGURATION nac1
						WHERE na.ResourceID = nac1.ResourceID
						FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,0,'') ipEhernet,
				STUFF((SELECT DISTINCT '' + na1.MACAddress0 + ', '
						FROM v_GS_NETWORK_ADAPTER na1
							LEFT JOIN  v_GS_NETWORK_ADAPTER_CONFIGURATION nac1
								ON NA1.ResourceID = nac1.ResourceID
									AND na1.MACAddress0 = nac1.MACAddress0
						WHERE na.ResourceID = na1.ResourceID
							AND  na1.AdapterType0 IS NOT NULL
							AND nac1.IPAddress0 IS NOT NULL
							AND na1.Name0 NOT LIKE 'WAN%'
							AND na1.Name0 NOT LIKE '%virtual%'
							AND na1.Name0 NOT LIKE '%blue%'        
							AND na1.MACAddress0 IS NOT NULL
							AND (na1.Description0 NOT LIKE '%wire%' AND na1.Description0 NOT LIKE '%wi%fi%')
							AND na1.Description0 NOT IN ('RAS ASync Adapter','KASpersky Security Data Escort Adapter')
     				   FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,0,'') macEhternet,
				STUFF((SELECT DISTINCT '' + na1.Description0 + ', '
						FROM v_GS_NETWORK_ADAPTER na1
							LEFT JOIN v_GS_NETWORK_ADAPTER_CONFIGURATION nac1
								ON NA1.ResourceID = nac1.ResourceID
									AND na1.MACAddress0 = nac1.MACAddress0
						WHERE na.ResourceID = na1.ResourceID
							AND na1.AdapterType0 IS NOT NULL
							AND nac1.IPAddress0 is not null
							AND na1.Name0 NOT LIKE 'WAN%'
							AND na1.Name0 NOT LIKE '%virtual%'
							AND na1.Name0 NOT LIKE '%blue%'
							AND na1.MACAddress0 IS NOT NULL
							AND (na1.Description0 NOT LIKE '%wire%' AND na1.Description0 NOT LIKE '%wi%fi%')       
							AND na1.Description0 NOT IN ('RAS ASync Adapter','KASpersky Security Data Escort Adapter')
						FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,0,'') descriptionEhternet
						 /*na.Description0 AS descriptionEhternet*/
			FROM v_GS_NETWORK_ADAPTER NA
				LEFT JOIN v_GS_NETWORK_ADAPTER_CONFIGURATION nac
					ON NA.ResourceID = nac.ResourceID
					AND na.MACAddress0 = nac.MACAddress0
			WHERE NA.AdapterType0 IS NOT NULL
				AND NA.Name0 NOT LIKE 'WAN%'
				AND NA.Name0 NOT LIKE '%virtual%'
				AND NA.Name0 NOT LIKE '%blue%'      
				AND NA.MACAddress0 IS NOT NULL
				AND (na.Description0 NOT LIKE '%wire%' AND na.Description0 NOT LIKE '%wi%fi%')
				AND nac.IPAddress0 is not null
				AND na.Description0 NOT IN ('RAS ASync Adapter','KASpersky Security Data Escort Adapter')
			) ea
    ON cs.ResourceID = ea.ResourceID

  LEFT JOIN (SELECT DISTINCT na.ResourceID AS ResourceID,
				STUFF((SELECT '' + nac1.IPAddress0 + ', '
						FROM v_GS_NETWORK_ADAPTER_CONFIGURATION nac1
						WHERE na.ResourceID = nac1.ResourceID
						FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,0,'') ipWIreless,
				STUFF((SELECT DISTINCT '' + na1.MACAddress0 + ', '
						FROM v_GS_NETWORK_ADAPTER na1
						WHERE na.ResourceID = na1.ResourceID
							AND na.MACAddress0 = na1.MACAddress0
						FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,0,'') macWIreless,
                STUFF((SELECT DISTINCT '' + na1.Description0 + ', '
                        FROM v_GS_NETWORK_ADAPTER na1
                        WHERE na.ResourceID = na1.ResourceID
							AND na.MACAddress0 = na1.MACAddress0
                        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),1,0,'') descriptionWIreless
             /*na.Description0 AS descriptionEhternet*/
            FROM v_GS_NETWORK_ADAPTER na
			LEFT JOIN v_GS_NETWORK_ADAPTER_CONFIGURATION nac
				ON NA.ResourceID = nac.ResourceID
					AND na.MACAddress0 = nac.MACAddress0
            WHERE NA.AdapterType0 IS NOT NULL
            AND NA.Name0 NOT LIKE 'WAN%'
            AND NA.Name0 NOT LIKE '%virtual%'
            AND NA.Name0 NOT LIKE '%blue%'
            AND NA.MACAddress0 IS NOT NULL
            AND (na.Description0 LIKE '%wire%' OR na.Description0 LIKE '%wi%fi%')
            AND na.Description0 NOT IN ('RAS ASync Adapter')) wa
	ON cs.ResourceID = wa.ResourceID
WHERE 1 = 1 /*and cs.Name0 in ( 'KK-PC-IT007616','KK-NB-IT005333')*/
	AND cs.Manufacturer0 NOT IN ('VMware, Inc.')
	AND vcm.SiteCode = 'MMZ'
	AND cs.Name0 NOT LIKE ('%SRV%')
	AND cs.Model0 NOT IN ('VirtualBox')
	--and cs.ResourceID = 33555329
	--and cs.Name0 = 'MMZ-IT07'

/*  
SELECT *
FROM v_GS_COMPUTER_SYSTEM

SELECT *
FROM v_ClientMachines

SELECT *
FROM v_GS_COMPUTER_SYSTEM_PRODUCT

SELECT *
FROM v_GS_PROCESSOR

SELECT *
FROM v_GS_OPERATING_SYSTEM
*/