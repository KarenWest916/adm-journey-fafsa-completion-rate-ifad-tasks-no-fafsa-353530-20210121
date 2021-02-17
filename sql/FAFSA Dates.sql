

SELECT distinct
StudentID,
Id AS ContactId,
StudentFAFSAFileDate,
InitialSNHUISIRReceiptDate,
LatestSNHUISIRReceiptDate,
FileCompleteDate,
PackageDateAwardLetter

FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer] nof
LEFT JOIN UnifyStaging.dbo.Contact c
ON nof.ContactID = c.Id
INNER JOIN Data_Reporting.dbo.FAFunnelData f
ON f.StudentID = c.Colleague_ID__c

