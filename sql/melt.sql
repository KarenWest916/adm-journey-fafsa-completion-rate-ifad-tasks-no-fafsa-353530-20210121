SELECT nsh.Student_SK,
       nsh.StudentColleagueID,
	   nsh.InitialRegistrationDate,
	   nsh.EnrolledDay1,
       nsh.EnrolledDay15
	   FROM aarda.[dbo].[NewStartsHistoricalReport] AS nsh

	   --WHERE 
    --  nsh.term LIKE '%21EW4%'

