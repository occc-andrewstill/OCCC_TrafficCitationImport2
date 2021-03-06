USE [OdyClerkInternal]
GO
/****** Object:  StoredProcedure [dbo].[TrafficCitationImport_Update18PercentStatuteCode]    Script Date: 8/11/2020 11:30:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =====================================================================================
-- Author:		Tarig Mudawi
-- Create date: 12/16/2019
-- Description:	This stored procedure update the statute code for specific 18 percent 
--               statutes. 

-- =====================================================================================

ALTER PROC [dbo].[TrafficCitationImport_Update18PercentStatuteCode] @FileLogId varchar(20)
AS

BEGIN

SET NOCOUNT ON

	UPDATE dbo.TrafficCitation_Import
	   SET Code = Case
					When ((convert(int,t.ActualSpeed) - convert(int,t.PostedSpeed)) >= 6) AND ((convert(int,t.ActualSpeed) - convert(int,t.PostedSpeed)) <= 9) Then t.Statute + '-A6'
					When ((convert(int,t.ActualSpeed) - convert(int,t.PostedSpeed)) > 9) AND ((convert(int,t.ActualSpeed) - convert(int,t.PostedSpeed)) <= 14) Then t.Statute + '-A10'
					When ((convert(int,t.ActualSpeed) - convert(int,t.PostedSpeed)) > 14) AND ((convert(int,t.ActualSpeed) - convert(int,t.PostedSpeed)) <= 19) Then t.Statute + '-A15'
					When ((convert(int,t.ActualSpeed) - convert(int,t.PostedSpeed)) > 19) AND ((convert(int,t.ActualSpeed) - convert(int,t.PostedSpeed)) <= 29) Then t.Statute + '-A20'
					Else t.Statute + '-A'
				End
		FROM dbo.TrafficCitation_import t JOIN dbo.TrafficCitationImport_18Percent tp ON t.Statute = tp.Statute 
		WHERE t.ViolationCode = tp.ViolationCode 
		AND	(ISNULL(t.ViolationSchoolZone,'') = ISNULL(tp.SchoolZone,'') OR ISNULL(t.ViolationWorkersPresent,'') = ISNULL(tp.WorkZone,''))
		AND t.FileLogId = @FileLogId

	-- Updating the CodeId too T.M. 8/5/2020
	UPDATE dbo.TrafficCitation_Import
			SET StatuteCodeID = uc.CodeID
		FROM dbo.TrafficCitation_import t JOIN Justice.dbo.uCode uc ON uc.Code = t.Code
		WHERE t.FileLogId = @FileLogId

		
SET NOCOUNT OFF		

END	


-- exec TrafficCitationImport_Update18PercentStatuteCode @FileLogId = 333999

