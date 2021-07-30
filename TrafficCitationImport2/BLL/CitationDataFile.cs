using NLog;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using TrafficCitationImport2.Models;

namespace TrafficCitationImport2.BLL
{
	public class CitationDataFile
	{
		private static Logger log = LogManager.GetCurrentClassLogger();

		public List<string> DataFileName(VendorsInfo vendor, string localpath)
		{
			log.Info("Begin DataFileName...");

			string dataFileName = "";

			var allDataFiles = new List<string>();

			try
			{

				string fhpSourceFolder = ConfigurationManager.AppSettings["dataFile"];

				string[] dataFiles = Directory.GetFiles(fhpSourceFolder);


				DateTime yesterday = DateTime.Now;
				yesterday = yesterday.Date.AddDays(-1);
				string FileDate = yesterday.ToString("yyyyMMdd");

				// Get the current data file for FHP
				if (vendor.AgencyName == "FHP")
				{
					foreach (string dataFileWithPath in dataFiles)
					{
						dataFileName = Path.GetFileName(dataFileWithPath);
						log.Debug("FHP : DataFileName: [" + dataFileName + "]");

						if (dataFileName == "07000" + FileDate + "01fcit" || dataFileName == "07000" + FileDate + "02fcit")
						{
							log.Debug("Copying data file from: [" + fhpSourceFolder + "\\" + dataFileName + "] to [" + vendor.LocalPath + "]");

							File.Copy(fhpSourceFolder + "\\" + dataFileName, vendor.LocalPath + "\\" + dataFileName, true);
							File.Copy(fhpSourceFolder + "\\" + dataFileName, vendor.LocalPath + "\\" + "Processed" + "\\" + dataFileName, true);
							File.Copy(fhpSourceFolder + "\\" + dataFileName, vendor.LocalPath + "\\" + "Archive" + "\\" + dataFileName, true);
						}
					}
				}

				string oldFileName = "";
				string[] allFiles = Directory.GetFiles(vendor.LocalPath);
				foreach (string fileNameWithPath in allFiles)
				{
					oldFileName = Path.GetFileName(fileNameWithPath);
					if (vendor.AgencyName == "FHP")
					{
						if (oldFileName.Substring(oldFileName.Length - 3) == "cit")
						{
							dataFileName = localpath + "\\" + oldFileName;
							log.Debug("Data file name: " + dataFileName + " for agency: " + vendor.AgencyName);
							allDataFiles.Add(dataFileName);
						}
					}
					/************ New code for Winter Garden, Oakland and Ocoee  T.M. 7/16/2015 *******/
					else if (vendor.AgencyName == "Ocoee")
					{
						if (oldFileName.Substring(oldFileName.Length - 3) == "cit" && oldFileName.Substring(0, 5) == "07042")
						{
							dataFileName = vendor.LocalPath + "\\" + oldFileName;
							log.Debug("Data file name: " + dataFileName + " for agency: " + vendor.AgencyName);
							allDataFiles.Add(dataFileName);
						}
					}
					else if (vendor.AgencyName == "Oakland")
					{
						if (oldFileName.Substring(oldFileName.Length - 3) == "cit" && oldFileName.Substring(0, 5) == "07052")
						{
							dataFileName = vendor.LocalPath + "\\" + oldFileName;
							log.Debug("Data file name: " + dataFileName + " for agency: " + vendor.AgencyName);
							allDataFiles.Add(dataFileName);
						}
					}
					else if (vendor.AgencyName == "Winter Garden")
					{
						if (oldFileName.Substring(oldFileName.Length - 3) == "cit" && oldFileName.Substring(0, 5) == "07041")
						{
							dataFileName = vendor.LocalPath + "\\" + oldFileName;
							log.Debug("Data file name: " + dataFileName + " for agency: " + vendor.AgencyName);
							allDataFiles.Add(dataFileName);
						}
					}
					else if (vendor.AgencyName == "Windermere")
					{
						if (oldFileName.Substring(oldFileName.Length - 3) == "cit" && oldFileName.Substring(0, 5) == "07050")
						{
							dataFileName = vendor.LocalPath + "\\" + oldFileName;
							log.Debug("Data file name: " + dataFileName + " for agency: " + vendor.AgencyName);
							allDataFiles.Add(dataFileName);
						}
					}
					/******************************* End code for Winter Garden, Oakland and Ocoee **********************************************/

					/******************************* Code for Red Light Agencies .. RLCApopkaPD, RLCOrlando and RLCOcoee  *************************/
					else if (vendor.AgencyName == "Apopka-RedLight")
					{
						if (oldFileName.Substring(oldFileName.Length - 3) == "cit")
						{
							dataFileName = vendor.LocalPath + "\\" + oldFileName;
							log.Debug("Data file name: " + dataFileName + " for agency: " + vendor.AgencyName);
							allDataFiles.Add(dataFileName);
						}
					}
					else if (vendor.AgencyName == "Ocoee-RedLight")
					{
						if (oldFileName.Substring(oldFileName.Length - 3) == "cit")
						{
							dataFileName = vendor.LocalPath + "\\" + oldFileName;
							log.Debug("Data file name: " + dataFileName + " for agency: " + vendor.AgencyName);
							allDataFiles.Add(dataFileName);
						}
					}
					else if (vendor.AgencyName == "Orlando-RedLight")
					{
						if (oldFileName.Substring(oldFileName.Length - 3) == "cit")
						{
							dataFileName = vendor.LocalPath + "\\" + oldFileName;
							log.Debug("Data file name: " + dataFileName + " for agency: " + vendor.AgencyName);
							allDataFiles.Add(dataFileName);
						}
					}
					/******************************* End of Red Light Code *************************************************************************/

					else if (vendor.AgencyName == "Edgewood" || vendor.AgencyName == "Apopka" || vendor.AgencyName == "OCSO" || vendor.AgencyName == "Eatonville")
					{
						if (oldFileName.Substring(oldFileName.Length - 3) == "cit")
						{
							dataFileName = vendor.LocalPath + "\\" + oldFileName;
							log.Debug("Data file name: " + dataFileName + " for agency: " + vendor.AgencyName);
							allDataFiles.Add(dataFileName);
						}
					}

					else if (vendor.AgencyName == "UCF")
					{
						if (oldFileName.Substring(oldFileName.Length - 3) == "cit")
						{
							dataFileName = vendor.LocalPath + "\\" + oldFileName;
							log.Debug("Data file name: " + dataFileName + " for agency: " + vendor.AgencyName);
							allDataFiles.Add(dataFileName);
						}
					}

					////////////////////////////////////////////
					// Adding CFX Toll T.M. 2/20/2017
					else if (vendor.AgencyName == "CFX")
					{
						if (oldFileName.Substring(oldFileName.Length - 7) == "cit.dat")
						{
							dataFileName = vendor.LocalPath + "\\" + oldFileName;
							log.Debug("Data file name: " + dataFileName + " for agency: " + vendor.AgencyName);
							allDataFiles.Add(dataFileName);
						}
					}
					else if (vendor.AgencyName == "LEA1")
					{
						if (oldFileName.Substring(oldFileName.Length - 3) == "cit")
						{
							dataFileName = vendor.LocalPath + "\\" + oldFileName;
							log.Debug("Data file name: " + dataFileName + " for agency: " + vendor.AgencyName);
							allDataFiles.Add(dataFileName);
						}
					}
					else { }
				}
			}
			catch (Exception exp)
			{
				log.Error(exp, "Failed to retrieve data file for [" + vendor.AgencyName + "]");
			}

			log.Info("End function DataFileName");

			return allDataFiles;
		}
	}
}

