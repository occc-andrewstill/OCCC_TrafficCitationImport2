using System.Collections.Generic;
using TrafficCitationImport2.Models;

namespace TrafficCitationImport2.BLL
{
	interface IDownloadUtility
	{
		List<string> GetVendorRemoteFileList(VendorsInfo vendor);

		void TransferFiles(VendorsInfo vendor);
		void DeleteRemoteFiles(VendorsInfo vendor);
	}
}
