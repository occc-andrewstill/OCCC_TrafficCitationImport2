using NLog;
using System;
using System.Collections.Generic;
using System.Linq;
using TrafficCitationImport2.Models;

namespace TrafficCitationImport2.DAL
{
	public class FileLogId
	{
		private static Logger log = LogManager.GetCurrentClassLogger();
		public string GetFileLogId(string dataFileName)
		{
			log.Info("Begin GetFileLogID");

			string fileLogId = string.Empty;

			try
			{
				using (ReferenceEntities db = new ReferenceEntities())
				{

					var importedFileId = (from file in db.TrafficCitation_ImportFileLog
										  where file.ProcessStatus == "Pending"
										  && file.VendorAgencyId != null
										  && file.FileName == dataFileName
										  select file).FirstOrDefault();

					fileLogId = importedFileId.FileLogId.ToString();

					log.Debug("Successfully retrieved File Log ID [" + fileLogId + "] for data file: [" + dataFileName + "]");
				}
			}
			catch (Exception ex)
			{
				log.Error(ex, "Error during extracting fileLogId: " + ex);
			}

			log.Info("End GetFileLogID");

			return fileLogId;
		}
	}
}
