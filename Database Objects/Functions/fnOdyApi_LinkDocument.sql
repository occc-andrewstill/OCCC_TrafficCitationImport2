USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[fnOdyApi_LinkDocument]    Script Date: 8/11/2020 11:41:18 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- ============================================================================
-- Author:		Tarig Mudawi / Anthony Payne
-- Create date: 3/7/2014
-- Description:	This function can be used to Build and\or Execute
--				the Odyssey LinkDocument API Message
--				@Execute=FALSE Returns Request XML
--				@Execute=TRUE Returns Api Web Service Call Response XML
-- ============================================================================
ALTER FUNCTION [dbo].[fnOdyApi_LinkDocument]
	 (@Execute bit,
	  @ReferenceNumber varchar(50)=1,
	  @MessageUserId varchar(50),
	  @DocumentID varchar(50),
	  @EntityID varchar(50)	  
	  )
RETURNS XML
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result XML, @ApiMessage varchar(max), @MessageText varchar(max), @DocType varchar(20)

Set @ApiMessage='<Message MessageType="LinkDocument" NodeID="1" ReferenceNumber="'+@ReferenceNumber+'" UserID="'+@MessageUserId+'" Source="Tyler">'
Set @ApiMessage=@ApiMessage+'<DocumentID>'+@DocumentID+'</DocumentID>'
Set @ApiMessage=@ApiMessage+'<Entities><Entity><EntityType>Event</EntityType><EntityID>'+@EntityID+'</EntityID></Entity></Entities>'
Set @ApiMessage=@ApiMessage+'</Message>'

	 
	IF @Execute='TRUE'
		Set @Result=dbo.fnOdyApiCall(@ApiMessage,Default)
	ELSE
		Set @Result=Cast(@ApiMessage as XML)
		
	RETURN @Result
END

