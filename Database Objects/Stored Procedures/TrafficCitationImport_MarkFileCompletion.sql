USE [OdyClerkInternal]
GO
/****** Object:  StoredProcedure [dbo].[TrafficCitationImport_MarkFileCompletion]    Script Date: 8/11/2020 11:23:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =====================================================================================================
-- Author:		Tarig Mudawi
-- Create date: 05/15/2020
-- Description:	This Stored Procedure marks to completion of data file processing by providing the datatime of 
--              file completion.

-- ================================================================================================================

ALTER PROC [dbo].[TrafficCitationImport_MarkFileCompletion] @FileLogId int=NULL

AS

SET NOCOUNT ON
    
    -- Update FileLog Table with Status and Completion Time
	 Update OdyClerkInternal..TrafficCitation_ImportFileLog 
	 Set ProcessStatus='Complete',ProcessEndTime=Getdate()
	 Where FileLogId=@FileLogId
	 
	 
SET NOCOUNT OFF


