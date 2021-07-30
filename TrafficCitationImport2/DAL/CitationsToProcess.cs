using NLog;
using System;
using System.Collections.Generic;
using System.Linq;
using TrafficCitationImport2.BLL;

namespace TrafficCitationImport2.DAL
{
	public class CitationsToProcess
	{
		private static Logger log = LogManager.GetCurrentClassLogger();
		public List<string> GetCitations(string fileLogId)
		{
			log.Info("Begin GetCitations...");
			log.Debug("Processing fileLogId [" + fileLogId + "]");

			List<string> citations = new List<string>();

			using (ReferenceEntities db = new ReferenceEntities())
			{
				try
				{
					var result = (from record in db.TrafficCitation_Import
								  where (record.FileLogId == fileLogId)
								  && record.Processed == false
								  && record.Has_Image == true
								  && record.CaseId == null
								  && (record.WorkFlowItemId == null || record.ExceptionFlag == 2)
								  && (record.ExceptionFlag == 0 ||
									  record.ExceptionFlag == -1 ||
									  record.ExceptionFlag == -2 ||
									  record.ExceptionFlag == 2)
								  select record.CitationNumber).ToList();

					citations = result;

					log.Debug("Retrieved [" + citations.Count + "] citations");
				}
				catch (Exception exp)
				{
					log.Error(exp, "Error inside GetCitations function");
				}

			}

			log.Info("End GetCitations");

			return citations;
		}
	}
}
