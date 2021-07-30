using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TrafficCitationImport2.Models
{
	public class ImageDetail
	{
		private string fullPath;
		public string FullPath
		{
			get
			{
				return this.fullPath;
			}
			set
			{
				this.fullPath = value;
			}
		}

		public string FileNameWithExtension
		{
			get
			{
				FileInfo thisFile = new FileInfo(fullPath);

				return thisFile.Name;
			}
		}

		public string Name
		{
			get
			{
				FileInfo thisFile = new FileInfo(fullPath);

				string file = thisFile.Name;

				int length = file.Length;


				return file.Substring(0, length - 4);
			}
		}
	}
}
