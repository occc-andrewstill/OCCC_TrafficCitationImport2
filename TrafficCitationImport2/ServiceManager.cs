using System;
using System.Timers;
using NLog;
using System.Configuration;
using TrafficCitationImport2.Models;
using TrafficCitationImport2.DAL;
using TrafficCitationImport2.BLL;

namespace TrafficCitationImport2
{
	public class ServiceManager
	{
		private readonly Timer _timer;
		private static Logger logger = LogManager.GetCurrentClassLogger();
		private static string _serviceCode;
		private static bool _customerTimer;
		private static int _runInterval;
		private static DateTime _initialRunTime;

		public ServiceManager()
		{
			//Defaults
			int timerInterval = 60000;
			_serviceCode = "TCI2";
			_customerTimer = false;
			_runInterval = 1;
			_initialRunTime = DateTime.Now;

			//This is the timer interval that the windows service will run.
			logger.Info("Service manager constructor start");
			timerInterval = Convert.ToInt32(ConfigurationManager.AppSettings["TimerInterval"]);
			_timer = new Timer(timerInterval) { AutoReset = true };
			_timer.Elapsed += TimerElapsed;

			_serviceCode = ConfigurationManager.AppSettings["ServiceCode"].ToString();
			_customerTimer = Convert.ToBoolean(ConfigurationManager.AppSettings["CustomTimer"]);
			_runInterval = Convert.ToInt32(ConfigurationManager.AppSettings["RunIntervalMinutes"]);
			_initialRunTime = Convert.ToDateTime(ConfigurationManager.AppSettings["InitialRunTime"]);

			logger.Debug("Timer Interval [" + timerInterval.ToString() + "]");
			logger.Debug("ServiceCode [" + _serviceCode + "]");
			logger.Debug("Custom Time [" + _customerTimer.ToString() + "]");
			logger.Debug("Initial Run Time from configuration [" + _initialRunTime.ToShortDateString() + " " + _initialRunTime.ToShortTimeString() + "]");

			try
			{
				SetIntialRunTime();

				logger.Debug("Initial run time set");
			}
			catch (Exception exp)
			{
				logger.Error(exp, exp.Message);
			}

			string statusMessage = "Service has been initialized";
			SetNotification(_serviceCode, statusMessage);

			logger.Info("Service manager constructor end");
		}

		public void Start()
		{
			logger.Debug("Start service");
			_timer.Start();
			string statusMessage = "Service has started";
			SetNotification(_serviceCode, statusMessage);
		}

		public void Stop()
		{
			logger.Debug("Stop service");
			_timer.Stop();
			string statusMessage = "Service has stopped";
			SetNotification(_serviceCode, statusMessage);
		}

		public void TimerElapsed(object sender, ElapsedEventArgs e)
		{
			//logger.Info("Start time elapsed");
			int runId = 0;
			//string serviceCode = GetServiceCode();

			try
			{
				ScheduleDetail rtd = GetRunTimeDetails(_serviceCode);
				runId = rtd.RunId;

				if (rtd.RunNow)
				{
					_timer.Enabled = false;
					logger.Debug("Tasks to be run, timer disabled");

					SetNotification(_serviceCode, "Service/Task running");

					TaskManager tm = new TaskManager();
					tm.Run();

					//tm.Run(_serviceCode);
					logger.Debug("Tasks are complete");

					UpdateRunTimeRecord(rtd.RunId, "Run");

					if (rtd.RunType == "S")
					{
						logger.Debug("This run was a service run");
						DateTime nextRunTime = GetNextRunTime(rtd.RunTime);
						rtd.RunTime = nextRunTime;
						SetNextRunTime(rtd);
					}

					SetNotification(_serviceCode, "Service/Task completed");

					logger.Debug("Task complete");
				}
				else
				{
				}
			}
			catch (Exception exp)
			{
				logger.Error(exp, exp.Message);

				UpdateRunTimeRecord(runId, exp.Message);

				SetNotification(_serviceCode, "Service/Task exception [" + exp.Message + "]");

			}
			finally
			{
				_timer.Enabled = true;
				//logger.Debug("Timer enabled");
			}

			//logger.Info("End time elapsed");
		}

