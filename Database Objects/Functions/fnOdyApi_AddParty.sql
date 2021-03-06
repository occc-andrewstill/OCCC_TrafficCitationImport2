USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[fnOdyApi_AddParty]    Script Date: 8/11/2020 11:39:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- ============================================================================
-- Author:		Tarig Mudawi
-- Create date: 4/22/2015
-- Description:	This function is used to Add a new Party to Odyssey
--				@Execute=FALSE Returns Request XML
--				@Execute=TRUE Returns Api Web Service Call Response XML
-- ============================================================================
ALTER FUNCTION [dbo].[fnOdyApi_AddParty]
	 (@Execute bit,
	  @ReferenceNumber varchar(10)=1,
	  @MessageUserId varchar(10),
	  @FirstName varchar(100)=NULL,
	  @MiddleName varchar(100)=NULL,
	  @LastName varchar (100),
	  @BirthDate varchar(10),
	  @Gender varchar(10),
	  @Race varchar(20)=NULL,
	  @DLState varchar(50)=NULL,
	  @AddressLine1 varchar(255),
	  @City varchar(100),
	  @State varchar(100),
	  @ZipCode varchar(15), 
	  @AddressDiffLicense varchar(50)=NULL,
	  @CommercialVehicle varchar(100)
	  )
RETURNS XML
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result XML, @ApiMessage varchar(max), @MessageText varchar(max), @AddressTypeTag Varchar(4000), @ForeignDL Varchar(20), @CanadaDL Varchar(20), @MexecoDL Varchar(20),
	@StateNumber Varchar(20)
	
    /****** If Foreign Country (State value is 'FF') Then use Foreign Address Tag     T. Mudawi 2/7/2014 ******/
	If(@DLState = 'FF')
	Begin
	    SELECT @AddressTypeTag = '<Foreign><Line1>'+@AddressLine1+'</Line1><Line4>'+ISNULL(@City,'')+' '+ISNULL(@State,'')+' '+ISNULL(@ZipCode,'')+'</Line4></Foreign>'
	End
	Else If(@DLState = 'FF' AND @AddressDiffLicense = 'Y')
	Begin
		SELECT @AddressTypeTag = '<NonStandardUS><Line1>'+@AddressLine1+'</Line1><City>'+@City+'</City><State>'+@State+'</State><Zip>'+@ZipCode+'</Zip></NonStandardUS>'
	End
	Else If(@DLState = 'CD')
	Begin
	   SELECT @AddressTypeTag = '<NonStandardUS><Line1>'+@AddressLine1+'</Line1><City>'+@City+'</City><State>'+@State+'</State><Zip>'+@ZipCode+'</Zip></NonStandardUS>'
	End
	Else If(@DLState = 'MX')
	Begin
	   SELECT @AddressTypeTag = '<Foreign><Line1>'+@AddressLine1+'</Line1><Line2>'+@City+'</Line2><Line3>'+@State+'</Line3><Line4>'+@ZipCode+'</Line4></Foreign>'
	End
	Else
	Begin 
	    SELECT @AddressTypeTag = '<NonStandardUS><Line1>'+@AddressLine1+'</Line1><City>'+@City+'</City><State>'+@State+'</State><Zip>'+@ZipCode+'</Zip></NonStandardUS>'
	End
	
	
	-- Get the State Number
	SELECT @StateNumber = CodeID FROM Justice..uCode WHERE CacheTableID = 456 AND Code = @State
	
	
Set @ApiMessage='<Message MessageType="AddParty" Source="Tyler" NodeID="0" ReferenceNumber="'+@ReferenceNumber+'" UserID="'+@MessageUserId+'">'
	--Set @ApiMessage=@ApiMessage+'<ConfigurationID>1</ConfigurationID>'
	

--Set @ApiMessage=@ApiMessage+'<Name>'
--	Set @ApiMessage=@ApiMessage+   '<Person>'
--    Set @ApiMessage=@ApiMessage+     '<First>'+@FirstName+'</First>'
--	Set @ApiMessage=				  ISNULL(@ApiMessage+'<Middle>'+@MiddleName+'</Middle>',@ApiMessage)
--    Set @ApiMessage=@ApiMessage+     '<Last>'+@LastName+'</Last>'
--    Set @ApiMessage=@ApiMessage+   '</Person>'
--	Set @ApiMessage=@ApiMessage+'</Name>'

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

	Set @ApiMessage=@ApiMessage+'<DateOfBirth>'+@BirthDate+'</DateOfBirth>'
	Set @ApiMessage=@ApiMessage+'<Address>'
	Set @ApiMessage=@ApiMessage+@AddressTypeTag
	Set @ApiMessage=@ApiMessage+'</Address>'
	Set @ApiMessage=@ApiMessage+'<StateID><Number>'+@StateNumber+'</Number><State>'+@State+'</State></StateID>'
    Set @ApiMessage=@ApiMessage+'<Gender>'+@Gender+'</Gender>'
    Set @ApiMessage=@ApiMessage+'<Race>'+@Race+'</Race>'
    Set @ApiMessage=@ApiMessage+'</Message>'

	 
	IF @Execute='TRUE'
		Set @Result=dbo.fnOdyApiCall(@ApiMessage,Default)
	ELSE
		Set @Result=Cast(@ApiMessage as XML)


	-- Return the result of the function
	RETURN @Result
END

