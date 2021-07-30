using NLog;
using System;
using System.Configuration;
using System.IO;

namespace TrafficCitationImport2.BLL
{
	public class ArchiveOldProcessedFiles
	{
		private static Logger log = LogManager.GetCurrentClassLogger();
		public void ArchiveProcessedFiles(string directoryPath, string destinationPath)
		{
			log.Info("Begin ArchiveProcessedFiles...");

			try
			{
				// making the days value configurable TM 9/16/2020
				int DaysToArchiveImage = int.Parse(ConfigurationManager.AppSettings["DaysToArchiveImage"]);

				log.Debug("Days to Archive: [" + DaysToArchiveImage + "]");
				log.Debug("Directory Path: [" + directoryPath + "]");
				log.Debug("Destination Path: [" + destinationPath + "]");

				string[] files = Directory.GetFiles(directoryPath);

				log.Debug("# of files to archive: [" + files.Length + "]");

				foreach (string file in files)
				{
					FileInfo fi = new FileInfo(file);

					string filename = Path.GetFileName(file);

					log.Debug("Archiving file: [" + filename + "]");

					if (fi.LastAccessTime < DateTime.Now.AddDays(DaysToArchiveImage))
					{
						fi.MoveTo(destinationPath + "\\" + filename);
					}
				}
			}
			catch(Exception e)
			{
				log.Error(e, "An error during ArchiveProcessedFiles");
			}

			log.Info("End ArchiveProcessedFiles");
		}
	}
}
