USE [OdyClerkInternal]
GO
/****** Object:  StoredProcedure [dbo].[TrafficCitationImport_Exceptions]    Script Date: 8/11/2020 11:19:18 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






-- =====================================================================================
-- Author:		Tarig Mudawi
-- Create date: 10/15/2013
-- Description:	This stored procedure validate the records in the TrafficCitation_Import,
--              it then flags every bad record in the table to exculde from calling the 
--              API. We can create a report later out of those records.
--  Updated:    9/8/2014:	Added code to fix OfficerID/Badge Number, modify ExceptionReason
--						    for Statute to differenciate between Odyssey and Appendix rejection.
--						    Added a condition to reject DOB in the future. Also added warning for 
--						    all zeros Zip Code.
--				9/17/2014:	Updated to exclude dashes from Citation Number while Checking
--							for Duplicates	  
--  Updated     2/16/2015   T.Mudawi - Fixed the Issue with the FHP naming according to Trooper Unit, new
--                          code tries to select the correct trooper unit and thus the correct officer party Id
--                          preventing the request from being empty if officer party id is Null 
--                          due to bad selection of Trooper Unit/FHP agency i.e. FHPD, FHPK ...etc 
--  Updated     2/24/2015   Fixed the issue with multipe officers coming with the same citation and both active
--                          and belonging to the same agency, We match against both OfficerId and Badge number
--                          and if needed the last name, if a match couldn't be found we return the Generic
--                          officer. Also if the match could not be determined due to NULL Trooper Unit (FHP Case)
--                          we also return the Generic officer.
--  Updated     4/24/2015   T.Mudawi - Added the @CurrExceptionFlag to send only failures.
--  Updated     4/24/2015   T.Mudawi - Fixed code to not select Jurisdiction that are hidden under the NodeId
--  Update      3/30/2016   T.Mudawi - Fix to Allow Vehicle with Null or unknown color to process without warning.
--	Update		08/01/2017	A.Payne	- Set Vehicle Make to UNK if not supplied or blank.
--  Update		09/28/2017  T.Mudawi - Fix to address Case Type selection with Statutes that have 
--					                   duplicate uCodes and Violation Codes.
--  Updated     05/30/2019  T.Mudawi - Added code to map agency codes for FHPTC, FHPTI, FHPTL and FHPTQ
--  Updated     07/02/2019  T.Mudawi - Added code to map agency codes for FHPTF
--  Updated     12/16/2019  T.Mudawi - Updating Statute Code for 18% T.M. 
--  Updated     01/15/2020  T.Mudawi - Per SR86090 and request from Traffic we citation import should select code 316.172(1)(A)-A instead of 316.172(1)(A)-C when encountering statute 316.172(1)(A) 
--		                               the citation does not have the injury to another, serious bodily injury to another or fatal injury.
-- =====================================================================================

ALTER PROC [dbo].[TrafficCitationImport_Exceptions] @FileLogId int, @LocalPath Varchar(1000),
@DebugFlag  TINYINT=0
AS

BEGIN

SET NOCOUNT ON

		DECLARE
		@CitationNumber				VARCHAR(100),
		@PrevCitationNumber			VARCHAR(100),
		@Section					VARCHAR(100),
		@Subsection					VARCHAR(100),
		@Subsection2				VARCHAR(100),
		@SectionLength				VARCHAR(10),
		@SubsectionLength			VARCHAR(20),
		@SubsectionDigits			VARCHAR(20),
		@SubsectionLetters			VARCHAR(10),
		@Statute					VARCHAR(100),
		@FileStatute1				VARCHAR(100),
		@FileStatute2				VARCHAR(100),
		@Code						VARCHAR(100),
		@PrevStatute				VARCHAR(100),
		@PrevCode					VARCHAR(100),
		@CodeID						VARCHAR(100),
		@Amount						VARCHAR(100),
		@PrevAmount					VARCHAR(100),
		@SectionSubsection			VARCHAR(100),
		@Jurisdiction				VARCHAR(100),
		@CurrChar					INT,
		@TempSubString				VARCHAR(10),
		@OffenseDatePermitPeriod    VARCHAR(50),
		@OffenseGroup				VARCHAR(50),
		@sFileDate					VARCHAR(20),
		@sCitationImage             VARCHAR(100),
		@sCurrDate                  DateTime,
		@Agency						VARCHAR(100),
		@Sql						VARCHAR(8000),
		@Sql2						VARCHAR(8000)

        
        -- test2
        
		SELECT @SubsectionDigits = '', @SubsectionLetters = ''

		SELECT @OffenseDatePermitPeriod = CONVERT(VARCHAR(20),Datepart(mm,GetDate() - 25)) +'/'+CONVERT(VARCHAR(20),Datepart(dd,GetDate() - 25))+'/'+CONVERT(VARCHAR(20),Datepart(yy,GetDate() - 25))

		-- SELECT @sFileDate = RIGHT('00'+CAST(DATEPART(mm,GETDATE()) AS VARCHAR(10)), 2) + RIGHT('00'+CAST(DATEPART(dd,GETDATE()) AS VARCHAR(10)), 2) +CAST(DATEPART(yyyy,GETDATE()) AS VARCHAR(10))

		set @sCurrDate='2014-02-05 12:00:00:000'

		SELECT @sFileDate = RIGHT('00'+CAST(DATEPART(mm,@sCurrDate) AS VARCHAR(10)), 2) + RIGHT('00'+CAST(DATEPART(dd,@sCurrDate) AS VARCHAR(10)), 2) +CAST(DATEPART(yyyy,@sCurrDate) AS VARCHAR(10))



				 /**** Citation Number is missing in the File ***************/
								UPDATE TrafficCitation_Import
								SET ExceptionReason = CASE 
														 WHEN ExceptionReason IS NULL OR ExceptionReason = 'Citation number is missing' 
															 THEN 'Citation number is missing'
														 WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Citation number is missing%'
															 THEN ExceptionReason + ', Citation number is missing'
														 WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Citation number is missing%'
															 THEN ExceptionReason
													  END,
									ExceptionFlag = 1
								WHERE (CitationNumber = NULL OR LTRIM(RTRIM(CitationNumber)) ='' OR CitationNumber IS NULL)
								AND FileLogId = @FileLogId 
								AND Processed = 0
								
								-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Citation number is missing'
								AND tc.ExceptionReason LIKE '%Citation number is missing%'
								AND(CitationNumber = NULL OR LTRIM(RTRIM(CitationNumber)) ='' OR CitationNumber IS NULL)
								AND FileLogId = @FileLogId 
								AND Processed = 0
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions)                     
		                        
							   --SET ExceptionReason = 'Citation Number is missing' + ISNULL(ExceptionReason,''), 
		                              
				 /**** Citation Number already exist is Odyssey ***************/ 
				  --Activate this later
								UPDATE TrafficCitation_Import
								SET ExceptionReason =  CASE 
								                          WHEN ExceptionReason IS NULL OR ExceptionReason = 'Possible Duplicate'
								                               THEN 'Possible Duplicate'
								                          WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Possible Duplicate%'
								                               THEN ExceptionReason + ', Possible Duplicate'
								                           WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Possible Duplicate%'
								                               THEN ExceptionReason
								                       END,
								    ExceptionFlag = 1
								WHERE REPLACE(CitationNumber,'-','') IN(SELECT REPLACE(CitationNumber,'-','') FROM Justice..Citation)
								AND FileLogId = @FileLogId 
								AND Processed = 0
								
								-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Possible Duplicate'
								AND tc.ExceptionReason LIKE '%Possible Duplicate%'
								AND REPLACE(CitationNumber,'-','') IN(SELECT REPLACE(CitationNumber,'-','') FROM Justice..Citation)
								AND FileLogId = @FileLogId
								AND Processed = 0
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
		           
				   /**** Missing Offense Date ***************/
								UPDATE TrafficCitation_Import
								SET ExceptionReason = CASE 
														 WHEN ExceptionReason IS NULL OR ExceptionReason = 'Offense Date is missing' 
															 THEN 'Offense Date is missing'
														 WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Offense Date is missing%' --IS NULL AND ExceptionFlag = 1
															 THEN ExceptionReason + ', Offense Date is missing'
													     WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Offense Date is missing%' --IS NULL AND ExceptionFlag = 1
															 THEN ExceptionReason
													  END,
									ExceptionFlag = 1
								WHERE (OffenseDate = NULL OR LTRIM(RTRIM(OffenseDate)) ='' OR OffenseDate IS NULL)
								AND FileLogId = @FileLogId 
								AND Processed = 0
								
								-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Offense Date is missing'
								AND tc.ExceptionReason LIKE '%Offense Date is missing%'
								AND (OffenseDate = NULL OR LTRIM(RTRIM(OffenseDate)) ='' OR OffenseDate IS NULL)
								AND FileLogId = @FileLogId
								AND Processed = 0
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
		                        
				/**** Old Offense Date ***************/   -- COMMENT FOR NOW, REMOVE BEFORE GOING LIVE
								UPDATE TrafficCitation_Import
								SET ExceptionReason = CASE 
								                         WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Offense date outside of 25 days') AND CAST(OffenseDate AS DATE) < CAST(@OffenseDatePermitPeriod AS DATE) 
								                             THEN 'Offense date outside of 25 days'
								                         WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Offense date outside of 25 days%' AND CAST(OffenseDate AS DATE) < CAST(@OffenseDatePermitPeriod AS DATE)
								                             THEN ExceptionReason + ', Offense date outside of 25 days'
								                      END,
								    ExceptionFlag = 1
								WHERE CAST(OffenseDate AS DATE) < CAST(@OffenseDatePermitPeriod AS DATE)
								AND FileLogId = @FileLogId
								AND Processed = 0
								
								-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Offense date outside of 25 days'
								AND tc.ExceptionReason LIKE '%Offense date outside of 25 days%'
								AND CAST(OffenseDate AS DATE) < CAST(@OffenseDatePermitPeriod AS DATE)
								AND FileLogId = @FileLogId
								AND Processed = 0
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
		                        
				  /**** Missing First Name ***************/
								UPDATE TrafficCitation_Import
								SET ExceptionReason = CASE 
														  WHEN (ExceptionReason IS NULL OR ExceptionReason = 'First Name is missing')
															   THEN 'First Name is missing'
														  WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%First Name is missing%'
															   THEN ExceptionReason + ', First Name is missing'
														  WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%First Name is missing%'
															   THEN ExceptionReason
													  END,
									ExceptionFlag = 1
								WHERE (DriverFirstName IS NULL OR LTRIM(RTRIM(DriverFirstName)) ='' OR DriverFirstName = NULL)
								  AND (Business != 'Y' OR Business IS NULL)
								  AND CommercialVehicleCode = 'N'
								  AND FileLogId = @FileLogId 
								  AND Processed = 0
								  
								-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'First Name is missing'
								AND tc.ExceptionReason LIKE '%First Name is missing%'
								AND (DriverFirstName IS NULL OR LTRIM(RTRIM(DriverFirstName)) ='' OR DriverFirstName = NULL)
								AND CommercialVehicleCode = 'N'
								AND FileLogId = @FileLogId
								AND Processed = 0
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
		                        
								--SET ExceptionReason = 'First Name is missing' + ISNULL(ExceptionReason,''),
		                        
							/**** Missing Last Name ***************/
								UPDATE TrafficCitation_Import
								SET ExceptionReason = CASE 
														  WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Last Name is missing')
															   THEN 'Last Name is missing'
														  WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Last Name is missing%' 
															   THEN ExceptionReason + ', Last Name is missing'
														  WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Last Name is missing%' 
															   THEN ExceptionReason
													  END,
									ExceptionFlag =  1
								WHERE (DriverLastName = NULL OR LTRIM(RTRIM(DriverLastName)) ='' OR DriverLastName IS NULL)
								AND FileLogId = @FileLogId 
								AND Processed = 0
								
								-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Last Name is missing'
								AND tc.ExceptionReason LIKE '%Last Name is missing%'
								AND (DriverLastName = NULL OR LTRIM(RTRIM(DriverLastName)) ='' OR DriverLastName IS NULL)
								AND FileLogId = @FileLogId
								AND Processed = 0
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
		                        
							 --SET ExceptionReason = 'Last Name is missing' + ISNULL(ExceptionReason,''),
		                     
							 /******* Ensure Birth Date is Valid for Date Comparison *********/
							 Update TrafficCitation_Import SET ExceptionReason = CASE 
														  WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Invalid Birth Date')
															   THEN 'Invalid Birth Date'
														  WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Invalid Birth Date%'
														       THEN ExceptionReason + ', Invalid Birth Date'
														  WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Invalid Birth Date%'
														       THEN ExceptionReason
													  END,
							ExceptionFlag = 1
							Where ISDATE(BirthDate)=0 and FilelogId=@FileLogId

							-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Invalid Birth Date'
								AND tc.ExceptionReason LIKE '%Invalid Birth Date%'
								AND ExceptionFlag = 1
								AND ISDATE(BirthDate)=0 
								AND FilelogId=@FileLogId
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)		




							 /**** Missing Birth Date ***************/
								UPDATE TrafficCitation_Import
								SET ExceptionReason = CASE 
														  WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Birth date is missing')
															   THEN 'Birth date is missing'
														  WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Birth date is missing%'
														       THEN ExceptionReason + ', Birth date is missing'
														  WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Birth date is missing%'
														       THEN ExceptionReason
													  END,
									ExceptionFlag = 1
								WHERE (BirthDate = NULL OR BirthDate ='' OR BirthDate IS NULL)
								 AND (Business != 'Y' OR Business IS NULL) 
								 AND FileLogId = @FileLogId 
								 AND Processed = 0
								 
								 -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Birth date is missing'
								AND tc.ExceptionReason LIKE '%Birth date is missing%'
								AND (BirthDate = NULL OR BirthDate ='' OR BirthDate IS NULL)
								AND FileLogId = @FileLogId
								AND Processed = 0
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
		                        
								--SET ExceptionReason = 'Birth Date is missing' + ISNULL(ExceptionReason,''),
								
							 /**** Birth Date in the future ***************/
								UPDATE TrafficCitation_Import
								SET ExceptionReason = CASE 
														  WHEN ExceptionReason IS NULL OR ExceptionReason = 'Invalid Birth Date'
															   THEN 'Invalid Birth Date'
														  WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Invalid Birth Date%'
															   THEN ExceptionReason + ', Invalid Birth Date'
														  WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Invalid Birth Date%'
															   THEN ExceptionReason
													  END,
									ExceptionFlag = 1
								WHERE 
								 ExceptionFlag<>1
								 AND CAST(BirthDate AS Date) > CAST(GetDate() AS Date)
								 AND (Business != 'Y' OR Business IS NULL) 
								 AND FileLogId = @FileLogId 
								 AND Processed = 0

								 
								-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Invalid Birth Date'
								AND tc.ExceptionReason LIKE '%Invalid Birth Date%'
								AND ExceptionFlag<>1
								AND Processed = 0
								AND CAST(BirthDate AS Date) > CAST(GetDate() AS Date)
								AND (Business != 'Y' OR Business IS NULL) AND FileLogId = @FileLogId
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
		                        
						   /**** Missing Gender(Sex) ***************/
								UPDATE TrafficCitation_Import
								SET ExceptionReason = CASE 
														  WHEN ExceptionReason IS NULL OR ExceptionReason = 'Gender is missing'  
															   THEN 'Gender is missing'
														  WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Gender is missing%'
															   THEN ExceptionReason + ', Gender is missing'
														  WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Gender is missing%'
															   THEN ExceptionReason
													  END,
									-- Make the gender default to male and changed from failure (1) to warning (2) per traffic request to Anthony  T.M. 11/30/2017
									ExceptionFlag = 2,
									Sex = 'M'
								WHERE (Sex = NULL OR Sex NOT IN('M', 'F') OR Sex IS NULL)
								 AND (Business != 'Y' OR Business IS NULL) 
								 AND ExceptionFlag not in(1,-1)
								 -- Added extra criteria for first name not null and commercial vehicle = 'N'
								 --AND DriverFirstName IS NOT NULL 
								 --AND CommercialVehicleCode = 'N'
								 AND FileLogId = @FileLogId 
								 
								-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Gender is missing'
								AND tc.ExceptionReason LIKE '%Gender is missing%'
								AND (Sex = NULL OR Sex NOT IN('M', 'F') OR Sex IS NULL)
								AND (Business != 'Y' OR Business IS NULL) 
								AND ExceptionFlag not in(1,-1)
								-- Added extra criteria for first name not null and commercial vehicle = 'N'
								--AND DriverFirstName IS NOT NULL 
								--AND CommercialVehicleCode = 'N'
								AND FileLogId = @FileLogId
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
								
				 /**** If DL state is 'FF' and AddressDiffLicense field in the data file is 'Y' we use Non standard US address and flag it as a warning ****/
				 UPDATE dbo.TrafficCitation_Import
				 SET ExceptionReason = CASE 
				                         WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Address different from license') AND ExceptionFlag != 1
				                              THEN 'Address different from license'
				                         WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Address different from license%' AND ExceptionFlag != 1
				                              THEN ExceptionReason + ', Address different from license'
				                         WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Address different from license%' AND ExceptionFlag != 1
				                              THEN ExceptionReason
				                      END,
				      ExceptionFlag = 2
				  WHERE DriverLicenseState = 'FF' AND AddressDiffLicense = 'Y' AND ExceptionFlag != 1 AND FileLogId = @FileLogId
				 
							    -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Address different from license'
								AND tc.ExceptionReason LIKE '%Address different from license%'
								AND DriverLicenseState = 'FF' AND AddressDiffLicense = 'Y'
								AND FileLogId = @FileLogId
								AND ExceptionFlag NOT IN (1,-1)
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
		                        
				 /**** Missing Driver License ***************/  -- below code was commented before 8/12/14                      
								UPDATE TrafficCitation_Import
								SET ExceptionReason = CASE 
														  WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Driver license is missing') AND ExceptionFlag != 1
															   THEN 'Driver license is missing'
														  WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Driver license is missing%' AND ExceptionFlag != 1
															   THEN ExceptionReason + ', Driver license is missing'
														  WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Driver license is missing%' AND ExceptionFlag != 1
															   THEN ExceptionReason
														  ELSE 'Driver license is missing'
													  END,
									ExceptionFlag = 2 -- changed from rejection to warning per Jessica
																																										-- Added NOT LIKE '%[0-9]%' to exclude DL numbers like NONE --> makes them warnings
								WHERE (DriverLicenseNumber = NULL OR DriverLicenseNumber IS NULL OR DriverLicenseNumber ='' /* OR Len(Ltrim(Rtrim(DriverLicenseNumber)))<10 */ OR DriverLicenseNumber NOT LIKE '%[0-9]%' )	
								AND (Business != 'Y' OR Business IS NULL)
								AND FileLogId = @FileLogId 
								AND ExceptionFlag NOT IN (1,-1)
								
								
								-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Driver license is missing'
								AND tc.ExceptionReason LIKE '%Driver license is missing%'
								AND (DriverLicenseNumber = NULL OR DriverLicenseNumber IS NULL OR DriverLicenseNumber ='' /* OR Len(Ltrim(Rtrim(DriverLicenseNumber)))<10 */ OR DriverLicenseNumber NOT LIKE '%[0-9]%' )
								AND (Business != 'Y' OR Business IS NULL) AND FileLogId = @FileLogId
								AND ExceptionFlag NOT IN (1,-1)
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)

		                        
				  /**** Correct missing or invalid Race ***************/                        
								UPDATE TrafficCitation_Import
									SET RaceOdy = CASE 
														  WHEN Race IS NULL OR Race = '' -- Added or = '' for Citation Import 2 TM 7/22/2020
															   THEN 'U'
														  WHEN Race NOT IN('A','B','S','I','E','M','H','O','R','U','W')
															   THEN 'O'
														  WHEN Race = 'H'
														       THEN 'S'
														  ELSE Race
													  END
							   WHERE FileLogId = @FileLogId 
		                        
				 /*** Determine the Offense Group from the Statute ********/
		         
				 /**** Format License Expiration Date  *****/			 
				 --UPDATE dbo.TrafficCitation_Import 
				 --SET ViolationExpiredDLOdy = SUBSTRING(BirthDate,1,6)+ViolationExpiredDL								                         
				 --Where ViolationExpiredDLOdy IS NULL AND FileLogId = @FileLogId 
				 
			 /****** Fix for Leap year issue with Driver License Expiry date  T.M. 11/20/14   *****/ 						
			  --  UPDATE TrafficCitation_Import
			    --SET ViolationExpiredDLOdy = CASE WHEN ISDATE(SUBSTRING(BirthDate,1,6)+ViolationExpiredDL) = 0 
			    --                                    THEN SUBSTRING(BirthDate,1,2)+'/'+ CAST((CAST(SUBSTRING(BirthDate,4,2) As INT) -1) AS varchar(20)) +'/' +ViolationExpiredDL
			    --                                 ELSE 
			    --                                        SUBSTRING(BirthDate,1,6) + ViolationExpiredDL
			    --                            END
			   
			   --Update TrafficCitation_Import Set ViolationExpiredDLOdy= SUBSTRING(BirthDate,1,2)+'/'+ CAST((CAST(SUBSTRING(BirthDate,4,2) As INT) -1) AS varchar(20)) +'/' +ViolationExpiredDL
			   --Where FileLogId=@FileLogId and ISDATE(BirthDate)=1 
			   
			 --  ISDATE(SUBSTRING(BirthDate,1,6)+ViolationExpiredDL)=1

		         		                 									
			 /******  Lookup Agency Name *********************/
		      -- New code to avoid description and resolve issue with Orlando red light 5/5/2016
			  -- For all agencies except FHP 6/10/2016
			  UPDATE dbo.TrafficCitation_import
			  SET IssueAgencyNameOdy = uc.code
			  FROM Justice..uCode uc Join dbo.TrafficCitation_AgencyVendorInfo ti (Nolock) On uc.Code = ti.AgencyCode
			                         Join dbo.TrafficCitation_import tc (Nolock) On tc.VendorAgencyId = ti.VendorAgencyId
			  WHERE uc.CacheTableID = 61
			  AND tc.VendorAgencyId != 15
			  AND FileLogId = @FileLogId

			  -- For FHP Troop 'J' check first against the mapping table  T.M. 9/28/2016
			  UPDATE dbo.TrafficCitation_import
			  SET IssueAgencyNameOdy = (SELECT OdyCode FROM dbo.TrafficCitation_Mapping WHERE OdyCode = 'FHPTJ'),
			  TrooperUnitOdy = 'J'
			  WHERE TrooperUnit = 'J' 
			  AND VendorAgencyId = 15
			  AND FileLogId = @FileLogId

			  -- Mapping code for troopers 'I', 'C', 'L' and 'Q' similar to code for 'J' above TM 5/29/2019 -----------------------------
			   UPDATE dbo.TrafficCitation_import
			  SET IssueAgencyNameOdy = (SELECT OdyCode FROM dbo.TrafficCitation_Mapping WHERE OdyCode = 'FHPTI'),
			  TrooperUnitOdy = 'I'
			  WHERE TrooperUnit = 'I' 
			  AND VendorAgencyId = 15
			  AND FileLogId = @FileLogId

			  UPDATE dbo.TrafficCitation_import
			  SET IssueAgencyNameOdy = (SELECT OdyCode FROM dbo.TrafficCitation_Mapping WHERE OdyCode = 'FHPTC'),
			  TrooperUnitOdy = 'C'
			  WHERE TrooperUnit = 'C' 
			  AND VendorAgencyId = 15
			  AND FileLogId = @FileLogId

			  UPDATE dbo.TrafficCitation_import
			  SET IssueAgencyNameOdy = (SELECT OdyCode FROM dbo.TrafficCitation_Mapping WHERE OdyCode = 'FHPTL'),
			  TrooperUnitOdy = 'L'
			  WHERE TrooperUnit = 'L' 
			  AND VendorAgencyId = 15
			  AND FileLogId = @FileLogId

			   UPDATE dbo.TrafficCitation_import
			  SET IssueAgencyNameOdy = (SELECT OdyCode FROM dbo.TrafficCitation_Mapping WHERE OdyCode = 'FHPTQ'),
			  TrooperUnitOdy = 'Q'
			  WHERE TrooperUnit = 'Q' 
			  AND VendorAgencyId = 15
			  AND FileLogId = @FileLogId

			   UPDATE dbo.TrafficCitation_import
			  SET IssueAgencyNameOdy = (SELECT OdyCode FROM dbo.TrafficCitation_Mapping WHERE OdyCode = 'FHPTF'),
			  TrooperUnitOdy = 'F'
			  WHERE TrooperUnit = 'F' 
			  AND VendorAgencyId = 15
			  AND FileLogId = @FileLogId

			  ------------ End of Mapping code for troopers code 'I', 'C', 'L' and 'Q' -------------------------------------------------------

			  -- For FHP only 6/10/2016
			  UPDATE dbo.TrafficCitation_import
			  SET IssueAgencyNameOdy = Substring(uc.code,1,3)
			  FROM Justice..uCode uc Join dbo.TrafficCitation_AgencyVendorInfo ti (Nolock) On Substring(uc.code,1,3) = ti.AgencyCode
			                         Join dbo.TrafficCitation_import tc (Nolock) On tc.VendorAgencyId = ti.VendorAgencyId
			  WHERE uc.CacheTableID = 61
			  AND tc.VendorAgencyId = 15
			  AND FileLogId = @FileLogId
			  --AND TrooperUnit != 'J'
			  -- exclude troops 'I', 'C', 'L' and 'Q' too TM 5/29/2019
			  AND TrooperUnit not in('J','I', 'C', 'L', 'Q', 'F')

			 -- Old code commented 5/5/2016
			 --UPDATE dbo.TrafficCitation_import
			 --SET IssueAgencyNameOdy = uc.code 
			 --FROM justice..uCode uc INNER JOIN justice..CodeMapping cm (NOLOCK) ON uc.CodeId =  cm.CodeMappingKey          
				--  INNER JOIN justice..sMappingCode mc (NOLOCK) ON cm.CodeMapTypeKey = mc.CodeMapTypeKey
				--  AND mc.MappingCodeID = cm.MappingCodeID
			 --WHERE mc.CodeMapTypeKey ='FLAGY'
				--AND mc.Code = Replace(IssueAgencyCode,'0','')
				----AND uc.Description like ''+IssueAgencyName+'%'
				--AND uc.Description like ''+Replace(IssueAgencyName,'PD','')+'%' --> Changed to grab Ocoee, Winter Garden and Oakland T.M. 8/4/2015
				--AND uc.userIdCreate =1
				--AND FileLogId = @FileLogId 

				
			 /******* Populating TrooperUnitOdy column ******/
			 UPDATE dbo.TrafficCitation_import
			 SET TrooperUnitOdy = TrooperUnit
			 WHERE TrooperUnit IS NOT NULL
			 AND VendorAgencyId = 15        
			 AND FileLogId = @FileLogId

			 /***** If trooper unit is null in the file then figure it out T.M. 6/30/2016  ******/
			 Update TrafficCitation_import
			Set TrooperUnitOdy = Case When OfficerID in(Select badgeNum from Justice..officer Where AgencyID = '22213') Then 'D'
								  When Substring(OfficerID,1,1) = 0 and Substring(OfficerID,2,4) in(Select badgeNum from Justice..officer Where AgencyID = '22213') Then 'D'
								  When OfficerID in(Select badgeNum from Justice..officer Where AgencyID = '22214') Then 'K'
								  When Substring(OfficerID,1,1) = 0 and Substring(OfficerID,2,4) in(Select badgeNum from Justice..officer Where AgencyID = '22214') Then 'K'
								  When OfficerBadgeNumber in(Select badgeNum from Justice..officer Where AgencyID = '22213') Then 'D'
								  When Substring(OfficerBadgeNumber,1,1) = 0 and Substring(OfficerBadgeNumber,2,4) in(Select badgeNum from Justice..officer Where AgencyID = '22213') Then 'D'
								  When OfficerBadgeNumber in(Select badgeNum from Justice..officer Where AgencyID = '22214') Then 'K'
								  When Substring(OfficerBadgeNumber,1,1) = 0 and Substring(OfficerBadgeNumber,2,4) in(Select badgeNum from Justice..officer Where AgencyID = '22214') Then 'K'
								End
			Where TrooperUnitOdy IS NULL
			AND VendorAgencyId = 15
			AND FileLogId = @FileLogId 


			 
			 --/***** Naming FHP according to Trooper Unit *****/   
			 UPDATE dbo.TrafficCitation_Import
			 SET IssueAgencyNameOdy = 'FHP' + TrooperUnitOdy
			 WHERE SUBSTRING(IssueAgencyNameOdy,1,3) = 'FHP'
			 AND TrooperUnitOdy IS NOT NULL
			 -- AND TrooperUnitOdy != 'J'
			 -- exclude troops 'I', 'C', 'L' and 'Q' too TM 5/29/2019
			  AND TrooperUnit not in('J','I', 'C', 'L', 'Q', 'F')
			 AND FileLogId = @FileLogId 
						
			  /******* Update Values for OfficerIDOdy (This column populates the XMLs for API call ********************/
			  /*** New Officers Code 2/19/2015 ***/ 
				
				UPDATE TrafficCitation_Import 
				SET OfficerIDOdy = dbo.GetOfficerBadgeNumber(OfficerBadgeNumber, OfficerId, IssueAgencyNameOdy, OfficerLastName)
				WHERE FileLogId = @FileLogId
				
			  /*** End New Officers Code ***/

             UPDATE dbo.TrafficCitation_import
			 SET TrooperUnitOdy = SUBSTRING(uc.Code,4,1) 
			 FROM Justice..uCode uc JOIN Justice..Officer o (NOLOCK) ON uc.CodeID = o.AgencyID
			                        JOIN Justice..Name n (NOLOCK) ON o.PartyID = n.PartyID
									--JOIN TrafficCitation_Import tc (NOLOCK) ON SUBSTRING(tc.OfficerId,2,4) = o.BadgeNum OR tc.OfficerBadgeNumber = o.BadgeNum
									JOIN TrafficCitation_Import tc (NOLOCK) ON tc.OfficerIDOdy = o.BadgeNum
			 WHERE SUBSTRING(tc.IssueAgencyNameOdy,1,3) = 'FHP' 
			 AND TrooperUnit IS NULL
			 AND n.NameLast = OfficerLastName
			 AND FileLogId = @FileLogId 

			   --/**** Invalid or Missing Officer Badge Number ***************/
								UPDATE TrafficCitation_Import
								SET ExceptionReason = CASE 
									   WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Review Officer Information: ' + Replace(OfficerFirstName + ' ' + ISNULL(OfficerMiddleName, '') + ' ' + OfficerLastName, '  ',' ')) AND ExceptionFlag != 1
											   THEN 'Review Officer Information: ' + Replace(OfficerFirstName + ' ' + ISNULL(OfficerMiddleName, '') + ' ' + OfficerLastName, '  ',' ')
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Review Officer Information%' AND ExceptionFlag != 1 
											   THEN ExceptionReason + ', Review Officer Information:  ' + Replace(OfficerFirstName + ' ' + ISNULL(OfficerMiddleName, '') + ' ' + OfficerLastName, '  ',' ')
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Review Officer Information%' AND ExceptionFlag != 1 
											   THEN ExceptionReason
									END,
									ExceptionFlag = 2
							   WHERE OfficerIDOdy = '0000' AND ExceptionFlag != 1
							   AND FileLogId = @FileLogId 
							   
							   -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Review Officer Information'
								AND tc.ExceptionReason LIKE '%Review Officer Information%'
								AND OfficerIDOdy = '0000' AND ExceptionFlag != 1
								AND FileLogId = @FileLogId
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
								                                          				
		                                       
			  /**** Missing Jurisdiction Number ***************/ -- comment this for now 6/19/14
					   --UPDATE TrafficCitation_Import
					   --SET JurisdictionCode = 'OC'
					   --WHERE JurisdictionNumber IS NULL AND FileLogId = @FileLogId 
	                          
			  /**** Invalid Jurisdiction Number ***************/
								UPDATE TrafficCitation_Import
								SET ExceptionReason = CASE 
									   WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Invalid Jurisdiction') AND JurisdictionNumber IS NOT NULL 
											   THEN 'Invalid Jurisdiction'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Invalid Jurisdiction%' AND JurisdictionNumber IS NOT NULL
											   THEN ExceptionReason + ', Invalid Jurisdiction'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Invalid Jurisdiction%' AND JurisdictionNumber IS NOT NULL
											   THEN ExceptionReason
									END,
									ExceptionFlag = 1
								WHERE JurisdictionNumber NOT IN (SELECT DISTINCT cm.TextValue FROM Justice..CodeMapping cm
													JOIN OdyClerkInternal..TrafficCitation_Import TC (NOLOCK) ON cm.TextValue=TC.JurisdictionNumber 
													JOIN Justice..uCode UC (NOLOCK) ON cm.CodeMappingKey=UC.CodeID) 
								AND JurisdictionNumber != '00'	
								AND FileLogId = @FileLogId
								AND Processed = 0
								
								-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Invalid Jurisdiction'
								AND tc.ExceptionReason LIKE '%Invalid Jurisdiction%'
								AND JurisdictionNumber NOT IN (SELECT DISTINCT cm.TextValue FROM Justice..CodeMapping cm
													JOIN OdyClerkInternal..TrafficCitation_Import TC (NOLOCK) ON cm.TextValue=TC.JurisdictionNumber 
													JOIN Justice..uCode UC (NOLOCK) ON cm.CodeMappingKey=UC.CodeID) 
								AND JurisdictionNumber != '00'
								AND FileLogId = @FileLogId 
								AND Processed = 0	
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)											     						         
		   				
			/************ This part takes the section and subsection and genertaed a formatted statute and code ************/
		    
			Select @PrevCitationNumber = '', @PrevCode = '', @PrevStatute = '', @PrevAmount = ''
		    
		     
			 UPDATE TrafficCitation_import
			 SET Statute = Case WHEN dbo.TrafficCitationImport_FormatStatute(TrafficCitation_import.Section,TrafficCitation_import.Subsection) IS NOT NULL
									   THEN dbo.TrafficCitationImport_FormatStatute(TrafficCitation_import.Section,TrafficCitation_import.Subsection)
								ELSE dbo.TrafficCitationImport_FormatStatute(TrafficCitation_import.Section,'')
						   END
			 WHERE FileLogId = @FileLogId 
		                   
			 /***** Updating Offense Codes with Non-Unique Violations Codes  ****/              
			 UPDATE TrafficCitation_import
			 SET Code = CASE WHEN dbo.TrafficCitationImport_GetStatuteGroupID(Statute) IN('1','2','3')
								 THEN dbo.TrafficCitationImport_GetUniqueOffenseCode(Statute, ViolationCode, FileAmount, BloodAlcoholLevel)
						END
			 WHERE Code IS NULL
			 AND FileLogId = @FileLogId  	      
		           
			 /***** Updating Offense Codes with Unique Violations Codes  ****/
		     
				UPDATE TrafficCitation_import
				SET Code = uc.Code, StatuteCodeId=uc.CodeId
				FROM Justice..CodeMapping cm JOIN Justice..uCode uc (NOLOCK) ON cm.CodeMappingKey=uc.CodeID
											 JOIN Justice..uOff uo (NOLOCK) ON uc.CodeID = uo.OffenseID
											 JOIN TrafficCitation_Import tc (NOLOCK) ON uo.Statute = tc.Statute 							
				WHERE cm.TextValue = tc.ViolationCode 
				AND CodeMapTypeKey IN('FLDVC')
				AND cm.CacheTableID =85
				AND (uc.ObsoleteDate IS NULL OR uc.ObsoleteDate > GETDATE())
				--AND uc.CodeID NOT IN(SELECT codeID FROM justice..xuCodeNode WHERE Hidden !=0 AND NodeID IN(600, 601, 602, 603, 604)) --> commenetd on 7/20/2015
				-- Fix for Hidden code/code Id  T.M. 7/20/2015
				AND uc.CodeID NOT IN(SELECT codeID FROM justice..xuCodeNode WHERE Hidden =1)
				--AND uc.CodeID IN(SELECT CodeID FROM justice..xuCodeNode WHERE Hidden =0 AND NodeID = tc.NodeID)
				AND SUBSTRING(uc.Description,1,3) IN('TR-', 'CT-', 'TR ', 'CT ')
				--AND tc.Code IS NULL  --< commenetd to fix hidden codeId issue  T.M. 7/21/2015
				AND FileLogId = @FileLogId 
				
				Update TrafficCitation_Import set StatuteCodeId=uc.CodeId
				From TrafficCitation_Import TC Join Justice..uCode uc with (nolock) on TC.Code=uc.Code
				Where tc.StatuteCodeId is Null and tc.Code is not null
				and FileLogid=@FileLogId

				
				/***** If statute is not in the appendix then reject the citation *****/ 
				UPDATE TrafficCitation_Import
				SET ExceptionReason = CASE WHEN ExceptionReason IS NULL OR ExceptionReason = 'Statute not in Appendix'
											  THEN 'Statute not in Appendix'
								          WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Statute not in Appendix%' 
								              THEN ExceptionReason + ', Statute not in Appendix' 
								          WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Statute not in Appendix%' 
								              THEN ExceptionReason
								     END,
				ExceptionFlag = 1
				WHERE Statute NOT IN (SELECT apx.Statute FROM TrafficeCitationImport_Appendix_C apx JOIN TrafficCitation_Import tc (NOLOCK) ON apx.Statute = tc.Statute AND apx.ViolationCode = tc.ViolationCode )
				/* AND ExceptionReason != 'Unable to Match Statute - Statute not in Appendix' */  -- modified for 2nd round 8/14/2014
				AND FileLogid=@FileLogId
				AND Processed = 0
				
				-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Statute not in Appendix' 
								AND tc.ExceptionReason LIKE '%Statute not in Appendix%'
								AND Statute NOT IN (SELECT apx.Statute FROM TrafficeCitationImport_Appendix_C apx JOIN TrafficCitation_Import tc (NOLOCK) ON apx.Statute = tc.Statute AND apx.ViolationCode = tc.ViolationCode )
								AND FileLogId = @FileLogId 	
								AND Processed = 0
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
		     
			 ------------------------------------------------------------------------
			 UPDATE TrafficCitation_Import
					  SET ExceptionReason = CASE
							WHEN ExceptionReason IS NULL OR ExceptionReason = 'Statute not in Odyssey'
								   THEN 'Statute not in Odyssey'   
							WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Statute not in Odyssey%'
								   THEN ISNULL(ExceptionReason,'') + ', Statute not in Odyssey' 
						    WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Statute not in Odyssey%'
								   THEN ExceptionReason 
						  END, 
						 ExceptionFlag = 1  
						 --WHERE Statute NOT IN(SELECT Statute From Justice..uOff)
						WHERE EXISTS(select uc.Code
										 FROM Justice..uCode uc WHERE uc.Code != Code)
						/* AND ExceptionReason != 'Unable to Match Statute - Statute or Code not in Odyssey' */  -- modified for 2nd round 8/14/2014 
						AND FileLogId = @FileLogId 
						AND Processed = 0
						
				-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Statute not in Odyssey' --'Unable to Match Statute - Statute or Code not in Odyssey'
								AND tc.ExceptionReason LIKE '%Statute not in Odyssey%' --'%Unable to Match Statute - Statute or Code not in Odyssey%'
								AND EXISTS(select uc.Code
										 FROM Justice..uCode uc WHERE uc.Code != Code)
								AND FileLogId = @FileLogId 
								AND Processed = 0
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)		                                                    
		         
			 /***** Getting Officer Full Name *****/
			 UPDATE dbo.TrafficCitation_import
			 SET OfficerFullName = Replace(OfficerFirstName + ' ' + ISNULL(OfficerMiddleName, '') + ' ' + OfficerLastName, '  ',' ')
			 WHERE FileLogId = @FileLogId 
		     
		     
			/**** Lookup for Officer Code(PartyID in Officer Table) ********/
		    
			--First set the officerPartyID to NULL to start clean
			UPDATE TrafficCitation_import
			set officerPartyId = NULL
			WHERE FileLogId = @FileLogId 
		     
		     -- Fixed code for Officer, changed OfficerBadgeNumber with OfficerIdOdy, also commented the 2nd update statement
			 UPDATE dbo.TrafficCitation_import
			 SET OfficerPartyID = o.PartyID
			 FROM Justice..Officer o, Justice..uCode uc 
			 WHERE o.BadgeNum = OfficerIdOdy   -- OfficerBadgeNumber
			 AND o.AgencyID = uc.CodeID
			 AND uc.Code = IssueAgencyNameOdy  
			 AND (o.InactiveDate IS NULL OR o.InactiveDate > GetDate())  
			 AND FileLogId = @FileLogId 
			 
			 -- Add this extra query to pick records that still left null 2/17/2015
			 UPDATE dbo.TrafficCitation_import
			 SET OfficerPartyID = o.PartyID
			 FROM Justice..Officer o, Justice..uCode uc 
			 WHERE o.BadgeNum = OfficerIdOdy   -- OfficerBadgeNumber
			 AND o.AgencyID = uc.CodeID
			 --AND uc.Code = IssueAgencyNameOdy  
			 --AND (o.InactiveDate IS NULL OR o.InactiveDate > GetDate())  
			 AND OfficerPartyID IS NULL 
			 AND FileLogId = @FileLogId 

			 /**** Lookup for Officer Code(PartyID in Officer Table) for Generic Officer ********/
			 UPDATE dbo.TrafficCitation_import
			 SET OfficerPartyID = o.PartyID
			 FROM Justice..Officer o, Justice..uCode uc 
			 WHERE o.BadgeNum = '0000'
			 AND o.AgencyID = uc.CodeID
			 AND uc.Code = IssueAgencyNameOdy
			 AND OfficerPartyID IS NULL 
			 AND FileLogId = @FileLogId 
		     
				/************ If Officer Party ID is NULL send the record as generic officer ******************************/
				UPDATE TrafficCitation_Import
					  SET ExceptionReason = CASE
							WHEN ExceptionReason IS NULL OR ExceptionReason = 'Review Officer Information' AND ExceptionFlag != 1
								   THEN 'Review Officer Information' 
							WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Review Officer Information%' AND  ExceptionFlag != 1
								   THEN ExceptionReason + ', Review Officer Information'
						    WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Review Officer Information%' AND  ExceptionFlag != 1
								   THEN ExceptionReason
						  END, 
						 ExceptionFlag = 2 
				   WHERE (OfficerPartyID IS NULL OR OfficerPartyID = '' OR OfficerPartyID = '0000') AND ExceptionFlag != 1 AND FileLogId = @FileLogId 
				   
				   -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Review Officer Information'
								AND tc.ExceptionReason LIKE '%Review Officer Information%'
								--WHERE tc.ExceptionReason = tr.ExceptionReason
								AND (OfficerPartyID IS NULL OR OfficerPartyID = '' OR OfficerPartyID = '0000') AND ExceptionFlag != 1
								AND FileLogId = @FileLogId 
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
		           
		    
			/**** Lookup the Vehicle Make Code ********/
				UPDATE dbo.TrafficCitation_Import 
				SET VehicleMakeCode = uc.Code
				FROM Justice..uCode uc JOIN TrafficCitation_Import tc (NOLOCK) ON uc.Code = tc.VehicleMake
				WHERE uc.CacheTableID = 158 AND FileLogId = @FileLogId 
			
			/***** Check Mapping Table *************/
				UPDATE dbo.TrafficCitation_Import 
				SET VehicleMakeCode = m.OdyCode
				FROM TrafficCitation_Mapping m 
				JOIN TrafficCitation_Import tc (NOLOCK) ON m.FileCode = tc.VehicleMake and m.MappingType='VMake'
				WHERE FileLogId = @FileLogId 
				and VehicleMakeCode IS NULL

	 		/***** Set Vehicle Make to UNKNOWN if Blank ****/
			Update OdyClerkInternal.dbo.TrafficCitation_Import
			Set VehicleMakeCode='UNK' 
			Where (VehicleMakeCode IS NULL or Len(Ltrim(Rtrim(VehicleMakeCode)))=0)
			and FileLogId = @FileLogId 
			 

		  
		   /**** Lookup the Vehicle Color Code ********/ 
		   UPDATE dbo.TrafficCitation_Import 
		   SET VehicleColorCode = uc.Code
		   FROM Justice..uCode uc JOIN TrafficCitation_Import tc (NOLOCK) ON uc.Code = tc.VehiclyColor
		   WHERE uc.CacheTableID = 149 AND FileLogId = @FileLogId 
		   
		   /***** Check Mapping Table *************/
		   UPDATE dbo.TrafficCitation_Import 
		   SET VehicleColorCode = m.OdyCode
		   FROM TrafficCitation_Mapping m 
				JOIN TrafficCitation_Import tc (NOLOCK) ON m.FileCode = tc.VehiclyColor and m.MappingType='VColor'
		   WHERE FileLogId = @FileLogId 
		   and VehicleColorCode IS NULL
		
		     
		   /**** Validating the Vehicle Make Code ********/
							UPDATE TrafficCitation_Import
							SET ExceptionReason = CASE 
									   WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Invalid Vehicle Make') 
										   AND (VehicleMakeCode = 'UNK' OR VehicleMakeCode IS NULL) 
											   THEN 'Invalid Vehicle Make'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Invalid Vehicle Make%' AND ExceptionFlag = 2 
										   AND (VehicleMakeCode = 'UNK' OR VehicleMakeCode IS NULL)
											   THEN ExceptionReason + ', Invalid Vehicle Make'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Invalid Vehicle Make%' AND ExceptionFlag = 2 
										   AND (VehicleMakeCode = 'UNK' OR VehicleMakeCode IS NULL)
											   THEN ExceptionReason
									END,
									ExceptionFlag = 2
							 WHERE (VehicleMakeCode IS NULL OR VehicleMakeCode = 'UNK') AND ExceptionFlag NOT IN(1, -1) AND FileLogId = @FileLogId
							 
							 -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Invalid Vehicle Make'
								AND tc.ExceptionReason LIKE '%Invalid Vehicle Make%'
								AND (VehicleMakeCode IS NULL OR VehicleMakeCode = 'UNK') AND ExceptionFlag NOT IN(1, -1)
								AND FileLogId = @FileLogId 
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
		                    
		                    UPDATE dbo.TrafficCitation_Import 
							SET ExceptionReason = 'Invalid Vehicle Make',
							    ExceptionFlag = 2
							WHERE VehicleMakeCode NOT IN(SELECT Code FROM Justice..uCode WHERE CacheTableID = 158)
							 AND VehicleMakeCode NOT IN(SELECT FileCode FROM TrafficCitation_Mapping WHERE MappingType='VMake')
							 AND VehicleMakeCode IS NOT NULL AND ExceptionFlag != 1 AND FileLogId = @FileLogId
							 
							 -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Invalid Vehicle Make'
								AND tc.ExceptionReason LIKE '%Invalid Vehicle Make%'
								AND VehicleMakeCode NOT IN(SELECT Code FROM Justice..uCode WHERE CacheTableID = 158)
								AND VehicleMakeCode NOT IN(SELECT FileCode FROM TrafficCitation_Mapping WHERE MappingType='VMake')
								AND VehicleMakeCode IS NOT NULL AND ExceptionFlag != 1
								AND FileLogId = @FileLogId 
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
							 
		 		  /**** Validating the Vehicle Color Code ********/
		                    -- Commenetd old code T.M. 3/30/2016
							--UPDATE TrafficCitation_Import
							--SET ExceptionReason = CASE 
							--		   WHEN ExceptionReason IS NULL OR ExceptionReason = 'Invalid Vehicle Color' AND VehicleColorCode IS NULL 
							--				   THEN 'Invalid Vehicle Color'
							--		   WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Invalid Vehicle Color%' AND VehicleColorCode IS NULL
							--				   THEN ExceptionReason + ', Invalid Vehicle Color'
							--		   WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Invalid Vehicle Color%' AND VehicleColorCode IS NULL
							--				   THEN ExceptionReason
							--		END,
							--		ExceptionFlag = 2
							-- WHERE VehicleColorCode IS NULL AND ExceptionFlag != 1 AND FileLogId =@FileLogId

							-- New code to not set vehicle color to warning if coming NULL or UNKNOWN in the file T.M. 3/30/2016
							 UPDATE TrafficCitation_Import
							SET ExceptionReason = CASE 
									   WHEN ExceptionReason IS NULL AND VehicleColorCode IS NULL AND (VehiclyColor IS NOT NULL AND VehiclyColor != 'UNKNOWN')
											   THEN 'Invalid Vehicle Color'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Invalid Vehicle Color%' AND VehicleColorCode IS NULL AND (VehiclyColor IS NOT NULL AND VehiclyColor != 'UNKNOWN')
											   THEN ExceptionReason + ', Invalid Vehicle Color'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Invalid Vehicle Color%' AND VehicleColorCode IS NULL AND (VehiclyColor IS NOT NULL AND VehiclyColor != 'UNKNOWN')
											   THEN ExceptionReason
									END,
									ExceptionFlag = 2
							 WHERE VehicleColorCode IS NULL AND (VehiclyColor IS NOT NULL AND VehiclyColor != 'UNKNOWN') AND ExceptionFlag != 1 AND FileLogId =@FileLogId

		 /******** If Vehicle color is coming null in the file do not sent it as warning per Traffic team request (Jaya) T.M. 3/30/2016 ***********/
		                  UPDATE TrafficCitation_import
						  SET ExceptionFlag = 0,
						      ExceptionReason = NULL
						  WHERE VehiclyColor IS NULL OR VehiclyColor = 'UNKNOWN'
						  AND ExceptionFlag = 2 
						  AND ExceptionReason = 'Invalid Vehicle Color'
						  AND FileLogId =@FileLogId
							 
							 -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Invalid Vehicle Color'
								AND tc.ExceptionReason LIKE '%Invalid Vehicle Color%'
								AND VehicleColorCode IS NULL AND ExceptionFlag != 1
								AND FileLogId = @FileLogId
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
							 
							UPDATE dbo.TrafficCitation_Import 
							SET ExceptionReason = 'Invalid Vehicle Color',
							    ExceptionFlag = 2
							WHERE VehicleColorCode NOT IN(SELECT Code FROM Justice..uCode WHERE CacheTableID = 149)
							 AND VehicleColorCode NOT IN(SELECT FileCode FROM TrafficCitation_Mapping WHERE MappingType='VColor')
							 AND VehicleColorCode IS NOT NULL AND ExceptionFlag != 1 AND FileLogId = @FileLogId
							 
							 -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Invalid Vehicle Color'
								AND tc.ExceptionReason LIKE '%Invalid Vehicle Color%'
								AND VehicleColorCode NOT IN(SELECT Code FROM Justice..uCode WHERE CacheTableID = 149)
								AND VehicleColorCode NOT IN(SELECT FileCode FROM TrafficCitation_Mapping WHERE MappingType='VColor')
								AND VehicleColorCode IS NOT NULL AND ExceptionFlag != 1
								AND FileLogId = @FileLogId
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)

			/***** Check for bad vehicle year T.M. 5/8/2017  *******/
			 UPDATE dbo.TrafficCitation_import
			 SET ExceptionReason = CASE 
									   WHEN ExceptionReason IS NULL AND (VehicleYear = '0' OR VehicleYear IS NULL)
											   THEN 'Invalid vehicle year'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Invalid vehicle year%' AND (VehicleYear = '0' OR VehicleYear IS NULL)
											   THEN ExceptionReason + ', Invalid vehicle year'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Invalid vehicle year%' AND (VehicleYear = '0' OR VehicleYear IS NULL)
											   THEN ExceptionReason
									END,
									ExceptionFlag = 1
							 WHERE (VehicleYear = '0' OR VehicleYear IS NULL) AND ExceptionFlag != 1 
							 AND FileLogId =@FileLogId
							 AND Processed = 0

               -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Invalid vehicle year'
								AND tc.ExceptionReason LIKE '%Invalid vehicle year%'
								AND  (VehicleYear = '0' OR VehicleYear IS NULL) AND ExceptionFlag != 1
								AND FileLogId = @FileLogId
								AND Processed = 0
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)

			 /***** Fix the Height if it includes anon-numeric character T.M. 5/8/2017   ******/
			  UPDATE dbo.TrafficCitation_import
			  SET Height = '00'
			  WHERE Height LIKE '%[^0-9]%'
			  AND FileLogId = @FileLogId
		                     
			  /**** Extracting the Height Feet and inches *******/  
			  UPDATE dbo.TrafficCitation_import
			  SET HeightFeet = RIGHT('00' + SUBSTRING(Height,1,1), 2),
				  HeightInches = RIGHT('00' + SUBSTRING(Height,2,2), 2) 
			  WHERE FileLogId = @FileLogId


			  /**** Handling the issue of driver address state coming as 'FF' and causing API errors  T.M. 5/9/2017   *****/
			   UPDATE TrafficCitation_Import
							SET ExceptionReason = CASE 
									   WHEN ExceptionReason IS NULL AND (StateofDriversAddress = 'FF' OR StateofDriversAddress IS NULL)
											   THEN 'Invalid driver address state'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Invalid driver address state%' AND (StateofDriversAddress = 'FF' OR StateofDriversAddress IS NULL)
											   THEN ExceptionReason + ', Invalid driver address state'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Invalid driver address state%' AND (StateofDriversAddress = 'FF' OR StateofDriversAddress IS NULL)
											   THEN ExceptionReason
									END,
									ExceptionFlag = 1
							 WHERE (StateofDriversAddress = 'FF' OR StateofDriversAddress IS NULL) AND ExceptionFlag != 1 
							 AND FileLogId =@FileLogId
							 AND Processed = 0

							-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Invalid driver address state'
								AND tc.ExceptionReason LIKE '%Invalid driver address state%'
								AND (StateofDriversAddress = 'FF' OR StateofDriversAddress IS NULL) AND ExceptionFlag != 1
								AND FileLogId = @FileLogId
								AND Processed = 0
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)

			  /******  Preparing the Degree **********************/  
			  /*    	      
		      UPDATE dbo.TrafficCitation_import
			  SET Degree = Justice..uCode.Code 
			  FROM Justice..uOff uo JOIN Justice..xuOffuDegree (NOLOCK) ON uo.OffenseID = Justice..xuOffuDegree.OffenseID
			  JOIN Justice..uCode (NOLOCK) ON ucode.CodeID = xuOffuDegree.DegreeID
			  JOIN Justice..uCode uc2 (NOLOCK) ON uc2.CodeId = uo.OffenseId
			  WHERE uo.Statute = dbo.TrafficCitation_import.Statute
			  AND TrafficCitation_Import.Code = uc2.Code  
			  AND FileLogId = @FileLogId
			  */
			  -- New code for Degree T.M. 7/23/2015
             -- First clear Degree before starting
             UPDATE TrafficCitation_Import
             SET Degree = NULL 
             WHERE FileLogId = @FileLogId 
             
			 UPDATE TrafficCitation_Import
			 SET Degree = uc.Code
			 From Justice..uCode uc Join Justice..uOff uo (Nolock) ON uc.CodeID = uo.DefaultDegreeID    -- uc.CodeID = ISNULL(uo.DefaultDegreeID,'4446')
                       Join Justice..uCode uc2 (Nolock) ON uo.OffenseID = uc2.CodeID
                      Join TrafficCitation_Import tc (Nolock) On tc.Statute = uo.Statute 
			 Where tc.Code = uc2.Code
			 And FileLogId = @FileLogId

			  -- If No default Degree then use the old code since the offense has a degree but not set as a default.T.M. 10/26/2015
			  UPDATE dbo.TrafficCitation_import
			  SET Degree = Justice..uCode.Code 
			  FROM Justice..uOff uo JOIN Justice..xuOffuDegree (NOLOCK) ON uo.OffenseID = Justice..xuOffuDegree.OffenseID
			  JOIN Justice..uCode (NOLOCK) ON ucode.CodeID = xuOffuDegree.DegreeID
			  JOIN Justice..uCode uc2 (NOLOCK) ON uc2.CodeId = uo.OffenseId
			  WHERE uo.Statute = dbo.TrafficCitation_import.Statute
			  AND TrafficCitation_Import.Code = uc2.Code  
			  AND TrafficCitation_Import.Degree IS NULL  --<--  Added to prevent overwritting of the degree, only populate if degree is null  T.M. 5/27/2016
			  AND FileLogId = @FileLogId
			 
			 -- Commenting this code T.M. 10/26/2015
			 -- If degree still null set it to 'NDI'
		     --UPDATE TrafficCitation_Import
       --      SET Degree = 'NDI' 
       --      WHERE Degree IS NULL AND Statute IS NOT NULL and Code IS NOT NULL
       --      AND FileLogId = @FileLogId 
             
             
			 /***** Mapping other values from the file *******/
			 UPDATE dbo.TrafficCitation_import
			 SET CommercialVehicleCodeOdy = Case WHEN CommercialVehicleCode = 'Y' THEN 'TRUE'
											   ELSE 'FALSE'
										  END,
				 HazardousMaterialsOdy = Case WHEN HazardousMaterials = 'Y' THEN 'TRUE'
											ELSE 'FALSE'
									   END,
				 AggressiveDriverFlagOdy = Case WHEN AggressiveDriverFlag = 'Y' THEN 'TRUE'
											  ELSE 'FALSE'
										END,
							   InjuryOdy = Case WHEN Injury = 'Y' THEN 'TRUE'
											  ELSE 'FALSE'
										END,
						 SeriousInjuryOdy = Case WHEN SeriousInjury = 'Y' THEN 'TRUE'
											   ELSE 'FALSE'                              
										END,
						 FatalInjuryOdy = Case WHEN FatalInjury = 'Y' THEN 'TRUE'
											 ELSE 'FALSE'
										END,
						 CriminalCourtReqOdy = Case WHEN CriminalCourtReq = 'N' OR CriminalCourtReq IS NULL THEN 'FALSE'
												  ELSE 'TRUE'
										END,
						  ZipCodeOdy = SUBSTRING(ZipCode,1,5)
			  WHERE FileLogId = @FileLogId 
			  
			  /****** Ivalid or all zeros zip code ******/
		       UPDATE OdyClerkInternal..TrafficCitation_Import
		       SET ExceptionReason = CASE WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Invalid Zip Code') AND ZipCodeOdy = '00000'
		                                      THEN 'Invalid Zip Code' 
		                                  WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Invalid Zip Code%' AND ZipCodeOdy = '00000'
		                                      THEN ExceptionReason + ', Invalid Zip Code'   
		                                  WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Invalid Zip Code%' AND ZipCodeOdy = '00000'
		                                      THEN ExceptionReason                 
		                              END,
		           ExceptionFlag = 2
		       WHERE ExceptionFlag NOT IN (1,-1) AND ZipCodeOdy = '00000' AND FileLogId = @FileLogId
		       
		       -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Invalid Zip Code'
								AND tc.ExceptionReason LIKE '%Invalid Zip Code%'
								AND ExceptionFlag NOT IN (1,-1) AND ZipCodeOdy = '00000'
								AND FileLogId = @FileLogId
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
		       
			 --/*** Jurisdiction Mapping *****/		     
			 UPDATE OdyClerkInternal..TrafficCitation_Import
			 SET jurisdictionNumberOdy = CASE 
								  WHEN JurisdictionNumber = '00' THEN '56'
								  Else JurisdictionNumber
								 End
			 WHERE jurisdictionNumberOdy IS NULL OR jurisdictionNumberOdy = '' AND FileLogId = @FileLogId 
			 
			 UPDATE dbo.TrafficCitation_Import
			 SET JurisdictionCode = uc.Code --, 
				 -- Jurisdiction = mc.Description --<--- comment Jurisdiction to fix UCF Jursdiction issue T.M. 3/4/2016
			 FROM Justice..CodeMapping cm JOIN Justice..ucode uc (NOLOCK) ON CM.CodeMappingKey=UC.CodeID 
										--  JOIN Justice..sMappingCode mc (NOLOCK) ON cm.CodeMapTypeKey = mc.CodeMapTypeKey --<--- comment Jurisdiction to fix UCF Jursdiction issue T.M. 3/4/2016
										  JOIN  OdyClerkInternal..TrafficCitation_Import tc (NOLOCK) ON cm.TextValue = tc.jurisdictionNumberOdy
			 WHERE cm.codemaptypekey='FLJUR'
			 -- add the following two lines to check for obsolete and hidden codes T. Mudawi 9/17/14
			 AND (uc.ObsoleteDate IS NULL OR uc.ObsoleteDate > GETDATE())
			 -- Replaced the line below to fix the Jurisdiction being hidden issue specifically jurisdiction OOET T.M. 4/24/2015 
		     --AND uc.CodeID NOT IN(SELECT codeID FROM justice..xuCodeNode WHERE Hidden !=0 AND NodeID IN(600, 601, 602, 603, 604)) --> commented 7/15/2015, below fix for Hidden Code/CodeId
		     AND uc.CodeID NOT IN(SELECT codeID FROM justice..xuCodeNode WHERE Hidden =1)
		     --AND uc.CodeID IN(SELECT CodeID FROM justice..xuCodeNode WHERE Hidden =0 AND NodeID = tc.NodeID)
			-- AND uc.Description = mc.Description --<--- comment Jurisdiction to fix UCF Jursdiction issue T.M. 3/4/2016
			 AND FileLogId = @FileLogId 
			 ---------------------------------------------------------------------------------------------- up
			 
			 /***** If Jurisdiction Code is Null set it as OC *****/ 
			 UPDATE TrafficCitation_Import
			 SET JurisdictionCode = 'OC',
			     Jurisdiction = 'Orange County'
			 WHERE JurisdictionCode IS NULL AND FileLogId = @FileLogId
			 
			 /*** Fix for OOET Jurisdiction, change it to OC since Traffic team does that when correcting it. T.M. 5-11-2015 ****/
			 UPDATE TrafficCitation_Import
			 SET JurisdictionCode = 'OC',
			     Jurisdiction = 'Orange County'
			 WHERE JurisdictionCode = 'OOET' AND FileLogId = @FileLogId
			 
			 /******* Fix for Jurisdiction 46 issue  T.M. 7/15/2015   *******/
			 Update TrafficCitation_Import
			 Set JurisdictionCode = Case When CityName = 'Orlando' Then 'ORPD'
									Else 'OC'
                       End,
				 Jurisdiction = Case When CityName = 'Orlando' Then 'Orlando'
                            Else 'Orange County'
                       End 
				Where JurisdictionNumber = '46'
				And FileLogId = @FileLogId
		     
			 /******* Configuring the NodeID for all agencies based on Court City Name *******/     
			 UPDATE dbo.TrafficCitation_import
			 SET NodeID = Case WHEN CourtCity = 'APOPKA' or Jurisdiction='APOPKA' THEN '601'
							   WHEN CourtCity = 'OCOEE'  or Jurisdiction='OCOEE'  THEN '602'
							   WHEN CourtCity = 'ORLANDO'     THEN '603'
							   WHEN CourtCity = 'WINTER PARK' THEN '604'
						  END
			 WHERE FileLogId = @FileLogId 
			 
			 -- Configuring NodeId for All Agencies when Court City is Null - T. Mudawi 9/17/2014
			 UPDATE dbo.TrafficCitation_import
			 SET NodeID = av.NodeID
			 FROM OdyClerkInternal..TrafficCitation_import tc, OdyClerkInternal..TrafficCitation_AgencyVendorInfo av
			 WHERE tc.VendorAgencyId = av.VendorAgencyId
			 AND FileLogId = @FileLogId
			 AND tc.NodeID IS NULL
		                  
			 /**** Missing Driver License State ***************/
			  UPDATE TrafficCitation_Import        -- Need to add business exception
			  SET ExceptionReason = CASE 
									   WHEN ExceptionReason IS NULL OR  ExceptionReason = 'Driver license State is missing' 
											THEN 'Driver license State is missing'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Driver license State is missing%' 
									        THEN ExceptionReason+', Driver license State is missing'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Driver license State is missing%' 
									        THEN ExceptionReason
										--ELSE ExceptionReason + ', Driver license State is missing' commented 11/26/14
											 END,
									ExceptionFlag = 1    -- Fix the Bad State entry issue 8/20/2014
								--WHERE (DriverLicenseState IS NULL OR DriverLicenseState = NULL OR DriverLicenseState = '' OR DriverLicenseState NOT IN(Select Code FROM Justice..uCode WHERE CacheTableID = 456)) 
								--  AND (StateofDriversAddress IS NULL OR StateofDriversAddress = NULL OR StateofDriversAddress ='' OR StateofDriversAddress NOT IN(Select Code FROM Justice..uCode WHERE CacheTableID = 456))
								--  AND FileLogId = @FileLogId 
							    WHERE DriverLicenseState NOT IN(Select Code FROM Justice..uCode WHERE CacheTableID = 456) 
								 AND  StateofDriversAddress NOT IN(Select Code FROM Justice..uCode WHERE CacheTableID = 456)  
								 AND FileLogId=@FileLogId
								 AND Processed = 0
								 
			-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Driver license State is missing'
								AND tc.ExceptionReason LIKE '%Driver license State is missing%'
								 AND DriverLicenseState NOT IN(Select Code FROM Justice..uCode WHERE CacheTableID = 456) 
								 AND  StateofDriversAddress NOT IN(Select Code FROM Justice..uCode WHERE CacheTableID = 456)  
								 AND FileLogId = @FileLogId
								 AND Processed = 0
								 AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
								 
			UPDATE OdyClerkInternal..TrafficCitation_Import set QueueStatus = 4 --ExceptionFlag=4 
			From OdyClerkInternal..TrafficCitation_Import TI 
			Join Operations..WorkFlowTrans Trans with (Nolock) on TI.WorkFlowItemId=Trans.ItemID 
			Where  Trans.StatusKey='COM'
			AND FileLogId = @FileLogId 
			
		   
			   /**** Capturing Criminal Statutes ***********/
			   UPDATE TrafficCitation_Import
								SET ExceptionReason = 'Criminal Statutes',
									ExceptionFlag = 3,
									CriminalCase = 'Y'
			 FROM TrafficCitation_Import 
			 WHERE dbo.TrafficCitationImport_GetStatuteGroupID(Statute) = '5' 
			 AND FileLogId = @FileLogId
			 AND Processed = 0
			 
			 -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Criminal Statutes'
								AND tc.ExceptionReason LIKE '%Criminal Statutes%'
								AND dbo.TrafficCitationImport_GetStatuteGroupID(Statute) = '5'
								AND FileLogId = @FileLogId
								AND Processed = 0
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
			   	   
		   ---
			 /**** Populating the Case Type *******/ 
			   UPDATE dbo.TrafficCitation_Import
					SET CaseType = CASE WHEN SUBSTRING(uc.Description,1,3) IN('TR-','TR ') THEN 'TINF'
									WHEN SUBSTRING(uc.Description,1,3) IN('CT-','CT ') THEN 'CTT'
									ELSE ''
							   END
				FROM Justice..uCode uc JOIN Justice..uOff uo (NOLOCK) ON uc.CodeID = uo.OffenseID
											 JOIN Justice..CodeMapping cm with (nolock) on cm.CodeMappingKey=uc.CodeId
											 JOIN TrafficCitation_Import tc (NOLOCK) ON uo.Statute = tc.Statute 
				WHERE (uc.ObsoleteDate IS NULL OR uc.ObsoleteDate > GETDATE())
				AND cm.TextValue = tc.ViolationCode 
				AND CodeMapTypeKey IN('FLDVC')
				AND cm.CacheTableID =85
				AND uc.CodeID NOT IN(SELECT codeID FROM justice..xuCodeNode WHERE Hidden !=0 AND NodeID IN(600, 601, 602, 603, 604))
				--AND uc.CodeID IN(SELECT CodeID FROM justice..xuCodeNode WHERE Hidden =0 AND NodeID = tc.NodeID)
				AND SUBSTRING(uc.Description,1,3) IN('TR-', 'CT-', 'TR ', 'CT ')	
				AND tc.Code IS NOT NULL
				AND FileLogId = @FileLogId
				-- Fix issue of one statute mapped to multiple codes TM 9/28/2017
				AND uc.Code = tc.Code  
				
				
				  /******* Determining the Court Mandatory Cases *****************/				
					   UPDATE TrafficCitation_Import
								SET CourtMandatory = Case WHEN SeriousInjury = 'Y' THEN 'Y' 
														  WHEN FatalInjury = 'Y' THEN 'Y' 
														 -- WHEN dbo.TrafficCitationImport_GetStatuteGroupID(Statute) =1 THEN 'Y'
														 -- WHEN dbo.TrafficCitationImport_GetStatuteGroupID(Statute) =2 AND (CAST(ActualSpeed AS INT) - CAST(PostedSpeed AS INT) >= 30) THEN 'Y'
														  WHEN CaseType = 'CTT' THEN 'Y'
														  ELSE 'N'
													  END
		                 WHERE FileLogId = @FileLogId  
		                 
		              UPDATE TrafficCitation_Import
		              SET CourtMandatory = 'Y'
		              FROM TrafficCitation_Import tc JOIN StatuteGroups sg (NOLOCK) ON tc.Statute = sg.Statute
		              WHERE (sg.StatuteGroupID = 1 OR (sg.StatuteGroupID = 2 AND (CAST(ActualSpeed AS INT) - CAST(PostedSpeed AS INT) >= 30)))
		              AND FileLogId = @FileLogId 
				
		    /***** If there is property damage and no amount flag it as a warning ******/
		    UPDATE TrafficCitation_Import
		    SET ExceptionReason = CASE WHEN ExceptionReason IS NULL OR ExceptionReason = 'No Property Damage Amount'
											THEN 'No Property Damage Amount'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%No Property Damage Amount%'
											THEN ExceptionReason + ', No Property Damage Amount'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%No Property Damage Amount%'
											THEN ExceptionReason
		        END,
		    ExceptionFlag = 2
		    WHERE PropertyDamage = 'Y' AND PropertyDamageAmount = 0 AND FileLogId = @FileLogId
		    AND ExceptionFlag NOT IN (1,-1)
		    
		    -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'No Property Damage Amount'
								AND tc.ExceptionReason LIKE '%No Property Damage Amount%'
								 AND PropertyDamage = 'Y' AND PropertyDamageAmount = 0 AND ExceptionFlag NOT IN (1,-1)
								 AND FileLogId = @FileLogId
								 AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
		    
		    /***** If there is a property damage amount but the flage says no we flag it as warning too ******/
		    UPDATE TrafficCitation_Import
		    SET ExceptionReason = CASE WHEN ExceptionReason IS NULL OR ExceptionReason = 'Property Damage Amount but flag is N' AND ExceptionFlag != 1
										THEN 'Property Damage Amount but flag is N'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Property Damage Amount but flag is N%' AND ExceptionFlag != 1
										THEN ExceptionReason + ', Property Damage Amount but flag is N'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Property Damage Amount but flag is N%' AND ExceptionFlag != 1
										THEN ExceptionReason
								END,
				ExceptionFlag = 2
		    WHERE PropertyDamage = 'N' AND PropertyDamageAmount > 0 AND FileLogId = @FileLogId
		    AND ExceptionFlag NOT IN (1,-1)
		    
		    -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								 WHERE tr.ExceptionReason = 'Property Damage Amount but flag is N'
								 AND tc.ExceptionReason LIKE '%Property Damage Amount but flag is N%'
								 AND PropertyDamage = 'N' AND PropertyDamageAmount > 0 AND ExceptionFlag NOT IN (1,-1)
								 AND FileLogId = @FileLogId
								 AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
		    
		    
				
			/***** Missing Code Or Case Type   *****/
				 UPDATE TrafficCitation_Import
								SET ExceptionReason = CASE 
														 WHEN ExceptionReason IS NULL OR ExceptionReason = 'Statute not in Odyssey'
															 THEN 'Statute not in Odyssey' 
														 WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Statute not in Odyssey%' --AND Code IS NULL AND ExceptionFlag = 1 
															 THEN ExceptionReason + ', Statute not in Odyssey'  
														  WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Statute not in Odyssey%' --AND Code IS NULL AND ExceptionFlag = 1 
															 THEN ExceptionReason
														-- WHEN ExceptionReason = 'Statute not in Odyssey' AND Code IS NULL
														    -- THEN 'Statute not in Odyssey' 
														-- ELSE 'Statute not in Odyssey' 
													   END,
									ExceptionFlag = 1  
				 WHERE (Code IS NULL OR Code = '') AND ExceptionFlag != 3 AND 
				 FileLogId = @FileLogId 
				 AND Processed = 0
				 
				 -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								 WHERE tr.ExceptionReason = 'Statute not in Odyssey' 
								 AND tc.ExceptionReason LIKE '%Statute not in Odyssey%' 
								 AND (Code IS NULL OR Code = '') AND ExceptionFlag != 3 
								 AND FileLogId = @FileLogId
								 AND Processed = 0
								 AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
								 
		/****** Warning for specific statues/violation codes combinations per Traffic division instructions ******/
		UPDATE TrafficCitation_Import
		SET ExceptionReason = CASE
									WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Warning - Check Case Financial') AND ExceptionFlag != 1
									    THEN 'Warning - Check Case Financial'	
									WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Warning - Check Case Financial%' AND ExceptionFlag != 1
									    THEN ExceptionReason + ', Warning - Check Case Financial'	
									WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Warning - Check Case Financial%' AND ExceptionFlag != 1
									    THEN ExceptionReason	
							  END,
			ExceptionFlag = 2
		WHERE ((dbo.TrafficCitationImport_GetStatuteGroupID(Statute) = '6' AND ViolationCode =573 AND Statute != '316.074(1)') OR (Statute = '316.074(1)' AND ViolationCode =543))
		  AND ExceptionFlag NOT IN(1,-1) AND FileLogId = @FileLogId 
		
		-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								 WHERE tr.ExceptionReason = 'Warning - Check Case Financial' 
								 AND tc.ExceptionReason LIKE '%Warning - Check Case Financial%'
								 AND ExceptionFlag NOT IN(1,-1) AND FileLogId = @FileLogId 
								 AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
		
		-- Remove Punctuation from Comments fields
		Update TrafficCitation_Import set OtherComments=dbo.fn_RemovePunctuation(OtherComments)
		Where FileLogId=@FileLogId
		
		
		/*** Fix the issue with Height Inches being greater than 11 by flaging the citation as warning  ***/
		UPDATE TrafficCitation_Import
								SET ExceptionReason = CASE 
														 WHEN ExceptionReason IS NULL OR ExceptionReason = 'Check Height Inches'
														      THEN 'Check Height Inches'
														 WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Check Height Inches%'  
														      THEN ExceptionReason + ', Check Height Inches'
														 WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Check Height Inches%'
														      THEN ExceptionReason
													  END,
								    ExceptionFlag = 2
		WHERE HeightInches > '11' AND ExceptionFlag NOT IN(1,-1,3) AND FileLogId = @FileLogId 
		
		INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								 WHERE tr.ExceptionReason = 'Check Height Inches' 
								 AND tc.ExceptionReason LIKE '%Check Height Inches%'
								 AND ExceptionFlag NOT IN(1,-1) AND FileLogId = @FileLogId 
								 AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID) 
		 
		
		 /**** Validating the Vehicle State T.M. 7/21/2015 ********/
							UPDATE TrafficCitation_Import
							SET ExceptionReason = CASE 
									   WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Invalid Vehicle State') 
											   THEN 'Invalid Vehicle State'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Invalid Vehicle State%' AND ExceptionFlag = 2 
											   THEN ExceptionReason + ', Invalid Vehicle State'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Invalid Vehicle State%' AND ExceptionFlag = 2 
											   THEN ExceptionReason
									END,
									ExceptionFlag = 2
							 WHERE (VehicleState IS NULL OR VehicleState NOT IN(SELECT Code from Justice..uCode where CacheTableID = 456 AND Code NOT IN('NA','FF'))) AND ExceptionFlag NOT IN(1, -1) AND FileLogId = @FileLogId
							 
							 -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Invalid Vehicle State'
								AND tc.ExceptionReason LIKE '%Invalid Vehicle State%'
								AND (VehicleState IS NULL OR VehicleState NOT IN(SELECT Code from Justice..uCode where CacheTableID = 456 AND Code in('NA','FF'))) AND ExceptionFlag NOT IN(1, -1)
								AND FileLogId = @FileLogId 
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
								
		/*********** Flagging invalid city as a warning **************/
			      UPDATE TrafficCitation_Import
							SET ExceptionReason = CASE 
									   WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Invalid City Name') 
											   THEN 'Invalid City Name'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Invalid City Name%' AND ExceptionFlag = 2 
											   THEN ExceptionReason + ', Invalid City Name'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Invalid City Name%' AND ExceptionFlag = 2 
											   THEN ExceptionReason
									END,
									ExceptionFlag = 2
							 WHERE City LIKE '%[0-9]%'  AND ExceptionFlag NOT IN(1, -1) AND FileLogId = @FileLogId
							 
					  -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Invalid City Name'
								AND tc.ExceptionReason LIKE '%Invalid City Name%'
								AND City NOT LIKE '%[0-9]%'  AND ExceptionFlag NOT IN(1, -1)
								AND FileLogId = @FileLogId 
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)

		/******************* If Court City is missing for FHP or OCSO then fail the citation  *********************/
				UPDATE TrafficCitation_Import
							SET ExceptionReason = CASE 
									   WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Missing Court City') 
											   THEN 'Missing Court City'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Missing Court City%' 
											   THEN ExceptionReason + ', Missing Court City'
									   WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Missing Court City%'
											   THEN ExceptionReason
									  END,
						    ExceptionFlag = 1
				 Where (IssueAgencyNameOdy LIKE 'FHP%' OR IssueAgencyNameOdy = 'OCSO')
				 AND CourtCity IS NULL
				 AND FileLogId = @FileLogId
				 AND Processed = 0

				 -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Missing Court City'
								AND tc.ExceptionReason LIKE '%Missing Court City%'
								AND (IssueAgencyNameOdy LIKE 'FHP%' OR IssueAgencyNameOdy = 'OCSO')
								AND CourtCity IS NULL
								AND FileLogId = @FileLogId 
								AND Processed = 0
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)	
								
			 /**** Invalid Driver License ***************/      
			 -- if the DL exceeds 20 characters we need to fail it since the API will fail it anyway  T.M. 7/13/2016                
								UPDATE TrafficCitation_Import
								SET ExceptionReason = CASE 
														  WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Driver license exceeds maximum length')
															   THEN 'Driver license exceeds maximum length'
														  WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Driver license exceeds maximum length%'
															   THEN ExceptionReason + ', Driver license exceeds maximum length'
														  WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Driver license exceeds maximum length%'
															   THEN ExceptionReason
														  ELSE 'Driver license exceeds maximum length'
													  END,
									ExceptionFlag = 1
																																				
								WHERE (Len(Ltrim(Rtrim(DriverLicenseNumber)))>20)	
								-- AND (Business != 'Y' OR Business IS NULL)
								AND FileLogId = @FileLogId 
								AND Processed = 0
								-- AND ExceptionFlag NOT IN (1,-1)
								
								
								-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Driver license exceeds maximum length'
								AND tc.ExceptionReason LIKE '%Driver license exceeds maximum length%'
								AND (Len(Ltrim(Rtrim(DriverLicenseNumber)))<10 )
								--AND (Business != 'Y' OR Business IS NULL) 
								AND FileLogId = @FileLogId
								AND Processed = 0
								-- AND ExceptionFlag NOT IN (1,-1)
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)
			
			/**** Invalid zip Code, zip code contains letters  *****/
			   UPDATE OdyClerkInternal..TrafficCitation_Import
		       SET ExceptionReason = CASE WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Bad Zip Code')
		                                      THEN 'Bad Zip Code' 
		                                  WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Bad Zip Code%'
		                                      THEN ExceptionReason + ', Bad Zip Code'   
		                                  WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Bad Zip Code%'
		                                      THEN ExceptionReason                 
		                              END,
		           ExceptionFlag = 1
		       WHERE ZipCodeOdy LIKE '%[^0-9]%' 
			   AND FileLogId = @FileLogId
			   AND Processed = 0
			   
			    -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Bad Zip Code'
								AND tc.ExceptionReason LIKE '%Bad Zip Code%'
								AND ZipCodeOdy LIKE '%[^0-9]%'
								AND FileLogId = @FileLogId
								AND Processed = 0
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)	
								
			/***** Invalid or missing driver address state  ******/
			   UPDATE OdyClerkInternal..TrafficCitation_Import
		       SET ExceptionReason = CASE WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Invalid or missing driver address state')
		                                      THEN 'Invalid or missing driver address state' 
		                                  WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Invalid or missing driver address state%'
		                                      THEN ExceptionReason + ', Invalid or missing driver address state'   
		                                  WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Invalid or missing driver address state%'
		                                      THEN ExceptionReason                 
		                              END,
		           ExceptionFlag = 1
		       WHERE StateofDriversAddress IS NULL 
			   AND FileLogId = @FileLogId
			   AND Processed = 0
			   
			    -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Invalid or missing driver address state'
								AND tc.ExceptionReason LIKE '%Invalid or missing driver address state%'
								AND StateofDriversAddress IS NULL
								AND FileLogId = @FileLogId
								AND Processed = 0
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)	
			
			/***** Invalid vehicle tag expiration year  *****/  											  
			 UPDATE OdyClerkInternal..TrafficCitation_Import
		       SET ExceptionReason = CASE WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Invalid vehicle tag expiration year')
		                                      THEN 'Invalid vehicle tag expiration year' 
		                                  WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Invalid vehicle tag expiration year%'
		                                      THEN ExceptionReason + ', Invalid vehicle tag expiration year'   
		                                  WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Invalid vehicle tag expiration year%'
		                                      THEN ExceptionReason                 
		                              END,
		           ExceptionFlag = 1
		       WHERE VehicleTagExpYear = '9999' 
			   AND FileLogId = @FileLogId
			   AND Processed = 0
			   
			    -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Invalid vehicle tag expiration year'
								AND tc.ExceptionReason LIKE '%Invalid vehicle tag expiration year%'
								AND VehicleTagExpYear = '9999'
								AND FileLogId = @FileLogId
								AND Processed = 0
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)


			/****** Fix issue with statute 316.1925(1) to always point to 316.1925(1) instead of sometimes to 316.1923 per Jaclyn request  T.M. 8/12/2016   ******/
			Update OdyClerkInternal..TrafficCitation_Import
			Set Code = '316.1925(1)',
			    StatuteCodeID = '18459'
			Where Statute = '316.1925(1)' 
			And Code = '316.1923'
			And StatuteCodeID = '24183'
			And FileLogId = @FileLogId


			/***** If FHP + TrooperUnit doesn't match the agency code in uCode table fail the citation T.M. 8/23/2016  ******/
			UPDATE OdyClerkInternal..TrafficCitation_Import
		       SET ExceptionReason = CASE WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Invalid agency code')
		                                      THEN 'Invalid agency code' 
		                                  WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Invalid agency code%'
		                                      THEN ExceptionReason + ', Invalid agency code'   
		                                  WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Invalid agency code%'
		                                      THEN ExceptionReason                 
		                              END,
		           ExceptionFlag = 1
		       WHERE IssueAgencyNameOdy NOT IN(SELECT Code FROM Justice..uCode WHERE CacheTableID = 61 AND (ObsoleteDate IS NULL OR ObsoleteDate > GETDATE())) OR IssueAgencyNameOdy IS NULL 
			   AND FileLogId = @FileLogId
			   AND Processed = 0

							-- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Invalid agency code'
								AND tc.ExceptionReason LIKE '%Invalid agency code%'
								AND (IssueAgencyNameOdy NOT IN(SELECT Code FROM Justice..uCode WHERE CacheTableID = 61 AND (ObsoleteDate IS NULL OR ObsoleteDate > GETDATE())) OR IssueAgencyNameOdy IS NULL)
								AND FileLogId = @FileLogId
								AND Processed = 0
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)


			/***** If TrooperUnit for FHP is any value othen than 'D', 'K', 'J', 'H' or 'O' then flag it as a warning for review T.M. 9/26/2016  ******/
			-- included troopers 'I', 'C', 'L', 'Q' TM 5/29/2019
			UPDATE OdyClerkInternal..TrafficCitation_Import
		       SET ExceptionReason = CASE WHEN (ExceptionReason IS NULL OR ExceptionReason = 'Review Troop Information')
		                                      THEN 'Review Troop Information' 
		                                  WHEN ExceptionReason IS NOT NULL AND ExceptionReason NOT LIKE '%Review Troop Information%'
		                                      THEN ExceptionReason + ', Review Troop Information'   
		                                  WHEN ExceptionReason IS NOT NULL AND ExceptionReason LIKE '%Review Troop Information%'
		                                      THEN ExceptionReason                 
		                              END,
		           ExceptionFlag = 2
		       -- WHERE TrooperUnitOdy NOT IN('D', 'K', 'J', 'O', 'H') 
			   -- included troops  'I', 'C', 'L', 'Q' TM 5/29/2019
		       WHERE TrooperUnitOdy NOT IN('D', 'K', 'J', 'O', 'H',  'I', 'C', 'L', 'Q', 'F') 		  
			   AND VendorAgencyId = 15
			   AND ExceptionFlag NOT IN(1,-1)
			   AND FileLogId = @FileLogId
		   
			   -- Insert into the TrafficCitation_ExceptionReasons 
								INSERT INTO dbo.TrafficCitation_CitationExceptions
								SELECT tc.CitationNumber, tr.ExceptionReasonID
								FROM TrafficCitation_Import tc, TrafficCitation_ExceptionReasons tr
								WHERE tr.ExceptionReason = 'Review Troop Information'
								AND tc.ExceptionReason LIKE '%Review Troop Information%'
								-- AND TrooperUnitOdy NOT IN('D', 'K', 'J', 'O', 'H')
								-- included troops  'I', 'C', 'L', 'Q' TM 5/29/2019
								AND TrooperUnitOdy NOT IN('D', 'K', 'J', 'O', 'H',  'I', 'C', 'L', 'Q', 'F')								 
								AND VendorAgencyId = 15
								AND ExceptionFlag NOT IN(1,-1)
								AND FileLogId = @FileLogId
								AND tc.CitationNumber NOT IN(SELECT CitationNumber FROM dbo.TrafficCitation_CitationExceptions WHERE ExceptionReasonID = tr.ExceptionReasonID)


		-- Per SR86090 and request from Traffic citation import should select code 316.172(1)(A)-A instead of 316.172(1)(A)-C when encountering statute 316.172(1)(A) 
		-- if the citation does not have the injury to another, serious bodily injury to another or fatal injury.
		-- T.M. 1/15/2020
			Update OdyClerkInternal..TrafficCitation_Import
			Set Code = '316.172(1)(A)-A'
			Where Statute = '316.172(1)(A)'
			And InjuryOdy = 'False'
			And FatalInjuryOdy = 'False' 
			And SeriousInjuryOdy = 'False'
			And FileLogId = @FileLogId

																
		-- Updating Statute Code for 18% T.M. 12/16/2019
		-- Comment 18 Percent for now until codes are entered into DEV, TEST and PROD T.M. 1/16/2020 
		-- Need to move corresponding table and stored procedure too 
		Execute OdyClerkInternal.dbo.TrafficCitationImport_Update18PercentStatuteCode @FileLogId											 			
		
SET NOCOUNT OFF		

END



