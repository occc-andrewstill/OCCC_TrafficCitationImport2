using NLog;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TrafficCitationImport2.DAL
{
	public class InsertDataFile
	{
		private static Logger log = LogManager.GetCurrentClassLogger();
		public void ImportFileLog_Insert(string DataFile, int VendorAgencyId)
		{
			log.Info("Begin ImportFileLog_Insert...");

			try
			{
				using (ReferenceEntities db = new ReferenceEntities())
				{
					// check if file already exist 
					if (db.TrafficCitation_ImportFileLog.Any(u => u.FileName == DataFile))
					{
					}
					else
					{
						log.Debug("Now inserting data file: [" + DataFile + "] for agency Id: [" + VendorAgencyId + "]");

						var file = db.Set<TrafficCitation_ImportFileLog>();
						file.Add(new TrafficCitation_ImportFileLog { FileDate = DateTime.Today, FileName = DataFile, ProcessStatus = "Pending", VendorAgencyId = VendorAgencyId });

						db.SaveChanges();
					}
				}
			}
			catch (Exception exp)
			{
				log.Error(exp, "Error inserting data file: [" + DataFile + "] for agency Id: [" + VendorAgencyId + "]");
			}

			log.Info("End function ImportFileLog_Insert");
		}
	}
}
