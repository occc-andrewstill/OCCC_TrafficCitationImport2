using NLog;
using System;
using System.Linq;

namespace TrafficCitationImport2.DAL
{
	public class MarkReceivedImages
	{
		private static Logger log = LogManager.GetCurrentClassLogger();
		public void MarkImages(string citationImage)
		{
			log.Info("Begin MarkImages...");
			try
			{
				log.Debug("Citation Image [" + citationImage + "]");
				using (ReferenceEntities db = new ReferenceEntities())
				{
					log.Debug("Using ReferenceEntities");
					var result = db.TrafficCitation_Import.SingleOrDefault(x => x.CitationNumber == citationImage);
					if (result != null)
					{
						log.Debug("Found the record for [" + citationImage + "]");
						result.Has_Image = true;
						db.SaveChanges();
						log.Debug("Result saved for [" + citationImage + "]");
					}
				}
			}
			catch (Exception ex)
			{
				log.Error(ex, "Error while processing citation image [" + citationImage + "]");
			}

			log.Info("End MarkImages");
		}
	}
}