using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using NLog;
using TrafficCitationImport2.DAL;
using TrafficCitationImport2.Models;

namespace TrafficCitationImport2.BLL
{
	public class VendorUtility
	{
		private static Logger log = LogManager.GetCurrentClassLogger();

		public List<VendorsInfo> GetVendorList()
		{
			//log.Info("Start");
			List<VendorsInfo> vendors = DataAccess.GetVendorInfo();
			//log.Info("End");
			return vendors;
		}

	}
}
