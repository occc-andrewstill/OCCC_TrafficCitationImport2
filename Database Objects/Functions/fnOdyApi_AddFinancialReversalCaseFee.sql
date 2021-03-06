USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[fnOdyApi_AddFinancialReversalCaseFee]    Script Date: 8/11/2020 11:39:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- ============================================================================
-- Author:		Tarig Mudawi
-- Create date: 5/27/2014
-- Description:	This function is to reverse a Financial Transaction
--				in Odyssey, it uses the AddFinancialReversalCaseFee API Message.
-- ============================================================================
ALTER FUNCTION [dbo].[fnOdyApi_AddFinancialReversalCaseFee]
(  
@Execute                BIT,
@nNodeID                INT,
@sUserID				VARCHAR(50),
@sReferenceNumber       VARCHAR(50),
@nReceiptID				INT,
@sTransactionDate       VARCHAR(50),
@sStation				VARCHAR(50),
@sTill					VARCHAR(50),
@Comment				VARCHAR(MAX)
)
RETURNS XML
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result XML, @ApiMessage VARCHAR(MAX)

		Set @ApiMessage='<Message MessageType="AddFinancialReversalCaseFee" NodeID="'+convert(varchar(10),@nNodeID)+'" ReferenceNumber="'+@sReferenceNumber+'" UserID="'+@sUserID+'" Source="Tyler">'
		Set @ApiMessage=@ApiMessage+'<ReceiptID>'+convert(varchar(20),@nReceiptID)+'</ReceiptID>'	
		Set @ApiMessage=@ApiMessage+'<TransactionDate>'+@sTransactionDate+'</TransactionDate>'
		Set @ApiMessage=@ApiMessage + 
			CASE 
				WHEN @sStation is null 
				THEN ''
				ELSE '<Station>'+@sStation+'</Station>'
			END
		Set @ApiMessage=@ApiMessage+
			CASE 
				WHEN @sTill is null
				THEN ''
				ELSE '<Till>'+@sTill+'</Till>'
			END
		Set @ApiMessage=@ApiMessage+'<Comment>'+@Comment+'</Comment>'
		Set @ApiMessage=@ApiMessage+'</Message>'
 
	IF @Execute='TRUE'
		Set @Result=dbo.fnOdyApiCall(@ApiMessage,Default)
	ELSE
		Set @Result=Cast(@ApiMessage as XML)
		
	RETURN @Result
	
END


