using NLog;
using System;
using System.IO;
using TrafficCitationImport2.Models;

namespace TrafficCitationImport2.BLL
{
	public class CitationRename
	{
		private static Logger log = LogManager.GetCurrentClassLogger();
		public void CitationImageRename(VendorsInfo vendor, string localpath)
		{
			log.Info("Begin CitationImageRename...");

			try
			{
				int startPos = 0;

				//loop through each directory and rename all pdf images to match citation number
				string oldFileName = "", newFileName = "", fileExtension = "";
				string[] allFiles = Directory.GetFiles(vendor.LocalPath);

				log.Debug("Current Agency: [" + vendor.AgencyName + "]");

				foreach (string fileNameWithPath in allFiles)
				{
					oldFileName = Path.GetFileName(fileNameWithPath);
					fileExtension = Path.GetExtension(fileNameWithPath);

					log.Debug("Original File Name: [" + oldFileName + " / " + fileExtension + "]");

					if (vendor.AgencyName == "FHP")
					{
						if ((fileExtension == ".PDF" || fileExtension == ".pdf"))
						{
							newFileName = oldFileName.Replace("UTC", "").Replace("ORANGE", "").Replace("---", "").Replace("-", "").Replace(" ", "");
							if (!File.Exists(vendor.LocalPath + "\\" + newFileName))
							{
								log.Debug("Moving file from: [" + vendor.LocalPath + "\\" + oldFileName + "] to [" + vendor.LocalPath + "\\" + newFileName + "]");
								File.Move(vendor.LocalPath + "\\" + oldFileName, vendor.LocalPath + "\\" + newFileName);
							}
							else
                            {
								log.Debug("File already exists: [" + vendor.LocalPath + "\\" + newFileName + "]");
							}

							File.Delete(vendor.LocalPath + "\\" + oldFileName);
						}

						log.Debug("New File Name: [" + newFileName + "]");

					}
					/************ New code for Winter Garden, Oakland and Ocoee  T.M. 7/16/2015 *******/
					else if (vendor.AgencyName == "Ocoee")
					{
						log.Debug("Original File Name: [" + oldFileName + " / " + fileExtension + "]");

						if ((fileExtension == ".PDF" || fileExtension == ".pdf"))
						{
							newFileName = oldFileName.Replace("UTC", "").Replace("ORANGE", "").Replace("---", "").Replace("-", "").Replace(" ", "");
							if (!File.Exists(vendor.LocalPath + "\\" + newFileName))
							{
								log.Debug("Moving file from: [" + vendor.LocalPath + "\\" + oldFileName + "] to [" + vendor.LocalPath + "\\" + newFileName + "]");
								File.Move(vendor.LocalPath + "\\" + oldFileName, vendor.LocalPath + "\\" + newFileName);
							}
							else
							{
								log.Debug("File already exists: [" + vendor.LocalPath + "\\" + newFileName + "]");
							}
						}

						log.Debug("New File Name: [" + newFileName + "]");
					}
					else if (vendor.AgencyName == "Oakland")
					{
						log.Debug("Original File Name: [" + oldFileName + " / " + fileExtension + "]");

						if ((fileExtension == ".PDF" || fileExtension == ".pdf"))
						{
							newFileName = oldFileName.Replace("UTC", "").Replace("ORANGE", "").Replace("---", "").Replace("-", "").Replace(" ", "");
							if (!File.Exists(vendor.LocalPath + "\\" + newFileName))
							{
								log.Debug("Moving file from: [" + vendor.LocalPath + "\\" + oldFileName + "] to [" + vendor.LocalPath + "\\" + newFileName + "]");
								File.Move(vendor.LocalPath + "\\" + oldFileName, vendor.LocalPath + "\\" + newFileName);
							}
							else
							{
								log.Debug("File already exists: [" + vendor.LocalPath + "\\" + newFileName + "]");
							}
						}

						log.Debug("New File Name: [" + newFileName + "]");
					}
					else if (vendor.AgencyName == "Winter Garden")
					{
						log.Debug("Original File Name: [" + oldFileName + " / " + fileExtension + "]");

						if ((fileExtension == ".PDF" || fileExtension == ".pdf"))
						{
							newFileName = oldFileName.Replace("UTC", "").Replace("ORANGE", "").Replace("---", "").Replace("-", "").Replace(" ", "");
							if (!File.Exists(vendor.LocalPath + "\\" + newFileName))
							{
								log.Debug("Moving file from: [" + vendor.LocalPath + "\\" + oldFileName + "] to [" + vendor.LocalPath + "\\" + newFileName + "]");
								File.Move(vendor.LocalPath + "\\" + oldFileName, vendor.LocalPath + "\\" + newFileName);
							}
							else
							{
								log.Debug("File already exists: [" + vendor.LocalPath + "\\" + newFileName + "]");
							}
						}

						log.Debug("New File Name: [" + newFileName + "]");
					}
					else if (vendor.AgencyName == "Windermere")
					{
						log.Debug("Original File Name: [" + oldFileName + " / " + fileExtension + "]");

						if ((fileExtension == ".PDF" || fileExtension == ".pdf"))
						{
							newFileName = oldFileName.Replace("UTC", "").Replace("ORANGE", "").Replace("---", "").Replace("-", "").Replace(" ", "");
							if (!File.Exists(vendor.LocalPath + "\\" + newFileName))
							{
								log.Debug("Moving file from: [" + vendor.LocalPath + "\\" + oldFileName + "] to [" + vendor.LocalPath + "\\" + newFileName + "]");
								File.Move(vendor.LocalPath + "\\" + oldFileName, vendor.LocalPath + "\\" + newFileName);
							}
							else
							{
								log.Debug("File already exists: [" + vendor.LocalPath + "\\" + newFileName + "]");
							}
						}

						log.Debug("New File Name: [" + newFileName + "]");
					}
					/******************************* End code for Winter Garden, Oakland and Ocoee **********************************************/

					/******************************* Code for Red Light Agencies .. RLCApopkaPD, RLCOrlando and RLCOcoee  *************************/
					else if (vendor.AgencyName == "Apopka-RedLight")
					{
						log.Debug("Original File Name: [" + oldFileName + " / " + fileExtension + "]");

						if ((fileExtension == ".PDF" || fileExtension == ".pdf"))
						{
							newFileName = oldFileName.Substring(startPos, 7) + /* "O" + */ ".pdf"; // <-- use this for Apopka Reg Light
							if (!File.Exists(vendor.LocalPath + "\\" + newFileName))
							{
								log.Debug("Moving file from: [" + vendor.LocalPath + "\\" + oldFileName + "] to [" + vendor.LocalPath + "\\" + newFileName + "]");
								File.Move(vendor.LocalPath + "\\" + oldFileName, vendor.LocalPath + "\\" + newFileName);
							}
							else
							{
								log.Debug("File already exists: [" + vendor.LocalPath + "\\" + newFileName + "]");
							}
						}

						log.Debug("New File Name: [" + newFileName + "]");
					}

					else if (vendor.AgencyName == "Ocoee-RedLight")
					{
						log.Debug("Original File Name: [" + oldFileName + " / " + fileExtension + "]");

						if ((fileExtension == ".PDF" || fileExtension == ".pdf"))
						{
							newFileName = oldFileName.Substring(startPos, 7) + /* "O" + */ ".pdf"; // <-- use this for Apopka Reg Light
							if (!File.Exists(vendor.LocalPath + "\\" + newFileName))
							{
								log.Debug("Moving file from: [" + vendor.LocalPath + "\\" + oldFileName + "] to [" + vendor.LocalPath + "\\" + newFileName + "]");
								File.Move(vendor.LocalPath + "\\" + oldFileName, vendor.LocalPath + "\\" + newFileName);
							}
							else
							{
								log.Debug("File already exists: [" + vendor.LocalPath + "\\" + newFileName + "]");
							}
						}

						log.Debug("New File Name: [" + newFileName + "]");
					}


					else if (vendor.AgencyName == "Orlando-RedLight")
					{
						log.Debug("Original File Name: [" + oldFileName + " / " + fileExtension + "]");

						if ((fileExtension == ".PDF" || fileExtension == ".pdf"))
						{
							newFileName = oldFileName.Substring(startPos, 7) +  /* "O" + */ ".pdf"; // <-- use this for Apopka Reg Light
							if (!File.Exists(vendor.LocalPath + "\\" + newFileName))
							{
								log.Debug("Moving file from: [" + vendor.LocalPath + "\\" + oldFileName + "] to [" + vendor.LocalPath + "\\" + newFileName + "]");
								File.Move(vendor.LocalPath + "\\" + oldFileName, vendor.LocalPath + "\\" + newFileName);
							}
							else
							{
								log.Debug("File already exists: [" + vendor.LocalPath + "\\" + newFileName + "]");
							}
						}

						log.Debug("New File Name: [" + newFileName + "]");

					}
					/******************************* End of Red Light Code *************************************************************************/

					else if (vendor.AgencyName == "Edgewood" || vendor.AgencyName == "Apopka" || vendor.AgencyName == "OCSO" || vendor.AgencyName == "Eatonville")
					{
						log.Debug("Original File Name: [" + oldFileName + " / " + fileExtension + "]");

						if (oldFileName.Contains("_") && (fileExtension == ".PDF" || fileExtension == ".pdf") && oldFileName.Substring(0, 9) != "CourtInfo")
						{
							startPos = oldFileName.IndexOf("_") + 1;
							newFileName = oldFileName.Substring(startPos, 7) + ".pdf";
							// Copy the code below to all other agencies when bringing each one live
							if (!File.Exists(vendor.LocalPath + "\\" + newFileName))
							{
								log.Debug("Moving file from: [" + vendor.LocalPath + "\\" + oldFileName + "] to [" + vendor.LocalPath + "\\" + newFileName + "]");
								File.Move(vendor.LocalPath + "\\" + oldFileName, vendor.LocalPath + "\\" + newFileName);
							}
							else
							{
								log.Debug("File already exists: [" + vendor.LocalPath + "\\" + newFileName + "]");
							}
							File.Delete(vendor.LocalPath + "\\" + oldFileName);
						}

						log.Debug("New File Name: [" + newFileName + "]");
					}

					else if (vendor.AgencyName == "UCF")
					{
						log.Debug("Original File Name: [" + oldFileName + " / " + fileExtension + "]");

						if (oldFileName.Contains("_") && (fileExtension == ".PDF" || fileExtension == ".pdf"))
						{
							newFileName = oldFileName.Split('_')[1];
							newFileName = newFileName + ".pdf";

							if (!File.Exists(vendor.LocalPath + "\\" + newFileName))
							{
								log.Debug("Moving file from: [" + vendor.LocalPath + "\\" + oldFileName + "] to [" + vendor.LocalPath + "\\" + newFileName + "]");
								File.Move(vendor.LocalPath + "\\" + oldFileName, vendor.LocalPath + "\\" + newFileName);
							}
							else
							{
								log.Debug("File already exists: [" + vendor.LocalPath + "\\" + newFileName + "]");
							}
							File.Delete(vendor.LocalPath + "\\" + oldFileName);
						}

						log.Debug("New File Name: [" + newFileName + "]");
					}

					////////////////////////////////////////////
					// Adding CFX Toll T.M. 2/20/2017
					else if (vendor.AgencyName == "CFX")
					{
						log.Debug("Original File Name: [" + oldFileName + " / " + fileExtension + "]");

						if (oldFileName.Contains("_") && (fileExtension == ".PDF" || fileExtension == ".pdf"))
						{
							startPos = oldFileName.IndexOf("_") + 1;
							newFileName = oldFileName.Substring(startPos, 7) + ".pdf";

							// Copy the code below to all other agencies when bringing each one live
							if (!File.Exists(vendor.LocalPath + "\\" + newFileName))
							{
								log.Debug("Moving file from: [" + vendor.LocalPath + "\\" + oldFileName + "] to [" + vendor.LocalPath + "\\" + newFileName + "]");
								File.Move(vendor.LocalPath + "\\" + oldFileName, vendor.LocalPath + "\\" + newFileName);
							}
							else
							{
								log.Debug("File already exists: [" + vendor.LocalPath + "\\" + newFileName + "]");
							}
							File.Delete(vendor.LocalPath + "\\" + oldFileName);
						}

						log.Debug("New File Name: [" + newFileName + "]");
					}
				}
			}
			catch (Exception exp)
			{
				log.Error(exp, "A CitationImageRename error has occurred");
			}

			log.Info("End function CitationImageRename");
		}

	}

}


