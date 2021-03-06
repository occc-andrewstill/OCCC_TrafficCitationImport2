USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[fnOdyApi_AddCitationToCriminalCaseChargeFLUTC]    Script Date: 8/11/2020 11:34:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- ============================================================================
-- Author:		Anthony Payne \ Tarig Mudawi
-- Create date: 10/15/2013
-- Description:	This function can be used to Build and\or Execute
--				the Odyssey AddCitationToCriminalCaseChargeFLUTC API Message
--				@Execute=FALSE Returns Request XML
--				@Execute=TRUE Returns Api Web Service Call Response XML
-- Update T.M.  Fix to exclude expiration date if invalid and allow DL Type as unknown T.M. 5/27/2020 reference ticket SR86699
-- ============================================================================
ALTER FUNCTION [dbo].[fnOdyApi_AddCitationToCriminalCaseChargeFLUTC]
	 (@Execute bit=FALSE,
	  @NodeId varchar(5),
	  @ReferenceNumber varchar(10)=1,
	  @MessageUserId varchar(10),
	  @CaseId varchar(15),
	  @ChargeId varchar(15),
	  @CitationNumber varchar(20),
	  @CheckDigit varchar(5),
	  @Agency varchar(20),
	  @CaseType varchar(20),
	  @OffenseDate varchar(15),
	  @OffenseTime varchar(15),
	  @FirstName varchar(50)=NULL,
	  @MiddleName varchar(50)=NULL,
	  @LastName varchar(50),
	  @AddressLine1 varchar(250),
	  @City varchar(100),
	  @State varchar(100),
	  @ZipCode varchar(15),
	  @BirthDate varchar(10),
	  @HeightFeet varchar(5)=NULL,
	  @HeightInches varchar(5)=NULL,
	  @DLNumber varchar(50)=NULL,
	  @DLState varchar(50)=NULL,
	  @DLType varchar(20)=NULL,
	  @ExpirationDate varchar(50)=NULL,
	  @VehicleYear varchar(4)=NULL,
	  @VehicleMake varchar(50)=NULL,
	  @VehicleModel varchar(50)=NULL,
	  @VehicleColor varchar(10)=NULL,
	  @LicensePlateNumber varchar(20)=NULL,
	  @LicensePlateState varchar (5)=NULL,
	  @LicensePlateExp	varchar(10)=NULL,
	  @CommercialVehicle varchar(5)=NULL,
	  @HazMat varchar (5)=NULL,
	  @Jurisdiction varchar(50),
	  @OfficerId varchar(20)=NULL,
	  @AggressiveDriving varchar(10),
	  @PropertyDamage varchar(10),
	  @Amount varchar(10),
	  @Accident varchar(10),
	  @Injury varchar(50),
	  @SeriousInjury varchar(50),
	  @FatalInjury varchar(50),
	  @CourtRequired varchar(5),
	  @DistanceFeet varchar(10)=NULL,
	  @DistanceMiles varchar(10)=NULL,
	  @FileDate varchar(12)=NULL,
	  @Comment varchar(500)=NULL,
	  @VehicleTrailerNumber varchar(50),
	  @AddressDiffLicense varchar(50)=NULL,
	  @ValidDLExpirationDate int,
	  @IssueArrestDate varchar(100)=NULL,
	  @IsRedLightOrTOLL varchar(10),
	  @IsBusiness varchar(5) 
	  )
