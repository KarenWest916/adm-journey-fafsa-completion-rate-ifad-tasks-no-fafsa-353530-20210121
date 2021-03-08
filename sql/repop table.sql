/****** Script for SelectTopNRows command from SSMS  ******/



/*
Planned term start on treatment days to make sure student was still in population

E.g. 

If student entered pop on on 1/21, that was the date of a dialer. 
Because of how we put students into the original remap table and the filters we used, 
we know on that day that they had a planned term start of 21EW4, so no need to check for it here.

But if a student entered pop on 1/21 and we put them into the 'Dialer + Task' population, the task
doesn't happen until 1/28. 
On 1/28, we reran the list for the funding task and filtered out the students that dropped out of population
because their term start changed (or they registered, or closed lost, etc). 
So the funding task LIST was right but the remap table would still have a record of student that entered
'Dialer + Task' population on 1/21, but never ACTUALLY received the task.

So, HERETOFOR, the temp tables below are grabbing the planned term start date on the date of that
second week treatment (e.g. the funding task that occured on 1/28).
That way if the student doesn't still have a planned term start date on 1/28 then I can't consider them
for the 'Dialer + Task' population, even though we originally put them in that test group in the remap table.

For contacts that dropped out of pop because they registered or were closed out, I determine those
based on the timestamp that exists in unify staging. Change of planned term start only exists
in the pipeline logging redux table.


*/


		IF OBJECT_ID ('tempdb..#jan28') IS NOT NULL
			DROP TABLE #jan28;
			SELECT p.studentid,
			p.Planned_Start_Term,
			p.ID
			INTO #jan28
		FROM Data_Reporting.dbo.PipelineLoggingRedux p
		WHERE p.DateOfEntry = '2021-01-28'
		AND p.Planned_Start_Term = '21EW4'
		AND p.coce_admissionstatus_displayname = 'Open'


		IF OBJECT_ID ('tempdb..#feb4') IS NOT NULL
			DROP TABLE #feb4;
			SELECT p.studentid,
			p.Planned_Start_Term,
			p.Id
			INTO #feb4
		FROM Data_Reporting.dbo.PipelineLoggingRedux p
		WHERE p.DateOfEntry = '2021-02-04'
		AND p.Planned_Start_Term = '21EW4'
		AND p.coce_admissionstatus_displayname = 'Open'

		IF OBJECT_ID ('tempdb..#feb11') IS NOT NULL
			DROP TABLE #feb11;
			SELECT p.studentid,
			p.Planned_Start_Term,
			p.Id
			INTO #feb11
		FROM Data_Reporting.dbo.PipelineLoggingRedux p
		WHERE p.DateOfEntry = '2021-02-11'
		AND p.Planned_Start_Term = '21EW4'
		AND p.coce_admissionstatus_displayname = 'Open'




/* this is here I got stuck - attempting to insert the planned term from the temp tables into newly added columns in Repop table*/

UPDATE Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
SET jan28_term = 'inpipe'
--INSERT INTO Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop] --(jan28_term)
--SELECT Planned_Start_Term,J28.*
FROM #jan28 j28
INNER JOIN Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop] pop
ON j28.studentid = pop.ContactID
--WHERE j28.studentid = pop.ContactID


UPDATE Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
SET feb4_term = 'inpipe'
--INSERT INTO Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop] --(jan28_term)
--SELECT Planned_Start_Term,J28.*
--SELECT f4.*
FROM #feb4 f4
INNER JOIN Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop] pop
ON f4.studentid = pop.ContactID
--WHERE j28.studentid = pop.ContactID

UPDATE Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
SET feb11_term = 'inpipe'
--INSERT INTO Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop] --(jan28_term)
--SELECT Planned_Start_Term,J28.*
--SELECT f11.*
FROM #feb11 f11
INNER JOIN Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop] pop
ON f11.studentid = pop.ContactID
--WHERE j28.studentid = pop.ContactID



