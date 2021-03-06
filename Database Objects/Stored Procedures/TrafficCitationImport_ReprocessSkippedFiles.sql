USE [OdyClerkInternal]
GO
/****** Object:  StoredProcedure [dbo].[TrafficCitationImport_ReprocessSkippedFiles]    Script Date: 8/11/2020 11:27:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =====================================================================================================
-- Author:		Tarig Mudawi
-- Create date: 10/15/2013
-- Description:	This Stored Procedure execute each record from the Traffic Citation file
-- Updated:
-- ================================================================================================================

ALTER PROC [dbo].[TrafficCitationImport_ReprocessSkippedFiles]

AS

DECLARE
@FileLogId int,
@CitationNumber varchar(50)

SET NOCOUNT ON


DECLARE CitationSkippedFile_Cur CURSOR FOR

   SELECT FileLogId
   FROM OdyClerkInternal.dbo.TrafficCitation_ImportFileLog
   WHERE FileDate = CONVERT(date, getdate())
   And RecordCount is not NULL
   And ProcessStartTime > CONVERT(date, getdate())
   And ProcessEndTime is NULL
   And ProcessStatus = 'Validating'
    
 OPEN CitationSkippedFile_Cur
  FETCH CitationSkippedFile_Cur
  INTO
  @FileLogId
      
     WHILE @@FETCH_STATUS = 0
     BEGIN

	        -- Create an inner cursor for each file to get the citations
			DECLARE Citation_Cur CURSOR FOR
			SELECT CitationNumber
			FROM OdyClerkInternal.dbo.TrafficCitation_Import
			WHERE CaseId IS NULL 
			And ExceptionFlag in (0,2,-1,-2)
			And (FileLogID = @FileLogId or Has_Image=1 ) -- This is to capture all API errors
			And (WorkFlowItemId IS NULL OR ExceptionFlag=2)
			And Processed=0 
			And CitationNumber NOT IN(SELECT CitationNumberSearch FROM Justice..Citation(Nolock))
			And Has_Image = 1

			OPEN Citation_Cur
			FETCH Citation_Cur
			INTO
			@CitationNumber

			WHILE @@FETCH_STATUS = 0
			BEGIN

				-- call the processing stored procedure for each skipped file
				Execute OdyClerkInternal.dbo.TrafficCitationImport_ProcessCitations @FileLogId= @FileLogId, @CitationNumber = @CitationNumber

			FETCH Citation_Cur
			INTO
			@CitationNumber

			END
			CLOSE Citation_Cur
			DEALLOCATE Citation_Cur

			 -- Update FileLog Table with Status and Completion Time
			 Update OdyClerkInternal..TrafficCitation_ImportFileLog 
			 Set ProcessStatus='Complete',ProcessEndTime=Getdate()
			 Where FileLogId=@FileLogId
				 
		FETCH CitationSkippedFile_Cur
		INTO
		@FileLogId
     
     END     
     CLOSE CitationSkippedFile_Cur    
     DEALLOCATE CitationSkippedFile_Cur 

SET NOCOUNT OFF