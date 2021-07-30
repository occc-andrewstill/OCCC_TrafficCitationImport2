using NLog;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TrafficCitationImport2.Models;

namespace TrafficCitationImport2.DAL
{
	public class ScheduleDAL
	{
		private static Logger logger = LogManager.GetCurrentClassLogger();
		public ScheduleDetail GetNextRunTime(string serviceCode)
		{
			string proc = "usp_GetServiceNextRunTime";
			ScheduleDetail rtd = new ScheduleDetail();

			SqlConnection conn = GetConnection();

			SqlCommand cmd = new SqlCommand();
			cmd.CommandText = proc;
			cmd.CommandType = CommandType.StoredProcedure;

			SqlParameter pServiceCode = new SqlParameter();
			pServiceCode.ParameterName = "ServiceCode";
			pServiceCode.DbType = DbType.String;
			pServiceCode.Value = serviceCode;
			cmd.Parameters.Add(pServiceCode);
			try
			{
				cmd.Connection = conn;
				conn.Open();
				SqlDataReader reader = cmd.ExecuteReader();

				if (reader.Read())
				{
					var value = reader["RunId"];
					rtd.RunId = Convert.ToInt32(reader["RunId"].ToString());
					rtd.RunTime = Convert.ToDateTime(reader["RunTime"].ToString());
					rtd.RunType = reader["RunType"].ToString();
				}
			}
			catch (Exception exp)
			{
				logger.Error(exp, exp.Message);
				throw new Exception("FAILED TO GET NEXT RUN TIME");
			}
			finally
			{
				if (conn != null)
				{
					conn.Close();
				}
				logger.Info("End");
			}
			return rtd;
		}

		public void SetNextRunTime(string serviceCode, int thisRunId, DateTime nextRunTime, string runType)
		{
			logger.Info("Start");
			string proc = "usp_SetServiceNextRunTime";
			SqlConnection conn = GetConnection();

			SqlCommand cmd = new SqlCommand();
			cmd.CommandText = proc;
			cmd.CommandType = CommandType.StoredProcedure;

			SqlParameter pServiceCode = new SqlParameter();
			pServiceCode.ParameterName = "serviceCode";
			pServiceCode.DbType = DbType.String;
			pServiceCode.Value = serviceCode;
			cmd.Parameters.Add(pServiceCode);

			SqlParameter pThisRunId = new SqlParameter();
			pThisRunId.ParameterName = "previousRunId";
			pThisRunId.DbType = DbType.Int32;
			pThisRunId.Value = thisRunId;
			cmd.Parameters.Add(pThisRunId);

			SqlParameter pNextRunTime = new SqlParameter();
			pNextRunTime.ParameterName = "nextRunTime";
			pNextRunTime.DbType = DbType.DateTime;
			pNextRunTime.Value = nextRunTime;
			cmd.Parameters.Add(pNextRunTime);

			SqlParameter pRunType = new SqlParameter();
			pRunType.ParameterName = "runType";
			pRunType.DbType = DbType.String;
			pRunType.Value = runType;
			cmd.Parameters.Add(pRunType);

			try
			{
				cmd.Connection = conn;
				conn.Open();

				cmd.ExecuteNonQuery();

			}
			catch (Exception exp)
			{
				logger.Error(exp, exp.Message);
				throw new Exception("FAILED TO SET NEXT RUN TIME");
			}
			finally
			{
				if (conn != null)
				{
					conn.Close();
				}
				logger.Info("End");
			}
		}

		public void UpdateRunTime(int runId, string statusmessage)
		{
			//logger.Info("Start");
			string proc = "usp_SchedulerRunTimeUpdate";
			SqlConnection conn = GetConnection();

			SqlCommand cmd = new SqlCommand();
			cmd.CommandText = proc;
			cmd.CommandType = CommandType.StoredProcedure;

			SqlParameter pRunId = new SqlParameter();
			pRunId.ParameterName = "runId";
			pRunId.DbType = DbType.Int32;
			pRunId.Value = runId;
			cmd.Parameters.Add(pRunId);

			SqlParameter pStatusMessage = new SqlParameter();
			pStatusMessage.ParameterName = "statusMessage";
			pStatusMessage.DbType = DbType.String;
			pStatusMessage.Value = statusmessage;
			cmd.Parameters.Add(pStatusMessage);

			try
			{
				cmd.Connection = conn;
				conn.Open();

				cmd.ExecuteNonQuery();

			}
			catch (Exception exp)
			{
				logger.Error(exp, exp.Message);
				throw new Exception("FAILED TO UPDATE RUN TIME");
			}
			finally
			{
				if (conn != null)
				{
					conn.Close();
				}
				//logger.Info("End");
			}
		}

		private SqlConnection GetConnection()
		{
			logger.Info("Start");

			string connection = ConfigurationManager.ConnectionStrings["Schedule"].ConnectionString;
			SqlConnection conn = new SqlConnection(connection);

			logger.Info("End");

			return conn;
		}
	}
}
