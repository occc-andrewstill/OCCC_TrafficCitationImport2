using NLog;
using System;
using System.Collections.Generic;
using System.Linq;
using TrafficCitationImport2.Models;

namespace TrafficCitationImport2.DAL
{
	public class GetStoredProcedureParameters
	{
		private static Logger log = LogManager.GetCurrentClassLogger();
		public List<TrafficCitation_ImportFileLog> GetParametes(VendorsInfo vendor/*, string dataFileName*/)
		{
			log.Info("Begin GetParameters...");

			List<TrafficCitation_ImportFileLog> result = new List<TrafficCitation_ImportFileLog>();

			try
			{
				using (ReferenceEntities db = new ReferenceEntities())
				{
					var importedFileRecord = (from file in db.TrafficCitation_ImportFileLog
											  where file.ProcessStatus == "Pending"
											  && file.RecordCount != null
											  && file.ProcessStartTime == null
											  && file.ProcessEndTime == null
											  && file.VendorAgencyId == vendor.VendorAgencyId
											  select file).ToList();

					result = importedFileRecord;

					log.Debug("Retrieved [" + result.Count + "] data files.");
				}
			}
			catch (Exception ex)
			{
				log.Error(ex, "Error during retrieving file records");
			}

			log.Info("End GetParameters");

			return result;
		}
	}
}