--SELECT * FROM Data_Reporting.DBO.PipelineLoggingRedux WHERE DateOfEntry = '2021-01-28' AND ID = '0063l00000l8JKIAA2'





		/*this takes the most recent opportunity that existed out of the
		 three dates for that student

		 		--grabs all unify staging opps that are admission opportunities


		*/

		IF OBJECT_ID ('tempdb..#pipeopp') IS NOT NULL
			DROP TABLE #pipeopp;
			--SELECT distinct p2.id AS OppId, p2.studentid
			
			--INTO #pipeopp

		
			--FROM Data_Reporting.dbo.PipelineLoggingRedux p2
			--INNER JOIN 

			--(


			--Grab contactid, oppid, and max date for the three later dates in the fafsa table
			SELECT p.Id AS OppId,
			p.studentid, 
			MAX(p.dateofentry) [MaxDate]
			INTO #pipeopp

			FROM Data_Reporting.dbo.PipelineLoggingRedux p

			INNER JOIN 
			--grabs all oppIds that are admission opportunities
			(
			SELECT 
			--DISTINCT 
			    o.Contact__c, o.id, ROW_NUMBER() OVER (PARTITION BY O.Contact__c ORDER BY O.CreatedDate DESC) AS RN
				FROM UnifyStaging.dbo.Opportunity o
				INNER JOIN UnifyStaging.dbo.RecordType rt
				ON rt.id = o.RecordTypeId
				WHERE rt.name = 'Admission Opportunity'
				AND EXISTS(SELECT 1 FROM 
				 Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer] WHERE ContactID = o.Contact__c AND Acad = 'UG' AND DateofEntry > '2021-01-20')

				) AS admopp ON admopp.id = p.Id
				AND admopp.Contact__c = p.studentid AND admopp.RN = 1

			WHERE(p.DateOfEntry = '2021-01-28'
			OR p.DateOfEntry = '2021-02-04'
			OR p.DateOfEntry = '2021-02-11')
			GROUP BY p.Id,p.studentid
			
			--) AS p1

			--ON p1.OppId = p2.id


			--where p1.RN = 1
			--AND p2.DateOfEntry = p1.DateOfEntry
			--AND p2.studentid = '0033l00002gFYRUAA4'

--update original fafsa storage table
UPDATE F 
SET [OppID]  = p.OppId
--SELECT f.* 
FROM #pipeopp p
INNER JOIN Data_Reporting.dbo.Remap_NoFAFSA_Dialer_UG_Repop f ON f.ContactID = p.studentid
WHERE f.OppID IS NULL 







SELECT * FROM Data_Reporting.dbo.PipelineLoggingRedux
WHERE studentid ='0033l00002gFYRUAA4'
ORDER BY DateOfEntry desc
WHERE id = '0063l00000lNygmAAC'


SELECT * FROM #pipeopp



--DELETE FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]


/*

1/21 - Dialer
1/28 - Task
2/4  - Dialer
2/11 - Task

*/



--INSERT INTO [Data_Reporting].[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]

SELECT 
--nof.OppID AS remap_opp_id,
--pipe.OppId AS pipe_temp_opp_id,

