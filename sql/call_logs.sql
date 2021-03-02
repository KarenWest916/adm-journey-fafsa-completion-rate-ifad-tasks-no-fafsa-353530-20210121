


SELECT 
UnifySalesforceContactID,
MAX(CallDate) AS last_dialed,
MAX(CASE WHEN
CallDate IS NULL THEN 0 ELSE 1 END) AS dialed,
--SELECT Disposition, 

MAX(CASE WHEN disposition IN (

'DNC Request',
'Do Not Call',
'Follow up Call',
'Not Using FAFSA',
'Successful Transfer',
'Transferred To 3rd Party'

) THEN 1 ELSE 0 END) AS [contacted]
--Campaign, DialingList, 
--,COUNT(1)
--SELECT *
FROM [AARDW].[AARPL].[CallLog]
WHERE CallDate > '2021-01-20'
AND campaign like '%No FAFSA OB Dialer%' --AND Disposition = 'No Contact'
--GROUP BY Disposition
--Campaign, DialingList	
--AND UnifySalesforceContactID = '0033l00002SRKedAAH'
GROUP BY UnifySalesforceContactID

