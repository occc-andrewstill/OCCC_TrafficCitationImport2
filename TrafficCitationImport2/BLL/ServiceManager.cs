using NLog;
using System;
using System.Configuration;
using System.Timers;
using TrafficCitationImport2.BLL;

namespace TrafficCitationImport2
{
	public class ServiceManager
	{
		DateTime scheduleTime;
		static Timer timer;

		int prevRunHour = 0;
		int prevRunMinute = 0;

		private static Logger logger = LogManager.GetCurrentClassLogger();

		// Constructor
		public ServiceManager()
		{
			logger.Info("Start - ServiceManager");

			try
			{
				int days = int.Parse(ConfigurationManager.AppSettings["days"]);
				int hours = int.Parse(ConfigurationManager.AppSettings["hours"]);
				int minutes = int.Parse(ConfigurationManager.AppSettings["minutes"]);
				int interval = int.Parse(ConfigurationManager.AppSettings["interval"]);

				logger.Debug("Interval [" + interval + "]");

				logger.Debug("Scheduled time [" + hours + ":" + minutes + "]");

				prevRunHour = hours;
				prevRunMinute = minutes;				

				timer = new Timer(interval);

				// day, hours and minutes are configured at App.config file
				scheduleTime = DateTime.Today.AddDays(days).AddHours(hours).AddMinutes(minutes);
			}
			catch(Exception ex)
			{
				logger.Error("Error during scheduleTime: " + ex.Message);
			}

			logger.Info("End - ServiceManager");
		}


		// Starting the timer
		public bool Start()
		{
			logger.Debug("Start - Starting the OCCC Citation Import Service!");

			try
			{
				int spanHours = int.Parse(ConfigurationManager.AppSettings["spanHours"]);
				int spanMinutes = int.Parse(ConfigurationManager.AppSettings["spanMinutes"]);
				int spanSeconds = int.Parse(ConfigurationManager.AppSettings["spanSeconds"]);

				logger.Debug("Start function - before enabling the timer");

				timer.Enabled = true;

				logger.Debug("Start function - after enabling the timer");

				//Test if its a time in the past and protect setting timer.Interval with a negative number which causes an error.
				double tillNextInterval = scheduleTime.Subtract(DateTime.Now).TotalSeconds * 1000;
				if (tillNextInterval < 0) tillNextInterval += new TimeSpan(spanHours, spanMinutes, spanSeconds).TotalSeconds * 1000;
				timer.Interval = tillNextInterval;
				timer.Elapsed += new ElapsedEventHandler(Timer_Elapsed);
				logger.Debug("Start function - before starting the timer");
				timer.Start();
				logger.Debug("Start function - after starting the timer");
			}
			catch(Exception ex)
			{
				logger.Error("Error before or while starting timer: " + ex.Message);
			}

			logger.Info("End - Starting the OCCC Citation Import Service");

			return true;
		}

		// Stopping the timer
		public bool Stop()
		{
			logger.Info("Start - Stopping the OCCC Citation Import Service!");
			try
			{
				logger.Debug("Stop function - before disabing the timer");
				timer.Enabled = false;
				logger.Debug("Stop function - after disabing the timer");
			}
			catch(Exception ex)
			{
				logger.Error("Error while stopping timer: " + ex.Message);
			}
			logger.Info("End - Stopped the OCCC Citation Import Service!");

			return true;
		}

		// Wakeup every one hour
		public void Timer_Elapsed(object sender, ElapsedEventArgs e)
		{
			logger.Info("Start- Timer_Elapsed");

			try
			{

				// Declaring an instance of Task Manager
				TaskManager tm = new TaskManager();

				int diffHoursNormal = int.Parse(ConfigurationManager.AppSettings["diffHoursNormal"]);
				int diffHoursSpecial = int.Parse(ConfigurationManager.AppSettings["diffHoursSpecial"]);

				if ((scheduleTime.Day == DateTime.Now.Day && scheduleTime.Hour == DateTime.Now.Hour && scheduleTime.Minute == DateTime.Now.Minute) ||
									(DateTime.Now.Hour - prevRunHour == diffHoursNormal && DateTime.Now.Minute == prevRunMinute) ||  // <-- generic case
									(prevRunHour - DateTime.Now.Hour == diffHoursSpecial && prevRunMinute == DateTime.Now.Minute)    // <-- special cases
					)
				{
					prevRunHour = DateTime.Now.Hour;
					prevRunMinute = DateTime.Now.Minute;
					logger.Debug("Inside Timer_Elapsed - capturing prevRunHour as [" + prevRunHour + "]");
					logger.Debug("Inside Timer_Elapsed - capturing prevRunMinute as [" + prevRunMinute + "]");

					logger.Debug("Inside Timer_Elapsed - before executing the Run()");
					tm.Run();
					logger.Debug("Inside Timer_Elapsed - after executing the Run()");

					// Restart the timer for the next run TM 8/13/2020
					timer.Stop();
					timer.Start();
				}

			}
			catch(Exception ex)
			{
				logger.Error("Error while executing timer: " + ex.Message);
			}

			logger.Info("End- Timer_Elapsed");

		}
	}
}
