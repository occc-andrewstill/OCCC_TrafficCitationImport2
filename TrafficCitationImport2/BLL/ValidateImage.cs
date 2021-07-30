using NLog;
using System;
using System.Collections.Generic;
using System.IO;
using TrafficCitationImport2.Models;

namespace TrafficCitationImport2.BLL
{
	public class ValidateImage
	{
		private static Logger log = LogManager.GetCurrentClassLogger();
		public List<ImageDetail> GetPDFDocumentList(string folder)
		{
			log.Info("Begin GetPDFDocumentList...");

			List<ImageDetail> images = new List<ImageDetail>();

			log.Debug("Validating images at folder [" + folder + "]");

			try
			{
				string[] pdfDocuments = Directory.GetFileSystemEntries(folder, "*.pdf", SearchOption.TopDirectoryOnly);

				foreach (string pdfDocument in pdfDocuments)
				{
					log.Debug("Currently processing document [" + pdfDocument + "]");
					ImageDetail id = new ImageDetail();
					id.FullPath = pdfDocument;

					images.Add(id);

					log.Debug("Sucessfully processed document [" + pdfDocument + "]");
				}
			}
			catch (Exception ex)
			{
				log.Error(ex, "Error while preparing document list");
			}

			log.Info("End GetPDFDocumentList");

			return images;
		}
	}
}
