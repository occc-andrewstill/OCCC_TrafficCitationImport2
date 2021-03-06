USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[fnOdyApi_AddCriminalCase]    Script Date: 8/11/2020 11:35:26 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- ============================================================================
-- Author:		Anthony Payne \ Tarig Mudawi
-- Create date: 10/15/2013
-- Description:	This function can be used to Build and\or Execute
--				the Odyssey AddCriminalCase API Message
-- ============================================================================
ALTER FUNCTION [dbo].[fnOdyApi_AddCriminalCase]
	 (@Execute bit,
	  @NodeId varchar(5),
	  @ReferenceNumber varchar(10)=1,
	  @CaseType varchar(10),
	  @FileDate varchar (10),
	  @MessageUserId varchar(10),
	  @AssignmentDate varchar(10),
	  @StatusDate varchar(10),
	  @PartyId varchar(20),
	  @NameId varchar(50),
	  @AddDate varchar(20),
	  @OffenseDate varchar(20),
	  @BadgeNumber varchar(20),
	  @OffenseTime varchar(20),
	  @OfficerName varchar(100),
	  @Agency varchar(100),
	  @Jurisdiction varchar(100),
	  @StatuteCodeId varchar(10),
	  @StatuteCode varchar(50),
	  @sStatute    varchar(50),
	  @Degree varchar(100),
	  @SpeedActual varchar(20),
	  @SpeedLimit varchar(20),
	  @sHasOffenseFineProgramID char(1)
	  
	  )
