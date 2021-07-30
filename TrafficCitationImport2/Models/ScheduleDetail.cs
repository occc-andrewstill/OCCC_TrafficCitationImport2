using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TrafficCitationImport2.Models
{
	public class ScheduleDetail
	{
		//private string _serviceCode;
		//private DateTime _runTime;
		//private string _runType;

		public int RunId { get; set; }
		public string ServiceCode { get; set; }

		public DateTime RunTime { get; set; }
		public string RunType { get; set; }
		public bool RunNow { get; set; }

	}
}
