using System;
using System.Collections.Generic;
using TrafficCitationImport2.DAL;
using TrafficCitationImport2.Models;
using NLog;
using System.Data.SqlClient;

namespace TrafficCitationImport2.BLL
{
	class TaskManager
	{
		private static Logger log = LogManager.GetCurrentClassLogger();

		//string LastServer = "";
		public void Run()
		{
			log.Info("Begin Run...");
			List<VendorsInfo> vendors = null;
			try
			{
				log.Debug("Retrieving list of agencies");
				VendorUtility vu = new VendorUtility();
				vendors = vu.GetVendorList();
				log.Debug("Total agencies retrieved: [" + vendors.Count + "]");

				//var allDataFiles = new List<string>();

				foreach (var vendor in vendors)
				{

					log.Debug("Beginning file processing for agency [" + vendor.AgencyName + "]");
					try
					{
						//Start by archiving all files older than 15 days in the Processed folder to Processed_Archive
						ArchiveOldProcessedFiles archiveOldProcessedFiles = new ArchiveOldProcessedFiles();
						archiveOldProcessedFiles.ArchiveProcessedFiles(vendor.LocalPath + "\\" + "Processed", vendor.LocalPath + "\\" + "Processed_Archive");

						IDownloadUtility download = GetTransferObject(vendor);

						//Get list of files to transfer from vendor
						List<string> listOfRemoteFiles = download.GetVendorRemoteFileList(vendor);
						vendor.RemoteFileList = listOfRemoteFiles;

						TransferVendorFiles(download, vendor);

						// calling the UnzipFile
						CitationUnzip unzip = new CitationUnzip();						
						unzip.UnzipFile(vendor, vendor.LocalPath);
						
						// Calling the rename functionality
						CitationRename cr = new CitationRename();
						cr.CitationImageRename(vendor, vendor.LocalPath);

						// Stamp the citation image
						CitationImageStamp cimg = new CitationImageStamp();
						cimg.ImageStamp(vendor);
					}

					catch (Exception exp)
					{
						log.Error(exp, "A file processing error has occurred");
					}
				}

				var allDataFiles = new List<string>();

				foreach (var vendor in vendors)
				{

					log.Debug("About to transfer files for vendor [" + vendor.VendorName + "]");
					try
					{
						// Get the date file 
						CitationDataFile getDataFile = new CitationDataFile();
						allDataFiles = getDataFile.DataFileName(vendor, vendor.LocalPath);

						// Inserting data file into ImportFileLog table
						InsertDataFile dataFile = new InsertDataFile();

						foreach (string dataFileName in allDataFiles)
						{
							log.Debug("Begin ImportFileLog_Insert for agency: " + vendor.AgencyName);
							dataFile.ImportFileLog_Insert(dataFileName, vendor.VendorAgencyId);
							log.Debug("End ImportFileLog_Insert for agency: " + vendor.AgencyName);

							FileLogId fileLogId = new FileLogId();
							string fileId = fileLogId.GetFileLogId(dataFileName);

							PCBDataFiles pcbDataFiles = new PCBDataFiles();
							log.Debug("Begin PCBDataFile for agency: " + vendor.AgencyName);
							pcbDataFiles.PCBDataFile(vendor, dataFileName, fileId);
							log.Debug("End PCBDataFile for agency: " + vendor.AgencyName);

						}
					}
					catch (Exception exp)
					{
						log.Error(exp, "Failed to delete file for agency [" + vendor.AgencyName + "]");
					}
				}

				// Move this to before the marking of images
				foreach (var vendor in vendors)
				{
					try
					{
						// Save old files to archive and processed folders
						SaveOldFiles saveFiles = new SaveOldFiles();
						saveFiles.SaveFiles(vendor);

						// Finally delete old files from parent folder for each agency
						log.Debug("Deleting files for agency [" + vendor.AgencyName + "]");
						DeleteOldFiles deleteFiles = new DeleteOldFiles();
						deleteFiles.DeleteFiles(vendor);
					}
					catch (Exception exp)
					{
						log.Error(exp, "Failed to delete file for agency [" + vendor.AgencyName + "]");
					}
				}

				VendorsInfo pre_vendor = null;

				// Marking of images starts here.
				foreach (var vendor in vendors)
				{

					log.Debug("About to transfer files for agency [" + vendor.AgencyName + "]");
					try
					{
						// Validate images between agencies folders and TrafficCitation_Import table
						ValidateImage vi = new ValidateImage();

						string folder = vendor.LocalPath + "\\Processed";

						List<ImageDetail> images = vi.GetPDFDocumentList(folder);

						log.Debug("Marking images for agency [" + vendor.AgencyName + "]");
						if (vendor != pre_vendor)
						{
							foreach (ImageDetail image in images)
							{
								MarkReceivedImages markImages = new MarkReceivedImages();
								markImages.MarkImages(image.Name);
							}
						}
						log.Debug("End marking images for agency [" + vendor.AgencyName + "]");

						pre_vendor = vendor;
					}
					catch (Exception exp)
					{
						log.Error(exp, "Failed to delete file for agency [" + vendor.AgencyName + "]");
					}
				}

				//VendorsInfo prev_vendor = null;

				foreach (var vendor in vendors)
				{

					log.Debug("Transferring files for agency [" + vendor.AgencyName + "]");
					try
					{
						// Get the stored procedure parameters
						List<TrafficCitation_ImportFileLog> fileRecords = new List<TrafficCitation_ImportFileLog>();

						GetStoredProcedureParameters parameters = new GetStoredProcedureParameters();
						log.Debug("Calling GetParameters for agency [" + vendor.AgencyName + "]");
						fileRecords = parameters.GetParametes(vendor);
						log.Debug("End GetParameters for agency [" + vendor.AgencyName + "]");

						foreach (var fileRecord in fileRecords)
						{

							// call the TrafficCitationImport_ImportCitationFile stored procedure and pass FileLogId, VendorAgencyId and RecordCount
							int fileLogID = fileRecord.FileLogId;
							int vendorAgencyID = fileRecord.VendorAgencyId.Value;
							string localPath = vendor.LocalPath;

							log.Debug("FileLogID [" + fileLogID + "]");
							log.Debug("VendorAgencyID [" + vendorAgencyID + "]");
							log.Debug("LocalPath [" + localPath + "]");

							ReferenceEntities db = new ReferenceEntities();

							log.Debug("Begin TrafficCitationImport_ImportCitationsToOdyssey SP");
							db.TrafficCitationImport_ImportCitationsToOdyssey(fileLogID, vendorAgencyID, localPath);
							log.Debug("End TrafficCitationImport_ImportCitationsToOdyssey SP");

							// Send failures to failures queue
							log.Debug("Begin TrafficCitationImport_SendFailedToQueue SP (errors)");
							db.TrafficCitationImport_SendFailedToQueue(fileLogID, "1");
							log.Debug("End TrafficCitationImport_SendFailedToQueue SP (errors)");

							// Update the jurisdiction 
							log.Debug("Begin TrafficCitationImport_UpdateJurisdiction SP");
							db.TrafficCitationImport_UpdateJurisdiction();
							log.Debug("End TrafficCitationImport_UpdateJurisdiction SP");

							// Mark citations fixed manually from the queues
							log.Debug("Begin TrafficCitationImport_QueueCitationsFixedManually SP");
							db.TrafficCitationImport_QueueCitationsFixedManually(fileLogID);
							log.Debug("End TrafficCitationImport_QueueCitationsFixedManually SP");

							// Get date files
							//GetDataFiles getDataFiles = new GetDataFiles();
							//List<TrafficCitation_ImportFileLog> dataFileList = getDataFiles.GetDataFileId();

							//foreach (var fileId in dataFileList)
							//{
								// Get the list of file citations to process
								CitationsToProcess citationsToProcess = new CitationsToProcess();
								List<string> citations = citationsToProcess.GetCitations(fileRecord.FileLogId.ToString());

								//Process Citations one at a time
								log.Debug("Beginning to process citations - TrafficCitationImport_ProcessCitations");
								foreach (string citation in citations)
								{
									log.Debug("Processing citation number [" + citation + "]");
									db.TrafficCitationImport_ProcessCitations(fileLogID, citation);									
								}
								log.Debug("Finished processing citations");
							//}


							// Send warnings to warnings queue
							SqlParameter param6 = new SqlParameter("@CurrExceptionFlag", 2);
							log.Debug("Begin TrafficCitationImport_SendFailedToQueue SP (warnings)");
							db.TrafficCitationImport_SendFailedToQueue(fileLogID, "2");
							log.Debug("End TrafficCitationImport_SendFailedToQueue SP (warnings)");

							// Mark the completion of file processing
							log.Debug("Begin TrafficCitationImport_MarkFileCompletion SP");
							db.TrafficCitationImport_MarkFileCompletion(fileLogID);
							log.Debug("End TrafficCitationImport_MarkFileCompletion SP");

						}
					}
					catch (Exception exp)
					{
						log.Error(exp, "Failed to connect to agency [" + vendor.AgencyName + "]");
					}
				}

				//Delete remote files
				foreach (var vendor in vendors)
				{
					log.Debug("Deleting files for vendor: " + vendor);
					IDownloadUtility download = GetTransferObject(vendor);
					download.DeleteRemoteFiles(vendor);
				}

				log.Debug("Files have been transfered for vendors");

				ReferenceEntities db2 = new ReferenceEntities();
				List<TrafficCitation_ImportFileLog> fileRecords2 = new List<TrafficCitation_ImportFileLog>();

				// Get skipped files
				GetSkippedFiles getSkippedFiles = new GetSkippedFiles();
				List<TrafficCitation_ImportFileLog> skippedFilesList = getSkippedFiles.GetSkippedFileId();

				foreach (var skippedFile in skippedFilesList)
				{
					// Get the list of file citations to process
					CitationsToProcess citationsToProcess2 = new CitationsToProcess();

					int skippedFileLogID = skippedFile.FileLogId;

					List<string> skippedCitations = citationsToProcess2.GetCitations(skippedFileLogID.ToString());
						foreach (var citation in skippedCitations)
						{
							log.Debug("Now processing citation " + citation + "");
							db2.TrafficCitationImport_ProcessCitations(skippedFileLogID, citation);
						}

					db2.TrafficCitationImport_MarkFileCompletion(skippedFileLogID);
				}


				// Reporocess citations with failed API and the ones their images received later
				ReprocessCitations reprocessCitations = new ReprocessCitations();
				List<string> failedCitations =  reprocessCitations.GetFailedCitations();
				foreach (var citation in failedCitations)
				{
					log.Debug("Now processing citation " + citation + "");				
					db2.TrafficCitationImport_ProcessFailedCitations(citation);
				}


			}
			catch (Exception ex)
			{
				log.Error(ex);

			}
			log.Info("End run");


		}