nof.[Icosagonain_Expirmentation_Cell__c]
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
      ,nof.[stagename]
      ,(nof.[DateofEntry]) AS enter_pop_date
      ,nof.[WrongFAFSA]
      ,nof.[Acad]
      ,nof.[Test_Group]
      ,nof.[OppID]
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
	 

	 /*The following case when statements are identifying the treatment the testing groups ACTUALLY received
	 and the treatments that the control group would have been eligible to receive*/

	CASE WHEN 

		/* 
	*****DIALER + TASK ELIGIBLE*****
	
	Now let's find the people that actually recieved a dialer AND a task, what a lucky bunch. 
	 If you entered pop 2/4 (dialer day) and stayed till task day (2/11)
	 or entered 1/28 (task day), stayed thru dialer day (2/4)
	 or entered 1/21 (dialer day), stayed thru task day (1/28)
	 AND we originally said you were in the 'Dialer + Task' group then congratulations, you get to
	 stay in the 'Dialer + Task' group
	 Same situation for control group, we can assume they could have received the same treatment.
	*/

	 
	(
	(
		nof.DateofEntry = '2021-02-04' 
		AND (o.Closed_Lost_Date_Time__c is NULL OR o.Closed_Lost_Date_Time__c > '2021-02-12') 
		AND (o.Registered_Date_Time__c IS NULL OR o.Registered_Date_Time__c > '2021-02-12')
	AND ( faf.MAILING_CORR_RECEIVED_DATE IS NULL OR faf.MAILING_CORR_RECEIVED_DATE > '2021-02-11')  )
	OR
	(nof.DateofEntry = '2021-01-28' AND (o.Closed_Lost_Date_Time__c is NULL OR o.Closed_Lost_Date_Time__c > '2021-02-05') AND (o.Registered_Date_Time__c IS NULL OR o.Registered_Date_Time__c > '2021-02-05')
	AND ( faf.MAILING_CORR_RECEIVED_DATE IS NULL OR faf.MAILING_CORR_RECEIVED_DATE > '2021-02-04') )
	OR
    (nof.DateofEntry = '2021-01-21' AND (o.Closed_Lost_Date_Time__c is NULL OR o.Closed_Lost_Date_Time__c > '2021-01-29') AND (o.Registered_Date_Time__c IS NULL OR o.Registered_Date_Time__c > '2021-01-29')
	AND ( faf.MAILING_CORR_RECEIVED_DATE IS NULL OR faf.MAILING_CORR_RECEIVED_DATE > '2021-01-28') ))

	AND (nof.Test_Group <> 'Dialer Only')

	THEN 'Dialer + Funding Task' 



	--******DIALER ONLY*******

	/*

	any lead that entered population on a dialer day (1/21 or 2/4) and was originally assigned 'Dialer Only' can stay
	as Dialer Only because we they were appropriately assigned as the right test group in the remap table
	*/

	when

	(((nof.DateofEntry = '2021-01-21' OR nof.DateofEntry = '2021-02-04')

	/*
	if they entered the pop on 1/28 which was a funding task day and they were 'Dialer Only', then they had to remain
	in the pop till the dialer on 2/4 to stay 'Dialer Only'. The 2nd task day was 2/11, and there was no dialer after that.

		students that entered on the 2nd task date of 2/11 would not have been eligible for ANY dialer since the last dialer was 2/4
		There were issues on 2/18 that prevented us from pulling the dialer list, so the 2/18 dialer never happened.
	*/

    OR (nof.DateofEntry = '2021-01-28' 
	AND (o.Closed_Lost_Date_Time__c is NULL OR o.Closed_Lost_Date_Time__c > '2021-02-05') 
	AND (o.Registered_Date_Time__c IS NULL OR o.Registered_Date_Time__c > '2021-02-05')
	AND (faf.MAILING_CORR_RECEIVED_DATE IS NULL OR faf.MAILING_CORR_RECEIVED_DATE > '2021-02-04') 
	)

	AND nof.Test_Group <> 'Dialer + Task')

	OR	

	/*
	If lead was originally assigned to 'Control' or 'Dialer + Task' and entered pop on dialer day 1/21 or 2/4, 
	but closed out before funding task day, they would only have been eligible for Dialer Only
	*/

		---UPDATE 3/8 Karen:
	--originally this included the closed/lost null, registered null, received date null, but we don't want these to be null.
	--if all of those fields are null, then you would have been around long enough to get both treatments
	--need to rework, to see the update query done on 3/8, search for "Karen 3/8 Update Dialer Task Onlys" in this query

	
	(
	(nof.DateofEntry = '2021-01-21' 
	AND (o.Closed_Lost_Date_Time__c < '2021-01-28') 
	AND (o.Registered_Date_Time__c < '2021-01-28') 
	AND (faf.MAILING_CORR_RECEIVED_DATE < '2021-01-29'))

		OR
        
	(nof.DateofEntry = '2021-02-04' 
	AND (o.Closed_Lost_Date_Time__c < '2021-02-11') 
	AND (o.Registered_Date_Time__c < '2021-02-11') 
	AND (faf.MAILING_CORR_RECEIVED_DATE < '2021-02-11'))

		AND nof.Test_Group <> 'Dialer Only'
		))

	THEN 'Dialer Only'
	


	/*

	***FUNDING TASK ONLY***

	if lead entered test pop on 2/11, this was the last treatment and it was a funding task, no dialers after this point
	so if you entered 2/11 and we put you in 'Dialer + Task' you ONLY received a task.
	Same situation for original control group, we can assume they would receive same treatment.

	1/28 was a task day. If you entered that day but closed out before 2/4 which was the last dialer then you're only a
	funding task person. Sorry, no dialer for you even if we put you in the 'Dialer + Task' group in the remap table.
	*/


	---UPDATE 3/8 Karen:
	--originally this included the closed/lost null, registered null, received date null, but we don't want these to be null.
	--if all of those fields are null, then you would have been around long enough to get both treatments
	--need to rework, to see the update query done on 3/8, search for "Karen 3/8 Update Funding Task Onlys" in this query

	when
	(nof.DateofEntry = '2021-02-11'
	OR 
	(nof.DateofEntry = '2021-01-28' 
	AND (o.Closed_Lost_Date_Time__c < '2021-02-04') 
	AND (o.Registered_Date_Time__c < '2021-02-04')
	AND (faf.MAILING_CORR_RECEIVED_DATE < '2021-02-04') ))
	AND (nof.Test_Group <> 'Dialer Only')

	THEN 'Funding Task Only'


	ELSE NULL	

	END AS treatment,

	CASE WHEN nof.Test_Group IS NULL THEN NULL 
	WHEN nof.Test_Group LIKE '%control%' THEN 'Control'
	ELSE 'Test'
	END AS new_test_or_control,


	CAST(faf.MAILING_CORR_RECEIVED_DATE AS DATE)





  FROM [Data_Reporting].[dbo].[Remap_NoFAFSA_Dialer] nof
  INNER JOIN	

