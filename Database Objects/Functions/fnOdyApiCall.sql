USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[fnOdyApiCall]    Script Date: 8/11/2020 11:42:39 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER FUNCTION [dbo].[fnOdyApiCall](@Msg [nvarchar](max), @Transaction [bit] = False)
RETURNS [nvarchar](max) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [OdyApiCLR].[OdySqlCLR.UserDefinedFunctions].[ApiCall]