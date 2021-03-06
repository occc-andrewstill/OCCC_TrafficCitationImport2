USE [OdyClerkInternal]
GO
/****** Object:  StoredProcedure [dbo].[TrafficCitationImport_SendImagesToTraffic]    Script Date: 8/11/2020 11:29:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =====================================================================================
-- Author:		Tarig Mudawi, Anthony Payne
-- Create date: 7/20/2016
-- Description:	This stored procedure check the existance of the citation image in the directory
--              vs. the TrafficCitation_Import table and Odyssey database and flags all citations 
--              images without data or citations that failed with API error and send all of them 
--              to a network folder for Traffic team.

-- =====================================================================================

ALTER PROC [dbo].[TrafficCitationImport_SendImagesToTraffic] 
AS

BEGIN

SET NOCOUNT ON

-- SET ANSI_WARNINGS OFF

-------------------- New Code --------------------------------------------------------------------------------
Declare 
@Sql		Varchar(1000),
@AgencyName Varchar(100),
@LocalPath  Varchar(1000),
@CitationImageNumber  Varchar(50),
@Agency               Varchar(50),
@Destination_Folder Varchar(100),
@cmdstring         Varchar(1000),
@Error_Msg         Varchar(Max)

-- First Loop through the TrafficCitation_AgencyVendorInfo table to get the path and agency name
   Declare Agency_ImageFile_And_CreateDate_Cur Cursor For
	Select Distinct
	AgencyName,
	LocalPath +'\Processed\'
	From OdyClerkInternal.dbo.TrafficCitation_AgencyVendorInfo
	Where Active = 1
	And LocalPath not like '%CTSNonFHP%'

	Union

	Select Distinct
	'CTSNonFHP',
	LocalPath +'\Processed\'
	From OdyClerkInternal.dbo.TrafficCitation_AgencyVendorInfo
	Where Active = 1
	And LocalPath like '%CTSNonFHP%'

	Open Agency_ImageFile_And_CreateDate_Cur

	Fetch Agency_ImageFile_And_CreateDate_Cur
	Into
	@AgencyName,
	@LocalPath

	WHILE @@FETCH_STATUS = 0
    BEGIN

		 Set @Sql = 'Insert into TrafficCitationImport_ProdDirectoryCitations(CitationImageNumber, depth, Isfile) EXEC master.sys.xp_dirtree '+''''+@LocalPath+''',1,1;'

		 Exec(@Sql)	

		 Update TrafficCitationImport_ProdDirectoryCitations set Agency = @AgencyName, Date_Received = CONVERT(VARCHAR(10), cast(GETDATE() as date), 101)
		 where Agency is null

		  -- Keep only pdf images
		  delete from TrafficCitationImport_ProdDirectoryCitations Where Isfile != 1 Or depth != 1 -- Or Right(CitationImageNumber,3) != 'PDF' 

		  -- Call the GetDirectoryFilenamesWithCreationDates to get the Create date for the eacg agency image files
		  Exec dbo.TrafficCitationImport_GetDirectoryFilenamesWithCreationDates @LocalPath

		  				 /********* Start the process of moving images from mapp01 folder to Traffic folder ***********/
				 
						Declare Send_Images_to_Traffic Cursor For
						-- Citations in directory but not in Odyssey or the citation import table
						Select
						CitationImageNumber,
						Agency
						From TrafficCitationImport_ProdDirectoryCitations t (Nolock)
						Where Not Exists(Select CitationNumberSearch from Justice.dbo.Citation with (Nolock) where CitationNumberSearch = t.CitationNumber )
						and Not Exists (select CitationNumber from OdyClerkInternal.dbo.TrafficCitation_Import with (Nolock) where CitationNumber = t.CitationNumber)
						and Agency = @AgencyName
						and Sent_to_Traffic is null
						and CAST(FileCreateDate As Date) <= CAST(GetDate()- 10 As Date)
						and Right(CitationImageNumber, 3) = 'pdf'
						
						Union

						-- Citations in the directory and the citation import table but not in Odyssey
						Select 
						CitationImageNumber,
						Agency
						From TrafficCitationImport_ProdDirectoryCitations (Nolock)
						Where CitationNumber in(select CitationNumber from OdyClerkInternal.dbo.TrafficCitation_Import with (Nolock)
				                              where CitationNumber not in(Select CitationNumberSearch from Justice.dbo.Citation with (Nolock))
                                              and WorkFlowItemId is null)
						and Agency = @AgencyName
						and Sent_to_Traffic is null
						and Right(CitationImageNumber, 3) = 'pdf'
				        --and CAST(FileCreateDate As Date) <= CAST(GetDate()- 10 As Date)


						 Open Send_Images_to_Traffic

						 Fetch Send_Images_to_Traffic
						 into 
						 @CitationImageNumber,
						 @Agency

						 WHILE @@FETCH_STATUS = 0
						 BEGIN

							-- Set @LocalPath = @LocalPath + '\' + @CitationImageNumber						    							

							-- set @cmdstring = 'copy ' + @LocalPath + @CitationImageNumber +' '+ 'C:\TrafficImages\'+ @CitationImageNumber

							set @cmdstring = 'copy ' + @LocalPath + @CitationImageNumber +' '+ '\\cwpmapp01.myorangeclerk.net\SSISTempData\CitationImport\TrafficImages\'+ @CitationImageNumber

							

							begin try

									exec master..xp_cmdshell @cmdstring 

										--- Update Date_Received and Sent_to_Traffic for records that are 10 days or older
											Update  TrafficCitationImport_ProdDirectoryCitations 
                                            set Sent_to_Traffic = 1,
                                            Reason =  'No Data File',
                                            Date_Sent_to_Traffic = GetDate()
                                            Where Not Exists(Select CitationNumberSearch from Justice.dbo.Citation with (Nolock) 
															  where CitationNumberSearch = TrafficCitationImport_ProdDirectoryCitations.CitationNumber )
                                                              and Not Exists (select CitationNumber from OdyClerkInternal.dbo.TrafficCitation_Import with (Nolock)
																			   where CitationNumber = TrafficCitationImport_ProdDirectoryCitations.CitationNumber)
                                                                               and FileCreateDate <= (GetDate() - 10)


										Update  TrafficCitationImport_ProdDirectoryCitations
										set Sent_to_Traffic = 1,
											Reason = 'API Error',
											Date_Sent_to_Traffic = GetDate()
											Where CitationNumber in(select CitationNumber from OdyClerkInternal.dbo.TrafficCitation_Import with (Nolock)
																						 where CitationNumber not in(Select CitationNumberSearch from Justice.dbo.Citation with (Nolock))
																						 and WorkFlowItemId is null)
											-- and FileCreateDate <= (GetDate() - 10)
											 and CitationImageNumber = @CitationImageNumber

							end try
							begin catch
							        Set @Error_Msg = @@ERROR

							        Update  TrafficCitationImport_ProdDirectoryCitations
									set ErrorMessage = @Error_Msg
									where CitationImageNumber = @CitationImageNumber
							end catch


						 Fetch Send_Images_to_Traffic
						 into 
						 @CitationImageNumber,
						 @Agency

						 END

					Close Send_Images_to_Traffic
					Deallocate Send_Images_to_Traffic



	Fetch Agency_ImageFile_And_CreateDate_Cur
	Into
	@AgencyName,
	@LocalPath

	END

	Close Agency_ImageFile_And_CreateDate_Cur
	Deallocate Agency_ImageFile_And_CreateDate_Cur


SET NOCOUNT OFF	

-- SET ANSI_WARNINGS ON


END	


-----

-- exec dbo.TrafficCitationImport_SendImagesToTraffic_2
