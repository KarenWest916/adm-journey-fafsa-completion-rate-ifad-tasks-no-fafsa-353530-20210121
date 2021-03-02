/****** Script for SelectTopNRows command from SSMS  ******/



SELECT [Icosagonain_Expirmentation_Cell__c]
      ,[LeadType]
      ,[ContactID]
      ,[ContactFirstName]
      ,[ContactLastName]
      ,[ContactPEmail]
      ,[Home_Phone__c]
      ,[MobilePhone]
      ,[Business_Phone__c]
      ,[PhoneNumber]
      ,[MailingState]
      ,[MailingStateCode]
      ,[stagename]
      ,MIN([DateofEntry]) AS enter_pop_date
      ,[WrongFAFSA]
      ,[Acad]
      ,[Test_Group]
      ,[OppID]
      ,[Financial__c]
  FROM [Data_Reporting].[dbo].[Remap_NoFAFSA_Dialer]

  	    where Acad = 'UG'
  AND DateofEntry > '2021-01-20'

  GROUP BY [Icosagonain_Expirmentation_Cell__c]
      ,[LeadType]
      ,[ContactID]
      ,[ContactFirstName]
      ,[ContactLastName]
      ,[ContactPEmail]
      ,[Home_Phone__c]
      ,[MobilePhone]
      ,[Business_Phone__c]
      ,[PhoneNumber]
      ,[MailingState]
      ,[MailingStateCode]
      ,[stagename]
      ,[WrongFAFSA]
      ,[Acad]
      ,[Test_Group]
      ,[OppID]
      ,[Financial__c]

