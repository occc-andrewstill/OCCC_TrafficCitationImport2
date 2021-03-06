USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[fnNextBusinessDay]    Script Date: 8/11/2020 11:54:35 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =====================================================
-- Author:		Anthony Payne
-- Create date: 11/21/2012
-- Description:	Return next BusinessDay 
--			    Excluding Weekends and Court Holidays
-- =====================================================
ALTER FUNCTION [dbo].[fnNextBusinessDay]
(
	-- Add the parameters for the function here
	@StartDate Datetime
)
RETURNS  DateTime
AS
BEGIN
	Declare @NextBusinessDay DateTime
	Set @NextBusinessDay=@StartDate
	While @StartDate <= @NextBusinessDay
		  BEGIN	
			Set @NextBusinessDay = DATEADD(d,1,@NextBusinessDay)
			IF @NextBusinessDay Not In (SELECT [UnavailableDate] FROM [Justice].[dbo].[UnavailableTime] where CalendarResourceID = 439) 
									and DATENAME(WEEKDAY, @NextBusinessDay) NOT IN ('Saturday', 'Sunday')  
				BREAK
			ELSE
				CONTINUE
			END
	Return @NextBusinessDay

END

