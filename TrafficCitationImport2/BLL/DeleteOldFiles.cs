using NLog;
using System;
using System.IO;
using TrafficCitationImport2.Models;

namespace TrafficCitationImport2.BLL
{
	public class DeleteOldFiles
	{
		private static Logger log = LogManager.GetCurrentClassLogger();
		public void DeleteFiles(VendorsInfo vendor)
		{
			log.Info("Begin DeleteFiles...");

			log.Debug("SDeleting files for agency [" + vendor.AgencyName + "]");

			try
			{
				string[] allFiles = Directory.GetFiles(vendor.LocalPath);

				//Remove old Files to Processed folder then delete them from current folder
				foreach (string filename in allFiles)
				{
					string fileExtension = Path.GetExtension(filename);
					string fileWithExtention = Path.GetFileName(filename);

					string file = Path.GetFileNameWithoutExtension(filename);

					// This is to avoid missing the files in case the package fails right after downloading the files and before 
					// moving them to the Processed folder T.M. 3-7-2016
					/////////////////////////////////////////////////////////////////////////
					if (File.Exists(vendor.LocalPath + "\\Processed\\" + fileWithExtention))
					{
						log.Debug("Deleting the file [" + filename + "]");

						if (fileExtension == ".pdf" || fileExtension == ".PDF")
						{
							File.Delete(filename);
						}
						else if (fileExtension == ".ZIP" || fileExtension == ".zip")
						{
							File.Delete(filename);
						}
						else if (file.Substring(file.Length - 3) == "cit")
						{
							File.Delete(filename);
						}
						else if (file.Substring(file.Length - 3) == "dat")
						{
							File.Delete(filename);
						}
						else
						{

						}
					}
					////////////////////////////////////////////////////////////////////////
					else
					{
						log.Debug("File [" + vendor.LocalPath + "\\Processed\\" + fileWithExtention + "] does not exist.");
					}
				}
			}
			catch (Exception exp)
			{
				log.Error(exp, "Failed to connect vendor [" + vendor.VendorName + "]");
			}

			log.Info("End function DeleteFiles");
			
		}
	}

}
