using System;
using System.Collections.Generic;
using System.Linq;
using NLog;
using TrafficCitationImport2.Models;

namespace TrafficCitationImport2.DAL
{
	public static class DataAccess
	{
		private static Logger log = LogManager.GetCurrentClassLogger();

		//     public static List<TrafficCitation_AgencyVendorInfo> GetVendorInfo(string vendorName)
		//     {
		//log.Info("Start GetVendorInfo");

		//log.Debug("Getting info for vendor: " + vendorName);

		//         try
		//         {
		//             List<TrafficCitation_AgencyVendorInfo> returnValue;
		//             using (OdyClerkInternalEntities db = new OdyClerkInternalEntities())
		//             {
		//                 returnValue = db.TrafficCitation_AgencyVendorInfo.Where(v => v.Active == true && v.VendorName == vendorName).OrderBy(f => f.ServerName).ToList();

		//		log.Debug("Successfully returned infor for vendor: " + vendorName);
		//             }
		//             return returnValue;
		//         }
		//         catch (Exception ex)
		//         {
		//             log.Error(ex);

		//         }
		//         return null;
		//     }
		public static List<VendorsInfo> GetVendorInfo()
		{
			log.Info("Begin GetVendorInfo...");

			List<VendorsInfo> vendorList = new List<VendorsInfo>();

			try
			{

				List<TrafficCitation_AgencyVendorInfo> vendors;
				using (ReferenceEntities db = new ReferenceEntities())
				{
					vendors = db.TrafficCitation_AgencyVendorInfo.Where(v => v.Active == true).OrderBy(f => f.ServerName).ToList();
				}

				foreach (TrafficCitation_AgencyVendorInfo vendor in vendors)
				{
					VendorsInfo vi = new VendorsInfo(vendor);
					vendorList.Add(vi);

					log.Debug("Agency added: [" + vi.AgencyName + "]");
				}
			}
			catch (Exception e)
			{
				log.Error(e, "Error ocurred during GetVendorInfo");
			}

			log.Info("End GetVendorInfo");

			return vendorList;
		}

	}
}
