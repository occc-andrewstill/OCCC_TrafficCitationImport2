USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[fnOdyApi_AddDocument]    Script Date: 8/11/2020 11:36:25 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- ============================================================================
-- Author:		Tarig Mudawi / Anthony Payne
-- Create date: 1/21/2014
-- Description:	This function can be used to Build and\or Execute
--				the Odyssey AddDocument API Message
--				@Execute=FALSE Returns Request XML
--				@Execute=TRUE Returns Api Web Service Call Response XML
-- ============================================================================
ALTER FUNCTION [dbo].[fnOdyApi_AddDocument]
	 (@Execute bit,
	  @ReferenceNumber varchar(10)=1,
	  @MessageUserId varchar(10),
	  @EffectiveDate varchar(10),
	  @NodeID  varchar(10),
	  @DocumentName  varchar(50),
	  @CaseType   varchar(20)=NULL,
	  @sFolder    varchar(100),
	  @DocType	varchar(100)=NULL  
	  )
RETURNS XML
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result XML, @ApiMessage varchar(max), @MessageText varchar(max)
	
	--Select @DocType = 'NFHPTR'
	IF @DocType IS NULL
		BEGIN
				Select @DocType = CASE 
                        WHEN @NodeID = '601'  AND @CaseType = 'TINF' THEN 'NAUTCTR'
                        WHEN @NodeID = '601'  AND @CaseType = 'CTT' THEN 'NAUTCCT' 
                        WHEN @NodeID = '602'  AND @CaseType = 'TINF' THEN 'OCPDTR'
                        WHEN @NodeID = '602'  AND @CaseType = 'CTT' THEN 'OCPDCT' 
                        WHEN @NodeID = '603'  AND @CaseType = 'TINF' THEN 'UTCTR'
                        WHEN @NodeID = '603'  AND @CaseType = 'CTT' THEN 'UTCCT'
                        WHEN @NodeID = '604'  AND @CaseType = 'TINF' THEN 'UTCTR'
                        WHEN @NodeID = '604'  AND @CaseType = 'CTT' THEN 'UTCCT'
						-- Added for CFX
						WHEN @NodeID = '603'  AND @CaseType = 'TINFRT' THEN 'TOLLEXP'
						
                    END  
		END
		
 --from Operations..uCode WHERE Code ='NFHPTR' and CacheTableID =15


		Set @ApiMessage='<Message MessageType="AddDocument" NodeID="'+@NodeID+'" ReferenceNumber="'+@ReferenceNumber+'" UserID="'+@MessageUserId+'" Source="Tyler">'
		Set @ApiMessage=@ApiMessage+'<UNCPath>'+@sFolder+'\'+@DocumentName+'.pdf</UNCPath>'	
		Set @ApiMessage=@ApiMessage+'<DocumentType>'+@DocType+'</DocumentType>'
		Set @ApiMessage=@ApiMessage+'<EffectiveDate>'+@EffectiveDate+'</EffectiveDate>'
		Set @ApiMessage=@ApiMessage+'<DocumentName>'+@DocumentName+'</DocumentName>'
		--Set @ApiMessage=@ApiMessage+'<DocumentName>'+@DocumentName+'.PDF</DocumentName>'
		Set @ApiMessage=@ApiMessage+'</Message>'
 
	IF @Execute='TRUE'
		Set @Result=dbo.fnOdyApiCall(@ApiMessage,Default)
	ELSE
		Set @Result=Cast(@ApiMessage as XML)
		-- Set @Result=@ApiMessage
		
	RETURN @Result
	
END


