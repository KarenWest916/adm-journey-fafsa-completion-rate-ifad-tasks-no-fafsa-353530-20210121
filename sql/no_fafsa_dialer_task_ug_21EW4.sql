



SELECT 

f0.Icosagonain_Expirmentation_Cell__c,
--CASE WHEN f0.Icosagonain_Expirmentation_Cell__c NOT IN ('A1','B1','C1','D1') THEN 'Experiment' ELSE 'Control' END AS 
f0.Test_Group AS testing_group,
f0.LeadType,
f0.ContactID,
f0.ContactFirstName,
f0.ContactLastName,
f0.ContactPEmail,
f0.Home_Phone__c,
f0.MobilePhone,
f0.Business_Phone__c,
f0.PhoneNumber,
f0.MailingState,
f0.MailingStateCode,
f0.stagename,
f0.DateofEntry,
f0.WrongFAFSA,
f0.Acad,
--f0.Financial__c,
--o.Name,
--current value from SSR (did they fill out FAFSA or not?)
f.Colleague_ID__c,
f.VerificationType,
CASE WHEN f.VerificationType LIKE '%No FAFSA Yet%' THEN 0 ELSE 1 END AS fafsa_completed,
--stuff from the opportunity
t.Name AS OppTerm,
o.StageName,
	 o.Inquired_Date_Time__c,
	 o.Applied_Date_Time__c,
	 o.App_in_Progress_Date_Time__c,
	 o.Accepted_Date_Time__c,
	 o.Registered_Date_Time__c,
	 o.Started_Date_Time__c,
	 o.[Closed_Lost_Date_Time__c],

CASE WHEN o.Applied_Date_Time__c IS NOT NULL THEN 1 ELSE 0 END AS Apps,
CASE WHEN o.App_in_Progress_Date_Time__c IS NOT NULL THEN 1 ELSE 0 END AS AppIPs,
CASE WHEN o.Accepted_Date_Time__c IS NOT NULL THEN 1 ELSE 0 END AS Accepts,
CASE WHEN o.Registered_Date_Time__c IS NOT NULL THEN 1 ELSE 0 END AS Regs,
CASE WHEN o.Registered_Date_Time__c IS NOT NULL AND o.stagename='Closed Won' THEN 1 ELSE 0 END AS Enrolls,
CASE WHEN o.Started_Date_Time__c IS NOT NULL THEN 1 ELSE 0 END AS Starts


FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer] f0 


--take most recent record from test table
INNER JOIN  
(
SELECT ContactID, MAX(DateofEntry)[MaxDate]
FROM 
Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer]
WHERE Acad = 'UG'
GROUP BY ContactID
) AS t_date ON t_date.ContactID = f0.ContactID AND t_date.MaxDate = F0.DateofEntry
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
--removing all of the nulls from the comparison
AND C.Icosagonain_Expirmentation_Cell__c IS NOT null
) AS curr_fafsa_status ON curr_fafsa_status.ContactID = o.Contact__c


 WHERE rt.name = 'Admission Opportunity'

 --removing all CWO from analysis
AND o.Name <> '%CWO%'

 ) AS f ON f.Contact__c = f0.ContactID
INNER JOIN Data_Reporting.mstr.DimStudent ds ON ds.Studentid = f.Contact__c
INNER JOIN UnifyStaging.dbo.Opportunity o ON o.id = f.Id
INNER JOIN UnifyStaging.dbo.Contact c ON c.id = f.Contact__c
--INNER JOIN Data_Reporting.MSTR.DimStudent df ON df.Studentid  = c.id
INNER JOIN UnifyStaging.dbo.hed__Term__c t ON t.id = o.Term__c
WHERE 
f.RN = 1
and
(t.Name ='21EW4')
--remove any of the null test groups
AND f0.Test_Group IS NOT NULL
AND (f0.Financial__c <> 'Out of Pocket' OR f0.Financial__c IS NULL)