RETURNS XML 
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result XML, @ApiMessage varchar(max), @MessageText varchar(max), @AddressTag Varchar(4000), @ForeignDL Varchar(20), @CanadaDL Varchar(20), @MexicoDL Varchar(20), @VehicleTag Varchar(max)
	
	-- Select @State = 'NY', @DLState = 'NY'
	
	/****** If Foreign Country (DL State value is 'FF') Then use Foreign Address Tag     T. Mudawi 2/7/2014 ******/
	If(/*@State = 'FF' OR*/ @DLState = 'FF')
	Begin
	   --SELECT @AddressTag = '<Address><Foreign><Line1>'+@AddressLine1+'</Line1><Line2>'+@City+'</Line2><Line3>'+@State+'</Line3><Line4>'+@ZipCode+'</Line4></Foreign></Address>'
	   SELECT @AddressTag = '<Address><Foreign><Line1>'+ISNULL(@AddressLine1,'')+'</Line1><Line4>'+ISNULL(@City,'')+' '+ISNULL(@State,'')+' '+ISNULL(@ZipCode,'')+'</Line4></Foreign></Address>'
	   SELECT @ForeignDL = 'true', @CanadaDL = 'false', @MexicoDL = 'false'
	End
	/****** If DL state is 'FF' and AddressDiffLicense field in the data file is 'Y' we use Non standard US address and flag it as a warning   T. Mudawi 11/3/2014 ******/
	Else If((/*@State = 'FF' OR*/ @DLState = 'FF') AND @AddressDiffLicense = 'Y')
	Begin
	   SELECT @AddressTag = '<Address><NonStandardUS><Line1>'+@AddressLine1+'</Line1><City>'+@City+'</City><State>'+@State+'</State><ZIP>'+@ZipCode+'</ZIP></NonStandardUS></Address>'
	   SELECT @ForeignDL = 'true', @CanadaDL = 'false', @MexicoDL = 'false'
	End
	Else If(/*@State = 'CD' OR*/ @DLState = 'CD')
	Begin
	   SELECT @AddressTag = '<Address><NonStandardUS><Line1>'+@AddressLine1+'</Line1><City>'+@City+'</City><State>'+@State+'</State><ZIP>'+@ZipCode+'</ZIP></NonStandardUS></Address>'
	   SELECT @CanadaDL = 'true', @ForeignDL = 'false', @MexicoDL = 'false'
	End
	Else If(/*@State = 'MX' OR*/ @DLState = 'MX')
	Begin
	   SELECT @AddressTag = '<Address><Foreign><Line1>'+@AddressLine1+'</Line1><Line2>'+@City+'</Line2><Line3>'+@State+'</Line3><Line4>'+@ZipCode+'</Line4></Foreign></Address>'
	   SELECT @MexicoDL = 'true', @ForeignDL = 'false', @CanadaDL = 'false' 
	End
	Else
	Begin 
	   SELECT @AddressTag = '<Address><NonStandardUS><Line1>'+@AddressLine1+'</Line1><City>'+@City+'</City><State>'+@State+'</State><ZIP>'+@ZipCode+'</ZIP></NonStandardUS></Address>'
	   SELECT @ForeignDL = 'false', @CanadaDL = 'false', @MexicoDL = 'false'
	End
	
	/**** Send Vehicle Color only if provided, otherwise hide the tag  T. Mudawi 5/21/2014 ****/
	--IF(@VehicleColor IS NOT NULL AND @VehicleColor != '')
	--		SELECT @VehicleTag = '<Vehicle><Year>'+@VehicleYear+'</Year><Make>'+@VehicleMake+'</Make><Model>'+@VehicleModel+'</Model><Color>'+@VehicleColor+'</Color><LicensePlate><Number>'+@LicensePlateNumber+'</Number><State>'+@LicensePlateState+'</State><CanadaVehicle>FALSE</CanadaVehicle><ExpirationDate>'+@LicensePlateExp+'</ExpirationDate></LicensePlate><CommercialVehicle>'+@CommercialVehicle+'</CommercialVehicle><HazardousMaterial>'+@HazMat+'</HazardousMaterial></Vehicle>'
	--ELSE
	--        SELECT @VehicleTag = '<Vehicle><Year>'+@VehicleYear+'</Year><Make>'+@VehicleMake+'</Make><Model>'+@VehicleModel+'</Model><LicensePlate><Number>'+@LicensePlateNumber+'</Number><State>'+@LicensePlateState+'</State><CanadaVehicle>FALSE</CanadaVehicle><ExpirationDate>'+@LicensePlateExp+'</ExpirationDate></LicensePlate><CommercialVehicle>'+@CommercialVehicle+'</CommercialVehicle><HazardousMaterial>'+@HazMat+'</HazardousMaterial></Vehicle>'
	
	/**** Send Vehicle Make only if provided, otherwise hide the tag  T. Mudawi 5/21/2014 ****/
	--IF(@VehicleMake IS NOT NULL AND @VehicleMake != '')
	--		SELECT @VehicleTag = '<Vehicle><Year>'+@VehicleYear+'</Year><Make>'+@VehicleMake+'</Make><Model>'+@VehicleModel+'</Model><Color>'+@VehicleColor+'</Color><LicensePlate><Number>'+@LicensePlateNumber+'</Number><State>'+@LicensePlateState+'</State><CanadaVehicle>FALSE</CanadaVehicle><ExpirationDate>'+@LicensePlateExp+'</ExpirationDate></LicensePlate><CommercialVehicle>'+@CommercialVehicle+'</CommercialVehicle><HazardousMaterial>'+@HazMat+'</HazardousMaterial></Vehicle>'
	--ELSE
	--		SELECT @VehicleTag = '<Vehicle><Year>'+@VehicleYear+'</Year><Model>'+@VehicleModel+'</Model><Color>'+@VehicleColor+'</Color><LicensePlate><Number>'+@LicensePlateNumber+'</Number><State>'+@LicensePlateState+'</State><CanadaVehicle>FALSE</CanadaVehicle><ExpirationDate>'+@LicensePlateExp+'</ExpirationDate></LicensePlate><CommercialVehicle>'+@CommercialVehicle+'</CommercialVehicle><HazardousMaterial>'+@HazMat+'</HazardousMaterial></Vehicle>'
		
	
	

	Set @ApiMessage='<Message MessageType="AddCitationToCriminalCaseChargeFLUTC" NodeID="'+@NodeId+'" ReferenceNumber="'+@ReferenceNumber+'" UserID="'+@MessageUserId+'" Source="Tyler">'
	Set @ApiMessage=@ApiMessage+'<CaseID>'+@CaseId+'</CaseID>'
	Set @ApiMessage=@ApiMessage+'<ChargeID>'+@ChargeId+'</ChargeID>'
	Set @ApiMessage=@ApiMessage+'<Citation>'
	Set @ApiMessage=@ApiMessage+	'<CitationNumber>'+@CitationNumber+'</CitationNumber>'
	IF(@CheckDigit != '' and @CheckDigit IS NOT NULL)
	Begin
		Set @ApiMessage=@ApiMessage+	'<CheckDigit>'+@CheckDigit+'</CheckDigit>'
	End
	Set @ApiMessage=@ApiMessage+	'<Agency>'+@Agency+'</Agency>'
	Set @ApiMessage=@ApiMessage+	'<CaseType>'+@CaseType+'</CaseType>'
	Set @ApiMessage=@ApiMessage+	'<OffenseDate>'+@OffenseDate+'</OffenseDate>'
	Set @ApiMessage=@ApiMessage+	'<OffenseTime>'+@OffenseTime+'</OffenseTime>'
	-- Setting the Ticket Date for Red light citations T.M. 8/18/2015
	IF(@IsRedLightOrTOLL = 'Y')  
		Begin
			Set @ApiMessage=@ApiMessage+    '<TicketDate>'+@IssueArrestDate+'</TicketDate>' 
		End
	Else
	    Begin
			Set @ApiMessage=@ApiMessage+    '<TicketDate>'+@OffenseDate+'</TicketDate>'
		End

	Set @ApiMessage=@ApiMessage+	'<Citee>'
				--Set @ApiMessage=@ApiMessage+		'<Name>'
				--Set @ApiMessage=@ApiMessage+			'<Person>'
				--Set @ApiMessage=@ApiMessage+				'<First>'+@FirstName+'</First>'
				--Set @ApiMessage=							 ISNULL(@ApiMessage+'<Middle>'+@MiddleName+'</Middle>',@ApiMessage)
				--Set @ApiMessage=@ApiMessage+				'<Last>'+@LastName+'</Last>'
				--Set @ApiMessage=@ApiMessage+			'</Person>'
				--Set @ApiMessage=@ApiMessage+		'</Name>'

   /********** Setting business name name Vs. person name based on the CommercialVehicle value  T.M. 8/18/2015  *******/
	IF(@CommercialVehicle = 'True' AND (@FirstName IS NULL OR @FirstName = 'Business') AND @Agency != 'CFX') -- checked also if First name is null T.M. 9/28/2015
		Begin
				Set @ApiMessage=@ApiMessage+		'<Name>'
				Set @ApiMessage=@ApiMessage+			'<Business>'
				Set @ApiMessage=@ApiMessage+				'<BusinessName>'+@LastName+'</BusinessName>'
				Set @ApiMessage=@ApiMessage+			'</Business>'
				Set @ApiMessage=@ApiMessage+		'</Name>'

				/******************  Setting the defaults for FL Business with missing DL#  T.M. 11/25/2015 ****************************************/
				 -- Per Jessica and Jaya Businesses with a Florida address should be defaulted to reflect DL#: NDL; DL State: FF; Type: Unknown.
				 IF( (@DLNumber IS NULL OR @DLNumber = '') AND @DLState = 'FL' )
				 Begin
					Select @DLNumber = 'NDL', @DLState = 'FF', @DLType = 'U', @ExpirationDate = Null, @ValidDLExpirationDate = 1 
	             End 	  
		End
	-- In case of CFX Business Citations we use Business flag to identify them T.M. 4/19/2017
	   Else	IF(@IsBusiness = 'Y' AND (@FirstName IS NULL OR @FirstName = 'Business') AND @Agency = 'CFX') -- checked also if First name is null T.M. 9/28/2015
		Begin
				Set @ApiMessage=@ApiMessage+		'<Name>'
				Set @ApiMessage=@ApiMessage+			'<Business>'
				Set @ApiMessage=@ApiMessage+				'<BusinessName>'+@LastName+'</BusinessName>'
				Set @ApiMessage=@ApiMessage+			'</Business>'
				Set @ApiMessage=@ApiMessage+		'</Name>'

				/******************  Setting the defaults for FL Business with missing DL#  T.M. 11/25/2015 ****************************************/
				 -- Per Jessica and Jaya Businesses with a Florida address should be defaulted to reflect DL#: NDL; DL State: FF; Type: Unknown.
				 IF( (@DLNumber IS NULL OR @DLNumber = '') AND @DLState = 'FL' )
				 Begin
					Select @DLNumber = 'NDL', @DLState = 'FF', @DLType = 'U', @ExpirationDate = Null, @ValidDLExpirationDate = 1 
	             End 	  
		End
	--- End of CFX Business citations code
	ELSE
	    Begin
				Set @ApiMessage=@ApiMessage+		'<Name>'
				Set @ApiMessage=@ApiMessage+			'<Person>'
				Set @ApiMessage=@ApiMessage+				'<First>'+@FirstName+'</First>'
				Set @ApiMessage=							 ISNULL(@ApiMessage+'<Middle>'+@MiddleName+'</Middle>',@ApiMessage)
				Set @ApiMessage=@ApiMessage+				'<Last>'+@LastName+'</Last>'
				Set @ApiMessage=@ApiMessage+			'</Person>'
				Set @ApiMessage=@ApiMessage+		'</Name>'
	  End
	Set @ApiMessage=				ISNULL(@ApiMessage+@AddressTag,@ApiMessage)
	--Set @ApiMessage=@ApiMessage+		'<Address>'
	--Set @ApiMessage=@ApiMessage+			'<NonStandardUS>'
	--Set @ApiMessage=@ApiMessage+				'<Line1>'+@AddressLine1+'</Line1>'
	--Set @ApiMessage=@ApiMessage+				'<City>'+@City+'</City>'
	--Set @ApiMessage=@ApiMessage+				'<State>'+@State+'</State>'
	--Set @ApiMessage=@ApiMessage+				'<ZIP>'+@ZipCode+'</ZIP>'
 --   Set @ApiMessage=@ApiMessage+			'</NonStandardUS>'
	--Set @ApiMessage=@ApiMessage+		'</Address>'
	--Set @ApiMessage=@ApiMessage+		'<DateOfBirth>'+@BirthDate+'</DateOfBirth>'
	
	--Set @ApiMessage=@ApiMessage+		'<Height>' --> commenetd 7/20/2015
	-- Change Tags for HeightFeet and Height Inches to Feet and Inches only to make it work in Odyssey 2014
	--Set @ApiMessage=					  ISNULL(@ApiMessage+'<HeightFeet>'+@HeightFeet+'</HeightFeet>',@ApiMessage)
	--Set @ApiMessage=					  ISNULL(@ApiMessage+'<HeightInches>'+@HeightInches+'</HeightInches>',@ApiMessage)
	
	--Set @ApiMessage=					  ISNULL(@ApiMessage+'<Feet>'+@HeightFeet+'</Feet>',@ApiMessage)       --> commenetd 7/20/2015
	--Set @ApiMessage=					  ISNULL(@ApiMessage+'<Inches>'+@HeightInches+'</Inches>',@ApiMessage) --> commenetd 7/20/2015
	--Set @ApiMessage=@ApiMessage+		'</Height>'
	
	-- Fix for Null Height   T.M. 7/20/2015
	Set @ApiMessage = ISNULL(@ApiMessage+'<Height><Feet>'+@HeightFeet+'</Feet><Inches>'+@HeightInches+'</Inches></Height>',@ApiMessage)

	-- Fix to exclude expiration date if invalid and allow DL Type as unknown T.M. 5/27/2020 reference ticket SR86699
	IF @ValidDLExpirationDate != 1
	  Set @ExpirationDate = NULL
	
	IF LEN(LTRIM(RTRIM(@DLNumber)))>0 --AND @ValidDLExpirationDate = 1  --> Check the expiration date too for Red Light citations T.M. 7/23/2015
		Begin
			Set @ApiMessage=@ApiMessage+		'<DriversLicense>'
			Set @ApiMessage=						 ISNULL(@ApiMessage+'<Number>'+@DLNumber+'</Number>',@ApiMessage)
			Set @ApiMessage=						 ISNULL(@ApiMessage+'<State>'+@DLState+'</State>',@ApiMessage)
			Set @ApiMessage=@ApiMessage+			'<DLType>'+@DLType+'</DLType>'
			Set @ApiMessage=						 ISNULL(@ApiMessage+'<ExpirationDate>'+@ExpirationDate+'</ExpirationDate>',@ApiMessage)
			Set @ApiMessage=@ApiMessage+			'<DLOverride>FALSE</DLOverride>'
			IF(@ForeignDL = 'true')
			Begin
				Set @ApiMessage=@ApiMessage+			'<ForeignDL>'+@ForeignDL+'</ForeignDL>'  -- uncommented 6/19/14
			End
			IF(@CanadaDL = 'true')
			Begin
				Set @ApiMessage=@ApiMessage+			'<CanadaDL>'+@CanadaDL+'</CanadaDL>'      -- uncommented 6/19/14
		    End
		    IF(@MexicoDL = 'true')
		    Begin                                       -- corrected spelling from MexecoDL to MexicoDL 5/31/2016
				Set @ApiMessage=@ApiMessage+			'<MexicoDL>'+@MexicoDL+'</MexicoDL>'       -- uncommented 6/19/14
			End
			Set @ApiMessage=@ApiMessage+		'</DriversLicense>'
		End
	
	Set @ApiMessage=@ApiMessage+	'</Citee>'
	Set @ApiMessage=				ISNULL(@ApiMessage+@VehicleTag,@ApiMessage)
	-- Modify code for Vehicle T.Mudawi 7/1/2014 ------
	IF(@VehicleYear IS NULL AND @VehicleMake IS NULL AND @VehicleModel IS NULL AND @VehicleColor IS NULL AND @LicensePlateNumber IS NULL AND @LicensePlateState IS NULL AND @LicensePlateExp IS NULL 
	   AND @CommercialVehicle IS NULL AND @HazMat IS NULL)
	Begin
	      Set @ApiMessage=@ApiMessage
	End
	ELSE
	Begin
	      	Set @ApiMessage=@ApiMessage+'<Vehicle>'
			Set @ApiMessage=ISNULL(@ApiMessage+'<Year>'+@VehicleYear+'</Year>',@ApiMessage)
			Set @ApiMessage=ISNULL(@ApiMessage+'<Make>'+@VehicleMake+'</Make>',@ApiMessage)
			Set @ApiMessage=ISNULL(@ApiMessage+'<Model>'+@VehicleModel+'</Model>',@ApiMessage)
			Set @ApiMessage=ISNULL(@ApiMessage+'<Color>'+@VehicleColor+'</Color>',@ApiMessage)
			
			Set @ApiMessage=@ApiMessage+'<LicensePlate>'
			
			IF @LicensePlateNumber IS NOT NULL and @LicensePlateState IS NOT NULL
				Begin
					IF(@LicensePlateState in(select Code from justice..uCode where CacheTableID = 456 and Code != 'FF'))
					Begin
					    Set @ApiMessage=ISNULL(@ApiMessage+'<Number>'+@LicensePlateNumber+'</Number>',@ApiMessage)
						Set @ApiMessage=ISNULL(@ApiMessage+'<State>'+@LicensePlateState+'</State>',@ApiMessage)
					End
				End
				
			Set @ApiMessage=ISNULL(@ApiMessage+'<CanadaVehicle>FALSE</CanadaVehicle>',@ApiMessage)
			Set @ApiMessage=ISNULL(@ApiMessage+'<ExpirationDate>'+@LicensePlateExp+'</ExpirationDate>',@ApiMessage)
			Set @ApiMessage=@ApiMessage+'</LicensePlate>'
			
			
			Set @ApiMessage=ISNULL(@ApiMessage+'<TrailerTagNumber>'+@VehicleTrailerNumber+'</TrailerTagNumber>',@ApiMessage)
			Set @ApiMessage=ISNULL(@ApiMessage+'<CommercialVehicle>'+@CommercialVehicle+'</CommercialVehicle>',@ApiMessage)
			Set @ApiMessage=ISNULL(@ApiMessage+'<HazardousMaterial>'+@HazMat+'</HazardousMaterial>',@ApiMessage)
			Set @ApiMessage=@ApiMessage+'</Vehicle>'
	End
	----------------- 
	--Set @ApiMessage=@ApiMessage+	'<Vehicle>'
	--Set @ApiMessage=@ApiMessage+		'<Year>'+@VehicleYear+'</Year>'
	--Set @ApiMessage=@ApiMessage+		'<Make>'+@VehicleMake+'</Make>'
	--Set @ApiMessage=@ApiMessage+		'<Model>'+@VehicleModel+'</Model>'
	--Set @ApiMessage=@ApiMessage+		'<Color>'+@VehicleColor+'</Color>'
	--Set @ApiMessage=@ApiMessage+		'<LicensePlate>'
	--Set @ApiMessage=@ApiMessage+			'<Number>'+@LicensePlateNumber+'</Number>'
	--Set @ApiMessage=@ApiMessage+			'<State>'+@LicensePlateState+'</State>'
	--Set @ApiMessage=@ApiMessage+			'<CanadaVehicle>FALSE</CanadaVehicle>'
	--Set @ApiMessage=@ApiMessage+			'<ExpirationDate>'+@LicensePlateExp+'</ExpirationDate>'
	--Set @ApiMessage=@ApiMessage+		'</LicensePlate>'
	--Set @ApiMessage=@ApiMessage+		'<CommercialVehicle>'+@CommercialVehicle+'</CommercialVehicle>'
	--Set @ApiMessage=@ApiMessage+		'<HazardousMaterial>'+@HazMat+'</HazardousMaterial>'
	--Set @ApiMessage=@ApiMessage+	'</Vehicle>'
	
	Set @ApiMessage=@ApiMessage+	'<Incident>'
	Set @ApiMessage=@ApiMessage+		'<Jurisdiction>'+@Jurisdiction+'</Jurisdiction>'
	Set @ApiMessage=@ApiMessage+		'<Officer>'
	Set @ApiMessage=@ApiMessage+			'<OfficerParty>'
	Set @ApiMessage=@ApiMessage+				'<OfficerID>'+@OfficerID+'</OfficerID>'
	Set @ApiMessage=@ApiMessage+			'</OfficerParty>'
	Set @ApiMessage=@ApiMessage+		'</Officer>'
	Set @ApiMessage=@ApiMessage+		'<AggressiveDriving>'+@AggressiveDriving+'</AggressiveDriving>'
	Set @ApiMessage=@ApiMessage+		'<Property>'+@PropertyDamage+'</Property>'
	Set @ApiMessage=@ApiMessage+		'<Accident>'+@Accident+'</Accident>'
	Set @ApiMessage=     ISNULL(@ApiMessage+'<Amount>'+@Amount+'</Amount>',@ApiMessage) --> fixed for Red Light, added IsNull T.M. 7/23/2015 
	Set @ApiMessage=     ISNULL(@ApiMessage+'<InjuryToOther>'+@Injury+'</InjuryToOther>',@ApiMessage) --> fixed for Red Light, added IsNull T.M. 7/23/2015
	Set @ApiMessage=	 ISNULL(@ApiMessage+'<SeriousBodilyInjury>'+@SeriousInjury+'</SeriousBodilyInjury>',@ApiMessage) --> fixed for Red Light, added IsNull T.M. 7/23/2015
	Set @ApiMessage=	 ISNULL(@ApiMessage+'<Fatality>'+@FatalInjury+'</Fatality>',@ApiMessage) --> fixed for Red Light, added IsNull T.M. 7/23/2015
	Set @ApiMessage=@ApiMessage+		'<LicenseReexam>FALSE</LicenseReexam>'
	Set @ApiMessage=	 ISNULL(@ApiMessage+'<RequiredCourtAppearance>'+@CourtRequired+'</RequiredCourtAppearance>',@ApiMessage) --> fixed for Red Light, added IsNull T.M. 7/23/2015
	Set @ApiMessage=@ApiMessage+		'<Distance>'
	Set @ApiMessage=@ApiMessage+			'<Feet>'+@DistanceFeet+'</Feet>'
	Set @ApiMessage=@ApiMessage+			'<Miles>'+@DistanceMiles+'</Miles>'
	Set @ApiMessage=@ApiMessage+		'</Distance>'
	Set @ApiMessage=		 ISNULL(@ApiMessage+'<Comment>'+@Comment+'</Comment>',@ApiMessage)
	Set @ApiMessage=		 ISNULL(@ApiMessage+'<FiledDate>'+@FileDate+'</FiledDate>',@ApiMessage)
	Set @ApiMessage=@ApiMessage+	'</Incident>'
	Set @ApiMessage=@ApiMessage+'</Citation>'
	Set @ApiMessage=@ApiMessage+'</Message>'
	
	 
	IF @Execute='TRUE'
		 Set @Result=dbo.fnOdyApiExec2(Cast(@ApiMessage as XML),Default)
	ELSE
		Set @Result=Cast(@ApiMessage as XML)

	-- Return the result of the function
	RETURN @Result
END
