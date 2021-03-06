USE [OdyClerkInternal]
GO
/****** Object:  StoredProcedure [dbo].[TrafficCitationImport_ProcessCitations]    Script Date: 8/11/2020 11:24:24 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =====================================================================================================
-- Author:		Tarig Mudawi
-- Create date: 10/15/2013
-- Description:	This Stored Procedure execute each record from the Traffic Citation file
--              and calls functions to build and execute the API transaction.
--				This runs after we already flag all exceptions.
-- Updated:     9/8/2014 Added code fix Expiration date, DL Class and fix party match update.
--              Also modified code to update QueueStatus instead of ExceptionFlag.
--				09/11/2014 Anthony Payne - Updated Cursor Where Clause to include Warning Citations
-- Updated      04/24/2015 T. Mudawi - Added a call to TrafficCitationImport_SendFailedToQueue
--              to send only Warnings.
--              Also added fix for connection timeout situation.
-- Updated      5/5/2015 T.M. - Reset the warnings back to their original flag before Api error. 
-- Updated      05/08/2015 T.Mudawi Added a fix to restore warnings to their original Exception flags and Reasons 
--              after Api errors reprocessed.
-- Updated      05/08/2015 Added the AddParty to fix the issues with not matching a single party and the father son issue too.
-- Updated      7/15/2015 T.Mudawi - Get the Agency Type to determine if it is Red light, Toll or Regular.
-- Updated      10/1/2015 T.M. - Adding officer as Law Enforcement Officer to the case party tab.
-- Updated      03/17/2016 T.M. - Make sure the DLNUM is alphanumeric and not letters only like 'NONE'  
-- Updates      03/31/2016 Replace any two consecutive spaces with one space since it cause TCAT errors per Jaya
-- Update       06/01/2016 T.M. Update DL Number to NDL, DL State to FF and DL Type to Unknown for FL businesses red light
-- Update		06/02/2020 T.M. if expiration date is invalid update it to null and set DL Type to Unknown.
-- ================================================================================================================

ALTER PROC [dbo].[TrafficCitationImport_ProcessCitations] @FileLogId int=NULL, @CitationNumber varchar(20)

AS

SET NOCOUNT ON

Declare 
@sUpdateType				VARCHAR(50),
@sCitationNumber			VARCHAR(50),
@sCheckDigit				VARCHAR(50),
@sJurisdictionNumber		VARCHAR(50),
@sCityName					VARCHAR(50),
@sIssueAgencyCode			VARCHAR(50),
@sIssueAgencyName           VARCHAR(200),
@sOffenseDate				VARCHAR(50),
@sOffenseTime				VARCHAR(50),
@sOffenseTimeAmPm   		VARCHAR(50),
@sDriverFirstName			VARCHAR(100),
@sDriverMiddleName			VARCHAR(100),
@sDriverLastName			VARCHAR(100),
@sStreetAddress				VARCHAR(100),
@sCity						VARCHAR(50),
@sStateofDriversAddress		VARCHAR(50),
@sZipCode					VARCHAR(20),
@sBirthDate					VARCHAR(20),
@sRaceOdy					VARCHAR(50),
@sSex						VARCHAR(10),
@sHeight					VARCHAR(50),
@sHeightFeet                VARCHAR(50),
@sHeightInches              VARCHAR(50),
@sDriverLicenseNumber		VARCHAR(50),
@sDriverLicenseState		VARCHAR(50),
@sDriverLicenseClass		VARCHAR(50),
@sViolationExpiredDL        VARCHAR(50),
@sCommercialVehicleCode     VARCHAR(50),
@sVehicleYear				VARCHAR(50),
@sVehicleMake				VARCHAR(50),
@sVehicleMakeCode           VARCHAR(50),
@sVehicleStyle				VARCHAR(50),
@sVehiclyColor				VARCHAR(50),
@sVehiclyColorCode   		VARCHAR(50),
@sHazardousMaterials		VARCHAR(50),
@sVehicleTagNumber			VARCHAR(50),
@sVehicleTrailerNumber      VARCHAR(50),
@sVehicleState				VARCHAR(50),
@sVehicleTagExpYear			VARCHAR(50),
@sDistanceFeet              VARCHAR(50),
@sDistanceMiles             VARCHAR(50),
@sOtherComments				VARCHAR(500),
@sViolationCode				VARCHAR(50),
@sFLDLEditOverride			VARCHAR(50),
@sSection					VARCHAR(50),
@sSubSection				VARCHAR(50),
@sCrash						VARCHAR(50),  -- Accident
@sPropertyDamage			VARCHAR(50), --property
@sPropertyDamageAmount		VARCHAR(50), -- Amount
@sInjury					VARCHAR(50),  -- Injury to other
@sSeriousInjury				VARCHAR(50),
@sFatalInjury				VARCHAR(50),
@sCriminalCourtReq          VARCHAR(50),
@sInfractionNoCourtReq      VARCHAR(50),
@sOfficerFullName           VARCHAR(50),
@sOfficerName               VARCHAR(100),
@sOfficerBadgeNumber		VARCHAR(50),
@sOfficerIdOdy					VARCHAR(50),
@sOfficerCode               VARCHAR(50),  -- This is the PartyID from Officer Table
@sOfficerPartyID            VARCHAR(50),

@sStatus					VARCHAR(50),
@sAggressiveDriverFlag		VARCHAR(50),
@sCommercialDL				VARCHAR(50),
@sExceptionReason			VARCHAR(MAX),
@nFileLogID					INT,
@nExceptionFlag				BIT,
@nCount						INT,
@sJurisdiction              VARCHAR(100),
@sDegree                    VARCHAR(50),
@sStatute                   VARCHAR(50),
@sStatuteCode               VARCHAR(50),
@sStatuteCodeID             VARCHAR(50),
@sPartyID                   INT,
@sNameIDCurrent             INT,
@sPartyIDFound              CHAR(1),
@sCaseType                  VARCHAR(50),
@sActualSpeed               VARCHAR(20),
@sPostedSpeed               VARCHAR(20),
@sJurisdictionCode           VARCHAR(50),
@sOffenseFineProgramID      VARCHAR(10),
@sHasOffenseFineProgramID   CHAR(1),
@sNodeID                    VARCHAR(20),
@sCaseID                    VARCHAR(50),
@sCaseNumber                VARCHAR(50),
@MessageUserId              VARCHAR(20),
@sDocumentID                VARCHAR(50),
@sDocVersionID              VARCHAR(50),
@sImageFolder               VARCHAR(100),                      
@sEventID                   VARCHAR(50),
@sValidResponse             CHAR(1),
@sVendorAgencyID            VARCHAR(10),
@sAppearByDate              VARCHAR(30),
@dtAppearByDate             DateTime,
@sDLLookupExpireDate        VARCHAR(50),
@sDLLookupDLClass           INT,
@sDlTypeID                  VARCHAR(50),
@MotorCycle				    varchar(50),
@AddressDiffLicense         VARCHAR(50), 
@ImageFound                 INT,   
@ExceptionFlag              VARCHAR(10),
@ExceptionReason			VARCHAR(100),
@CitationType				VARCHAR(50),
@IssueArrestDate			VARCHAR(50),
@DueDate			        VARCHAR(50),  -- Added due date  for CFX Toll T.M. 3/16/2017
@ValidDLExpirationDate      INT,
@IsRedLightOrTOLL           VARCHAR(10),
@OfficerNameID				INT,	
@CasePartyID                INT,	
@CasePartyConnID			INT,	  


@xMatchUpdateXMLRequest		XML,
@xMatchUpdateXMLResponse	XML,

@xAddCriminalCaseXMLRequest		XML,
@xAddCriminalCaseXMLResponse	XML,

@xAddCitationToCriminalCaseRequest XML,
@xAddCitationToCriminalCaseResponse XML,

@xAddDocumentRequest        XML,
@xAddDocumentResponse       XML, 
@sApiAddDocRequest          NVARCHAR(MAX),
@sApiAddDocResponse         VARCHAR(MAX),

@xLinkDocumentRequest        XML,
@xLinkDocumentResponse       XML,
@sApiLinkDocRequest          NVARCHAR(MAX),
@sApiAddLinkResponse         VARCHAR(MAX),         

@xOdyApi_TransactionRequest XML,
@xOdyApi_TransactionResponse XML,

@sApiRequest                NVARCHAR(MAX),
@sApiResponse               VARCHAR(MAX),
@sCurrDate                  DateTime,
@sFileDate					VARCHAR(20),
@sCitationImage             VARCHAR(100),
@sDisplayMessage            VARCHAR(MAX),
@sAddressID                 INT,

@xAddPartyRequest			XML,
@xAddPartyResponse			XML,
@sAddPartyRequest           VARCHAR(MAX),
@sAddPartyResponse          VARCHAR(MAX),

@xAddUnpaidTollFeeRequest  XML,
@sAddUnpaidTollFeeRequest  VARCHAR(MAX),
@xAddUnpaidTollFeeResponse XML,
@sAddUnpaidTollFeeResponse VARCHAR(MAX),

@sScheduleCode			   VARCHAR(50),
@sFeeCode                  VARCHAR(50),
@sAmount                   VARCHAR(50),

@IsBusiness				   VARCHAR(5),

@Fnresponse   int,

@SPName						VARCHAR(50)

INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'Entering SP')

SELECT @sPartyIDFound = 'N', @sHasOffenseFineProgramID = 'N'

SET @IsRedLightOrTOLL = 'N'

SET @MessageUserId = (Select userid from operations..appuser with(nolock) where loginname='CitationImport')

	
	SELECT @ImageFound = 0 

  
SELECT @sUpdateType = [UpdateType]
      ,@sCitationNumber = [CitationNumber]
      ,@sCheckDigit = [CheckDigit]
      ,@sJurisdictionNumber = [JurisdictionNumber]
      ,@sCityName = [CityName]
      ,@sIssueAgencyCode = [IssueAgencyCode]  -- Agency
      ,@sIssueAgencyName = [IssueAgencyNameOdy]
      ,@sOffenseDate = [OffenseDate]
      ,@sOffenseTime = [OffenseTime]
      ,@sOffenseTimeAmPm = [OffenseTimeAmPm]
      ,@IssueArrestDate = [IssueArrestDate]
	  --,@sDriverFirstName = REPLACE(REPLACE(REPLACE([DriverFirstName],'-',' '),'''',''),'  ',' ')      -- Replace any two consecutive spaces with one space since it cause TCAT errors per Jaya  T.M. 3/31/2016
	  ,@sDriverFirstName = REPLACE([DriverFirstName],'-',NULL)
      ,@sDriverMiddleName = REPLACE([DriverMiddleName],'',NULL) --REPLACE(REPLACE(REPLACE([DriverMiddleName],'-',''),'''',''),'  ','') 
	 -- ,@sDriverMiddleName = REPLACE(REPLACE(REPLACE([DriverMiddleName],'-',''),'''',''),'  ','')
      ,@sDriverLastName = REPLACE(REPLACE(REPLACE([DriverLastName],'-',' '),'''',''),'  ',' ') 
      ,@sStreetAddress = [StreetAddress]
      ,@sCity = [City]
      ,@sStateofDriversAddress = [StateofDriversAddress]
      ,@sZipCode = [ZipCodeOdy]
      ,@sBirthDate = [BirthDate]
      ,@sRaceOdy = [RaceOdy]
	  --,@sRaceOdy = REPLACE([RaceOdy],'',NULL)
      ,@sSex = [Sex]  -- Gender
      ,@sHeightFeet = [HeightFeet]
      ,@sHeightInches = [HeightInches]
      ,@sDriverLicenseNumber = [DriverLicenseNumber]
      ,@sDriverLicenseState = [DriverLicenseState]
      ,@sDriverLicenseClass = [DriverLicenseClass]
      ,@sViolationExpiredDL = [ViolationExpiredDLOdy]
      ,@sCommercialVehicleCode = [CommercialVehicleCodeOdy]
      ,@sVehicleYear = [VehicleYear]
      ,@sVehicleMakeCode = [VehicleMakeCode]
      ,@sVehicleStyle = [VehicleStyle]
      ,@sVehiclyColorCode = [VehicleColorCode]
      ,@sHazardousMaterials = [HazardousMaterialsOdy]
      ,@sVehicleTagNumber = [VehicleTagNumber]
      ,@sVehicleState = [VehicleState]
      ,@sVehicleTagExpYear = [VehicleTagExpYear]
      ,@sDistanceFeet = [DistanceFeet]
      ,@sDistanceMiles = [DistanceMiles]
      ,@sOtherComments = REPLACE([OtherComments], '',NULL)
      ,@sViolationCode = [ViolationCode]
      ,@sFLDLEditOverride = [FLDLEditOverride]
      ,@sSection = [Section]
      ,@sSubSection = ISNULL([SubSection],'')
      ,@sCrash = [Crash]  -- Accident
      ,@sPropertyDamage = [PropertyDamage] --property
      ,@sPropertyDamageAmount = [PropertyDamageAmount] -- Amount
      ,@sInjury = [InjuryOdy]  -- Injury to other
      ,@sSeriousInjury = [SeriousInjuryOdy]
      ,@sFatalInjury = [FatalInjuryOdy]
      ,@sCriminalCourtReq = [CriminalCourtReqOdy]
      ,@sInfractionNoCourtReq = [InfractionNoCourtReq]
      ,@sOfficerFullName = [OfficerFullName]
      ,@sOfficerIdOdy = [OfficerIdOdy]
      ,@sOfficerCode = [OfficerPartyID]
      ,@sStatus = [Status]
      ,@sAggressiveDriverFlag = [AggressiveDriverFlagOdy]
      ,@sCommercialDL = [CommercialDL]
      ,@sStatute = [Statute]
      ,@sActualSpeed = [ActualSpeed]
      ,@sPostedSpeed = [PostedSpeed]
      ,@sJurisdictionCode = [JurisdictionCode]
      ,@sDegree = [Degree]
      ,@sStatuteCode = [Code]
      ,@sStatuteCodeID = [StatuteCodeID]
      ,@sCaseType = [CaseType]
      ,@sNodeID = [NodeID]
      ,@sVendorAgencyID = [VendorAgencyID]
      ,@sVehicleTrailerNumber = [VehicleTrailerNumber]
      ,@MotorCycle = MotorCycle
      ,@AddressDiffLicense = AddressDiffLicense
      ,@ExceptionFlag = ExceptionFlag
      ,@ExceptionReason = ExceptionReason
	  ,@sAmount = FileAmount --<--- Added for unpaid toll amount T.M. 3/7/2017
	  ,@DueDate = DueDate    --<--- Added for toll T.M. 3/16/2017
	  ,@IsBusiness = Business
  FROM [OdyClerkInternal].[dbo].[TrafficCitation_Import] with(nolock)
  WHERE  CaseId IS NULL 
	and ExceptionFlag in (0,2,-1,-2)
    and (FileLogID = @FileLogId  or Has_Image=1 ) -- This is to capture all API errors
    and (WorkFlowItemId IS NULL OR ExceptionFlag=2)
    and Processed=0 
    and CitationNumber NOT IN(SELECT CitationNumberSearch FROM Justice..Citation with(Nolock))
    and Has_Image = 1
	and CitationNumber = @CitationNumber

	INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
	VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'After selecting values')

			--WAITFOR DELAY '00:00:03'

			
			 SELECT @sPropertyDamageAmount = @sPropertyDamageAmount + '.00'
			 
			/***** If Height inches is greater than 11 then capture the first digit only and set to warning(in Exception stored procedure).  *****/
			  IF(@sHeightInches > 11)
			      SELECT @sHeightInches = SUBSTRING(@sHeightInches,1,1)
			      
			
			/***** Getting the Image Folder   ******/
			-- Get the Agency Type to determine if it is Red light, Toll or Regular  7/15/2015
			  SELECT @sImageFolder = LocalPath+'\Processed\',
			         @CitationType= CitationType
			  FROM dbo.TrafficCitation_AgencyVendorInfo with(nolock)
			  WHERE VendorAgencyID = @sVendorAgencyID

			  INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			  VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'After getting image folder')



			 -- print 'image folder: ' + @sImageFolder + ' Citation Number: ' + @sCitationNumber

			/****** Adding the IsRedLight Flag T.M. 8/17/2015 ******/
			IF(@CitationType in ('REDLIGHT','TOLL'))
			Begin
			      Select @IsRedLightOrTOLL = 'Y'
			End

			/****** For Toll use DueDate for TicketDate instead of IssueArrestDate T.M. 3/16/2017  ******/
			IF(@CitationType = 'TOLL')
			Begin
			      Select @IssueArrestDate = @DueDate
			End
			
			INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'Before inserting citation into TrafficCitation_ApiMessageLog')
						
			/***** Insert CitationNumber into TrafficCitation_ApiMessageLog Table *****/
			IF NOT EXISTS(SELECT CitationNumber FROM dbo.TrafficCitation_ApiMessageLog with(nolock) WHERE CitationNumber = @sCitationNumber)
              INSERT INTO dbo.TrafficCitation_ApiMessageLog(CitationNumber)VALUES(ISNULL(@sCitationNumber, 'NULL'))

			INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'After inserting citation into TrafficCitation_ApiMessageLog')
			
			-- If the vehicle tag expire date is not a date make null and deal with it later
			IF(ISDATE(@sVehicleTagExpYear) = 0)
			    SELECT @sVehicleTagExpYear = NULL
		    
		    -- Clear the Variable
		    SELECT @sDLLookupExpireDate = ''
			/*** If License Expiration Date is more current in DLLookup then use it otherwise use the one in the file *****/
			-- Code to deal with Red Light DL expiry date (coming 0000 in the file) T.M. 7/23/2015
			SELECT @ValidDLExpirationDate = 1
			IF(@CitationType in ('RedLight', 'Toll'))
			Begin
			    IF(Exists(SELECT 1 FROM Justice..DLLookup with(nolock) WHERE DLNumber = @sDriverLicenseNumber AND DLExpiration IS NOT NULL /*ISDATE(DLExpiration) = 1*/))
			    Begin
					SELECT @ValidDLExpirationDate = 1
					SELECT @sViolationExpiredDL = cast(month(DLExpiration) as varchar(10))+'/'+ cast(day(DLExpiration) as varchar(10))+'/'+ cast(year(DLExpiration) as varchar(10)) FROM Justice..DLLookup with(nolock)				
					WHERE DLNumber = @sDriverLicenseNumber
			    End
			    ELSE
			       SELECT @ValidDLExpirationDate = 0
			       -- SELECT @sViolationExpiredDL = '01/01/1900'   --<-- No need for this
			End
			ELSE
			BEGIN
			IF @sDriverLicenseNumber IS NOT NULL and LEN(LTRIM(RTRIM(@sDriverLicenseNumber)))>0
				Begin
					--SELECT @sDLLookupExpireDate = DLExpiration FROM Justice..DLLookup
				    SELECT @sDLLookupExpireDate = cast(month(DLExpiration) as varchar(10))+'/'+ cast(day(DLExpiration) as varchar(10))+'/'+ cast(year(DLExpiration) as varchar(10)) FROM Justice..DLLookup				
					WHERE DLNumber = @sDriverLicenseNumber
					-- print '@sDLLookupExpireDate: ' + @sDLLookupExpireDate
					IF ISDATE(CAST(@sDLLookupExpireDate AS Varchar(30)))=0 SET @sDLLookupExpireDate=@sViolationExpiredDL
					  -- print '@sViolationExpiredDL: ' + @sViolationExpiredDL
					/*  Fixed the issue of converting @sViolationExpiredDL from date or time to varchar by checking the value is a valid date first  TM 7/21/2020 */
					IF( ISDATE(CAST(@sViolationExpiredDL AS Varchar(30)))=1 AND (CAST(@sDLLookupExpireDate AS Date) > CAST(@sViolationExpiredDL AS Date)))
						SELECT @sViolationExpiredDL = @sDLLookupExpireDate
						SELECT @ValidDLExpirationDate = 1
				End
			END

			INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'Before validadting Driver License Type (Class)')
					    
			/******* Validadting Driver License Type (Class) *****/
			-- First get the DL Type(Class) from DL Lookup
		    SELECT @sDLLookupDLClass = DLType FROM Justice..DLLookup with(nolock) WHERE DLNumber = @sDriverLicenseNumber
			IF(@sDriverLicenseClass IN(SELECT Code from Justice..uCode with(nolock) where CacheTableID =9 AND Code != 'U'))
			Begin
			  SELECT @sDriverLicenseClass = @sDriverLicenseClass 
			End 
			/**** If DL Class is not U in DL Lookup then use that value ******/
			ELSE IF(@sDriverLicenseClass NOT IN(SELECT Code from Justice..uCode with(nolock) where CacheTableID =9 AND Code != 'U') 
								AND @sDLLookupDLClass IN(SELECT CodeID FROM Justice..uCode with(nolock) WHERE CacheTableID = 9 AND Code != 'U'))
			Begin
			  SELECT @sDriverLicenseClass = Code FROM Justice..uCode with(nolock) WHERE CacheTableID = 9 AND CodeId = @sDLLookupDLClass
			End
			ELSE
			Begin
			    SELECT @sDriverLicenseClass = 'U'  -- Per Jessica's advise
			End
			   
			INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'After validadting Driver License Type (Class)')
		    
			/**** Format Speed ****/
			IF(SUBSTRING(@sActualSpeed,1,1) = '0')
				SELECT @sActualSpeed = Right(@sActualSpeed, 2)
			IF(SUBSTRING(@sPostedSpeed,1,1) = '0')
				SELECT @sPostedSpeed = Right(@sPostedSpeed, 2)
		    
			Set @sOffenseTime=Case When Cast(left(@sOffenseTime,2) AS Int)=0 Then '12:'+Right(@sOffenseTime,2)+' '+Upper(@sOffenseTimeAmPm)+'M' 
									Else @sOffenseTime + ' '+Upper(@sOffenseTimeAmPm)+'M' End	
		            
			  /***** If driver license state is null then use driver address state *****/
			  IF  (@sDriverLicenseState NOT IN(Select Code FROM Justice..uCode with(nolock) WHERE CacheTableID = 456)) 
			  	   SELECT @sDriverLicenseState = @sStateofDriversAddress
				   
		      -- Moved Image Folder code up    
			  
		 
				--WAITFOR DELAY '00:10';

			INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'Before extracting the PartyID and NameIDCurrent')

			 SELECT @sPartyID = '', @sNameIDCurrent = ''
		         
			 /**** Extracting the PartyID and NameIDCurrent and pass them to the API, No match Party Update is necessary here ****/
			  IF EXISTS(SELECT PartyID FROM Justice..DL with (nolock) WHERE DLNum = @sDriverLicenseNumber AND Inactive=0 AND DLNUM LIKE '%[0-9]%')
			  BEGIN 
			        -- If exist a PartyId with a matching driver license number, name and DOB use it   
					
							   SELECT TOP 1 @sPartyID = P.PartyID FROM Justice..DL DL with (nolock)
											Join Justice.dbo.Party P with (nolock) on P.PartyId=DL.PartyId and DL.DLID=P.DLIDCur
											Join Justice.dbo.Name N with (nolock) on P.NameIdCur=N.NameId
											Join Justice.dbo.DOB DOB with (nolock) on P.DobIdCur=Dob.DobId and Dob.DtDob=@sBirthDate
											WHERE DLNum = @sDriverLicenseNumber AND DL.Inactive=0
											AND DLNUM LIKE '%[0-9]%'  --<-- Make sure the DLNUM is alphanumeric and not letters only like 'NONE' T.M. 3/17/2016
											AND Replace(N.NameFirst,' ','')=Replace(@sDriverFirstName,' ','')
											AND Replace(N.NameLast,' ','')=Replace(@sDriverLastName,' ','')
											AND p.GenderKy IS NOT NULL
											AND p.RaceKy IS NOT NULL
												
								-- otherwise if exist a PartyId with only driver license number and DOB use it
								IF (@sPartyID IS NULL or @sPartyID='')
									Begin
										SELECT TOP 1 @sPartyID = P.PartyID FROM Justice..DL DL with (nolock)
											Join Justice.dbo.Party P with (nolock) on P.PartyId=DL.PartyId and DL.DLID=P.DLIDCur
											Join Justice.dbo.DOB DOB with (nolock) on P.DobIdCur=Dob.DobId and Dob.DtDob=@sBirthDate
											WHERE DLNum = @sDriverLicenseNumber AND DL.Inactive=0
											AND DLNUM LIKE '%[0-9]%'  --<-- Make sure the DLNUM is alphanumeric and not letters only like 'NONE' T.M. 3/17/2016
											AND p.GenderKy IS NOT NULL
											AND p.RaceKy IS NOT NULL
									End							
								
								-- Otherwise match on Drivers License and Name 
								IF (@sPartyID IS NULL or @sPartyID='')
									Begin
										SELECT TOP 1 @sPartyID = P.PartyID FROM Justice..DL DL with (nolock)
											Join Justice.dbo.Party P with (nolock) on P.PartyId=DL.PartyId and DL.DLID=P.DLIDCur
											Join Justice.dbo.Name N with (nolock) on P.NameIdCur=N.NameId
											WHERE DLNum = @sDriverLicenseNumber AND DL.Inactive=0
											AND DLNUM LIKE '%[0-9]%'  --<-- Make sure the DLNUM is alphanumeric and not letters only like 'NONE' T.M. 3/17/2016
											AND Replace(N.NameFirst,' ','')=Replace(@sDriverFirstName,' ','')
											AND Replace(N.NameLast,' ','')=Replace(@sDriverLastName,' ','')
											AND p.GenderKy IS NOT NULL
											AND p.RaceKy IS NOT NULL
									End
										
								
								IF @sPartyID>0 
								Begin
									SELECT @sPartyIDFound = 'Y'
									SELECT TOP 1 @sNameIDCurrent= NameIDCur FROM Justice..Party with(nolock) WHERE PartyID = @sPartyID
								End
				
			 END
			 -- Finally match against the name and DOB only
			 ELSE 
			  
					SELECT Top 1 @sPartyID = n.PartyID 
									FROM Justice..Name n JOIN Justice..DOB dob (NOLOCK) ON n.PartyID = dob.PartyID 
														 JOIN Justice..Party p (NOLOCK) ON n.NameID = p.NameIDCur
									WHERE  Replace(n.NameFirst,' ','') = Replace(@sDriverFirstName,' ','')
									AND   Replace(n.NameLast,' ','')= Replace(@sDriverLastName,' ','') 
									AND  dob.DtDOB = @sBirthDate
									AND p.GenderKy IS NOT NULL
									AND p.RaceKy IS NOT NULL
													
				        
					IF @sPartyID>0 
						Begin
							SELECT @sPartyIDFound = 'Y'
							SELECT TOP 1 @sNameIDCurrent= NameIDCur FROM Justice..Party with(nolock) WHERE PartyID = @sPartyID
						End
					ELSE -- Use the AddParty API message to create the party before using the Match party T.m. 5-7-2015
					Begin
					  
						 SELECT @xAddPartyRequest = CAST(dbo.fnOdyApi_AddParty(
						  0,
						  1,
						  @MessageUserId, 
						  ISNULL(@sDriverFirstName,'Business'),
						  @sDriverMiddleName,
						  @sDriverLastName,
						  @sBirthDate,
						  @sSex,
						  @sRaceOdy,
						  @sDriverLicenseState,
						  @sStreetAddress,
						  @sCity,
						  @sStateofDriversAddress,
						  @sZipCode,
						  @AddressDiffLicense,
						  @sCommercialVehicleCode
						  ) AS VARCHAR(8000)) 
						  
						  SELECT @sAddPartyRequest = CAST(@xAddPartyRequest AS VARCHAR(MAX))
		    
						  SELECT @xAddPartyResponse = CAST(dbo.fnOdyApiCall(@sAddPartyRequest, 0) AS XML)
						  
						  SELECT @sPartyID = @xAddPartyResponse.value('(/Result[1]/PartyID[1])','VARCHAR(50)')
						  
					End

			INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'After extracting the PartyID and NameIDCurrent')
			
			 -- Commenetd code after added business name type T.M. 8/17/2015		
			 -- For Red Light make first name equal last name if first name is null (in case of business) T.M. 7/24/2015
			 --IF(@CitationType = 'REDLIGHT' AND @sDriverFirstName IS NULL)
			 --Begin
			 --       SET @sDriverFirstName = @sDriverLastName
			 --End
					
								
			  /***** Check if the Statute has an offense fine program to calculate the fine ******/
			  SELECT @sOffenseFineProgramID = OffenseFineProgramID 
			  FROM Justice..xuOffFinHistNode with(nolock)
			  WHERE OffenseID = @sStatuteCodeID
		      
			  IF(@sOffenseFineProgramID IS NOT NULL OR @sOffenseFineProgramID != '')
				  SELECT @sHasOffenseFineProgramID = 'Y'
			  ELSE
				  SELECT @sHasOffenseFineProgramID = 'N'
		
		INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
		VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'Before constructing the transaction')

		-- print values for fnOdyApi_MatchUpdateParty
					 print '@MessageUserId: ' + @MessageUserId 
					 print '@sDriverFirstName: ' + ISNULL(@sDriverFirstName,'Business')
					 print  '@sDriverMiddleName: ' + ISNULL(@sDriverMiddleName, '')
					 print  '@sDriverLastName: ' + @sDriverLastName
					 print  '@sBirthDate: ' + @sBirthDate
					 print '@sHeightFeet: ' + @sHeightFeet
					 print '@sHeightInches: ' + @sHeightInches
					 print '@sSex: ' + @sSex 
					 print '@sRaceOdy: ' + @sRaceOdy
					 print '@sDriverLicenseNumber: ' + @sDriverLicenseNumber
					 print '@sDriverLicenseState: ' + @sDriverLicenseState
					 print '@sStreetAddress: ' +  @sStreetAddress
					 print '@sCity: ' + @sCity
					 print '@sStateofDriversAddress: ' + @sStateofDriversAddress
					 print '@sZipCode: ' + @sZipCode
					-- print '@sPartyID: ' + @sPartyID
					 print  '@AddressDiffLicense: ' + @AddressDiffLicense
					 print  '@sCommercialVehicleCode: ' + @sCommercialVehicleCode

			-- print values for fnOdyApi_AddCriminalCase
					print '@sNodeID: ' + @sNodeID
				   print '@sCaseType: ' + @sCaseType
				   print '@sOffenseDate: ' + @sOffenseDate
				   print '@sOfficerIdOdy: ' + @sOfficerIdOdy
				   print '@sOffenseTime: ' + @sOffenseTime
				   print '@sOfficerFullName: ' + @sOfficerFullName
				   print '@sIssueAgencyName: ' + @sIssueAgencyName
				   print '@sJurisdictionCode: ' + @sJurisdictionCode
				   print '@sStatuteCodeID: ' + @sStatuteCodeID
				   print '@sStatuteCode: ' + @sStatuteCode
				   print '@sStatute: ' + @sStatute
				   print '@sDegree: ' + @sDegree
				   print '@sActualSpeed: ' + @sActualSpeed
				   print '@sPostedSpeed: ' + @sPostedSpeed
				   print '@sHasOffenseFineProgramID: ' + @sHasOffenseFineProgramID

			-- print values for fnOdyApi_AddCitationToCriminalCaseChargeFLUTC
				   print '@sCitationNumber: ' + @sCitationNumber
				   print '@sCheckDigit: ' + ISNULL(@sCheckDigit,'')
				   print '@sIssueAgencyName: ' + @sIssueAgencyName
				   print '@sCaseType: ' + @sCaseType
				   print '@sOffenseDate: ' + @sOffenseDate
				   print '@sOffenseTime: ' + @sOffenseTime
				   print '@sDriverMiddleName: ' + @sDriverMiddleName
				   print '@sDriverLastName: ' + @sDriverLastName
				   print '@sStreetAddress: ' + @sStreetAddress
				   print '@sCity: ' + @sCity
				   print '@sStateofDriversAddress: ' + @sStateofDriversAddress
				   print '@sZipCode: ' + @sZipCode
				   print '@sBirthDate: ' + @sBirthDate
				   print '@sHeightFeet: ' + @sHeightFeet
				   print '@sHeightInches: ' + @sHeightInches
				   print '@sDriverLicenseNumber: ' + @sDriverLicenseNumber
				   print '@sDriverLicenseState: ' + @sDriverLicenseState
				   print '@sDriverLicenseClass: ' + @sDriverLicenseClass
				   print '@sViolationExpiredDL: ' + @sViolationExpiredDL
				   print '@sVehicleYear: ' + @sVehicleYear
				   print '@sVehicleMakeCode: ' + @sVehicleMakeCode			
				   print '@sVehicleStyle: ' + @sVehicleStyle
				   print '@sVehiclyColorCode: ' + @sVehiclyColorCode
				   print '@sVehicleTagNumber: ' + @sVehicleTagNumber
				   print '@sVehicleState: ' + @sVehicleState
				   print '@sVehicleTagExpYear: ' + @sVehicleTagExpYear
				   print '@sCommercialVehicleCode: ' + @sCommercialVehicleCode
				   print '@sHazardousMaterials: ' + @sHazardousMaterials
				   print '@sJurisdictionCode: ' + @sJurisdictionCode
				   print '@sOfficerCode: ' + @sOfficerCode
				   print '@sAggressiveDriverFlag: ' + @sAggressiveDriverFlag
				   print '@sPropertyDamage: ' + @sPropertyDamage
				   print '@sPropertyDamageAmount: ' + @sPropertyDamageAmount
				   print '@sCrash: ' + @sCrash
				   print '@sInjury: ' + @sInjury
				   print '@sSeriousInjury: ' + @sSeriousInjury
				   print '@sFatalInjury: ' + @sFatalInjury
				   print '@sCriminalCourtReq: ' + @sCriminalCourtReq
				   print '@sDistanceFeet: ' + @sDistanceFeet
				   print '@sDistanceMiles: ' + @sDistanceMiles
				   print '@sOtherComments: ' + @sOtherComments
				   print '@sVehicleTrailerNumber: ' + @sVehicleTrailerNumber
				   print '@AddressDiffLicense:; ' + @AddressDiffLicense
				 --  print '@ValidDLExpirationDate: ' + @ValidDLExpirationDate
				   print '@IssueArrestDate: ' + @IssueArrestDate
				   print '@IsRedLightOrTOLL: ' + @IsRedLightOrTOLL
				   print '@IsBusiness: ' + @IsBusiness

		Begin
		--select @sPartyID PartyId
		
				SELECT @xOdyApi_TransactionRequest = CAST('<Transaction ReferenceNumber="Test" Source="Test" TransactionType="CriminalCaseFiling">
				 <DataPropagation><IntraTxn xPath="/TxnResponse[1]/Result[1]/PartyID[1]" ReplStr="#|PartyID|#" />	
					<IntraTxn xPath="/TxnResponse[1]/Result[1]/CurrentKnownNameID[1]" ReplStr="#|CurrentKnownNameID|#" />
					<IntraTxn xPath="/TxnResponse[1]/Result[2]/CaseID[1]" ReplStr="#|CaseID|#" />
					<IntraTxn xPath="/TxnResponse[1]/Result[2]/NodeID[1]" ReplStr="#|NodeID|#" />
					<IntraTxn xPath="/TxnResponse[1]/Result[2]/Charges[1]/Charge[1]/ChargeID[1]" ReplStr="#|ChargeID|#" />
				  </DataPropagation>' 
				+ 
				CAST(dbo.fnOdyApi_MatchUpdateParty(
					  0,
					  1,
					  @MessageUserId, 
					  ISNULL(@sDriverFirstName,'Business'),
					  @sDriverMiddleName,
					  @sDriverLastName,
					  @sBirthDate,
					  @sHeightFeet,
					  @sHeightInches,
					  @sSex,  
					  @sRaceOdy,
					  @sDriverLicenseNumber,
					  @sDriverLicenseState,
					  @sStreetAddress,
					  @sCity,
					  @sStateofDriversAddress,
					  @sZipCode,
					  @sPartyID,
					  @AddressDiffLicense,
					  @sCommercialVehicleCode
					  ) AS VARCHAR(8000)) 
				+  
				CAST(dbo.fnOdyApi_AddCriminalCase(0,
				   @sNodeID,
				   2,
				   @sCaseType,
				   CAST(GetDate() AS DATE),
				   @MessageUserId,
				   CAST(GetDate() AS DATE),
				   CAST(GetDate() AS DATE),
				   '#|PartyID|#',  
				   '#|CurrentKnownNameID|#', 
				   CAST(GetDate() AS DATE),
				   @sOffenseDate,
				   @sOfficerIdOdy, 
				   @sOffenseTime,
				   @sOfficerFullName,
				   @sIssueAgencyName,
				   @sJurisdictionCode, 
				   @sStatuteCodeID,
				   @sStatuteCode,
				   @sStatute,
				   @sDegree,
				   @sActualSpeed,
				   @sPostedSpeed,
				   @sHasOffenseFineProgramID
				   ) AS VARCHAR(8000)) 
				  + 
				   CAST(dbo.fnOdyApi_AddCitationToCriminalCaseChargeFLUTC(
				   0,
				   @sNodeID, 
				   3,    --@ReferenceNumber,
				   @MessageUserId,  
				   '#|CaseID|#', 
				   '#|ChargeID|#', 
				   @sCitationNumber,
				   ISNULL(@sCheckDigit,''),
				   @sIssueAgencyName,
				   @sCaseType, 
				   @sOffenseDate,
				   @sOffenseTime,
				   ISNULL(@sDriverFirstName,'Business'),
				   @sDriverMiddleName,
				   @sDriverLastName,
				   @sStreetAddress,
				   @sCity,
				   @sStateofDriversAddress,
				   @sZipCode,
				   @sBirthDate,
				   @sHeightFeet,
				   @sHeightInches,
				   @sDriverLicenseNumber,
				   @sDriverLicenseState,
				   @sDriverLicenseClass,
				   --CAST(@sViolationExpiredDL AS Date),
				   @sViolationExpiredDL,
				   @sVehicleYear,
				   @sVehicleMakeCode,
				   -- if vehicle style is blanck make it NULL T.M. 6/22/2020
				   --REPLACE(@sVehicleStyle,'',NULL),				
				   @sVehicleStyle,
				   @sVehiclyColorCode, 
				   @sVehicleTagNumber,
				   @sVehicleState,
				   @sVehicleTagExpYear,
				   @sCommercialVehicleCode,
				   @sHazardousMaterials,
				   @sJurisdictionCode,
				   @sOfficerCode,
				   @sAggressiveDriverFlag,
				   @sPropertyDamage,
				   @sPropertyDamageAmount,
				   @sCrash,
				   @sInjury,
				   @sSeriousInjury,
				   @sFatalInjury,
				   @sCriminalCourtReq,
				   @sDistanceFeet,
				   @sDistanceMiles,
				   CAST(GetDate() AS DATE),
				   @sOtherComments,
				   @sVehicleTrailerNumber,
				   @AddressDiffLicense,
				   @ValidDLExpirationDate,
				   @IssueArrestDate,
				   @IsRedLightOrTOLL,
				   @IsBusiness ) AS VARCHAR(8000))  
				   + 
				   '</Transaction>' AS XML)
		   
		   End
		  
		  INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
		  VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'After constructing the transaction')

		   -- Debug
			   --Select  @xOdyApi_TransactionRequest
		    
			SELECT @sApiRequest = CAST(@xOdyApi_TransactionRequest AS VARCHAR(MAX))
		    
			SELECT @sApiResponse = dbo.fnOdyApiCall(@sApiRequest, 1)
		    
			SELECT @xOdyApi_TransactionResponse = CAST(@sApiResponse AS XML)
		    
			--SELECT @xOdyApi_TransactionResponse
		    
			/**** Log the API Errors or COM errors ****/
						-- Updated the code below to assign any API failure that doesn't have a case Id with -1 Exception Flag T.M. 5/1/2015
					    -- Updating the ApiStatus new column instead of ExceptionReason to preserver the Warnings in case of Api errors T.M. 7/28/2015
			  IF(@sApiResponse NOT LIKE '%<CaseID>%')
			  Begin
			        SELECT @sDisplayMessage = @xOdyApi_TransactionResponse.value('(/ERRORSTREAM[1]/ERROR[1]/DISPLAYMESSAGE[1])','VARCHAR(max)')
			        
			        IF(@ExceptionFlag = 0)
			        Begin
						UPDATE dbo.TrafficCitation_Import
						SET ApiStatus = 1,
							ExceptionFlag = -1 
						WHERE CitationNumber = @sCitationNumber
					End 
					
					
					-- To fix the issue with warnings for financial citations T. M. 5/5/2015
					IF(@ExceptionFlag = 2)
			        Begin
						UPDATE dbo.TrafficCitation_Import
						SET ApiStatus = 1,
							ExceptionFlag = -2
						WHERE CitationNumber = @sCitationNumber
					End 
					   
				End
				
				INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
				VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'Before getting the CaseID & Case Number from the transaction response')				
		    
			/***** Getting the CaseID & Case Number from the transaction response *****/

			   BEGIN
				   SELECT @sPartyID = @xOdyApi_TransactionResponse.value('(/TxnResponse[1]/Result[1]/PartyID[1])','VARCHAR(50)')
				   SELECT @sCaseID = @xOdyApi_TransactionResponse.value('(/TxnResponse[1]/Result[2]/CaseID[1])','VARCHAR(50)')
				   SELECT @sCaseNumber = @xOdyApi_TransactionResponse.value('(/TxnResponse[1]/Result[2]/CaseNumber[1])','VARCHAR(50)')
			   END
			  -- print '@sCaseID :' + @sCaseID
		       
			   INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
				VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'After getting the CaseID & Case Number from the transaction response')

			 /**** Calculating AppearByDate ****/			  
			 IF(@sCaseType = 'TINF' AND @CitationType = 'UTC') 
				 SELECT @dtAppearByDate =  dbo.fnNextBusinessDay(DATEADD(dd, 30, CAST(@sOffenseDate AS Date)))
				  --Added code to calculate the Appear by Date based on Issue Date for Red Light citations  T.M. 7/8/2015
			 ELSE IF(@sCaseType = 'TINF' AND @CitationType = 'REDLIGHT')
			      SELECT @dtAppearByDate =  dbo.fnNextBusinessDay(DATEADD(dd, 30, CAST(@IssueArrestDate AS Date)))
				  --Added code to calculate the Appear by Date based on Issue Date for Toll citations  T.M. 3/7/2017  
			 ELSE IF(@sCaseType = 'TINFRT' AND @CitationType = 'TOLL')
			      SELECT @dtAppearByDate =  dbo.fnNextBusinessDay(DATEADD(dd, 45, CAST(@DueDate AS Date)))    
			 ELSE 
				 SELECT @dtAppearByDate =  dbo.fnNextBusinessDay(DATEADD(dd, 10, CAST(@sOffenseDate AS Date)))
		         
		    
			-- IF @dtAppearByDate IS NOT NULL SELECT @sAppearByDate = CAST(@dtAppearByDate AS VARCHAR(30))
			IF @dtAppearByDate IS NOT NULL SELECT @sAppearByDate = CONVERT(VARCHAR, @dtAppearByDate, 121)
		     
		      
			 -- print 'Citation Type: ' + @CitationType + ' Case Type: ' + @sCaseType + ' Case Number: ' + @sCaseNumber + ' AppearByDate: ' + @sAppearByDate + ' @ValidDLExpirationDate: ' + cast(@ValidDLExpirationDate as varchar(10))

			 INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'Before populating AppearByDate and updating party DL info')

			 /**** Populating the AppearByDate in Odyssey ****/
			 -- First Update the value in the Citation table
			IF(@sCaseID IS NOT NULL)
			Begin
			   Begin Try
				Begin Tran
				UPDATE Justice..Citation
				SET AppearByDate = @sAppearByDate
				WHERE CitationNumber = @sCitationNumber
				AND AppearByDate IS NULL
		     
				-- Next insert a record in xCaseAppearDate table
				IF NOT EXISTS(SELECT CaseID FROM Justice..xCaseAppearDate with(nolock) WHERE CaseID = @sCaseID)
				Begin
					INSERT INTO [Justice].[dbo].[xCaseAppearDate]
					([CaseID]
					 ,[AppearByDate]
					 ,[TimestampCreate]
					 ,[UserIDCreate]
					 ,[ChangeSource]
				   )
					VALUES
					( @sCaseID,
					  @sAppearByDate,
					  GETDATE(),
					  @MessageUserId,
					  'CIT'
					 )
				 End
				 
				 -- Update Party DL Information
				        -- Update the DL Expiration date
						IF(@ValidDLExpirationDate = 1) -- check if expiration date is a valid date before updating T.M. 9/29/2015
						Begin
							UPDATE Justice..DL
							SET DtDlExpire = @sViolationExpiredDL,
								DLTypeID=(select codeid from justice..ucode with(nolock) where code=@sDriverLicenseClass and cachetableid=9),
								UserIDChange=@MessageUserId,
								TimestampChange=GetDate()
							WHERE PartyID = @sPartyId
							and DLNum=@sDriverLicenseNumber
							AND DLNUM LIKE '%[0-9]%'  --<-- Make sure the DLNUM is alphanumeric and not letters only like 'NONE' T.M. 3/17/2016
						End
						ELSE IF(@ValidDLExpirationDate != 1) -- if expiration date is invalid update it to null and set DL Type to Unknown T.M. 6/2/2020
						Begin
							UPDATE Justice..DL
							SET DtDlExpire = Null,
								DLTypeID=(select codeid from justice..ucode where code='U' and cachetableid=9),
								UserIDChange=@MessageUserId,
								TimestampChange=GetDate()
							WHERE PartyID = @sPartyId
							and DLNum=@sDriverLicenseNumber
							AND DLNUM LIKE '%[0-9]%'  --<-- Make sure the DLNUM is alphanumeric and not letters only like 'NONE' T.M. 3/17/2016
						End
						----Update DL Number to NDL, DL State to FF and DL Type to Unknown for FL businesses red light  T.M. 6/1/2016
						-----------------------------------------------------------------------------------------------------------------------------------------
						ELSE
						Begin
								IF(@sCommercialVehicleCode = 'True'  AND (@sDriverFirstName IS NULL OR @sDriverFirstName = 'Business') AND @sVendorAgencyID != 45) 

										 -- Per Jessica and Jaya Businesses with a Florida address should be defaulted to reflect DL#: NDL; DL State: FF; Type: Unknown.
										 IF( (@sDriverLicenseNumber IS NULL OR @sDriverLicenseNumber = '') AND @sDriverLicenseState = 'FL' )
										 Begin

											IF(Exists(Select 1 From Justice..DL with(nolock) Where PartyID = @sPartyId))
											Begin
													UPDATE Justice..DL
													SET DLNum = 'NDL',
														DLStateID = 4182,
														DtDlExpire = NULL,
														DLTypeID=23997,
														UserIDChange=@MessageUserId,
														TimestampChange=GetDate()
													WHERE PartyID = @sPartyId
													AND (DLNUM IS NULL OR DLNUM = '')
											End
											Else
											Begin
												 Insert Into Justice..DL(PartyID, DLNum, DLNumSrch, DLTypeID, DtDlExpire, ST, UserIDCreate, TimestampCreate, UserIDChange, TimestampChange, DLStateID, Inactive)
																  Values(@sPartyId, 'NDL', 'NDL', 23997, NULL, NULL, @MessageUserId, GetDate(), NULL, NULL, 4182, 0)
											End
										 End
								---- For Business Citations we use the Business flag to identify them T.M. 4/19/2017
								ELSE IF(@IsBusiness = 'Y'  AND (@sDriverFirstName IS NULL OR @sDriverFirstName = 'Business') AND @sVendorAgencyID = 45) 
								         IF( (@sDriverLicenseNumber IS NULL OR @sDriverLicenseNumber = '') AND @sDriverLicenseState = 'FL' )
								         Begin

								            IF(Exists(Select 1 From Justice..DL with(nolock) Where PartyID = @sPartyId))
											Begin
													UPDATE Justice..DL
													SET DLNum = 'NDL',
														DLStateID = 4182,
														DtDlExpire = NULL,
														DLTypeID=23997,
														UserIDChange=@MessageUserId,
														TimestampChange=GetDate()
													WHERE PartyID = @sPartyId
													AND (DLNUM IS NULL OR DLNUM = '')
											End
											Else
											Begin
												 Insert Into Justice..DL(PartyID, DLNum, DLNumSrch, DLTypeID, DtDlExpire, ST, UserIDCreate, TimestampCreate, UserIDChange, TimestampChange, DLStateID, Inactive)
																  Values(@sPartyId, 'NDL', 'NDL', 23997, NULL, NULL, @MessageUserId, GetDate(), NULL, NULL, 4182, 0)
											End
										 End 
								--- End of CFX Business Citation code	   	  
						End    
						-----------------------------------------------------------------------------------------------------------------------------------------------
				 --  Update Vehicle Type  
				 IF @MotorCycle='Y'
					BEGIN
				       Update Justice..Citation
					   Set VehicleTypeID=(Select CodeId from justice..ucode with(nolock) where Code='MOT' and CachetableId=167)
					   Where CitationNumber=@sCitationNumber		
				    END

			   Commit Tran
			  End Try
			  Begin Catch
				  Rollback Tran
			  End Catch 

			  INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			  VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'After populating AppearByDate and updating party DL info')
			  	
			  INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			  VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'Before Law Enforcement Officer to the case party')

				/********** Adding officer as Law Enforcement Officer to the case party tab  T.M. 10/1/2015  ***************/
			     Begin Try
				  Begin Tran
				  -- Get the officer current name Id
				  Select @OfficerNameID = NameIDCur From Justice..Party with(nolock) Where PartyID = @sOfficerCode

				  -- print '@sOfficerCode: ' + cast(@sOfficerCode as varchar(20))

				  -- Step 1: Insert into the CaseParty table
				  Insert into Justice..CaseParty
				  Select distinct @sCaseID, @sOfficerCode, NULL, @OfficerNameID, '0', NULL, @MessageUserId, GetDate(), NULL, NULL, NULL, NULL, '0', NULL, NULL, NULL, '0' 
				  Select @CasePartyID=@@IDENTITY
				  
				  -- Get the CasePartyID
				  
				  --Select @CasePartyID = CasePartyID 
				  --From Justice..CaseParty 
				  --Where CaseID = @sCaseID
				  --And CasePartyID Not In(Select CasePartyID From Justice..CasePartyConn)

				   -- Step 2: Insert into CasePartyConn
				   Insert Into Justice..CasePartyConn
				   Select distinct @CasePartyID, 'O1', '3398', @MessageUserId, GetDate(), NULL, NULL, '0', '1'
				   Select @CasePartyConnID=@@IDENTITY

				   -- Step 3: Insert into
				   Insert Into Justice..xCasePartyName (CasePartyID, NameID, NameTypeID) Values (@CasePartyID,@OfficerNameID,NULL)
				   --Select distinct @CasePartyID, @OfficerNameID, NULL 
				   --Where @CasePartyID Not In(Select CasePartyID From Justice..xCasePartyName)

				   -- Step 4: Insert into 

				  -- Select @CasePartyConnID = CasePartyConnID From Justice..CasePartyConn Where CasePartyID = @CasePartyID

				   insert into Justice..CasePartyConnStat (CasePartyConnID,DateAdded) Values (@CasePartyConnID,Getdate())

				   --Select distinct @CasePartyConnID, GetDate()
				   --Where @CasePartyConnID Not In(Select CasePartyConnID From Justice..CasePartyConnStat Where CasePartyConnID IS NOT NULL)
			   Commit Tran
			  End Try
			  Begin Catch
				  Rollback Tran
			  End Catch 

			  INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			  VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'After Law Enforcement Officer to the case party')

			/********* End Law Enforcement Officer code  ***************/
			End
		    
			INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'Before updating TrafficCitation_Import with CaseID and CaseNumber')

			UPDATE dbo.TrafficCitation_Import
			SET CaseID = @sCaseID,
				CaseNumber = @sCaseNumber
			WHERE CitationNumber = @sCitationNumber

			INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'After updating TrafficCitation_Import with CaseID and CaseNumber')
		    
			INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'Before Add Document')

			/**** Only add a document if we have a Case ID, meaning the API call succeeded  *****/
			IF(@sCaseID IS NOT NULL)
			Begin
				SELECT @xAddDocumentRequest = dbo.fnOdyApi_AddDocument
					(0,
					 1, --@ReferenceNumber
					@MessageUserId,
					CAST(GetDate() AS Date), --@EffectiveDate,
					@sNodeID,
					@sCitationNumber,
					@sCaseType,
					@sImageFolder,
					NULL  
					)
			  End
			  
			  --SELECT @xAddDocumentRequest
			  SELECT @sApiAddDocRequest = CAST(@xAddDocumentRequest AS VARCHAR(MAX))
			  SELECT @xAddDocumentResponse = CAST(dbo.fnOdyApiCall(@sApiAddDocRequest, 0) AS XML)
			  
			  --SELECT @xAddDocumentResponse
			  
			  /***** Get the DocumentID ******/ 
			  SELECT @sDocumentID = @xAddDocumentResponse.value('(/Result[1]/DocumentID[1])','VARCHAR(50)')
			  --Print '@sDocumentID: ' + @sDocumentID
			  
			  SELECT @sDocVersionID = @xAddDocumentResponse.value('(/Result[1]/VersionID[1])','VARCHAR(50)')
			  
			  UPDATE dbo.TrafficCitation_Import
				SET DocumentID = @sDocumentID,
					DocumentVersionID = @sDocVersionID
			  WHERE CitationNumber = @sCitationNumber

			INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'After Add Document')
			 
			 INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'Before Link Document') 
			  /***** Link the Document to the Case *****/
		      
			  /**** First get the EventID ******/
			  SELECT @sEventID = evt.EventID FROM Justice..CaseEvent ce with(nolock)
					 JOIN Justice..Event evt ON evt.EventID=ce.EventID
					 JOIN Justice..uCode uc ON uc.CodeID=evt.EventTypeID
					WHERE CaseID=@sCaseID AND uc.Code IN('TINF','TCTV')
						  AND uc.CacheTableID = 59
		                  
			  --print '@sEventID: ' + isnull(@sEventID,'@sEventID is NULL')
		            
			  SELECT @xLinkDocumentRequest = dbo.fnOdyApi_LinkDocument
			 (0,
			  1,  -- @ReferenceNumber
			  @MessageUserId,
			  @sDocumentID,
			  @sEventID  
			  )
			  
			   --SELECT @xLinkDocumentRequest
			  
			  UPDATE dbo.TrafficCitation_Import
				SET EventID = @sEventID
			  WHERE CitationNumber = @sCitationNumber
		    
			  SELECT @sApiLinkDocRequest = CAST(@xLinkDocumentRequest AS VARCHAR(MAX))
			  SELECT @xLinkDocumentResponse = CAST(dbo.fnOdyApiCall(@sApiLinkDocRequest, 0) AS XML)
			  
			   --SELECT @xLinkDocumentRequest, @xLinkDocumentResponse
			   
			  IF @xLinkDocumentResponse.value('(/Result[1]/Success[1])','VARCHAR(50)')='True'
				  Begin					
					-- Reset the warnings back to their original flag before Api error T.M. 5/5/2015
					/****************************************************************************************************************/
					Update OdyClerkInternal..TrafficCitation_Import 
					Set Processed=1,
					    ExceptionFlag = Case When ExceptionFlag = -1 Then 0 
					                         When ExceptionFlag = -2 Then 2
					                         Else ExceptionFlag 
					                    end                         
					 Where CitationNumber=@sCitationNumber
				   End

			  INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			  VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'After Link Document')
				   
				   /************************************************************************************************************************/
			      
			   Update OdyClerkInternal.dbo.TrafficCitation_Import Set LastApiAttempt=GETDATE() Where CitationNumber=@sCitationNumber   
		      
		      
			  -- To Address issue with Missing Height
			   IF(@sCaseID IS NOT NULL)
				Begin
					Update Justice.dbo.Citation set heightfeet=@sHeightFeet, heightinches=@sHeightInches
					where CitationNumber=@sCitationNumber and heightfeet is NULL
				End

			 INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			  VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'Before Toll Request')

			/****************** For Toll Citations only, add unpaid toll amount T.M. 3/6/2017   *******************************************/
              IF(@CitationType = 'TOLL' And @sCaseID IS NOT NULL)
			  Begin

			      Select @sScheduleCode = Code From Financial..uCode with(nolock) where CacheTableID = 37 and Code = 'UNPDTOLLEX'
				  Select @sFeeCode = Code from Financial..uCode with(nolock) where CacheTableID = 33 and Code = 'UNPDTOLLEX'

			      Select @xAddUnpaidTollFeeRequest = dbo.fnOdyApi_AddFinancialChargeCaseFee
				  (
					0,
					@sNodeID,
					@MessageUserId,
					1,
					@sCaseID,
					@sPartyID,
					Convert(Varchar(30),CAST(GetDate() AS DATE), 101),
					@sScheduleCode,
					@sFeeCode,
					@sAmount
				  )

				  SELECT @sAddUnpaidTollFeeRequest = CAST(@xAddUnpaidTollFeeRequest AS VARCHAR(MAX))
			      SELECT @xAddUnpaidTollFeeResponse = CAST(dbo.fnOdyApiCall(@sAddUnpaidTollFeeRequest, 0) AS XML)

				  INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			      VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'After Toll Response')

				  INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			      VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'Before updating or inserting TrafficCitation_ApiMessageLog')

					-- Update TrafficCitation_ApiMessageLog with the fee request and response
					IF EXISTS(SELECT CitationNumber FROM TrafficCitation_ApiMessageLog with(nolock) WHERE CitationNumber = @sCitationNumber)
					Begin
						  UPDATE TrafficCitation_ApiMessageLog
						  SET ApiRequest = @xOdyApi_TransactionRequest,
							  ApiResponse = @xOdyApi_TransactionResponse,
							  AddDocRequest = @xAddDocumentRequest,
							  AddDocResponse = @xAddDocumentResponse,
							  LinkDocRequest = @xLinkDocumentRequest,
							  LinkDocResponse = @xLinkDocumentResponse,
							  UnpaidTollFeeRequest = @xAddUnpaidTollFeeRequest,
							  UnpaidTollFeeResponse = @xAddUnpaidTollFeeResponse, 
							  LastApiAttempt = GETDATE()
						  WHERE CitationNumber = @sCitationNumber			       
					End
					ELSE
					Begin
						INSERT INTO dbo.TrafficCitation_ApiMessageLog(CitationNumber, ApiRequest, ApiResponse, AddDocRequest, AddDocResponse, LinkDocRequest, LinkDocResponse, LastApiAttempt, UnpaidTollFeeRequest, UnpaidTollFeeResponse)
						VALUES(ISNULL(@sCitationNumber, 'NULL'), @xOdyApi_TransactionRequest, @xOdyApi_TransactionResponse, @xAddDocumentRequest, @xAddDocumentResponse, @xLinkDocumentRequest, @xLinkDocumentResponse, GETDATE(), @xAddUnpaidTollFeeRequest, @xAddUnpaidTollFeeResponse)
					End
			End
               
			 INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			 VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'After updating TrafficCitation_ApiMessageLog')

			 INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			 VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'Before updating TrafficCitation_ApiMessageLog for Toll')
				
		    -- Update TrafficCitation_ApiMessageLog with the LinkDocRequest & LinkDocResponse
			IF(@CitationType != 'TOLL')
			Begin
				IF EXISTS(SELECT CitationNumber FROM TrafficCitation_ApiMessageLog with(nolock) WHERE CitationNumber = @sCitationNumber)
				Begin
					  UPDATE TrafficCitation_ApiMessageLog
					  SET ApiRequest = @xOdyApi_TransactionRequest,
						  ApiResponse = @xOdyApi_TransactionResponse,
						  AddDocRequest = @xAddDocumentRequest,
						  AddDocResponse = @xAddDocumentResponse,
						  LinkDocRequest = @xLinkDocumentRequest,
						  LinkDocResponse = @xLinkDocumentResponse,
						  LastApiAttempt = GETDATE()
					  WHERE CitationNumber = @sCitationNumber			       
				End
				ELSE
				Begin
					INSERT INTO dbo.TrafficCitation_ApiMessageLog(CitationNumber, ApiRequest, ApiResponse, AddDocRequest, AddDocResponse, LinkDocRequest, LinkDocResponse, LastApiAttempt)
					VALUES(ISNULL(@sCitationNumber, 'NULL'), @xOdyApi_TransactionRequest, @xOdyApi_TransactionResponse, @xAddDocumentRequest, @xAddDocumentResponse, @xLinkDocumentRequest, @xLinkDocumentResponse, GETDATE())
				End
			End	 

			 INSERT INTO dbo.TrafficCitation_SPLog(EventDate, SPName , EventDescription) 
			 VALUES(GETDATE(), 'TrafficCitationImport_ProcessCitations', 'After updating TrafficCitation_ApiMessageLog for Toll')
	 
SET NOCOUNT OFF


