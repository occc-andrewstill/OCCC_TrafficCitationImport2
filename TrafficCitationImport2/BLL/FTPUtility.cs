using NLog;
using System;
using System.IO;
using System.Net;
using System.Collections.Generic;
using TrafficCitationImport2.Models;
namespace TrafficCitationImport2.BLL
{
	public class FTPUtility : IDownloadUtility
	{
		private static Logger log = LogManager.GetCurrentClassLogger();

		public List<string> GetVendorRemoteFileList(VendorsInfo vendor)
		{
			log.Info("Begin GetVendorRemoteFileList...");

			log.Debug("Getting remote file list for agency: [" + vendor.AgencyName + "]");

			string serverUri = "ftp://" + vendor.ServerName + vendor.RemotePath;

			log.Debug("	ServerURI: [" + serverUri + "]");

			int port = Convert.ToInt32(vendor.ServerPort);

			log.Debug("	Port: [" + port + "]");

			List<string> allFiles = new List<string>();

			try
			{
				FtpWebRequest request = (FtpWebRequest)WebRequest.Create(serverUri);
				request.Method = WebRequestMethods.Ftp.ListDirectory;

				request.Credentials = new NetworkCredential(vendor.ServerUserName, vendor.ServerPassword);

				using (FtpWebResponse response = (FtpWebResponse)request.GetResponse())
				{
					using (Stream responseStream = response.GetResponseStream())
					{
						using (StreamReader reader = new StreamReader(responseStream))
						{
							while (responseStream.CanRead && !reader.EndOfStream)
							{
								allFiles.Add(reader.ReadLine());
							}

							log.Debug("[" + allFiles.Count + "] files found");

							foreach (string file in allFiles)
							{
								log.Debug("[" + file + "]");
							}
							
						}
					}
				}
			}
			catch (Exception exp)

			{
				log.Error(exp, "Error retrieving file list for [" + vendor.AgencyName + "]");
			}

			log.Info("End GetVendorRemoteFileList");

			return allFiles;
		}

		public void DeleteRemoteFiles(VendorsInfo vendor)
		{
			log.Info("Start function DeleteRemoteFiles");

			try
			{
				string[] files = Directory.GetFiles(vendor.LocalPath);

				foreach (string fileNameWithPath in files)
				{
					log.Debug("Now retrieving file: " + fileNameWithPath + " for agency: " + vendor.AgencyName);

					string fileName = Path.GetFileName(fileNameWithPath);

					string serverUri = "ftp://" + vendor.ServerName + vendor.RemotePath + fileName;

					FtpWebRequest request = (FtpWebRequest)WebRequest.Create(serverUri);
					request.Credentials = new NetworkCredential(vendor.ServerUserName, vendor.ServerPassword);

					if (File.Exists(fileNameWithPath))
					{
						request.Method = WebRequestMethods.Ftp.DeleteFile;
						log.Debug("Prepared request object for file: " + fileNameWithPath);
					}

					FtpWebResponse response = (FtpWebResponse)request.GetResponse();
					response.Close();
				}
			}
			catch (Exception exp)
			{
				log.Error(exp, "Error during retrieving file(s) for [" + vendor.AgencyName + "]");
			}

			log.Info("End function DeleteRemoteFiles");
		}

		public void TransferFiles(VendorsInfo vendor)
		{
			log.Info("Start function TransferFiles");

			try
			{
				// Declare a list to capture files for each vendor
				List<string> files = new List<string>();

				files = vendor.RemoteFileList;

				//files.Remove("CFXreportpickup");

				foreach (string file in files)
				{
					log.Debug("Start transferring file: " + file);

					if (file.Substring(file.Length - 3) == "zip" || file.Substring(file.Length - 3) == "ZIP" || file.Substring(file.Length - 3) == "Zip"
						|| file.Substring(file.Length - 3) == "cit" || file.Substring(file.Length - 3) == "dat")
					{
						string serverUri = "ftp://" + vendor.ServerName + vendor.RemotePath + file;

						FtpWebRequest request = (FtpWebRequest)WebRequest.Create(serverUri);
						request.Credentials = new NetworkCredential(vendor.ServerUserName, vendor.ServerPassword);

						FtpWebResponse response = (FtpWebResponse)request.GetResponse();
						Stream responseStream = response.GetResponseStream();
						StreamReader reader = new StreamReader(responseStream);

						byte[] buffer = new byte[16 * 16384];
						int len = 0;
						FileStream objFS = new FileStream(vendor.LocalPath + "\\" + file, FileMode.Create, FileAccess.Write, FileShare.Read);

						log.Debug("Now downloading file: " + vendor.LocalPath + "\\" + file + " for agency: " + vendor.AgencyName);

						while ((len = reader.BaseStream.Read(buffer, 0, buffer.Length)) != 0)
						{
							objFS.Write(buffer, 0, len);
						}

						objFS.Close();
						response.Close();
					}
					else if (File.Exists(vendor.LocalPath + "\\" + file))
					{
						log.Debug("File: " + vendor.LocalPath + "\\" + file + " already exist at local path");
						continue;
					}
					else
					{
					}
				}

			}
			catch (Exception exp)
			{
				log.Error(exp, "Error during file download for agency [" + vendor.AgencyName + "]");
			}

			DeleteRemoteFiles(vendor);

			log.Info("End function TransferFiles");
		}

	}
}


