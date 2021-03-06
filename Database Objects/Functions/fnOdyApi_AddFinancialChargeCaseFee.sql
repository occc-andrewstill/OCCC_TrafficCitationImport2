USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[fnOdyApi_AddFinancialChargeCaseFee]    Script Date: 8/11/2020 11:38:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ====================================================================================
-- Author:		Tarig Mudawi
-- Create date: 5/27/2014
-- Description:	This function is to assess a financial charge in the case fees financial
--				category in Odyssey, it uses the AddFinancialChargeCaseFee API Message.
-- =====================================================================================
ALTER FUNCTION [dbo].[fnOdyApi_AddFinancialChargeCaseFee]
(  
@Execute                BIT= FALSE,
@nNodeID                varchar(5),
@sUserID				VARCHAR(50),
@sReferenceNumber       VARCHAR(50),
@nCaseID				varchar(20),
@nPartyID               varchar(50),
@TransactionDate        varchar(50),
@sScheduleCode          VARCHAR(50),
@sFeeCode				VARCHAR(50),
@sAmount     			VARCHAR(50)
)
RETURNS XML
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result XML, @ApiMessage VARCHAR(MAX)
		

		Set @ApiMessage='<Message MessageType="AddFinancialChargeCaseFee" NodeID="'+@nNodeID+'" ReferenceNumber="'+@sReferenceNumber+'" UserID="'+@sUserID+'" Source="Tyler">'
		Set @ApiMessage=@ApiMessage+'<CaseID>'+@nCaseID+'</CaseID>'	
		Set @ApiMessage=@ApiMessage+'<PartyID>'+@nPartyID+'</PartyID>'
		Set @ApiMessage=@ApiMessage+'<TransactionDate>'+@TransactionDate+'</TransactionDate>'
		Set @ApiMessage=@ApiMessage+'<FeeSchedules><FeeSchedule>'
		Set @ApiMessage=@ApiMessage+'<ScheduleCode>'+@sScheduleCode+'</ScheduleCode>'
		Set @ApiMessage=@ApiMessage+'<Fees><Fee>'
		Set @ApiMessage=@ApiMessage+'<FeeCode>'+@sFeeCode+'</FeeCode>'   -- might need to add more fees
		Set @ApiMessage=@ApiMessage+'<Amount>'+@sAmount+'</Amount>'
		Set @ApiMessage=@ApiMessage+'</Fee></Fees>'
		Set @ApiMessage=@ApiMessage+'</FeeSchedule>'
		Set @ApiMessage=@ApiMessage+'</FeeSchedules>'
		Set @ApiMessage=@ApiMessage+'</Message>'
 
	IF @Execute='TRUE'
		Set @Result=dbo.fnOdyApiCall(@ApiMessage,Default)
	ELSE
		Set @Result=Cast(@ApiMessage as XML)
		
	RETURN @Result
	
END

