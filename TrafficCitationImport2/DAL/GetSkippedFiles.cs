using NLog;
using System;
using System.Collections.Generic;
using System.Linq;

namespace TrafficCitationImport2.BLL
{
	public class GetSkippedFiles
	{
		private static Logger log = LogManager.GetCurrentClassLogger();
		public List<TrafficCitation_ImportFileLog> GetSkippedFileId()
		{
			log.Info("Start GetSkippedFileId");

			List<TrafficCitation_ImportFileLog> result = new List<TrafficCitation_ImportFileLog>();

			DateTime today = DateTime.Now.Date;
			string thisDay = today.ToString("yyyy-MM-dd");

			try
			{
				using (ReferenceEntities db = new ReferenceEntities())
				{
					var importedFileRecord = (from file in db.TrafficCitation_ImportFileLog
											  where (file.FileDate).ToString() == thisDay
											  && file.RecordCount != null
											  && file.ProcessStartTime != null
											  && file.ProcessEndTime == null
											  && file.ProcessStatus == "Validating"
											  select file).ToList();

					result = importedFileRecord;

					log.Debug("Successfully retrieved skipped files ");
					//return importedFileRecord;
				}
			}
			catch (Exception ex)
			{
				log.Error("Error during extracting file records: " + ex);
			}

			log.Info("End GetSkippedFileId");

			return result;
		}
	}
}
