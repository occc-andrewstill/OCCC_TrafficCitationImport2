USE [OdyClerkInternal]
GO
/****** Object:  StoredProcedure [dbo].[TrafficCitationImport_FixAppearByDate]    Script Date: 8/11/2020 11:20:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- ============================================================================
-- Author:		Tarig Mudawi
-- Create date: 7/9/2014
-- Description:	This Stored Procedure to Fix appearByDate Issue.
-- ============================================================================

ALTER PROC [dbo].[TrafficCitationImport_FixAppearByDate] @FileLogId int=NULL

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
@sDlTypeID                  VARCHAR(50),
@MotorCycle				    varchar(50),


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

@Fnresponse   int

SET @MessageUserId = (Select userid from operations..appuser where loginname='CitationImport')

SELECT @sPartyIDFound = 'N'

  
DECLARE CitationImport_Cur CURSOR FOR

SELECT [UpdateType]
      ,[CitationNumber]
      ,[CheckDigit]
      ,[JurisdictionNumber]
      ,[CityName]
      ,[IssueAgencyCode]  -- Agency
      ,[IssueAgencyNameOdy]
      ,[OffenseDate]
      ,[OffenseTime]
      ,[OffenseTimeAmPm]
      ,[DriverFirstName]
      ,[DriverMiddleName]
      ,[DriverLastName]
      ,[StreetAddress]
      ,[City]
      ,[StateofDriversAddress]
      ,[ZipCodeOdy]
      ,[BirthDate]
      ,[RaceOdy]
      ,[Sex]  -- Gender
      ,[HeightFeet]
      ,[HeightInches]
      ,[DriverLicenseNumber]
      ,[DriverLicenseState]
      ,[DriverLicenseClass]
      ,[ViolationExpiredDLOdy]
      ,[CommercialVehicleCodeOdy]
      ,[VehicleYear]
      ,[VehicleMakeCode]
      ,[VehicleStyle]
      ,[VehicleColorCode]
      ,[HazardousMaterialsOdy]
      ,[VehicleTagNumber]
      ,[VehicleState]
      ,[VehicleTagExpYear]
      ,[DistanceFeet]
      ,[DistanceMiles]
      ,[OtherComments]
      ,[ViolationCode]
      ,[FLDLEditOverride]
      ,[Section]
      ,ISNULL([SubSection],'')
      ,[Crash]  -- Accident
      ,[PropertyDamage] --property
      ,[PropertyDamageAmount] -- Amount
      ,[InjuryOdy]  -- Injury to other
      ,[SeriousInjuryOdy]
      ,[FatalInjuryOdy]
      ,[CriminalCourtReqOdy]
      ,[InfractionNoCourtReq]
      ,[OfficerFullName]
      ,[OfficerIdOdy]
      ,[OfficerPartyID]
      ,[Status]
      ,[AggressiveDriverFlagOdy]
      ,[CommercialDL]
      ,[Statute]
      ,[ActualSpeed]
      ,[PostedSpeed]
      ,[JurisdictionCode]
      ,[Degree]
      ,[Code]
      ,[StatuteCodeID]
      ,[CaseType]
      ,[NodeID]
      ,[VendorAgencyID]
      ,[VehicleTrailerNumber]
      ,MotorCycle
      ,CaseID
  FROM [OdyClerkInternal].[dbo].[TrafficCitation_Import]
  WHERE ExceptionFlag in (0,2)
    AND FileLogID IN(44,45)
    --and WorkFlowItemId IS NULL
    --and Processed=0
   
  
  OPEN CitationImport_Cur
  FETCH CitationImport_Cur
  INTO
     @sUpdateType,
     @sCitationNumber,
     @sCheckDigit,
     @sJurisdictionNumber,
     @sCityName,
	 @sIssueAgencyCode,
	 @sIssueAgencyName,
	 @sOffenseDate ,
     @sOffenseTime,
     @sOffenseTimeAmPm,
     @sDriverFirstName,
     @sDriverMiddleName ,
     @sDriverLastName,
     @sStreetAddress,
     @sCity,
     @sStateofDriversAddress,
     @sZipCode,
     @sBirthDate,
     @sRaceOdy,
     @sSex,
     @sHeightFeet,
     @sHeightInches,
     @sDriverLicenseNumber,
     @sDriverLicenseState,
     @sDriverLicenseClass,
     @sViolationExpiredDL,
     @sCommercialVehicleCode,
     @sVehicleYear,
     @sVehicleMakeCode,
     @sVehicleStyle,
     @sVehiclyColorCode,
     @sHazardousMaterials,
     @sVehicleTagNumber,
     @sVehicleState,
     @sVehicleTagExpYear,
     @sDistanceFeet,
     @sDistanceMiles,
     @sOtherComments,
     @sViolationCode ,
     @sFLDLEditOverride,
     @sSection,
     @sSubSection,
     @sCrash,  -- Accident
     @sPropertyDamage, --property
     @sPropertyDamageAmount, -- Amount
     @sInjury,  -- Injury to other
     @sSeriousInjury,
     @sFatalInjury,
     @sCriminalCourtReq,
     @sInfractionNoCourtReq,
     @sOfficerFullName,
     @sOfficerIdOdy,
     @sOfficerCode,
     @sStatus,
     @sAggressiveDriverFlag,
     @sCommercialDL,
     @sStatute,
     @sActualSpeed,
     @sPostedSpeed,
     @sJurisdictionCode,
     @sDegree,
     @sStatuteCode,
     @sStatuteCodeID,
     @sCaseType,
     @sNodeID,
     @sVendorAgencyID,
     @sVehicleTrailerNumber,
     @MotorCycle,
     @sCaseID
      
     WHILE @@FETCH_STATUS = 0
     BEGIN
     
		--	WAITFOR DELAY '00:00:10'
			
			
			
			/*** If License Expiration Date is more current in DLLookup then use it otherwise use the one in the file *****/
			IF @sDriverLicenseNumber IS NOT NULL and LEN(LTRIM(RTRIM(@sDriverLicenseNumber)))>0
				Begin
					--SELECT @sDLLookupExpireDate = DLExpiration FROM Justice..DLLookup
					SELECT @sDLLookupExpireDate = cast(month(DOB) as varchar(10))+'/'+ cast(day(DOB) as varchar(10))+'/'+ cast(year(DLExpiration) as varchar(10)) FROM Justice..DLLookup
					WHERE DLNumber = @sDriverLicenseNumber
					IF(@sDLLookupExpireDate > @sViolationExpiredDL)
						SELECT @sViolationExpiredDL = @sDLLookupExpireDate
				End
			
      
			 /**** Calculating AppearByDate ****/
			 IF(@sCaseType = 'TINF')
				 SELECT @dtAppearByDate =  dbo.fnNextBusinessDay(DATEADD(dd, 30, CAST(@sOffenseDate AS Date)))
			 ELSE 
				 SELECT @dtAppearByDate =  dbo.fnNextBusinessDay(DATEADD(dd, 10, CAST(@sOffenseDate AS Date)))
		         
		    
			 IF @dtAppearByDate IS NOT NULL SELECT @sAppearByDate = CAST(@dtAppearByDate AS VARCHAR(30))
		     
		       
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
				IF NOT EXISTS(SELECT CaseID FROM Justice..xCaseAppearDate WHERE CaseID = @sCaseID)
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
				        UPDATE Justice..DL
						SET DtDlExpire = @sViolationExpiredDL,
						    DLTypeID=(select codeid from justice..ucode where code=@sDriverLicenseClass and cachetableid=9),
						    UserIDChange=@MessageUserId,
						    TimestampChange=GetDate()
						WHERE PartyID = (Select PartyId from Justice..CaseParty Where CaseId = @sCaseID And PartyId >1)
						and DLNum=@sDriverLicenseNumber
				  
				 --  Update Vehicle Style  
				 IF @MotorCycle='Y'
					BEGIN
				       Update Justice..Citation
					   Set VehicleTypeID=(Select CodeId from justice..ucode with (nolock) where Code='MOT' and CachetableId=148)
					   Where CitationNumber=@sCitationNumber
				    END
				 
			   Commit Tran
			  End Try
			  Begin Catch
				  Rollback Tran
			  End Catch 
			End

			Next_Record:
		    
			SELECT @sPartyIDFound = 'N', @sHasOffenseFineProgramID = 'N', @sPartyID = '', @sNameIDCurrent = '', @sCaseID = '', @sCaseNumber = '' , @sDocumentID = '', @sDocVersionID = '',  @sEventID = '', @sCitationImage ='', @sAppearByDate = '',
				   @sDisplayMessage ='', @sAddressID ='', @sDlTypeID =''
		    
		     
			 FETCH CitationImport_Cur
			 INTO
			 @sUpdateType,
			 @sCitationNumber,
			 @sCheckDigit,
			 @sJurisdictionNumber,
			 @sCityName,
			 @sIssueAgencyCode,
			 @sIssueAgencyName,
			 @sOffenseDate ,
			 @sOffenseTime,
			 @sOffenseTimeAmPm,
			 @sDriverFirstName,
			 @sDriverMiddleName ,
			 @sDriverLastName,
			 @sStreetAddress,
			 @sCity,
			 @sStateofDriversAddress,
			 @sZipCode,
			 @sBirthDate,
			 @sRaceOdy,
			 @sSex,
			 @sHeightFeet,
			 @sHeightInches,
			 @sDriverLicenseNumber,
			 @sDriverLicenseState,
			 @sDriverLicenseClass,
			 @sViolationExpiredDL,
			 @sCommercialVehicleCode,
			 @sVehicleYear,
			 @sVehicleMakeCode,
			 @sVehicleStyle,
			 @sVehiclyColorCode,
			 @sHazardousMaterials,
			 @sVehicleTagNumber,
			 @sVehicleState,
			 @sVehicleTagExpYear,
			 @sDistanceFeet,
			 @sDistanceMiles,
			 @sOtherComments,
			 @sViolationCode ,
			 @sFLDLEditOverride,
			 @sSection,
			 @sSubSection,
			 @sCrash,  -- Accident
			 @sPropertyDamage, --property
			 @sPropertyDamageAmount, -- Amount
			 @sInjury,  -- Injury to other
			 @sSeriousInjury,
			 @sFatalInjury,
			 @sCriminalCourtReq,
			 @sInfractionNoCourtReq,
			 @sOfficerFullName,
			 @sOfficerIdOdy,
			 @sOfficerCode,
			 @sStatus,
			 @sAggressiveDriverFlag,
			 @sCommercialDL,
			 @sStatute,
			 @sActualSpeed,
			 @sPostedSpeed,
			 @sJurisdictionCode,
			 @sDegree,
			 @sStatuteCode,
			 @sStatuteCodeID,
			 @sCaseType,
			 @sNodeID,
			 @sVendorAgencyID,
			 @sVehicleTrailerNumber,
			 @MotorCycle,
			 @sCaseID
     
     END
     
     CLOSE CitationImport_Cur
     
     DEALLOCATE CitationImport_Cur	 

SET NOCOUNT OFF




