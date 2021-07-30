using NLog;
using System;
using System.IO;
using TrafficCitationImport2.Models;

namespace TrafficCitationImport2.BLL
{
	public class SaveOldFiles
	{
		private static Logger log = LogManager.GetCurrentClassLogger();
		public void SaveFiles(VendorsInfo vendor)
		{
			log.Info("Begin SaveFiles...");

			try
			{
				string[] allFiles = Directory.GetFiles(vendor.LocalPath);

				//Remove old Files to Processed folder then delete them from current folder
				foreach (string filename in allFiles)
				{
					string fileExtension = Path.GetExtension(filename);

					string Name = Path.GetFileNameWithoutExtension(filename);

					log.Debug("Now saving file [" + filename + "] for agency [" + vendor.AgencyName + "]");

					if (fileExtension == ".pdf" || fileExtension == ".PDF")
					{
						File.Copy(filename, vendor.LocalPath + "\\" + "Processed" + "\\" + Name + ".pdf", true);
						log.Debug("Copying file [" + filename + "] to Processed folder");
					}
					else if (fileExtension == ".zip" || fileExtension == ".ZIP")
					{
						File.Copy(filename, vendor.LocalPath + "\\" + "Processed" + "\\" + Name + ".zip", true);
						File.Copy(filename, vendor.LocalPath + "\\" + "Archive" + "\\" + Name + ".zip", true);
						log.Debug("Copying file [" + filename + "] to Processed and Archive folders");
					}
					else if (fileExtension == ".dat")
					{
						File.Copy(filename, vendor.LocalPath + "\\" + "Processed" + "\\" + Name + ".dat", true);
						File.Copy(filename, vendor.LocalPath + "\\" + "Archive" + "\\" + Name + ".dat", true);
						log.Debug("Copying file [" + filename + "] to Processed and Archive folders");
					}
					else if (Name.Substring(Name.Length - 3) == "cit")
					{
						File.Copy(filename, vendor.LocalPath + "\\" + "Processed" + "\\" + Name, true);
						File.Copy(filename, vendor.LocalPath + "\\" + "Archive" + "\\" + Name, true);
						log.Debug("Copying file [" + filename + "] to Processed and Archive folders");
					}
					else { }
				}

			}
			catch (Exception exp)
			{
				log.Error(exp, "Error saving the old files for agency [" + vendor.AgencyName + "]");
			}

			log.Info("End SaveFiles");
		}
	}
}
