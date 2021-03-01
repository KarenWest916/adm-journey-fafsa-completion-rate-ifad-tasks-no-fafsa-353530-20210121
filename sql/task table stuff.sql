select nof.ContactID, COUNT(*)
FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer] nof
right JOIN UnifyStaging.dbo.Task task ON
nof.ContactID = task.WhoId
WHERE nof.Test_Group = 'Dialer + Task'
AND nof.Acad = 'UG'
AND nof.DateofEntry > '2021-01-27'
AND
task.ActivityDate > '2021-01-27'
AND task.subject = 'Check on Student Funding'
GROUP BY nof.ContactID



SELECT * FROM UnifyStaging.dbo.Task
WHERE ActivityDate > '2021-01-15'
AND subject = 'Check on Student Funding'


select task.WhoId AS who_id, MAX(task.ActivityDate) AS task_date
FROM UnifyStaging.dbo.Task task
INNER JOIN (
SELECT ContactID, ROW_NUMBER() OVER (PARTITION BY ContactID ORDER BY DateofEntry DESC) AS RN
FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer]
WHERE DateofEntry > '2021-01-27'
) AS nof
ON task.WhoId = nof.ContactID
WHERE
task.ActivityDate > '2021-01-27'
AND task.subject = 'Check on Student Funding'
AND nof.RN = 1
GROUP BY task.WhoId
ORDER BY COUNT(*) desc





select *
--task.WhoId AS who_id, MAX(task.ActivityDate) AS task_date
FROM UnifyStaging.dbo.Task task
WHERE
task.WhoId IN ('0033l00002ZLW4PAAX',
'0031N000021x0u1QAA',
'0031N000021x5MKQAY',
'0031N000021uXoZQAU'
)

--task.ActivityDate > '2021-01-27'
--AND task.subject = 'Check on Student Funding'
GROUP BY task.WhoId
ORDER BY COUNT(*) desc

