USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[fnOdyApi_AddEventToCase]    Script Date: 8/11/2020 11:37:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  UserDefinedFunction [dbo].[fnOdyApi_AddEventToCase]    Script Date: 09/14/2014 22:39:03 ******/

-- ============================================================================
-- Author:		Tarig Mudawi
-- Create date: 9/8/2014
-- Description:	This function can be used to Build and\or Execute
--				the Odyssey AddCaseEvent API Message
--				@Execute=FALSE Returns Request XML
--				@Execute=TRUE Returns Api Web Service Call Response XML
-- ============================================================================
ALTER FUNCTION [dbo].[fnOdyApi_AddEventToCase]
	 (@Execute bit,
	  @ReferenceNumber		varchar(10)=1,
	  @MessageUserId		varchar(10),
	  @EventDate			varchar(10),
	  @NodeID				varchar(10),
	  @CaseID				varchar(50),
	  @CaseEventType		varchar(20)
	  )
RETURNS XML
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result XML, @ApiMessage varchar(max), @MessageText varchar(max)
		


		Set @ApiMessage='<Message MessageType="AddCaseEvent" NodeID="'+@NodeID+'" ReferenceNumber="'+@ReferenceNumber+'" UserID="'+@MessageUserId+'" Source="Tyler">'
		Set @ApiMessage=@ApiMessage+'<CaseID>'+@CaseID+'</CaseID>'	
		Set @ApiMessage=@ApiMessage+'<CaseEventType>'+@CaseEventType+'</CaseEventType>'
		Set @ApiMessage=@ApiMessage+'<Date>'+@EventDate+'</Date>'
		Set @ApiMessage=@ApiMessage+'</Message>'
 
	IF @Execute='TRUE'
		Set @Result=dbo.fnOdyApiCall(@ApiMessage,Default)
	ELSE
		Set @Result=Cast(@ApiMessage as XML)
		-- Set @Result=@ApiMessage
		
	RETURN @Result
	
END