		private ScheduleDetail GetRunTimeDetails(string serviceCode)
		{
			//This reference code uses config values.
			//It is acceptable for this function to be accomplished from a database call

			ScheduleDAL rt = new ScheduleDAL();

			ScheduleDetail rtd = rt.GetNextRunTime(serviceCode);
			rtd.RunNow = false;

			DateTime current = DateTime.Now;
			int currentSecond = current.Second;
			int currentMinute = current.Minute;
			int currentHour = current.Hour;

			int runTimeHour = rtd.RunTime.Hour;
			int runTimeMinute = rtd.RunTime.Minute;
			int runTimeSecord = rtd.RunTime.Second;

			if ((currentHour == runTimeHour) && (currentMinute == runTimeMinute))
			{
				rtd.RunNow = true;
			}

			return rtd;
		}

		private void SetNextRunTime(ScheduleDetail rtd)
		{
			string runType = "S";
			int thisRunId = rtd.RunId;

			logger.Debug("Next run [" + rtd.RunTime.ToShortDateString() + " " + rtd.RunTime.ToShortTimeString() + "]");

			ScheduleDAL rt = new ScheduleDAL();
			rt.SetNextRunTime(_serviceCode, rtd.RunId, rtd.RunTime, runType);
		}

		private DateTime GetNextRunTime(DateTime runTime)
		{
			DateTime nextRunTime = DateTime.Parse("1/1/1970");

			if (_customerTimer)
			{
				nextRunTime = CustomSetNextRunTime();
			}
			else
			{
				logger.Debug("Interval minutes [" + _runInterval.ToString() + "]");

				nextRunTime = runTime.AddMinutes(_runInterval);
			}
			logger.Debug("Next Run Time [" + nextRunTime.ToShortDateString() + " " + nextRunTime.ToShortTimeString() + "]");

			return nextRunTime;
		}

		private void SetIntialRunTime()
		{
			//DateTime initialRunTime = Convert.ToDateTime(ConfigurationManager.AppSettings["InitialRunTime"]);
			//int runInterval = Convert.ToInt32(ConfigurationManager.AppSettings["RunIntervalMinutes"]);
			//string serviceCode = ConfigurationManager.AppSettings["ServiceCode"].ToString();

			if (_customerTimer)
			{
				logger.Debug("Using custom timer");
				_initialRunTime = CustomSetNextRunTime();
			}
			else
			{
				logger.Debug("Using standard timer");

				DateTime now = DateTime.Now;
				logger.Debug("Initial Run Time [" + _initialRunTime.ToShortDateString() + " " + _initialRunTime.ToShortTimeString() + "]");
				logger.Debug("Now [" + now.ToShortDateString() + " " + now.ToShortTimeString() + "]");

				if (_initialRunTime.Date <= now.Date)
				{
					logger.Debug("Initial run date is before today");
					string time = _initialRunTime.ToShortTimeString();
					string date = now.ToShortDateString();

					string newDate = date + " " + time;

					_initialRunTime = DateTime.Parse(newDate);
					logger.Debug("New Initial Run Time [" + _initialRunTime.ToShortDateString() + " " + _initialRunTime.ToShortTimeString() + "]");

				}

				while (_initialRunTime <= now)
				{
					logger.Debug("Initial run time is in the past");
					_initialRunTime = _initialRunTime.AddMinutes(_runInterval);
				}
			}

			logger.Debug("Initial Run Time will be [" + _initialRunTime.ToShortDateString() + " " + _initialRunTime.ToShortTimeString() + "]");

			ScheduleDetail rtd = new ScheduleDetail();
			rtd.ServiceCode = _serviceCode;
			rtd.RunId = 0;
			rtd.RunTime = _initialRunTime;
			rtd.RunType = "S";

			SetNextRunTime(rtd);
		}

		private void UpdateRunTimeRecord(int runId, string statusMessage)
		{
			ScheduleDAL sd = new ScheduleDAL();

			sd.UpdateRunTime(runId, statusMessage);

		}

		private void SetNotification(string serviceCode, string statusMessage)
		{
			NotificationDAL nd = new NotificationDAL();

			nd.AddNotification(serviceCode, statusMessage);
		}

		private DateTime CustomSetNextRunTime()
		{
			//If windows service requires a custom time use this method for setting the next run time

			DateTime customNextRunTime = DateTime.Now.AddMinutes(2);

			logger.Debug("Custom Run Time [" + customNextRunTime.ToShortDateString() + " " + customNextRunTime.ToShortTimeString() + "]");

			return customNextRunTime;
		}
	}
}