--records for the new table should only include the initial record when they entered the population
  (
  SELECT 
  ContactID, MIN(DateofEntry) AS enter
  FROM [Data_Reporting].[dbo].[Remap_NoFAFSA_Dialer]
  WHERE ACAD = 'UG'
  AND DateofEntry > '2021-01-20'
  --AND ContactID = '0033l00002gFYRUAA4'
  GROUP BY ContactID
  ) AS min
  ON min.ContactID = nof.ContactID


--don't want to pull most recent opp at this point, or do we? instead pulling whatever admission opp has 21EW4
INNER JOIN #pipeopp pipe 
ON pipe.studentid = min.ContactID

inner join UnifyStaging.dbo.Opportunity o 

ON o.Contact__c = pipe.studentid
AND o.id = pipe.OppId

/*did we receive fafsa and when?? 
what does POS mean in MSR.informer.ODS_CORR_RECEIVED??
there is more than one record per student, only difference is POS

*/

left JOIN
(
SELECT msr.MAILING_ID, MAX(msr.MAILING_CORR_RECEIVED_DATE) AS MAILING_CORR_RECEIVED_DATE, con.Id

FROM MSR.informer.ODS_CORR_RECEIVED msr
INNER JOIN 
(SELECT DISTINCT C.Colleague_ID__c, c.Id
FROM Data_Reporting.dbo.Remap_NoFAFSA_Dialer d 
INNER JOIN UnifyStaging.dbo.Contact c ON c.id = d.ContactID
WHERE d.DateofEntry >'2021-01-20' AND d.Acad = 'UG') con
ON con.Colleague_ID__c = msr.MAILING_ID
WHERE MAILING_CORR_RECEIVED = 'F20ISIRC'
GROUP BY msr.MAILING_ID, con.Id
) faf
ON 
faf.Id = nof.ContactID

