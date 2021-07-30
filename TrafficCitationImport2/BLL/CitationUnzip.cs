using NLog;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using TrafficCitationImport2.Models;

namespace TrafficCitationImport2.BLL
{
	public class CitationUnzip
	{
		private static Logger log = LogManager.GetCurrentClassLogger();
		public void UnzipFile(VendorsInfo vendor, string localPath)
		{
			log.Info("Begin UnzipFile...");

			log.Debug("Current agency: [" + vendor.AgencyName + "]");

			try
			{
				string[] allFiles = Directory.GetFiles(localPath);

				foreach (string fileNameWithPath in allFiles)
				{
					string fileName = Path.GetFileName(fileNameWithPath);
					string fileExtension = Path.GetExtension(fileName);

					log.Debug("Unzipping file: [" + fileNameWithPath + "]");

					// Get the size of the zip file and skip files with zero sizes
					FileInfo fi = new FileInfo(fileNameWithPath);

					string prev_sourceZipFile = string.Empty;

					if (File.Exists(localPath + "\\" + fileName) && (fileExtension == ".zip" || fileExtension == ".ZIP") && fi.Length > 0)
					{
						string sourceZipFile = localPath + "\\" + fileName;

						log.Debug("Source zip file: [" + sourceZipFile + "]");

						if (!Directory.Exists(localPath + " \\temp")) Directory.CreateDirectory(localPath + " \\temp");

						List<string> tempFiles = Directory.GetFiles(localPath + " \\temp").ToList();
						foreach (var item in tempFiles)
						{
							if (File.Exists(item))
							{
								File.Delete(item);
							}
						}

						ZipFile.ExtractToDirectory(sourceZipFile, localPath + " \\temp");

						log.Debug("Finished unzipping file: " + sourceZipFile + " to directory: " + localPath + " \\temp");

						List<string> fileNames = Directory.GetFiles(localPath + " \\temp").ToList();
						foreach (var item in fileNames)
						{

							string destFile = localPath + "\\" + Path.GetFileName(item);

							MoveFilesBackFromTemp(item, destFile);

							log.Debug("Moving files from: " + item + " to directory: " + destFile);
						}

						prev_sourceZipFile = sourceZipFile;
					}
					else // skipping files with zero size bytes (do not unzip such files)
					{
						continue;
					}

					List<string> tempFiles2 = Directory.GetFiles(localPath + " \\temp").ToList();
					foreach (var item in tempFiles2)
					{
						if (File.Exists(item))
						{
							File.Delete(item);
						}
					}
				}
			}
			catch (Exception exp)
			{
				log.Error(exp, "Error during unziping a file");
			}

			log.Info("End UnzipFile");
		}

		public void MoveFilesBackFromTemp(string item, string destFile)
		{
			File.Copy(item, destFile, true);
			File.Delete(item);
		}

		public bool IsDirectoryEmpty(string path)
		{
			return !Directory.EnumerateFileSystemEntries(path).Any();
		}

	}
}
