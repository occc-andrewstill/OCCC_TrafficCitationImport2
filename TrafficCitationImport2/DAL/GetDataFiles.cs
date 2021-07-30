using NLog;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TrafficCitationImport2.DAL
{
	public class GetDataFiles
	{
		private static Logger log = LogManager.GetCurrentClassLogger();
		public List<TrafficCitation_ImportFileLog> GetDataFileId()
		{
			log.Info("Start GetDataFileId");

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
											  && file.ProcessStartTime == null
											  && file.ProcessEndTime == null
											  && file.ProcessStatus == "Pending"
											  select file).ToList();

					result = importedFileRecord;

					log.Debug("Successfully retrieved data files ");
				}
			}
			catch (Exception ex)
			{
				log.Error("Error during extracting file records: " + ex);
			}

			log.Info("End GetDataFileId");

			return result;
		}
	}
}
