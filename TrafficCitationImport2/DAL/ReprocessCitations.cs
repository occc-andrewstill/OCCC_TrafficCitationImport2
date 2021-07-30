using NLog;
using System;
using System.Collections.Generic;
using System.Linq;

namespace TrafficCitationImport2.DAL
{
	public class ReprocessCitations
	{
		private static Logger log = LogManager.GetCurrentClassLogger();
		public List<string> GetFailedCitations()
		{
			log.Info("Start function GetFailedCitations");
			log.Debug("Inside GetFailedCitations function - processing fileLogId ");

			List<string> citations = new List<string>();

			DateTime sinceRunDate = DateTime.Today.AddDays(-10);
			string startRunDate = sinceRunDate.ToString("yyyy-MM-dd");

			using (ReferenceEntities db = new ReferenceEntities())
			{
				try
				{
					var result = (from record in db.TrafficCitation_Import
								  where record.RunDate >= sinceRunDate
								  && record.Processed == false
								  && record.Has_Image == true
								  && record.CaseId == null
								  && (record.WorkFlowItemId == null || record.ExceptionFlag == 2)
								  && (record.ExceptionFlag == -1 || record.ExceptionFlag == -2)
								  select record.CitationNumber).ToList();

					citations = result;

					log.Debug("Prepared list of citations for processing: " + citations);
				}
				catch (Exception exp)
				{
					log.Error("Error inside GetCitations function: " + exp.ToString() + "");
				}

			}

			log.Info("End function GetFailedCitations");

			return citations;
		}
	}
}