--inner JOIN #jan28 jan28
--ON  jan28.studentid = nof.ContactID
--inner JOIN #feb4 feb4
--ON feb4.studentid = nof.ContactID
--inner JOIN #feb11 feb11 
--ON feb11.studentid = nof.ContactID


 WHERE

	 nof.DateofEntry = min.enter
  AND nof.DateofEntry > '2021-01-20'
  --AND o.Id IS NOT null
  --AND rt.name = 'Admission Opportunity'
 -- AND pipe.Planned_Start_Term = '21EW4'

  
	 
	 --SELECT * FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 
	 --DELETE  FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 --
	 --SELECT DISTINCT contactID FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer]
	 --WHERE acad = 'UG'
	 --AND DateofEntry > '2021-01-20'
	 --GROUP BY ContactID

	 --SELECT TOP 100 * FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer]



	 --%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-
	 --%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-

	 /*
	 Updating the remap repop table to account for if anyone fell out of the treatment population because their term start changed from 21EW4 before they received the 2nd treatment
	 */

	 --1/21 was dialer day, so if you entered pop that day and you're Dialer Only, then you're still Dialer only
	 --If you are Dialer & Task or Control and you entered 1/21 and on Jan 28th you were no longer in the pipeline, 
	 --then you would have only received a Dialer


	 UPDATE Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 --SELECT *
	 SET treatment = 'Dialer Only'
	 FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 WHERE DateofEntry = '2021-01-21'
	 AND treatment <> 'Dialer Only'
	 AND jan28_term IS NULL
     


	 
--"Karen 3/8 Update Funding Task Onlys"  <--- search for this to see my notes above on why I did this, had an error in my original population of the REpop--


UPDATE Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]	
SELECT 
nof.[Icosagonain_Expirmentation_Cell__c]
      ,nof.[LeadType]
      ,nof.[ContactID]
      ,nof.[stagename]
      ,(nof.[DateofEntry]) AS enter_pop_date
      ,nof.[WrongFAFSA]
      ,nof.[Acad]
      ,nof.[Test_Group]
	  ,nof.new_test_or_control
	  ,nof.treatment
      ,nof.[OppID]
      ,nof.[Financial__c]
	  ,	 o.Inquired_Date_Time__c,
	 o.Applied_Date_Time__c,
	 o.App_in_Progress_Date_Time__c,
	 o.Accepted_Date_Time__c,
	 o.Registered_Date_Time__c,
	 o.Started_Date_Time__c,
	 o.[Closed_Lost_Date_Time__c],
	faf.MAILING_CORR_RECEIVED_DATE
--SET treatment = 'Dialer + Funding Task'

  FROM [Data_Reporting].[dbo].[Remap_NoFAFSA_Dialer_UG_Repop] nof
  INNER JOIN	

 UnifyStaging.dbo.Opportunity o 

on o.id = nof.OppId

left JOIN
(
SELECT msr.MAILING_ID, MAX(msr.MAILING_CORR_RECEIVED_DATE) AS MAILING_CORR_RECEIVED_DATE, con.Id

FROM MSR.informer.ODS_CORR_RECEIVED msr
INNER JOIN 
(SELECT DISTINCT C.Colleague_ID__c, c.Id
FROM Data_Reporting.dbo.Remap_NoFAFSA_Dialer d 
INNER JOIN UnifyStaging.dbo.Contact c ON c.id = d.ContactID
WHERE d.DateofEntry >'2021-01-20' AND d.Acad = 'UG') con
ON con.Colleague_ID__c = msr.MAILING_ID
WHERE MAILING_CORR_RECEIVED = 'F20ISIRC'
GROUP BY msr.MAILING_ID, con.Id
) faf
ON 
faf.Id = nof.ContactID

 WHERE
