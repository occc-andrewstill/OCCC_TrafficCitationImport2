USE [OdyClerkInternal]
GO
/****** Object:  StoredProcedure [dbo].[TrafficCitationImport_Report]    Script Date: 8/11/2020 11:26:35 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*********************************************************************************
Created:	05/01/2014	Anthony Payne
						Daily Report used by Traffic Division Intake Team to verify
						nightly processing of Citations that were imported by the
						Citation Import Process
Modified:	09/02/2014	Tarig Mudawi
						Added update statement for QueueStatus Column
			09/12/2014  Removed Exception Reasons, will be redesigned			

************************************************************************************/

ALTER PROCEDURE [dbo].[TrafficCitationImport_Report] 
	@NodeId varchar(max),
	@StartDt Date,
	@EndDt Date,
	@Agency varchar(max),
	@Reasons varchar(max)=NULL,
	@ExceptionFlag varchar(max)=NULL
AS
BEGIN
	
	SET NOCOUNT ON;                                     -- Modified to look at QueueStatus column
	UPDATE OdyClerkInternal..TrafficCitation_Import set QueueStatus = 4  --ExceptionFlag=4 
	From OdyClerkInternal..TrafficCitation_Import TI 
	Join Operations..WorkFlowTrans Trans with (Nolock) on TI.WorkFlowItemId=Trans.ItemID 
	Where  Trans.StatusKey in ('COM','MOV','DEL')
	
	UPDATE OdyClerkInternal..TrafficCitation_Import set CaseId=Cah.CaseId,CaseNumber=Cah.CaseNbr 
	From OdyClerkInternal..TrafficCitation_Import TI 
	Join Justice..Citation C on TI.CitationNumber=C.CitationNumber
	Join Justice..xCitationChrg xChrg with (nolock) on C.CitationId=xChrg.CitationId
	Join Justice..xCaseBaseChrg xCBC with (nolock) on xChrg.ChargeId=xCBC.ChargeId
	Join Justice..CaseAssignhist Cah with (nolock) on Cah.CaseId=xCBC.CaseId
	Where 
	TI.CaseID IS NULL  -- Modified to look at QueueStatus column
	AND TI.QueueStatus=4  --TI.ExceptionFlag=4
	--and TI.FileLogId between 38 and 42


	SELECT UpdateType, CitationNumber, CheckDigit, CountyNumber, Jurisdiction, CityName, IssueAgencyType, IssueAgencyCode, IssueAgencyName, DayofWeek, 
           OffenseDate, OffenseTime, OffenseTimeAMPM, DriverFirstName, DriverMiddleName, DriverLastName, DriverSuffix, StreetAddress, 
           AddressDiffLicense, City,StateofDriversAddress, ZipCode, Telephone, BirthDate, Race, Sex, Height, DriverLicenseNumber, 
           DriverLicenseState, DriverLicenseClass, ViolationExpiredDL,CommercialVehicleCode, VehicleYear, VehicleMake, VehicleStyle, 
           VehiclyColor, HazardousMaterials, VehicleTagNumber, VehicleTrailerNumber, VehicleState, VehicleTagExpYear, CompanionCitation, 
           ViolationLocation, DistanceFeet, DistanceMiles, DirectionN, DirectionS, DirectionE, DirectionW, OfNode, ActualSpeed, 
           PostedSpeed, Hwy4Lane, HwyInterstate, ViolationCareless, ViolationDevice, ViolationRow, ViolationLane, ViolationPassing, 
           ViolationChildRestraint, ViolationDUI,BloodAlcoholLevel, ViolationSeatBelt, ViolationEquipment, ViolationTagLess, ViolationTagMore,
           ViolationInsurance, ViolationExpiredDriverLicense,ViolationExpiredDLMore, ViolationNoDL, ViolationSuspendedDL, OtherComments, ViolationCode,
           FLDLEditOverride, StateStatuteIndicator, Section, SubSection,Crash, PropertyDamage, PropertyDamageAmount, Injury, SeriousInjury,
           FatalInjury, MethodOfArrest, CriminalCourtReq, InfractionCourtReq,InfractionNoCourtReq, CourtDate, CourtTime, CourtName, CourtTimeAMPM, 
           CourtAddress,CourtCity, CourtState, CourtZip, ArrestDeliveredTo,ArrestDeliveredDate, OfficerRank, OfficerFirstName, OfficerMiddleName, 
           OfficerLastName, OfficerBadgeNumber, SUBSTRING(OfficerId, 1, 4) AS BadgeNo,TrooperUnit, Bal08Above, DUIRefuse, DUILicenseSurrendered, DUILicenseRSN, 
           DuiEligible, DUIEligibleRSN, DUIBarOffice, Status, AggressiveDriverFlag,CriminalIndicator, FileAmount, Filler, IssueArrestDate, 
           OfficerDeliveryVerification, DueDate, Motorcycle, PassengerVehicle16, OfficerReExamFlag,DUIViolationUnder18, ECitationIndicator, 
           NameChange, CommercialDL, GPSLat, GPSLong, ViolationSignalRedLight, ViolationWorkersPresent, ViolationHandHeld,ViolationSchoolZone,
           AgencyIdentifier, PermanentRegistration, SpeedMeasuringDeviceId, ComplianceDate, DLSeize, Business, FileLogId, ExceptionReason, 
           ExceptionFlag, CaseId, CaseType, RunDate, CaseNumber, OfficerId,Statute, Code,TI.NodeId,C.Description as ClerkCourt,OfficerFullName,
           CourtMandatory,TI.QueueStatus,TI.VendorAgencyId,
	 --Case When DocumentVersionId>0 Then dbo.fnGetDocVersionPath(TI.DocumentVersionId)
		--  Else V.LocalPath+'\'+Ltrim(Rtrim(CitationNumber))+'.Pdf' 
	 --  End  
	   V.LocalPath+'\Processed\'+Ltrim(Rtrim(CitationNumber))+'.Pdf' as FilePath,V.CitationType
	FROM     OdyClerkInternal.dbo.TrafficCitation_Import TI with (nolock)
	Join OdyClerkInternal.dbo.TrafficCitation_AgencyVendorInfo V with (nolock) on TI.VendorAgencyId=V.VendorAgencyId
	LEFT Join OdyClerkInternal.dbo.Ody_NodeDetails C with (nolock) on C.NodeId=TI.NodeId
	WHERE  (RunDate BETWEEN @StartDt AND @EndDt) 
	AND TI.VendorAgencyId IN (select Value from dbo.fnSplitValues(@Agency,','))
	AND TI.NodeId in (select Value from dbo.fnSplitValues(@NodeId,','))
	AND NOT (TI.CaseID IS NULL and TI.ExceptionFlag=0)
	AND CitationNumber NOT IN
				(select citationnumber
					from trafficcitation_import
					where caseid is not null
					and documentid is null)
    AND TI.ExceptionFlag <> -1
	AND TI.ExceptionFlag <> -2	
	and TI.Has_Image=1				
	
--and CriminalCase='N'
    
END


