using NLog;
using Topshelf;
using TrafficCitationImport2.BLL;

namespace TrafficCitationImport2
{
	class Program
	{
		private static readonly Logger log = LogManager.GetCurrentClassLogger();
		static void Main(string[] args)
		{

			log.Info("Begin Main...");


			string runAsConsoleApp = AppSettings.RunAsConsoleApp;
			if (runAsConsoleApp == "Yes")
			{
				log.Debug("Running as a console app");
				TaskManager tm = new TaskManager();
				tm.Run();
			}
			else
			{
				log.Debug("Running as a windows service");
				// Run the windowws service
				HostFactory.Run(serviceConfig =>
				{

					serviceConfig.Service<ServiceManager>(serviceInstance =>
					{
						serviceInstance.ConstructUsing(
							() => new ServiceManager());

						serviceInstance.WhenStarted(execute => execute.Start());

						serviceInstance.WhenStopped(execute => execute.Stop());
					});

					serviceConfig.EnableServiceRecovery(recoverOption =>
					{
						recoverOption.RestartService(1);
						recoverOption.RestartService(5);
						recoverOption.TakeNoAction();
					});

					serviceConfig.SetServiceName("OCCCCitationImportService");
					serviceConfig.SetDisplayName("OCCC Citation Import");
					serviceConfig.SetDescription("OCCC Traffic Citation Import Service to import citations daily into Odyssey.");

					serviceConfig.StartAutomatically();

					serviceConfig.RunAsPrompt();

				});
			}


			log.Info("End Main");


		}

	}
}