nof.DateofEntry = '2021-01-28' 
AND o.Closed_Lost_Date_Time__c IS null
	AND o.Registered_Date_Time__c IS null
	AND faf.MAILING_CORR_RECEIVED_DATE IS NULL
    AND nof.treatment = 'Dialer Only'
	    --AND nof.treatment = 'Funding Task Only'
	AND nof.Test_Group IS NOT NULL
    


	---*******did I change original "Dialer Onlys" to "Dialer + Tasks"?? if so need to switch back

SELECT * FROM [Data_Reporting].[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
where Test_Group = 'Dialer Only'
and new_test_or_control = 'Dialer + Funding Task'

---okay good, no I didn't
	-----------

	
	 
--"Karen 3/8 Update Dialer Task Onlys"  <--- search for this to see my notes above on why I did this, had an error in my original population of the REpop--


UPDATE Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]	
--SELECT 
--nof.[Icosagonain_Expirmentation_Cell__c]
--      ,nof.[LeadType]
--      ,nof.[ContactID]
--      ,nof.[stagename]
--      ,(nof.[DateofEntry]) AS enter_pop_date
--      ,nof.[WrongFAFSA]
--      ,nof.[Acad]
--      ,nof.[Test_Group]
--	  ,nof.new_test_or_control
--	  ,nof.treatment
--      ,nof.[OppID]
--      ,nof.[Financial__c]
--	  ,	 o.Inquired_Date_Time__c,
--	 o.Applied_Date_Time__c,
--	 o.App_in_Progress_Date_Time__c,
--	 o.Accepted_Date_Time__c,
--	 o.Registered_Date_Time__c,
--	 o.Started_Date_Time__c,
--	 o.[Closed_Lost_Date_Time__c],
--	faf.MAILING_CORR_RECEIVED_DATE
SET treatment = 'Dialer + Funding Task'

  FROM [Data_Reporting].[dbo].[Remap_NoFAFSA_Dialer_UG_Repop] nof
  INNER JOIN	

 UnifyStaging.dbo.Opportunity o 

on o.id = nof.OppId

left JOIN
(
SELECT msr.MAILING_ID, MAX(msr.MAILING_CORR_RECEIVED_DATE) AS MAILING_CORR_RECEIVED_DATE, con.Id

FROM MSR.informer.ODS_CORR_RECEIVED msr
INNER JOIN 
(SELECT DISTINCT C.Colleague_ID__c, c.Id
FROM Data_Reporting.dbo.Remap_NoFAFSA_Dialer d 
INNER JOIN UnifyStaging.dbo.Contact c ON c.id = d.ContactID
WHERE d.DateofEntry >'2021-01-20' AND d.Acad = 'UG') con
ON con.Colleague_ID__c = msr.MAILING_ID
WHERE MAILING_CORR_RECEIVED = 'F20ISIRC'
GROUP BY msr.MAILING_ID, con.Id
) faf
ON 
faf.Id = nof.ContactID

 WHERE
