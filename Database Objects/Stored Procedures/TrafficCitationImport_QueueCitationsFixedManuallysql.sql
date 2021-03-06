USE [OdyClerkInternal]
GO
/****** Object:  StoredProcedure [dbo].[TrafficCitationImport_QueueCitationsFixedManually]    Script Date: 8/11/2020 11:25:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =====================================================================================================
-- Author:		Tarig Mudawi
-- Create date: 10/15/2013
-- Description:	This Stored Procedure execute each record from the Traffic Citation file
--              and calls functions to build and execute the API transaction.
--				This runs after we already flag all exceptions.
-- Updated:     9/8/2014 Added code fix Expiration date, DL Class and fix party match update.
--              Also modified code to update QueueStatus instead of ExceptionFlag.
--				09/11/2014 Anthony Payne - Updated Cursor Where Clause to include Warning Citations
-- Updated      04/24/2015 T. Mudawi - Added a call to TrafficCitationImport_SendFailedToQueue
--              to send only Warnings.
--              Also added fix for connection timeout situation.
-- Updated      5/5/2015 T.M. - Reset the warnings back to their original flag before Api error. 
-- Updated      05/08/2015 T.Mudawi Added a fix to restore warnings to their original Exception flags and Reasons 
--              after Api errors reprocessed.
-- Updated      05/08/2015 Added the AddParty to fix the issues with not matching a single party and the father son issue too.
-- Updated      7/15/2015 T.Mudawi - Get the Agency Type to determine if it is Red light, Toll or Regular.
-- Updated      10/1/2015 T.M. - Adding officer as Law Enforcement Officer to the case party tab.
-- Updated      03/17/2016 T.M. - Make sure the DLNUM is alphanumeric and not letters only like 'NONE'  
-- Updates      03/31/2016 Replace any two consecutive spaces with one space since it cause TCAT errors per Jaya
-- Update       06/01/2016 T.M. Update DL Number to NDL, DL State to FF and DL Type to Unknown for FL businesses red light
-- ================================================================================================================

ALTER PROC [dbo].[TrafficCitationImport_QueueCitationsFixedManually] @FileLogId int=NULL

AS

SET NOCOUNT ON

/****** Code for Citations fixed manually from WorkFlowQueue ******/
	UPDATE OdyClerkInternal..TrafficCitation_Import set QueueStatus = 4
	From OdyClerkInternal..TrafficCitation_Import TI 
	Join Operations..WorkFlowTrans Trans with (Nolock) on TI.WorkFlowItemId=Trans.ItemID 
	Where  Trans.StatusKey in ('COM','MOV','DEL')
	and TI.FileLogId=@FileLogId
		 
	 
SET NOCOUNT OFF


