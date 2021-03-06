USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[TrafficCitationImport_GetLicenseExpirationDate]    Script Date: 8/11/2020 11:49:25 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- ============================================================================
-- Author:		Tarig Mudawi
-- Create date: 5/15/2014
-- Description:	This function takes a driver license number and returns an expiration date 
--              from DLLookup table.
-- ============================================================================
ALTER FUNCTION [dbo].[TrafficCitationImport_GetLicenseExpirationDate]
(@DLNUmber VARCHAR(50))
RETURNS VARCHAR(50)
AS
BEGIN
    
    DECLARE @DLExpirationDate VARCHAR(50)
    SELECT @DLExpirationDate = DLExpiration FROM Justice..DLLookup WHERE DLNumber = @DLNUmber
    SELECT @DLExpirationDate = CONVERT(VARCHAR(20),DATEPART(mm,@DLExpirationDate))+'/'+CONVERT(VARCHAR(20),DATEPART(dd,@DLExpirationDate))+'/'+CONVERT(VARCHAR(20),DATEPART(YYYY,@DLExpirationDate))

    RETURN @DLExpirationDate
END



