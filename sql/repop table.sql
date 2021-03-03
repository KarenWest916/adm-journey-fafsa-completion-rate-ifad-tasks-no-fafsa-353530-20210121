/****** Script for SelectTopNRows command from SSMS  ******/

--INSERT INTO [Data_Reporting].[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]

SELECT nof.[Icosagonain_Expirmentation_Cell__c]
      ,nof.[LeadType]
      ,nof.[ContactID]
      ,nof.[ContactFirstName]
      ,nof.[ContactLastName]
      ,nof.[ContactPEmail]
      ,nof.[Home_Phone__c]
      ,nof.[MobilePhone]
      ,nof.[Business_Phone__c]
      ,nof.[PhoneNumber]
      ,nof.[MailingState]
      ,nof.[MailingStateCode]
      ,f.[stagename]
      ,([DateofEntry]) AS enter_pop_date
      ,[WrongFAFSA]
      ,[Acad]
      ,[Test_Group]
      ,[OppID]
      ,nof.[Financial__c]

	  --added these columns to the table

	  ,	 o.Inquired_Date_Time__c,
	 o.Applied_Date_Time__c,
	 o.App_in_Progress_Date_Time__c,
	 o.Accepted_Date_Time__c,
	 o.Registered_Date_Time__c,
	 o.Started_Date_Time__c,
	 o.[Closed_Lost_Date_Time__c],
	 o.FAFSA_Received__c,
	CASE WHEN 

	(nof.DateofEntry = '2021-02-11'
	OR 
	(nof.DateofEntry = '2021-01-28' AND (o.Closed_Lost_Date_Time__c is NULL OR o.Closed_Lost_Date_Time__c < '2021-02-04') AND (o.Registered_Date_Time__c IS NULL OR o.Registered_Date_Time__c < '2021-02-04')
	AND (o.FAFSA_Received__c IS NULL OR o.FAFSA_Received__c < '2021-02-04') ))
	AND (nof.Test_Group LIKE '%task%' OR nof.Test_Group LIKE '%control%')
	THEN 'Funding Task Only'

	WHEN 
	((nof.DateofEntry = '2021-02-04' AND (o.Closed_Lost_Date_Time__c is NULL OR o.Closed_Lost_Date_Time__c > '2021-02-11') AND (o.Registered_Date_Time__c IS NULL OR o.Registered_Date_Time__c > '2021-02-11')
	AND (o.FAFSA_Received__c IS NULL OR o.FAFSA_Received__c > '2021-02-11') )
	OR
	(nof.DateofEntry = '2021-01-28' AND (o.Closed_Lost_Date_Time__c is NULL OR o.Closed_Lost_Date_Time__c > '2021-02-04') AND (o.Registered_Date_Time__c IS NULL OR o.Registered_Date_Time__c > '2021-02-04')
	AND (o.FAFSA_Received__c IS NULL OR o.FAFSA_Received__c > '2021-02-04') )
	OR
    (nof.DateofEntry = '2021-01-21' AND (o.Closed_Lost_Date_Time__c is NULL OR o.Closed_Lost_Date_Time__c > '2021-01-28') AND (o.Registered_Date_Time__c IS NULL OR o.Registered_Date_Time__c > '2021-01-28')
	AND (o.FAFSA_Received__c IS NULL OR o.FAFSA_Received__c > '2021-01-28') ))
	AND (nof.Test_Group LIKE '%task%' OR nof.Test_Group LIKE '%control%')
	THEN 'Dialer + Funding Task' 
	
	WHEN 
	((nof.DateofEntry = '2021-02-04' AND (o.Closed_Lost_Date_Time__c is NULL OR o.Closed_Lost_Date_Time__c < '2021-02-11') AND (o.Registered_Date_Time__c IS NULL OR o.Registered_Date_Time__c < '2021-02-11')
	AND (o.FAFSA_Received__c IS NULL OR o.FAFSA_Received__c < '2021-02-11') )
	OR
    (nof.DateofEntry = '2021-01-21' AND (o.Closed_Lost_Date_Time__c is NULL OR o.Closed_Lost_Date_Time__c < '2021-01-28') AND (o.Registered_Date_Time__c IS NULL OR o.Registered_Date_Time__c < '2021-01-28')
	AND (o.FAFSA_Received__c IS NULL OR o.FAFSA_Received__c < '2021-01-28') ))
	AND (nof.Test_Group LIKE '%dialer%' OR nof.Test_Group LIKE '%control%')
	THEN 'Dialer Only'

	ELSE NULL	

	END AS grouping,

	CASE WHEN nof.Test_Group IS NULL THEN NULL 
	WHEN nof.Test_Group LIKE '%control%' THEN 'Control'
	ELSE 'Test'
	END AS new_test_or_control


  FROM [Data_Reporting].[dbo].[Remap_NoFAFSA_Dialer] nof
  INNER JOIN	

--records for the new table should only include the initial record when they entered the population
  (
  SELECT 
  ContactID, MIN(DateofEntry) AS enter
  FROM [Data_Reporting].[dbo].[Remap_NoFAFSA_Dialer]
  GROUP BY ContactID
  ) AS min
  ON min.ContactID = nof.ContactID
INNER JOIN  

 (

        SELECT --cm.ContactId,
               --c.Name,
			   o.Contact__c,
               o.Id,
			   c.Colleague_ID__c,
               o.CreatedDate,
			   o.stagename,
               ROW_NUMBER() OVER (PARTITION BY Contact__c ORDER BY o.CreatedDate DESC) AS RN,
			   curr_fafsa_status.VerificationType

FROM UnifyStaging.dbo.Opportunity o 
INNER JOIN UnifyStaging.dbo.RecordType rt ON rt.id = o.RecordTypeId 
INNER JOIN UnifyStaging.dbo.Contact c ON C.id = O.Contact__c
INNER JOIN 
(
--Base set of IDs in experiment population
SELECT DISTINCT ContactID, C.Colleague_ID__c,  SSR.VerificationType
FROM  Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer] F
INNER JOIN UnifyStaging.DBO.Contact C ON f.ContactID = c.Id
INNER JOIN  (
SELECT DISTINCT FA.[Student ID] AS StudentID, FA.[Verification Type] AS VerificationType
FROM  msr.fa.CRILimboDocDetails FA
WHERE   [Planned Start Term] in ('21EW4')
) AS SSR ON SSR.StudentID = c.Colleague_ID__c
WHERE Acad = 'UG'

) AS curr_fafsa_status ON curr_fafsa_status.ContactID = o.Contact__c


 WHERE rt.name = 'Admission Opportunity'

 --removing all CWO from analysis
AND o.Name <> '%CWO%'

 ) AS f ON f.Contact__c = nof.ContactID
INNER JOIN Data_Reporting.mstr.DimStudent ds ON ds.Studentid = f.Contact__c
INNER JOIN UnifyStaging.dbo.Opportunity o ON o.id = f.Id
INNER JOIN UnifyStaging.dbo.Contact c ON c.id = f.Contact__c
INNER JOIN UnifyStaging.dbo.hed__Term__c t ON t.id = o.Term__c


 WHERE
o.Name <> '%CWO%'

  	    and Acad = 'UG'
		AND f.RN = 1
  AND nof.DateofEntry = min.enter
  AND nof.DateofEntry > '2021-01-20'


  
	 
	 
	 
	 
	 
	 --SELECT * FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]

	  --DELETE FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]

	 