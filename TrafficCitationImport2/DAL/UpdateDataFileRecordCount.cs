using NLog;
using System;
using System.Linq;
using TrafficCitationImport2.Models;

namespace TrafficCitationImport2.DAL
{
	public class UpdateDataFileRecordCount
	{
		private static Logger log = LogManager.GetCurrentClassLogger();

		public void UpdateRecordCount(VendorsInfo vendor, string filePath, int recordCount)
		{
			log.Info("Start UpdateRecordCount");
			try
			{
				log.Debug("vendor [ " + vendor + " ] and file path [ " + filePath + " ]");
				// Updating data file record counts after bulk inserting the file
				using (ReferenceEntities db = new ReferenceEntities())
				{
					log.Debug("Using OdyClerkInternalEntities");
					var result = db.TrafficCitation_ImportFileLog.SingleOrDefault(x => x.VendorAgencyId == vendor.VendorAgencyId
																					&& x.FileName == filePath
																					&& x.RecordCount == null
																					&& x.ProcessStatus == "Pending"
																					&& x.ProcessStartTime == null
																					&& x.ProcessEndTime == null);
					if (result != null)
					{
						log.Debug("Captured the record cound of the data file as [ " + recordCount + " ]");
						result.RecordCount = recordCount;
						db.SaveChanges();
						log.Debug("Saved record count to table as [ " + recordCount + " ]");
					}
				}
			}
			catch (Exception ex)
			{
				log.Error("Error while updating record count for agency: " + vendor.AgencyName + " Error Message: " + ex.ToString() + "");
			}

			log.Info("End function UpdateRecordCount");
		}
	}
}
