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


		IF OBJECT_ID ('tempdb..#feb4') IS NOT NULL
			DROP TABLE #feb4;
			SELECT p.studentid,
			p.Planned_Start_Term,
			p.Id
			INTO #feb4
		FROM Data_Reporting.dbo.PipelineLoggingRedux p
		WHERE p.DateOfEntry = '2021-02-04'


		IF OBJECT_ID ('tempdb..#feb11') IS NOT NULL
			DROP TABLE #feb11;
			SELECT p.studentid,
			p.Planned_Start_Term,
			p.Id
			INTO #feb11
		FROM Data_Reporting.dbo.PipelineLoggingRedux p
		WHERE p.DateOfEntry = '2021-02-11'


		/*this takes the most recent opportunity that existed out of the
		 three dates for that student
		*/

		IF OBJECT_ID ('tempdb..#pipeopp') IS NOT NULL
			DROP TABLE #pipeopp;
			SELECT distinct p1.Id, p1.Planned_Start_Term
			INTO #pipeopp

			--SELECT DISTINCT p1.Id

			FROM Data_Reporting.dbo.PipelineLoggingRedux p1
			INNER JOIN 
			(SELECT Max(dateofentry) AS date, p.OppID
			FROM Data_Reporting.dbo.PipelineLoggingRedux p
			
			INNER JOIN 

			(
			--grabs all unify staging opps that are admission opportunities
			SELECT o.id
			FROM UnifyStaging.dbo.Opportunity o
			INNER JOIN UnifyStaging.dbo.RecordType rt
			ON rt.id = o.RecordTypeId
			WHERE rt.name = 'Admission Opportunity') AS admopp
			ON adm.id = p.OppID
			
			WHERE 
			(p.DateOfEntry = '2021-01-28'
			OR p.DateOfEntry = '2021-02-04'
			OR p.DateOfEntry = '2021-02-11')
			GROUP BY p.Id) AS  p2
	
	



			WHERE (p1.DateOfEntry = '2021-01-28'
			OR p1.DateOfEntry = '2021-02-04'
			OR p1.DateOfEntry = '2021-02-11')
			


--SELECT TOP 100 * FROM Data_Reporting.dbo.PipelineLoggingRedux





--DELETE FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]


