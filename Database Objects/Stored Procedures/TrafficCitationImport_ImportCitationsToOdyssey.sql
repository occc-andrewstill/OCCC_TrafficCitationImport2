USE [OdyClerkInternal]
GO
/****** Object:  StoredProcedure [dbo].[TrafficCitationImport_ImportCitationsToOdyssey]    Script Date: 8/11/2020 11:23:08 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Tarig Mudawi
-- Create date: 05/11/2020
-- Description:	FHP Citation Import Processing
--
-- =============================================
ALTER PROCEDURE [dbo].[TrafficCitationImport_ImportCitationsToOdyssey] @FileLogId int, @VendorAgencyId int, @LocalPath Varchar(1000)
		
AS
BEGIN
		
SET NOCOUNT ON

	DECLARE  @CitationType Varchar(100)

			Update OdyClerkInternal..TrafficCitation_ImportFileLog Set ProcessStatus='Imported' Where Filelogid=@FileLogId
			Update	OdyClerkInternal..TrafficCitation_Import Set FileLogId = NULL Where FileLogId = ''
			-- Update	OdyClerkInternal..TrafficCitation_Import Set FileLogId=@FileLogId,VendorAgencyId=@VendorAgencyId,Rundate=Getdate(),ExceptionFlag=0,Processed=0 Where FileLogId IS NULL

			Update	OdyClerkInternal..TrafficCitation_Import 
			Set FileLogId=@FileLogId,VendorAgencyId=@VendorAgencyId,Rundate=Getdate(),ExceptionFlag=0,Processed=0
			From OdyClerkInternal..TrafficCitation_Import tr, OdyClerkInternal..TrafficCitation_ImportFileLog tl
			Where tr.FileLogId = tl.FileLogId
			And tr.FileLogId = @FileLogId

			-- Get the Agenct Type to run the aproppriate velidation stored procedure T.M. 7/29/2015
			Select @CitationType = CitationType
			From OdyClerkInternal..TrafficCitation_AgencyVendorInfo
			Where VendorAgencyId = @VendorAgencyId
										
			-- Start Validation 
			--IF @FileLogId >0
			--	Begin
					Update OdyClerkInternal.dbo.TrafficCitation_ImportFileLog set ProcessStartTime=Getdate(),ProcessStatus='Validating' Where FileLogId=@FileLogId
					-- Modified the code to run the intended version of exception stored proc. T.M. 7/29/2015
					IF(@CitationType = 'UTC')
					Begin
							Execute OdyClerkInternal.dbo.TrafficCitationImport_Exceptions @FileLogId=@FileLogId, @LocalPath= @LocalPath
					End 
			
					Else IF(@CitationType = 'REDLIGHT')
					Begin
							Execute OdyClerkInternal.dbo.TrafficCitationImport_Exceptions_Red @FileLogId=@FileLogId, @LocalPath= @LocalPath
					End

					Else IF(@CitationType = 'TOLL')
					Begin
							Execute OdyClerkInternal.dbo.TrafficCitationImport_Exceptions_Toll @FileLogId=@FileLogId, @LocalPath= @LocalPath
					End
				--End  
										
END


