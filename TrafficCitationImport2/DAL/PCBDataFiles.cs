using System;
using System.Collections.Generic;
using System.IO;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using NLog;
using TrafficCitationImport2.Models;
using TrafficCitationImport2.BLL;

namespace TrafficCitationImport2.DAL
{
	public class PCBDataFiles
	{
		private static Logger logger = LogManager.GetCurrentClassLogger();

		public void PCBDataFile(VendorsInfo vendor, string filePath, string fileLogId)
		{
			logger.Info("Begin PCBDataFile...");

			try
			{
				// Add a datatable with same structure as the target table in the database
				logger.Debug("Creating temp table to hold records before bulk copy");

				var dt = new DataTable();

				// Add columns to the datatable
				dt.Columns.Add("UpdateType", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("CitationNumber", typeof(string)).AllowDBNull = false;
				dt.Columns.Add("CheckDigit", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("CountyNumber", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("JurisdictionNumber", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("CityName", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("IssueAgencyType", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("IssueAgencyCode", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("IssueAgencyName", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DayofWeek", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("OffenseDate", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("OffenseTime", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("OffenseTimeAMPM", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DriverFirstName", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DriverMiddleName", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DriverLastName", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DriverSuffix", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("StreetAddress", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("AddressDiffLicense", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("City", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("StateofDriversAddress", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ZipCode", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("Telephone", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("BirthDate", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("Race", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("Sex", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("Height", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DriverLicenseNumber", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DriverLicenseState", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DriverLicenseClass", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationExpiredDL", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("CommercialVehicleCode", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("VehicleYear", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("VehicleMake", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("VehicleStyle", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("VehiclyColor", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("HazardousMaterials", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("VehicleTagNumber", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("VehicleTrailerNumber", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("VehicleState", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("VehicleTagExpYear", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("CompanionCitation", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationLocation", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DistanceFeet", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DistanceMiles", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DirectionN", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DirectionS", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DirectionE", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DirectionW", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("OfNode", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ActualSpeed", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("PostedSpeed", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("Hwy4Lane", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("HwyInterstate", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationCareless", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationDevice", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationRow", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationLane", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationPassing", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationChildRestraint", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationDUI", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("BloodAlcoholLevel", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationSeatBelt", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationEquipment", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationTagLess", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationTagMore", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationInsurance", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationExpiredDriverLicense", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationExpiredDLMore", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationNoDL", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationSuspendedDL", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("OtherComments", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationCode", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("FLDLEditOverride", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("StateStatuteIndicator", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("Section", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("SubSection", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("Crash", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("PropertyDamage", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("PropertyDamageAmount", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("Injury", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("SeriousInjury", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("FatalInjury", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("MethodOfArrest", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("CriminalCourtReq", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("InfractionCourtReq", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("InfractionNoCourtReq", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("CourtDate", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("CourtTime", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("CourtName", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("CourtTimeAMPM", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("CourtAddress", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("CourtCity", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("CourtState", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("CourtZip", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ArrestDeliveredTo", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ArrestDeliveredDate", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("OfficerRank", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("OfficerFirstName", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("OfficerMiddleName", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("OfficerLastName", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("OfficerBadgeNumber", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("OfficerId", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("TrooperUnit", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("Bal08Above", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DUIRefuse", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DUILicenseSurrendered", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DUILicenseRSN", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DuiEligible", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DUIEligibleRSN", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DUIBarOffice", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("Status", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("AggressiveDriverFlag", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("CriminalIndicator", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("FileAmount", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("Filler", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("IssueArrestDate", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("OfficerDeliveryVerification", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DueDate", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("Motorcycle", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("PassengerVehicle16", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("OfficerReExamFlag", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DUIViolationUnder18", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ECitationIndicator", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("NameChange", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("CommercialDL", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("GPSLat", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("GPSLong", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationSignalRedLight", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationWorkersPresent", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationHandHeld", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ViolationSchoolZone", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("AgencyIdentifier", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("PermanentRegistration", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("SpeedMeasuringDeviceId", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("ComplianceDate", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("DLSeize", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("Business", typeof(string)).AllowDBNull = true;
				dt.Columns.Add("FileLogId", typeof(string)).AllowDBNull = true;

				int recordCount = 0;

				var fileData = File.ReadAllLines(filePath);


				logger.Debug("Building temp table for SQL bulk copy operation");
				foreach (string line in fileData)
				{
					if ((line.Substring(0, 4) == "EOF|"))
					{
						// get the record count
						int index1 = line.IndexOf('|') + 1;
						int index2 = line.IndexOf('|', line.IndexOf('|') + 1) - 1;

						recordCount = int.Parse(line.Substring(index1, index2 - index1 + 1));

						logger.Debug("Data file contains [" + recordCount + "] records");
					}
					else
					{
						dt.Rows.Add(line.Split('|'));
					}

				}
				logger.Debug("Temp table created");

				using (ReferenceEntities db = new ReferenceEntities())
				{
					SqlConnection sqlCon = new SqlConnection(db.Database.Connection.ConnectionString);
					sqlCon.Open();
					using (SqlBulkCopy s = new SqlBulkCopy(sqlCon.ConnectionString, SqlBulkCopyOptions.CheckConstraints))
					{
						foreach (var column in dt.Columns)
						{
							s.ColumnMappings.Add(column.ToString(), column.ToString());
						}

						//set the table name
						s.DestinationTableName = "dbo.TrafficCitation_Import";

						logger.Debug("Before SQL bulk copy operation");
						s.WriteToServer(dt);

						// Update record count
						UpdateDataFileRecordCount updateDataFileRecordCount = new UpdateDataFileRecordCount();
						updateDataFileRecordCount.UpdateRecordCount(vendor, filePath, recordCount);
						logger.Debug("After SQL bulk copy operation");
					}

					sqlCon.Close();
				}

				int vendorId = vendor.VendorAgencyId;

				// call the TrafficCitationImport_UpdateFileLogId stored procedure and pass FileLogId
				SqlParameter param1 = new SqlParameter("@FileLogId", fileLogId);

				ReferenceEntities db2 = new ReferenceEntities();

				logger.Debug("Begin TrafficCitationImport_UpdateFileLogId SP for agency: [" + vendor.AgencyName + "]");
				db2.Database.ExecuteSqlCommand("Execute OdyClerkInternal.dbo.TrafficCitationImport_UpdateFileLogId @FileLogId", param1);
				logger.Debug("End TrafficCitationImport_UpdateFileLogId SP for agency: [" + vendor.AgencyName + "]");
			}
			catch (Exception ex)
			{
				logger.Error(ex, "Inside PCBDataFile method - Error :");
			}

			logger.Info("End PCBDataFile");
		}


	}
}