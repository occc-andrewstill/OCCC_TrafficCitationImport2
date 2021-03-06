USE [OdyClerkInternal]
GO
/****** Object:  StoredProcedure [dbo].[TrafficCitationImport_GetDirectoryFilenamesWithCreationDates]    Script Date: 8/11/2020 11:21:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ==============================================================================================================
-- Author:		Tarig Mudawi
-- Create date: 7/26/2017
-- Description:	This takes the path as a parameter and returns a table of all filenames with their creation dates 

-- ================================================================================================================
ALTER PROC [dbo].[TrafficCitationImport_GetDirectoryFilenamesWithCreationDates] @PathName Varchar(1000)

AS

SET NOCOUNT ON

		-- List all files in a directory - T-SQL parse string for date and filename 
		-- Microsoft SQL Server command shell statement - xp_cmdshell
		DECLARE  @CMD            VARCHAR(512) 

		-- Drop temp tables if they already exist
		IF OBJECT_ID('tempdb..#CommandShell') IS NOT NULL
			   DROP TABLE #CommandShell

		IF OBJECT_ID('tempdb..#CommandShell_2') IS NOT NULL
			   DROP TABLE #CommandShell_2

		IF OBJECT_ID('tempdb..#CommandShell_3') IS NOT NULL
			   DROP TABLE #CommandShell_3


		CREATE TABLE #CommandShell ( Line VARCHAR(512)) 
 
 
		SET @CMD = 'DIR ' + @PathName + ' /TW' 
 
		PRINT @CMD -- test & debug
		-- DIR F:\data\download\microsoft /TC


		-- MSSQL insert exec - insert table from stored procedure execution
		INSERT INTO #CommandShell 
		EXEC MASTER..xp_cmdshell   @CMD 
 
		-- Delete lines not containing filename
		DELETE 
		FROM   #CommandShell 
		WHERE  Line NOT LIKE '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9] %' 
		OR Line LIKE '%<DIR>%'
		OR Line is null

		-- SQL reverse string function - charindex string function 
		SELECT 
		  FileName = REVERSE( LEFT(REVERSE(Line),CHARINDEX(' ',REVERSE(line))-1 ) ),
		  CreateDate = LEFT(Line,20) 
		INTO #CommandShell_2
		FROM #CommandShell
		ORDER BY FileName

		-- get only the PDF images
		SELECT * INTO #CommandShell_3 from #CommandShell_2 
		-- WHERE FileName LIKE '%.pdf'

		-- SELECT * FROM #CommandShell_3

		--- Update the TrafficCitationImport_ProdDirectoryCitations with the file create date
		Update dbo.TrafficCitationImport_ProdDirectoryCitations
		Set FileCreateDate = c.CreateDate
		From dbo.TrafficCitationImport_ProdDirectoryCitations t, #CommandShell_3 c
		Where t.CitationImageNumber = c.FileName


SET NOCOUNT ON

-------------

-- exec GetDirectoryFilenamesWithCreationDates '\\cwtmeaa01\CitationImport2$\AllPDFs'

--select  c.CreateDate
--		From dbo.TrafficCitationImport_ProdDirectoryCitations t, #CommandShell_3 c
--		Where t.CitationImageNumber = c.FileName
--		and t.Agency = 'Unmatch'