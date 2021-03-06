USE [OdyClerkInternal]
GO
/****** Object:  StoredProcedure [dbo].[TrafficCitationImport_UpdateJurisdiction]    Script Date: 8/11/2020 11:31:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =====================================================================================================
-- Author:		Tarig Mudawi
-- Create date: 10/15/2013
-- Description:	This Stored Procedure execute updates the jurisdiction
-- ================================================================================================================

ALTER PROC [dbo].[TrafficCitationImport_UpdateJurisdiction]

AS

SET NOCOUNT ON

UPDATE OdyClerkInternal..TrafficCitation_Import
SET jurisdictionNumberOdy = CASE 
                      WHEN JurisdictionNumber = '00' THEN '56'
                      Else JurisdictionNumber
                     End
WHERE jurisdictionNumberOdy IS NULL OR jurisdictionNumberOdy = ''
	 
SET NOCOUNT OFF


