USE [OdyClerkInternal]
GO
/****** Object:  StoredProcedure [dbo].[TrafficCitationImport_SendFailedToQueue_Retry]    Script Date: 8/11/2020 11:29:22 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================================================
-- Author:		Anthony Payne 
-- Modified by: Tarig Mudawi -- 10/20/2017
-- Create date: 05/10/2014
-- Description:	Procedure to Retry sending Failed Citations to Queues
             
-- =================================================================================
ALTER PROCEDURE [dbo].[TrafficCitationImport_SendFailedToQueue_Retry] 
AS
BEGIN
	 SET NOCOUNT ON 
	
		Declare @UserId int,@DocType varchar(100),@DocName varchar(100),@CaseType varchar(50),
		@NodeId varchar(10),@ImagePath varchar(500),@Reason varchar(max),@CitationType varchar(50),
		@ApiResponse XML,@QueDocName varchar(100),@DocId int,@DocVersionId int, @QueueItemId int,
		@WorkFlowQueueDocType varchar(100),@WorkFlowItemId int,@QueueId int,@TransactionTime DateTime,@ExceptionFlag int
		
		Set @UserId=(Select UserId from Operations.dbo.AppUser where LoginName='CitationImport')
		Set @TransactionTime=Getdate()
		
		Declare curFailedCitations Cursor For
		-- Updated the main select to work for retry T.M. 10/20/2017
			Select CitationNumber,CitationNumber,Citation.NodeID,
			Case CitationType 
					When 'UTC' THEN 'IMINF'
					When 'REDLIGHT' THEN 'IMRED'
					When 'TOLL' THEN 'IMTOLL'
					When 'CRIM' THEN 'IMCRI'
			End DocType,
			LocalPath+'\Processed' as LocalPath,ExceptionReason,CitationType,CaseType,ExceptionFlag,DocumentID,DocumentVersionId
			from OdyClerkInternal.dbo.TrafficCitation_Import Citation with (nolock)
			Join OdyClerkInternal.dbo.TrafficCitation_AgencyVendorInfo Vendor with (nolock) on Vendor.VendorAgencyId=Citation.VendorAgencyId
			Where Exceptionflag = 1  
			and WorkflowItemId IS NULL
			and Has_Image = 1
			and CitationNumber not in(Select CitationNumberSearch From  Justice.dbo.Citation with (nolock)) 
			and Citation.rundate > '10/03/2017'
		--and not exists
		--(select CitationNumber from OdyClerkInternal.dbo.TrafficCitationImport_ProdDirectoryCitations with (nolock)
  --                       where Sent_to_Traffic = 1
		--				 and Citation.CitationNumber = CitationNumber
		--				)
		order by RunDate
	
		
		OPEN curFailedCitations
		FETCH NEXT FROM curFailedCitations INTO @DocName,@QueDocName,@NodeId,@DocType,@ImagePath,@Reason,@CitationType,@CaseType,@ExceptionFlag,@DocId,@DocVersionId
		 WHILE @@FETCH_STATUS = 0
			 BEGIN
			 --WAITFOR DELAY '00:00:05'
			      -- Replace 2 for warnings with the parameter T.M. 4/24/2015 
			    IF @ExceptionFlag=2 SET @DocType='IMCIW' -- WARNING Queue ---
			    
				Set @QueueId=(Select CodeId from Operations.dbo.ucode with (nolock) where Code=@DocType and cachetableid=36) 
				Set @WorkFlowQueueDocType=(Select Description from Operations.dbo.ucode with (nolock) where Code=@DocType and cachetableid=15)	
				--Select @UserId,@DocName,@NodeId,@DocType,@ImagePath,@Reason,@CitationType
				
				
				IF @DocId IS NULL
					Begin
						Set @ApiResponse=OdyClerkInternal.dbo.fnOdyApi_AddDocument
								(1,1,@UserId,Cast(Cast(GetDate() as Date) as varchar(10)),@NodeId,@DocName,'TINF',@ImagePath,@DocType)
						
						--Select @ApiResponse
								
						--- Add Document to Odyssey
						SELECT @DocId = @ApiResponse.value('(/Result[1]/DocumentID[1])','VARCHAR(50)')
						SELECT @DocVersionId = @ApiResponse.value('(/Result[1]/VersionID[1])','VARCHAR(50)')
					    
						--Select @DocId,@DocVersionId
					End
				
			    
				IF Cast(@DocId as int) > 0
					BEGIN
						UPDATE OdyClerkInternal.dbo.TrafficCitation_Import 
						SET DocumentID=@DocId,DocumentVersionId=@DocVersionId
						WHERE CitationNumber=@DocName
							
						--- Add Document to Odyssey Queue		
						BEGIN TRY
							BEGIN TRANSACTION
								-- Create WorkFlow Item
									INSERT INTO [Operations].[dbo].[WorkFlowItem](Description,ItemTypeKey,
												[Priority],ItemData,ItemDataSearch)
									VALUES (Left(@Reason,60),'DOC',0,@QueDocName,Left(@Reason,100))
									Set @WorkFlowItemId=@@Identity
								
								--  Add Item to WorkFlowQueue	
									INSERT INTO [Operations].[dbo].[WorkFlowQueue]([WorkFlowQueueID],[ItemID],
												[StatusKey],[TimestampQueued],UserIdStatusChange)
									VALUES(@QueueID,@WorkFlowItemID,'PEND',@TransactionTime,@UserId)
									
								-- Add WorkFlow Transaction
									INSERT INTO [Operations].[dbo].[WorkFlowTrans]([ItemID],[WorkFlowQueueID],
												[StatusKey],[UserIDCreate],[TimestampCreate],Cmmnt)
									VALUES(@WorkFlowItemId,@QueueID,'PEND',@UserId,@TransactionTime,@Reason)
								
								-- Add WorkFlow Item Link	
									INSERT INTO [Operations].[dbo].[xWorkFlowItemLink] ([WorkFlowItemID],
												[WorkFlowItemLinkTypeKey],[LinkID])
									VALUES (@WorkFlowItemID,'DOC',@DocId)	
									
							COMMIT TRANSACTION		
						END TRY
						BEGIN CATCH
							ROLLBACK TRANSACTION
							--Print 'Error Occured, Transaction has been Rolled Back'
							--Declare @ErrMsg nvarchar(4000), @ErrSeverity int
							--Select @ErrMsg=ERROR_MESSAGE(), @ErrSeverity = ERROR_SEVERITY()
							--RAISERROR(@ErrMsg,@ErrSeverity,1)	
						END CATCH
						
						IF @WorkFlowItemId>0
							BEGIN
								UPDATE OdyClerkInternal.dbo.TrafficCitation_Import 
								SET WorkFlowItemId = @WorkFlowItemId WHERE CitationNumber = @DocName	
							END
					END		
					
			 FETCH NEXT FROM curFailedCitations INTO @DocName,@QueDocName,@NodeId,@DocType,@ImagePath,@Reason,@CitationType,@CaseType,@ExceptionFlag,@DocId,@DocVersionId
			 END
		
		CLOSE curFailedCitations
		DEALLOCATE curFailedCitations
		
		--Select @ApiResponse,@DocId,@QueueItemId	

	SET NOCOUNT OFF
    
END




