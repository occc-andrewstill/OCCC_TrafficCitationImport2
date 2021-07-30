using NLog;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TrafficCitationImport2.Models;

namespace TrafficCitationImport2.DAL
{
	public class GetCitationType
	{
		private static Logger log = LogManager.GetCurrentClassLogger();
		public VendorsInfo CitationType(VendorsInfo vendor)
		{
			log.Info("Start CitationType");

			log.Debug("Getting agency Id for agency: " + vendor.VendorAgencyId);

			VendorsInfo agencyId = null;
			try
			{
				using (ReferenceEntities db = new ReferenceEntities())
				{
					var result = db.TrafficCitation_AgencyVendorInfo.Select(x => x.VendorAgencyId == vendor.VendorAgencyId);

					agencyId = (VendorsInfo)result;

					// return (VendorsInfo)result;
				}
			}
			catch (Exception ex)
			{
				log.Error("Error during getting agencyId inside CitationType method: " + ex);
			}

			log.Info("End CitationType");

			return agencyId;

		}
	}
}
