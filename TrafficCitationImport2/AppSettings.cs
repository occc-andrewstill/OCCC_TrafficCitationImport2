using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TrafficCitationImport2
{
	public static class AppSettings
	{
		public static string RunAsConsoleApp
		{
			get
			{
				string runAsConsoleApp = ConfigurationManager.AppSettings.Get("RunAsConsoleApp");
				return runAsConsoleApp;
			}
		}


		public static string LocalFilePath

		{
			get
			{
				string filepath = ConfigurationManager.AppSettings.Get("localFilePath");
				return filepath;
			}
		}

		public static string ArchiveFilePath
		{
			get
			{
				string filepath = ConfigurationManager.AppSettings.Get("archiveFilePath");
				return filepath;
			}

		}
		public static int RetryTime
		{
			get
			{
				int retryInt = 0;
				string retrytime = ConfigurationManager.AppSettings.Get("RetryTime");
				bool isAnInt = int.TryParse(retrytime, out retryInt);
				if (isAnInt)
				{
					return retryInt;
				}
				return 0;
			}
		}

	}
}