/*

1/21 - Dialer
1/28 - Task
2/4  - Dialer
2/11 - Task

*/



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
	 or entered 1/28 (dialer day), stayed thru task day (2/4)
	 or entered 1/21 (task day), stayed thru dialer day (1/28)
	 AND we originally said you were in the 'Dialer + Task' group then congratulations, you get to
	 stay in the 'Dialer + Task' group
	 Same situation for control group, we can assume they could have received the same treatment.
	*/

	 
	((nof.DateofEntry = '2021-02-04' AND (o.Closed_Lost_Date_Time__c is NULL OR o.Closed_Lost_Date_Time__c > '2021-02-12') AND (o.Registered_Date_Time__c IS NULL OR o.Registered_Date_Time__c > '2021-02-12')
	AND (o.FAFSA_Received__c IS NULL OR o.FAFSA_Received__c > '2021-02-11')  AND feb11.Planned_Start_Term = '21EW4')
	OR
	(nof.DateofEntry = '2021-01-28' AND (o.Closed_Lost_Date_Time__c is NULL OR o.Closed_Lost_Date_Time__c > '2021-02-05') AND (o.Registered_Date_Time__c IS NULL OR o.Registered_Date_Time__c > '2021-02-05')
	AND (o.FAFSA_Received__c IS NULL OR o.FAFSA_Received__c > '2021-02-04') AND feb4.Planned_Start_Term = '21EW4')
	OR
    (nof.DateofEntry = '2021-01-21' AND (o.Closed_Lost_Date_Time__c is NULL OR o.Closed_Lost_Date_Time__c > '2021-01-29') AND (o.Registered_Date_Time__c IS NULL OR o.Registered_Date_Time__c > '2021-01-29')
	AND (o.FAFSA_Received__c IS NULL OR o.FAFSA_Received__c > '2021-01-28') AND jan28.Planned_Start_Term = '21EW4'))

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
	AND (o.FAFSA_Received__c IS NULL OR o.FAFSA_Received__c > '2021-02-04') 
	AND feb4.Planned_Start_Term = '21EW4'))

	AND nof.Test_Group = 'Dialer Only')

	OR	

	/*
	If lead was originally assigned to 'Control' or 'Dialer + Task' and entered pop on dialer day 1/21 or 2/4, 
	but closed out before funding task day, they would only have been eligible for Dialer Only
	*/
	
	(
	(nof.DateofEntry = '2021-01-21' 
	AND (o.Closed_Lost_Date_Time__c is NULL OR o.Closed_Lost_Date_Time__c < '2021-01-28') 
	AND (o.Registered_Date_Time__c IS NULL OR o.Registered_Date_Time__c < '2021-01-28') )

		OR
        
	(nof.DateofEntry = '2021-02-04' 
	AND (o.Closed_Lost_Date_Time__c is NULL OR o.Closed_Lost_Date_Time__c < '2021-02-11') 
	AND (o.Registered_Date_Time__c IS NULL OR o.Registered_Date_Time__c < '2021-02-11') )

		AND nof.Test_Group <> 'Dialer Only'
		)

	THEN 'Dialer Only'
	


	/*

	***FUNDING TASK ONLY***

	if lead entered test pop on 2/11, this was the last treatment and it was a funding task, no dialers after this point
	so if you entered 2/11 and we put you in 'Dialer + Task' you ONLY received a task.
	Same situation for original control group, we can assume they would receive same treatment.

	1/28 was a task day. If you entered that day but closed out before 2/4 which was the last dialer then you're only a
	funding task person. Sorry, no dialer for you even if we put you in the 'Dialer + Task' group in the remap table.
	*/

	when
	(nof.DateofEntry = '2021-02-11'
	OR 
	(nof.DateofEntry = '2021-01-28' 
	AND (o.Closed_Lost_Date_Time__c is NULL OR o.Closed_Lost_Date_Time__c < '2021-02-04') 
	AND (o.Registered_Date_Time__c IS NULL OR o.Registered_Date_Time__c < '2021-02-04')
	AND (o.FAFSA_Received__c IS NULL OR o.FAFSA_Received__c < '2021-02-04') ))
	AND (nof.Test_Group <> 'Dialer Only')

	THEN 'Funding Task Only'


	ELSE NULL	

	END AS treatment,

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
  WHERE ACAD = 'UG'
  AND DateofEntry > '2021-01-20'
  GROUP BY ContactID
  ) AS min
  ON min.ContactID = nof.ContactID


--don't want to pull most recent opp at this point, or do we? instead pulling whatever admission opp has 21EW4

INNER JOIN UnifyStaging.dbo.Opportunity o 
ON o.Contact__c = nof.ContactId
left JOIN #pipeopp pipe
ON pipe.Id = o.Id





inner JOIN #jan28 jan28
ON  jan28.studentid = nof.ContactID
inner JOIN #feb4 feb4
ON feb4.studentid = nof.ContactID
inner JOIN #feb11 feb11 
ON feb11.studentid = nof.ContactID


 WHERE

	 nof.DateofEntry = min.enter
  AND nof.DateofEntry > '2021-01-20'
  --AND rt.name = 'Admission Opportunity'
  AND pipe.Planned_Start_Term = '21EW4'

  
	 
	 --SELECT * FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer_UG_Repop]

	 --
	 --SELECT DISTINCT contactID FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer]
	 --WHERE acad = 'UG'
	 --AND DateofEntry > '2021-01-20'
	 --GROUP BY ContactID

	 --SELECT TOP 100 * FROM Data_Reporting.[dbo].[Remap_NoFAFSA_Dialer]