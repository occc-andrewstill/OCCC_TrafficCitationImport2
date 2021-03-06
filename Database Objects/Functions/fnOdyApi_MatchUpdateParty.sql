USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[fnOdyApi_MatchUpdateParty]    Script Date: 8/11/2020 11:42:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- ============================================================================
-- Author:		Anthony Payne \ Tarig Mudawi
-- Create date: 10/15/2013
-- Description:	This function can be used to Build and\or Execute
--				the Odyssey MatchUpdateParty API Message
--				@Execute=FALSE Returns Request XML
--				@Execute=TRUE Returns Api Web Service Call Response XML
-- ============================================================================
ALTER FUNCTION [dbo].[fnOdyApi_MatchUpdateParty]
	 (@Execute bit,
	  @ReferenceNumber varchar(10)=1,
	  @MessageUserId varchar(10),
	  @FirstName varchar(100)=NULL,
	  @MiddleName varchar(100)=NULL,
	  @LastName varchar (100),
	  @BirthDate varchar(10),
	  @HeightFeet varchar(5)=NULL,
	  @HeightInches varchar(5)=NULL,
	  @Gender varchar(10),
	  @Race varchar(20)=NULL,
	  @DLNumber varchar(50)=NULL,
	  @DLState varchar(50)=NULL,
	  @AddressLine1 varchar(255),
	  @City varchar(100),
	  @State varchar(100),
	  @ZipCode varchar(15), 
	  @PartyId varchar(20)=NULL,
	  @AddressDiffLicense varchar(50)=NULL,
	  @CommercialVehicle varchar(100)=NULL
	  )
