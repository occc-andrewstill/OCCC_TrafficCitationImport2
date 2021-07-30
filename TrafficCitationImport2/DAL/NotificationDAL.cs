using NLog;
using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace TrafficCitationImport2.DAL
{
	public class NotificationDAL
	{

		private static Logger logger = LogManager.GetCurrentClassLogger();

		public void AddNotification(string serviceCode, string statusMessage)
		{
			logger.Info("Start");

			string proc = "usp_NotificationAdd";
			SqlConnection conn = GetConnection();

			SqlCommand cmd = new SqlCommand();
			cmd.CommandText = proc;
			cmd.CommandType = CommandType.StoredProcedure;

			SqlParameter pServiceCode = new SqlParameter();
			pServiceCode.ParameterName = "serviceCode";
			pServiceCode.DbType = DbType.String;
			pServiceCode.Value = serviceCode;
			cmd.Parameters.Add(pServiceCode);

			SqlParameter pStatusMessage = new SqlParameter();
			pStatusMessage.ParameterName = "statusMessage";
			pStatusMessage.DbType = DbType.String;
			pStatusMessage.Value = statusMessage;
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
				//throw new Exception("FAILED TO ADD NOTIFICATION");
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
