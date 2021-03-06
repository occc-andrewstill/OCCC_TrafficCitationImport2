USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[TrafficCitationImport_GetStatuteGroupID]    Script Date: 8/11/2020 11:49:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================================
-- Author:		Tarig Mudawi
-- Create date: 3/12/2014
-- Description:	This function takes a Statute and returns the Statute Group ID.
-- ==========================================================================================
ALTER FUNCTION [dbo].[TrafficCitationImport_GetStatuteGroupID](@Statute Varchar(100))
RETURNS INT --VARCHAR(10)
AS
BEGIN
DECLARE
@StatuteGroupID INT --VARCHAR(10)

SELECT @StatuteGroupID = StatuteGroupID FROM dbo.StatuteGroups
WHERE Statute = @Statute
    
       RETURN @StatuteGroupID 
END