		public IDownloadUtility GetTransferObject(VendorsInfo vendor)
		{			
			IDownloadUtility download = null;
			string connectionType = vendor.ConnectionType;
			switch (connectionType)
			{
				case "FTP":					
					download = new FTPUtility();
					break;
				case "SFTP":
					download = new SFTPUtility();
					break;
				case "FILE":
					download = new FolderUtility();
					break;
				default:
					log.Debug("Default case");
					break;
			}

			log.Debug("Transfer object: [" + connectionType + "]");
			return download;
		}

		//Should this be in its own class SOLID?
		public void TransferVendorFiles(IDownloadUtility download, VendorsInfo vendor)
		{
			log.Info("Begin TransferVendorFiles...");
			int connectionAttempt = 1;
			bool successfulTransfer = false;

			while ((connectionAttempt <= 3) || (!successfulTransfer))
			{
				try
				{
					download.TransferFiles(vendor);
					successfulTransfer = true;
					log.Debug("Files successfully transferred");
					break;
				}
				catch (Exception ex)
				{
					log.Debug(ex, "Attempt [" + connectionAttempt + "]" + ex.Message);
					System.Threading.Thread.Sleep(AppSettings.RetryTime);
					connectionAttempt++;
					log.Debug("End Timer");

				}
				if (connectionAttempt > 3)
				{
					throw new Exception("Failed 3 times to connect vendor [" + vendor.VendorName + "]");
				}
			}
			log.Info("End TransferVendorFiles");
		}
	}
}
