using NLog;
using System;
using System.IO;
using TrafficCitationImport2.Models;

namespace TrafficCitationImport2.BLL
{
	public class CitationImageStamp
	{
		private static Logger log = LogManager.GetCurrentClassLogger();
		public void ImageStamp(VendorsInfo vendor)
		{
			log.Info("Begin ImageStamp...");

			log.Debug("Stamping images for: [" + vendor.AgencyName + "]");

			try
			{
				Neevia.docCreator dc = new Neevia.docCreator();

				dc.setParameter("StampX", "10");
				dc.setParameter("StampY", "20");
				dc.setParameter("StampFontName", "Arial");
				dc.setParameter("StampFontSize", "7");
				dc.setParameter("StampFontColor", "$000000");
				dc.setParameter("StampText", DateTime.Now + " FILED IN OFFICE CLERK OF COURT ORANGE COUNTY");

				dc.setParameter("PlaceStampOnPages", "1");

				string[] allFiles = Directory.GetFiles(vendor.LocalPath);
				foreach (string fileNameWithPath in allFiles)
				{
					log.Debug("Stamping image: [" + fileNameWithPath + "]");

					string fileName = Path.GetFileName(fileNameWithPath);
					string fileExtension = Path.GetExtension(fileNameWithPath);

					if (fileExtension == ".pdf" || fileExtension == ".PDF")
					{
						int rVal = dc.stampPDF(vendor.LocalPath + "\\" + fileName, vendor.LocalPath + "\\" + fileName);
					}
				}
			}
			catch (Exception exp)
			{
				log.Error(exp, "An error has occurred stamping the image");
			}

			log.Info("End ImageStamp");

		}

	}
}

