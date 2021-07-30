using System;
using System.Collections.Generic;
using TrafficCitationImport2.Models;
using System.IO;
using Renci.SshNet.Sftp;
using System.Net.Mail;
using System.Linq;
using NLog;

namespace TrafficCitationImport2.BLL
{
	public class SFTPUtility : IDownloadUtility
	{
		private static Logger log = LogManager.GetCurrentClassLogger();

		string downloadedFile = string.Empty;
		public List<string> GetVendorRemoteFileList(VendorsInfo vendor)
		{
			log.Info("Start function GetVendorRemoteFileList");

			int port = Convert.ToInt32(vendor.ServerPort);

			List<string> allFiles = new List<string>();

			log.Debug("Getting files list for vendor: " + vendor);

			try
			{
				using (Renci.SshNet.SftpClient sftpConn = new Renci.SshNet.SftpClient(vendor.ServerName, Convert.ToInt32(vendor.ServerPort), vendor.ServerUserName.Normalize(), vendor.ServerPassword))
				{
					sftpConn.BufferSize = 1024 * 32 - 52;
					sftpConn.Connect();

					var Files = (from file in sftpConn.ListDirectory(vendor.RemotePath, null) select file).ToList();

					foreach (var entry in Files)
					{

						if (entry.IsDirectory)
						{
							allFiles.Add(entry.FullName);
							log.Debug("Now retreving file: " + entry.FullName + " for agency: " + vendor.AgencyName);
						}
					}
				}
			}
			catch (Exception exp)
			{
				log.Error(exp, "Error during file retreival for agency [" + vendor.AgencyName + "]");
			}

			log.Info("End function GetVendorRemoteFileList");

			return allFiles;
		}

		public void DeleteRemoteFiles(VendorsInfo vendor)
		{
			log.Info("Start function DeleteRemoteFiles");

			log.Debug("Starting deleting remote files for agency: " + vendor.AgencyName);

			int port = Convert.ToInt32(vendor.ServerPort);

			string[] allFiles = Directory.GetFiles(vendor.LocalPath);

			try
			{
				foreach (string fileNameWithPath in allFiles)
				{
					string fileName = Path.GetFileName(fileNameWithPath);

					using (Renci.SshNet.SftpClient sftpConn = new Renci.SshNet.SftpClient(vendor.ServerName, port, vendor.ServerUserName, vendor.ServerPassword))
					{
						sftpConn.BufferSize = 1024 * 32 - 52;
						sftpConn.Connect();

						// Setting timeout value for SFTP server to 10 minutes T.M. 3/15/2016
						sftpConn.ConnectionInfo.Timeout = TimeSpan.FromSeconds(600);

						if (downloadedFile == fileName)
						{
							sftpConn.Delete(vendor.RemotePath + fileName);

							log.Debug("Now deleting remote file: " + vendor.RemotePath + fileName + " for agency: " + vendor.AgencyName);
						}
					}
				}
			}
			catch (Exception exp)
			{
				log.Error(exp, "Error during deleting remote file for agecny [" + vendor.AgencyName + "]");
			}

			log.Info("End function DeleteRemoteFiles");
		}

		public void TransferFiles(VendorsInfo vendor)
		{
			log.Info("Start function TransferFiles");

			log.Debug("Start transferring files for agency: " + vendor.AgencyName);

			// Declare a list to capture files for each vendor
			List<string> files = new List<string>();

			string fileName = "";
			DateTime date = DateTime.Now;

			int port = Convert.ToInt32(vendor.ServerPort);

			try
			{
				using (Renci.SshNet.SftpClient sftpConn = new Renci.SshNet.SftpClient(vendor.ServerName, port, vendor.ServerUserName, vendor.ServerPassword))
				{
					sftpConn.BufferSize = 1024 * 32 - 52;
					sftpConn.Connect();

					// Setting timeout value for SFTP server to 10 minutes T.M. 3/15/2016
					sftpConn.ConnectionInfo.Timeout = TimeSpan.FromSeconds(600);

					foreach (SftpFile file in sftpConn.ListDirectory(vendor.RemotePath, null))
					{
						fileName = file.Name;
						if (fileName.EndsWith("zip"))
						{
							SftpDownloadFile(fileName, vendor.LocalPath, vendor.RemotePath, sftpConn);
							log.Debug("Now downloading file: " + fileName + " for agency: " + vendor.AgencyName);

						}
						else
						{
							// Do nothing
						}

						downloadedFile = fileName;

						DeleteRemoteFiles(vendor);
						CheckZipFileReceived(vendor);
					}
					// disconnect SFTPConn object T.M. 3/8/2016
					sftpConn.Disconnect();
					sftpConn.Dispose();
				}
			}
			catch (Exception exp)
			{
				log.Error(exp, "Error during file download for agency [" + vendor.AgencyName + "]");
			}

			log.Info("End function TransferFiles");
		}

		public void SftpDownloadFile(string fileName, string uncPath, string remotePath, Renci.SshNet.SftpClient sftpConn)
		{
			log.Info("Start function SftpDownloadFile");

			try
			{
				Stream fout = null;
				fout = new FileStream(uncPath + "\\" + fileName, FileMode.Create);
				sftpConn.DownloadFile(remotePath + fileName, fout, null);
				log.Debug("Downloaded file: " + remotePath + fileName);
				fout.Close();
			}
			catch (Exception exp)
			{
				log.Error(exp, "Error during file download from remote path: [" + remotePath + fileName + "]");
			}

			log.Info("End function SftpDownloadFile");
		}

		void CheckZipFileReceived(VendorsInfo vendor)
		{
			log.Info("Start function CheckZipFileReceived");

			string agency = null;

			try
			{
				if (vendor.ConnectionType == "SFTP")
				{
					string path = vendor.LocalPath;
					int pos = path.LastIndexOf("\\") + 1;
					agency = path.Substring(pos, path.Length - pos);
					DirectoryInfo di = new DirectoryInfo(vendor.LocalPath);
					FileInfo[] zipFiles = di.GetFiles("*.zip");

					log.Debug("Checking existance of file at: " + vendor.LocalPath + " for agency: " + vendor.AgencyName);

					// commented for now 7/23/2020
					//if (zipFiles.Length == 0)
					//{
					//	sendMail(agency);
					//}
				}
			}
			catch (Exception exp)
			{
				log.Error(exp, "Error while checking existance of file at: [" + vendor.LocalPath + "]");
			}

			log.Info("End function CheckZipFileReceived");
		}

		//void sendMail(string agencyName)
		//{
		//	log.Info("Start function sendMail");

		//	log.Debug("Start sending file e-mail notification for agency: " + agencyName);

		//	try
		//	{
		//		MailMessage mail = new MailMessage("TraffiCitation_Import@myorangeclerk.com", "Tarig.Mudawi@myorangeclerk.com");
		//		SmtpClient client = new SmtpClient();
		//		client.Port = 25;
		//		client.DeliveryMethod = SmtpDeliveryMethod.Network;
		//		client.UseDefaultCredentials = false;
		//		client.Host = "mailrelay.MYORANGECLERK.NET";
		//		mail.Subject = "No file Available for " + agencyName;
		//		mail.Body = "No file received today " + DateTime.Now.ToString("M/d/yyyy") + " for " + agencyName;
		//		client.Send(mail);

		//		log.Debug("Sending the \"No file Available\" e-mail for agency: " + agencyName);
		//	}
		//	catch (Exception exp)
		//	{
		//		log.Error(exp, "Error while sending e-mail for agency [" + agencyName + "]");
		//	}

		//	log.Info("End function sendMail");
		//}
	}
}
