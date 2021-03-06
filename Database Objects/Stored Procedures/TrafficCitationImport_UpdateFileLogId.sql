USE [OdyClerkInternal]
GO
/****** Object:  StoredProcedure [dbo].[TrafficCitationImport_UpdateFileLogId]    Script Date: 8/11/2020 11:31:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =====================================================================================================
-- Author:		Tarig Mudawi
-- Create date: 07/02/2020
-- Description:	This Stored Procedure updats the fileLogId right after the SQL bulk copy operation.

-- ================================================================================================================

ALTER PROC [dbo].[TrafficCitationImport_UpdateFileLogId] @FileLogId int=NULL

AS

SET NOCOUNT ON
    
    -- Update FileLog Table with Status and Completion Time
	 --Update	OdyClerkInternal..TrafficCitation_Import 
	 --Set FileLogId= Case When FileLogId = '' Then @FileLogId
		--				 When FileLogId is null Then @FileLogId
		--			End
	 --Where FileLogId = '' or FileLogId is null

	 Update	OdyClerkInternal..TrafficCitation_Import 
	 Set FileLogId= @FileLogId
	 Where FileLogId = ''

	 Update	OdyClerkInternal..TrafficCitation_Import 
	 Set FileLogId= @FileLogId
	 Where FileLogId is null

	  Update	OdyClerkInternal..TrafficCitation_Import 
	 Set FileLogId= @FileLogId
	 Where FileLogId = 0

	 	 
SET NOCOUNT OFF


