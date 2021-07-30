using System;
using System.Collections.Generic;
using System.Linq;
using System.IO;
using NLog;
using TrafficCitationImport2.Models;


namespace TrafficCitationImport2.BLL
{
	public class FolderUtility : IDownloadUtility
	{
		private static Logger log = LogManager.GetCurrentClassLogger();

		public List<string> GetVendorRemoteFileList(VendorsInfo vendor)
		{
			log.Info("Begin GetVendorRemoteFileList...");
			List<string> fileList = GetFileList(vendor.RemotePath);
			log.Debug("Retrieved remote file list for [" + vendor.AgencyName + "]");
			log.Info("End GetVendorRemoteFileList");
			return fileList;
		}

		public void TransferFiles(VendorsInfo vendor)
		{
			log.Info("Begin TransferFiles...");
			try
			{		
				List<string> fileList = GetFileList(vendor.RemotePath);

				CopyFilesFromRemote(fileList, vendor.LocalPath, vendor.VendorName);
				log.Debug("Copied files to local");

				CopyFilesFromRemote(fileList, AppSettings.ArchiveFilePath, vendor.VendorName);
				log.Debug("Copied files to archive");


				RecordFilesTransfered(fileList);
				log.Debug("Recorded files copied from remote");
			}
			catch (Exception ex)
			{
				log.Error(ex);
				throw ex;
			}
			log.Info("End TransferFiles");
		}

		public void DeleteRemoteFiles(VendorsInfo vendor)
		{
			log.Info("Begin DeleteRemoteFiles...");
			List<string> listOfRemoteFiles = vendor.RemoteFileList;

			try
			{
				foreach (string fileName in listOfRemoteFiles)
				{
					//delete file
					log.Debug("Deleting file: [" + fileName + "]");
					File.Delete(fileName);
				}
			}
			catch (Exception ex)
			{
				log.Error(ex, "Error while deleting the file");
			}

			log.Info("End DeleteRemoteFiles");
		}

		private List<string> GetFileList(string remotePath)
		{
			log.Info("Begin GetFileList...");
			log.Debug("RemotePath: [" + remotePath + "]");

			List<string> fileList = null;

			if (Directory.Exists(remotePath))
			{
				fileList = System.IO.Directory.GetFiles(remotePath).ToList();

				foreach (string file in fileList)
				{
					log.Debug("[" + file + "] file found");
				}

				log.Debug("[" + fileList.Count + "] total files found");

			}
			else
			{
				log.Debug("RemotePath not found [" + remotePath + "]");
				throw new Exception("RemotePath not found [" + remotePath + "]");
			}

			log.Info("End GetFileList");

			return fileList;

		}

		private void CopyFilesFromRemote(List<string> filesToCopy, string destinationPath, string vendorFolder)
		{
			log.Info("Begin CopyFilesFromRemote...");
			log.Debug("Destination path [" + destinationPath + "]");
			log.Debug("Vendor name [" + vendorFolder + "}");

			string fullDestinationPath = String.Empty;

			if (destinationPath.Contains("Archive") == true)
			{
				fullDestinationPath = destinationPath + "\\" + vendorFolder;

				log.Debug("Destination file: " + fullDestinationPath);
			}
			else
			{
				fullDestinationPath = destinationPath;

				log.Debug("Destination file: " + fullDestinationPath);
			}

			if (!Directory.Exists(fullDestinationPath))
			{
				log.Debug("fullDestinationPath does not exist [" + fullDestinationPath + "]");
				throw new Exception("Path [" + fullDestinationPath + "] does not exist");

			}

			log.Debug("About to copy files");
			foreach (string remoteFile in filesToCopy)
			{

				string nameOfFile = Path.GetFileName(remoteFile);
				log.Debug("Name of file [" + nameOfFile + "]");

				string fullCopyFilePath = fullDestinationPath + "\\" + nameOfFile;
				log.Debug("Copying file to [" + fullCopyFilePath + "]");

				File.Copy(remoteFile, fullCopyFilePath, true);
			}

			log.Debug("Finished copying files");

			log.Info("End CopyFilesFromRemote");
		}


		public void RecordFilesTransfered(List<string> fileList)
		{
			//record the file that has been copied to OCCCC folder
		}


	}
}
