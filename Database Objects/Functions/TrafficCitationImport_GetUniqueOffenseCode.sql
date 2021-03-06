USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[TrafficCitationImport_GetUniqueOffenseCode]    Script Date: 8/11/2020 11:50:24 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================================
-- Author:		Tarig Mudawi
-- Create date: 3/11/2014
-- Description:	This function takes a Statute, Violation Code and Base Fine as arguments
--              and returns the correct Offense Code.
-- ==========================================================================================
ALTER FUNCTION [dbo].[TrafficCitationImport_GetUniqueOffenseCode](@Statute Varchar(100), @ViolationCode Varchar(50), @BaseFine Varchar(50), @BAL Varchar(50))
RETURNS VARCHAR(100)
AS
BEGIN
DECLARE
@OffenseCode Varchar(100),
@Description Varchar(1000)

SELECT @Description = Description FROM Justice..uCode uc JOIN Justice..uOff uo (NOLOCK) ON uc.CodeID = uo.OffenseID
WHERE uo.Statute = @Statute

IF(@Statute = '316.215' AND @ViolationCode = '137')
    SELECT @OffenseCode = '316.215-B'
ELSE IF(@Statute = '316.221' AND @ViolationCode = '137')
    SELECT @OffenseCode = '316.221-A'  
ELSE IF(@Statute = '316.061(2)' AND @ViolationCode = '400')
    SELECT @OffenseCode = '316.061(2)' 
ELSE IF(@Statute = '316.074(1)' AND @ViolationCode = '532')
    SELECT @OffenseCode = '316.074(1)-D' 
ELSE IF(@Statute = '316.074(1)' AND @ViolationCode = '547')
    SELECT @OffenseCode = '316.074(1)-C' 
ELSE IF(@Statute = '316.075(1)(C)1' AND @ViolationCode = '547')
    SELECT @OffenseCode = '316.075(1)(C)1-F'
ELSE IF(@Statute = '316.1925(1)' AND @ViolationCode = '455')
    SELECT @OffenseCode = '316.1925(1)'
ELSE IF(@Statute = '316.1926(2)' AND @ViolationCode = '589' AND (@Description LIKE '%2ND OFFENSE%' OR @Description LIKE '%SECOND OFFENSE%')  )
    SELECT @OffenseCode = '316.1926(2)-A'   
ELSE IF(@Statute = '316.1926(2)' AND @ViolationCode = '589' AND (@Description LIKE '%1ST OFFENSE%' OR @Description LIKE '%FIRST OFFENSE%') )
    SELECT @OffenseCode = '316.1926(2)' 
ELSE IF(@Statute = '316.2085(2)' AND @ViolationCode = '192' AND (@BaseFine = '1000.00' OR @BaseFine = '1104.00') )
    SELECT @OffenseCode = '316.2085(2)'    
ELSE IF(@Statute = '316.2085(2)' AND @ViolationCode = '192' AND (@BaseFine = '2500.00' OR @BaseFine = '2604.00') )
    SELECT @OffenseCode = '316.2085(2)-A'      
ELSE IF(@Statute = '316.2085(3)' AND @ViolationCode = '590' AND (@BaseFine = '1000.00' OR @BaseFine = '1104.00') )
    SELECT @OffenseCode = '316.2085(3)'   
ELSE IF(@Statute = '316.2085(3)' AND @ViolationCode = '590' AND (@BaseFine = '2500.00' OR @BaseFine = '2604.00') )
    SELECT @OffenseCode = '316.2085(3)-A'        
ELSE IF(@Statute = '316.061(1)' AND @ViolationCode = '313')
    SELECT @OffenseCode = '316.061(1)-A'   
ELSE IF(@Statute = '316.061(1)' AND @ViolationCode = '318')
    SELECT @OffenseCode = '316.061(1)-B'    
ELSE IF(@Statute = '316.193(4)' AND @ViolationCode = '647' AND @BAL >= '0.15' AND @BAL < '0.20')
    SELECT @OffenseCode = '316.193(4)-4'    
ELSE IF(@Statute = '316.193(4)' AND @ViolationCode = '647' AND @BAL >= '0.20')
    SELECT @OffenseCode = '316.193(4)-A' 
     
       RETURN @OffenseCode 
END



