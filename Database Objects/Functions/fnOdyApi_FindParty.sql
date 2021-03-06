USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[fnOdyApi_FindParty]    Script Date: 8/11/2020 11:40:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- ============================================================================
-- Author:		Anthony Payne
-- Create date: 11/05/2017
-- Description:	This function is used to Find Parties in Odyssey
--				@Execute=FALSE Returns Request XML
--				@Execute=TRUE Returns Api Web Service Call Response XML
-- ============================================================================
ALTER FUNCTION [dbo].[fnOdyApi_FindParty]
	 (@Execute bit=0,
	  @ReferenceNumber varchar(10)=1,
	  @MessageUserId varchar(10),
	  @FirstName varchar(100)=NULL,
	  @MiddleName varchar(100)=NULL,
	  @LastName varchar (100)=NULL,
	  @BirthDate varchar(10)=NULL,
	  @DLNumber varchar(50)=NULL,
	  @DLState varchar(50)=NULL,
	  @BusinessName varchar(100)=NULL,
	  @CitationNumber varchar(100)=NULL,
	  @CaseNumber varchar(100)=NULL
	  )
RETURNS XML
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result XML, @ApiMessage varchar(max), @MessageText varchar(max), @StateNumber int	
   
	-- Get the State Number
	SELECT @StateNumber = CodeID FROM Justice.dbo.uCode with (nolock) WHERE CacheTableID = 456 AND Code = @DLState
	
	
		Set @ApiMessage='<Message MessageType="FindParty" Source="Tyler" NodeID="0" ReferenceNumber="'+@ReferenceNumber+'" UserID="'+@MessageUserId+'">'
			--Set @ApiMessage=@ApiMessage+'<ConfigurationID>1</ConfigurationID>'
		Set @ApiMessage=@ApiMessage+	'<Options>
											 <PartyTypes>
														 <PartyType>CivDef</PartyType>  
														 <PartyType>CRDef</PartyType>
														 <PartyType>Complainant</PartyType>
														 <PartyType>CivPl</PartyType>
														 <PartyType>Other</PartyType>
															
											 </PartyTypes>'
											 --<EntityAssociationFilters>  
												--<CaseManagerCases>
												--	<Include>Active</Include>
												--</CaseManagerCases>
												--<Citations>
     							--					<Include>Active</Include>
												-- </Citations>
											 --</EntityAssociationFilters>'
			    Set @ApiMessage=@ApiMessage+'<MaxNumberOfResults>200</MaxNumberOfResults>'
				Set @ApiMessage=@ApiMessage+'</Options>'

			Set @ApiMessage=@ApiMessage+'<SearchCriteria>'
			Set @ApiMessage=@ApiMessage+'<Party>'
			
		   -- Set @ApiMessage=@ApiMessage+'<Soundex>true</Soundex>'
			
			IF (@FirstName IS NOT NULL and @LastName IS NOT NULL) or @BusinessName IS NOT NULL
				BEGIN
					Set @ApiMessage=@ApiMessage+'<Name>'
						IF (@FirstName IS NOT NULL and @LastName IS NOT NULL)
						Begin
							Set @ApiMessage=@ApiMessage+   '<Person>'
							Set @ApiMessage=@ApiMessage+     '<First>'+@FirstName+'</First>'
							Set @ApiMessage=				  ISNULL(@ApiMessage+'<Middle>'+@MiddleName+'</Middle>',@ApiMessage)
							Set @ApiMessage=@ApiMessage+     '<Last>'+@LastName+'</Last>'
							Set @ApiMessage=@ApiMessage+   '</Person>'
						End

					--Set @ApiMessage=ISNULL(@ApiMessage+'<Nickname><PartyNickname>true</PartyNickname></Nickname>',@ApiMessage)
					Set @ApiMessage=ISNULL(@ApiMessage+'<Business><BusinessName>'+ @BusinessName+'</BusinessName></Business>',@ApiMessage)
					Set @ApiMessage=@ApiMessage+'</Name>'
				END
			Set @ApiMessage=ISNULL(@ApiMessage+'<DateOfBirth>'+@BirthDate+'</DateOfBirth>',@ApiMessage)

			IF (@DLState IS NOT NULL and @DLNumber IS NOT NULL)
				BEGIN
					Set @ApiMessage=@ApiMessage+   '<DriversLicense>'
					Set @ApiMessage=@ApiMessage+		'<Number>'+@DLNumber+'</Number>'
					Set @ApiMessage=@ApiMessage+		'<DLState>'+@DLState+'</DLState>'
					Set @ApiMessage=@ApiMessage+   '</DriversLicense>'
				END

			Set @ApiMessage=@ApiMessage+'</Party>'
			--Set @ApiMessage=ISNULL(@ApiMessage+'<Business><Businessname>'+ @BusinessName+'</Businessname></Business>',@ApiMessage)
			Set @ApiMessage=@ApiMessage+'<IncludeResults>
											<DateofBirth>true</DateofBirth>
											<StateID>true</StateID>
											<DLNumber>true</DLNumber>
											<PersonID>true</PersonID>
											<Name>true</Name>
										</IncludeResults>'
			Set @ApiMessage=@ApiMessage+'</SearchCriteria>'
    
			Set @ApiMessage=@ApiMessage+'</Message>'

	 
	IF @Execute='TRUE'
		Set @Result=dbo.fnOdyApiCall(@ApiMessage,Default)
	ELSE
		Set @Result=Cast(@ApiMessage as XML)


	-- Return the result of the function
	RETURN @Result
END

