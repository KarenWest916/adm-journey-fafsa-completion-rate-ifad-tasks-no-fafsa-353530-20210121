

SELECT distinct
f.StudentID,
Id AS ContactId,
f.StudentFAFSAFileDate,
f.InitialSNHUISIRReceiptDate,
f.LatestSNHUISIRReceiptDate,
f.FileCompleteDate,
f.PackageDateAwardLetter


FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer] nof
LEFT JOIN UnifyStaging.dbo.Contact c
ON nof.ContactID = c.Id
INNER JOIN Data_Reporting.dbo.FAFunnelData f
ON f.StudentID = c.Colleague_ID__c