RETURNS XML 
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result XML, @ApiMessage varchar(max), @MessageText varchar(max), @AdditionalTag varchar(1000)
	
	/***** If the Statute has offense fine program then pass the SpeedActual and SpeedLimit      T. Mudawi 1/6/2014 ******/
	If(@sHasOffenseFineProgramID = 'Y' AND @SpeedActual > 0 AND  @SpeedLimit > 0)
	   Select @AdditionalTag = '<Additional><FineCalculation><SpeedingFineCalculation><SpeedActual>'+@SpeedActual+'</SpeedActual><SpeedLimit>'+@SpeedLimit+'</SpeedLimit></SpeedingFineCalculation></FineCalculation></Additional>'
	Else
	   Select @AdditionalTag = ''

	Set @ApiMessage='<Message MessageType="AddCriminalCase" NodeID="'+@NodeId+'" ReferenceNumber="'+@ReferenceNumber+'" UserID="'+@MessageUserId+'" Source="Tyler">'
	Set @ApiMessage=@ApiMessage+'<CaseType>'+@CaseType+'</CaseType>'
	Set @ApiMessage=@ApiMessage+'<FileDate>'+@FileDate+'</FileDate>'
	Set @ApiMessage=@ApiMessage+'<AssignmentDate>'+@AssignmentDate+'</AssignmentDate>'
	Set @ApiMessage=@ApiMessage+'<JudgeAssignment>'
	Set @ApiMessage=@ApiMessage+	'<SystemAssignment/>'
	Set @ApiMessage=@ApiMessage+'</JudgeAssignment>'
	Set @ApiMessage=@ApiMessage+'<Status>'
	Set @ApiMessage=@ApiMessage+	'<Date>'+@StatusDate+'</Date>'
	Set @ApiMessage=@ApiMessage+	'<Comment>Case added via Automated Citation Service</Comment>'
	Set @ApiMessage=@ApiMessage+'</Status>'
	Set @ApiMessage=@ApiMessage+'<CaseParties>'
	Set @ApiMessage=@ApiMessage+	'<CaseParty>'
	Set @ApiMessage=@ApiMessage+		'<PartyID>'+@PartyId+'</PartyID>'
	Set @ApiMessage=@ApiMessage+		'<ConnectionType>DEFE</ConnectionType>'
	Set @ApiMessage=@ApiMessage+		'<AddDate>'+@AddDate+'</AddDate>'
	Set @ApiMessage=@ApiMessage+		'<NameID>'+@NameId+'</NameID>'
	Set @ApiMessage=@ApiMessage+	'</CaseParty>'
	Set @ApiMessage=@ApiMessage+'</CaseParties>'
	Set @ApiMessage=@ApiMessage+'<Charges>'
	Set @ApiMessage=@ApiMessage+	'<Charge>'
	Set @ApiMessage=@ApiMessage+		'<PartyID>'+@PartyId+'</PartyID>'
	Set @ApiMessage=@ApiMessage+		'<OffenseDate>'+@OffenseDate+'</OffenseDate>'
	Set @ApiMessage=@ApiMessage+		'<OffenseDateTo>'+@OffenseDate+'</OffenseDateTo>'
	Set @ApiMessage=@ApiMessage+		'<OffenseDateOnOrAbout>TRUE</OffenseDateOnOrAbout>'
	Set @ApiMessage=@ApiMessage+		'<OffenseTime>'+@OffenseTime+'</OffenseTime>'
	Set @ApiMessage=@ApiMessage+		'<OffenseTimeTo>'+@OffenseTime+'</OffenseTimeTo>'
	Set @ApiMessage=@ApiMessage+		'<OffenseTimeAtOrAbout>TRUE</OffenseTimeAtOrAbout>'
	Set @ApiMessage=@ApiMessage+		'<ChargeTrackSequence>1</ChargeTrackSequence>'
	Set @ApiMessage=@ApiMessage+		'<OffenseReport>'
	-- Remove the Agency Tag to make it work in Odyssey 2014
	--Set @ApiMessage=@ApiMessage+			'<Agency>'+@Agency+'</Agency>'
    Set @ApiMessage=@ApiMessage+				'<Officer>'
	Set @ApiMessage=@ApiMessage+				'<OfficerFreeText>'
	Set @ApiMessage=@ApiMessage+					'<BadgeNumber>'+@BadgeNumber+'</BadgeNumber>'
	Set @ApiMessage=@ApiMessage+					'<Name>'+@OfficerName+'</Name>'
	Set @ApiMessage=@ApiMessage+				'</OfficerFreeText>'
    Set @ApiMessage=@ApiMessage+				'</Officer>'
	Set @ApiMessage=@ApiMessage+		'</OffenseReport>'
	Set @ApiMessage=@ApiMessage+		'<CaseFiling>'
	Set @ApiMessage=@ApiMessage+			'<Number>1</Number>'
	Set @ApiMessage=@ApiMessage+			'<Jurisdiction>'+@Jurisdiction+'</Jurisdiction>'
	Set @ApiMessage=@ApiMessage+			'<FilingDate>'+@FileDate+'</FilingDate>'
	Set @ApiMessage=@ApiMessage+			'<Offense>'
	Set @ApiMessage=@ApiMessage+				'<Code CodeID="'+@StatuteCodeId+'" ReferenceID="'+@StatuteCode+'">'+@StatuteCode+'</Code>'
	Set @ApiMessage=@ApiMessage+				'<Degree>'+@Degree+'</Degree>'
	Set @ApiMessage=@ApiMessage+				'<Statute>'+@sStatute+'</Statute>'
	Set @ApiMessage=@ApiMessage+			'</Offense>'
	Set @ApiMessage=@ApiMessage+ @AdditionalTag                    
	--Set @ApiMessage=							 ISNULL(@ApiMessage+'<Additional><FineCalculation><SpeedingFineCalculation><SpeedActual>'+@SpeedActual+'</SpeedActual><SpeedLimit>'+@SpeedLimit+'</SpeedLimit></SpeedingFineCalculation></FineCalculation></Additional>',@ApiMessage)
	Set @ApiMessage=@ApiMessage+		'</CaseFiling>'
	Set @ApiMessage=@ApiMessage+	'</Charge>'
	Set @ApiMessage=@ApiMessage+'</Charges>'
    Set @ApiMessage=@ApiMessage+'</Message>'
	
	 
	IF @Execute='TRUE'
		Set @Result=Cast(@ApiMessage as XML)
		--Set @Result=dbo.fnOdyApiExec2(Cast(@ApiMessage as XML),Default)
	ELSE
		Set @Result=Cast(@ApiMessage as XML)

	-- Return the result of the function
	RETURN @Result
END