RETURNS XML
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result XML, @ApiMessage varchar(max), @MessageText varchar(max), @AddressTypeTag Varchar(4000), @ForeignDL Varchar(20), @CanadaDL Varchar(20), @MexecoDL Varchar(20)
	
    /****** If Foreign Country (State value is 'FF') Then use Foreign Address Tag     T. Mudawi 2/7/2014 ******/
	If(/* @State = 'FF' OR */ @DLState = 'FF')
	Begin
	    --SELECT @AddressTypeTag = '<Foreign><Line1>'+@AddressLine1+'</Line1><Line2>'+@City+'</Line2><Line3>'+@State+'</Line3><Line4>'+@ZipCode+'</Line4></Foreign>'
	    SELECT @AddressTypeTag = '<Foreign><Line1>'+@AddressLine1+'</Line1><Line4>'+ISNULL(@City,'')+' '+ISNULL(@State,'')+' '+ISNULL(@ZipCode,'')+'</Line4></Foreign>'
	End
	Else If(/* @State = 'FF' OR */ @DLState = 'FF' AND @AddressDiffLicense = 'Y')
	Begin
		SELECT @AddressTypeTag = '<NonStandardUS><Line1>'+@AddressLine1+'</Line1><City>'+@City+'</City><State>'+@State+'</State><Zip>'+@ZipCode+'</Zip></NonStandardUS>'
	End
	Else If(/* @State = 'CD' OR */ @DLState = 'CD')
	Begin
	   SELECT @AddressTypeTag = '<NonStandardUS><Line1>'+@AddressLine1+'</Line1><City>'+@City+'</City><State>'+@State+'</State><Zip>'+@ZipCode+'</Zip></NonStandardUS>'
	End
	Else If(/* @State = 'MX' OR */ @DLState = 'MX')
	Begin
	   SELECT @AddressTypeTag = '<Foreign><Line1>'+@AddressLine1+'</Line1><Line2>'+@City+'</Line2><Line3>'+@State+'</Line3><Line4>'+@ZipCode+'</Line4></Foreign>'
	End
	Else
	Begin 
	    SELECT @AddressTypeTag = '<NonStandardUS><Line1>'+@AddressLine1+'</Line1><City>'+@City+'</City><State>'+@State+'</State><Zip>'+@ZipCode+'</Zip></NonStandardUS>'
	End
	
	Set @ApiMessage='<Message MessageType="MatchUpdateParty" Source="Tyler" NodeID="0" ReferenceNumber="'+@ReferenceNumber+'" UserID="'+@MessageUserId+'">'
	Set @ApiMessage=@ApiMessage+'<ConfigurationID>1</ConfigurationID>'
	
	IF @PartyId>0 
		Begin
			Set @ApiMessage=@ApiMessage+'<PartyID>'+@PartyId+'</PartyID>'
		End
	
	--Set @ApiMessage=@ApiMessage+'<Name>'
	--Set @ApiMessage=@ApiMessage+   '<Person>'
 --   Set @ApiMessage=@ApiMessage+     '<First>'+@FirstName+'</First>'
	--Set @ApiMessage=				  ISNULL(@ApiMessage+'<Middle>'+@MiddleName+'</Middle>',@ApiMessage)
 --   Set @ApiMessage=@ApiMessage+     '<Last>'+@LastName+'</Last>'
 --   Set @ApiMessage=@ApiMessage+   '</Person>'

  /********** Setting business name name Vs. person name based on the CommercialVehicle value  T.M. 8/18/2015  *******/
	IF(@CommercialVehicle = 'True' AND (@FirstName IS NULL OR @FirstName = 'Business')) -- checked also if First name is null T.M. 9/28/2015
		Begin
				Set @ApiMessage=@ApiMessage+		'<Name>'
				Set @ApiMessage=@ApiMessage+			'<Business>'
				Set @ApiMessage=@ApiMessage+				'<BusinessName>'+@LastName+'</BusinessName>'
				Set @ApiMessage=@ApiMessage+			'</Business>'
				Set @ApiMessage=@ApiMessage+		'</Name>'
		End
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

	--Set @ApiMessage=@ApiMessage+'</Name>'
	Set @ApiMessage=@ApiMessage+'<DateOfBirth>'+@BirthDate+'</DateOfBirth>'
	Set @ApiMessage=			  ISNULL(@ApiMessage+'<HeightFeet>'+@HeightFeet+'</HeightFeet>',@ApiMessage)
	Set @ApiMessage=			  ISNULL(@ApiMessage+'<HeightInches>'+@HeightInches+'</HeightInches>',@ApiMessage)
	Set @ApiMessage=@ApiMessage+'<Gender>'+@Gender+'</Gender>'
	Set @ApiMessage=			  ISNULL(@ApiMessage+'<Race>'+@Race+'</Race>',@ApiMessage)
	
	IF LEN(LTRIM(RTRIM(@DLNumber)))>0
		Begin
			Set @ApiMessage=@ApiMessage+'<DriversLicense>'
			Set @ApiMessage=			  ISNULL(@ApiMessage+'<Number>'+@DLNumber+'</Number>',@ApiMessage)
			Set @ApiMessage=			  ISNULL(@ApiMessage+'<State>'+@DLState+'</State>',@ApiMessage)
			Set @ApiMessage=@ApiMessage+'</DriversLicense>'
		End
	
	Set @ApiMessage=@ApiMessage+'<Address>'
	Set @ApiMessage=@ApiMessage+@AddressTypeTag
 --   Set @ApiMessage=@ApiMessage+     '<NonStandardUS>'
	--Set @ApiMessage=@ApiMessage+           '<Line1>'+@AddressLine1+'</Line1>'
	--Set @ApiMessage=@ApiMessage+           '<City>'+@City+'</City>'
	--Set @ApiMessage=@ApiMessage+           '<State>'+@State+'</State>'
	--Set @ApiMessage=@ApiMessage+		   '<Zip>'+@ZipCode+'</Zip>'
 --   Set @ApiMessage=@ApiMessage+	 '</NonStandardUS>'
    Set @ApiMessage=@ApiMessage+	 '<AddressFlags>'
	Set @ApiMessage=@ApiMessage+		   '<CurrentKnownAddress>TRUE</CurrentKnownAddress>'
	Set @ApiMessage=@ApiMessage+		   '<CorrespondenceAddress>TRUE</CorrespondenceAddress>'
	Set @ApiMessage=@ApiMessage+           '<RemitToAddress>FALSE</RemitToAddress>'
	Set @ApiMessage=@ApiMessage+           '<Undeliverable>FALSE</Undeliverable>'
	Set @ApiMessage=@ApiMessage+           '<Confidential>FALSE</Confidential>'
    Set @ApiMessage=@ApiMessage+     '</AddressFlags>'
    Set @ApiMessage=@ApiMessage+'</Address>'
	Set @ApiMessage=@ApiMessage+'</Message>'
	
	 
	IF @Execute='TRUE'
		Set @Result=dbo.fnOdyApiCall(@ApiMessage,Default)
	ELSE
		Set @Result=Cast(@ApiMessage as XML)


	-- Return the result of the function
	RETURN @Result
END