(nof.DateofEntry = '2021-01-21' OR nof.DateofEntry = '2021-02-04')
AND (o.Closed_Lost_Date_Time__c IS null
	AND o.Registered_Date_Time__c IS null
	AND faf.MAILING_CORR_RECEIVED_DATE IS NULL
    AND nof.treatment = 'Dialer Only'
	AND nof.Test_Group <> 'Dialer Only')



	 /*
	  1/28 was funding task day, so if you entered pop that day and you're Funding Task Only, then you're still Funding Task only
	 #1.) If you are Dialer Only but your term was not 21EW4 on 2/4, then you didn't actually receive a dialer so your are NULL
	 #2.) If you are Dialer + Task but your term was not 21EW4 on 2/4, then you are just Task
	 #3.) If you are Control and we reassigned you to treatment "Dialer + Task" but your term was not 21EW4 on 2/4, then you are just task
		(there are no Controls that were assigned to "Dialer Only" that entered on 1/28)
	 */




	--#1:
	UPDATE Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 --SELECT *
	 SET treatment = NULL
	 FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 WHERE DateofEntry = '2021-01-28'
	 AND new_test_or_control = 'Test'
	 AND treatment = 'Dialer Only'
	 --AND treatment = 'Dialer Only'
	 AND feb4_term IS NULL 
	 
	 --#2:
	 UPDATE Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 --SELECT *
	 SET treatment = 'Funding Task Only'
	 FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 WHERE DateofEntry = '2021-01-28'
	 AND new_test_or_control = 'Test'
	 AND treatment = 'Dialer + Funding Task'
	 --AND treatment = 'Dialer Only'
	 AND feb4_term IS NULL 
	 
	 --#3:
	 UPDATE Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 --SELECT *
	 SET treatment = 'Funding Task Only'
	 FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 WHERE DateofEntry = '2021-01-28'
	 AND new_test_or_control = 'Control'
	 AND treatment = 'Dialer + Funding Task'
	 --AND treatment = 'Dialer Only'
	 AND feb4_term IS NULL


	 /*
	  2/4 was dialer day, so if you entered pop that day and you're Dialer Only, then you're still Dialeronly
	 #1.) If you are Funding Task Only but your term was not 21EW4 on 2/11, then you didn't actually receive a funding task so your are NULL.
		There actually were no records to match the above criteria because Funding Task Only was not an original test group
	 #2.) If you are Dialer + Task but your term was not 21EW4 on 2/11, then you are just Dialer
	 #3.) If you are Control and we reassigned you to treatment "Dialer + Task" but your term was not 21EW4 on 2/4, then you are just dialer
	 this already appeared to have been updated
		(there are no Controls that were assigned to "Funding Only" that entered on 2/4)
	 */


	  --#1:
	 UPDATE Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 --SELECT *
	 --SET treatment = 'Funding Task Only'
	 FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 WHERE DateofEntry = '2021-02-04'
	 --AND new_test_or_control = 'Control'
	 AND treatment = 'Funding Task Only'
	 --AND treatment = 'Dialer Only'
	 AND feb11_term IS NULL


	--#2:
	 UPDATE Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 --SELECT *
	 SET treatment = 'Dialer Only'
	 FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 WHERE DateofEntry = '2021-02-04'
	 --AND new_test_or_control = 'Control'
	 AND treatment = 'Dialer + Funding Task'
	 --AND treatment = 'Dialer Only'
	 AND feb11_term IS NULL

	 
	--#3:
	 UPDATE Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 --SELECT *
	-- SET treatment = 'Dialer Only'
	 FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 WHERE DateofEntry = '2021-02-04'
	 	 AND feb11_term IS NULL
	 AND new_test_or_control = 'Control'
	 AND treatment = 'Dialer + Funding Task'



/*
Some of the original Dialer Only bunch got moved to Dialer + Funding Task  or Funding Task Only so we need to put them back to Dialer Only, we would not have given them a task
*/
	 UPDATE Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 --SELECT *
	 SET treatment = 'Dialer Only'
	 FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 WHERE 
	 Test_Group = 'Dialer Only'
	 --AND new_test_or_control = 'Control'
	 AND (treatment = 'Dialer + Funding Task' OR treatment = 'Funding Task Only')





	 --just making sure I didn't put any Ico nulls back into the mix and I did not 
	 SELECT * FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]
	 WHERE Icosagonain_Expirmentation_Cell__c IS NULL AND new_test_or_control IS NOT null