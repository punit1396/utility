using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
//using CommandLine;
using Kusto.Data.Net.Client;

namespace HelloKusto
{
    class Program
    {
        public static string inMarketResultsFilePath;
        public static string clientRequestIdsFilePath;
        public static string issueMapFilePath;
        public static bool genericProcess;
        public static bool needDRALogs;
        public static bool useSyncCalls;
        public static bool displayByMonth;
        public static ConsoleColor currentForgroundColor;

        static void Main(string[] args)
        {
            var watch = System.Diagnostics.Stopwatch.StartNew();
            currentForgroundColor = Console.ForegroundColor;

            var commandLineOptions = new CommandLineOptions();
            var commandLineParsingState = CommandLine.Parser.Default.ParseArguments(args, commandLineOptions);
            if (commandLineParsingState)
            {
                Console.ForegroundColor = ConsoleColor.DarkCyan;

                if (!string.IsNullOrEmpty(commandLineOptions.InputFile))
                {
                    clientRequestIdsFilePath = commandLineOptions.InputFile;
                    Console.WriteLine("Reading ClientRequestIds from file: " + clientRequestIdsFilePath);
                    ClientRequestIdHelper.Initialize(clientRequestIdsFilePath);
                }

                if (!string.IsNullOrEmpty(commandLineOptions.InputList))
                {
                    Console.WriteLine("Reading ClientRequestIds from command line list: " + commandLineOptions.InputList);
                    ClientRequestIdHelper.Initialize(commandLineOptions.InputList.Split(',').ToList());
                }

                if (!string.IsNullOrEmpty(commandLineOptions.OutputFile))
                {
                    inMarketResultsFilePath = commandLineOptions.OutputFile;
                }
                else
                {
                    inMarketResultsFilePath = Path.Combine(Path.GetDirectoryName(Environment.GetCommandLineArgs()[0]), "InMarketResultsFilePath" + ".txt");
                }

                if (!string.IsNullOrEmpty(commandLineOptions.IssueMapFile))
                {
                    issueMapFilePath = commandLineOptions.IssueMapFile;
                    IssueHelper.Initialize(issueMapFilePath);
                }
                else
                {
                    issueMapFilePath = Path.Combine(Path.GetDirectoryName(Environment.GetCommandLineArgs()[0]), "IssueMapFilePath" + ".txt");
                }
                Console.WriteLine("Reading IssueMaps from file: " + issueMapFilePath);
                IssueHelper.Initialize(issueMapFilePath);

                needDRALogs = commandLineOptions.WithDRALogs;
                useSyncCalls = commandLineOptions.UseAsyncKustoCalls;
                displayByMonth = commandLineOptions.DisplayByMonth;
            }

            if(args.Length == 0 || args[0] == "/?" || (string.IsNullOrEmpty(commandLineOptions.InputFile) && string.IsNullOrEmpty(commandLineOptions.InputList)) || string.IsNullOrEmpty(inMarketResultsFilePath) || string.IsNullOrEmpty(issueMapFilePath))
            {
                Console.WriteLine(commandLineOptions.GetUsage());
                Console.ForegroundColor = currentForgroundColor;
                return;
            }

            if (genericProcess)
            {
                GenericAnalysis();
            }
            else if(displayByMonth)
            {
                DisplayByMonth();
            }
            else
            {
                SpecificAnalysis();
            }

            watch.Stop();
            var elapsedMs = watch.ElapsedMilliseconds;
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("Total time taken for analysis: " + Math.Ceiling((double)elapsedMs / 1000) + " seconds");
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("Analysis is complete and output is generated at: " + inMarketResultsFilePath);
            Console.ForegroundColor = currentForgroundColor;
        }

        private static void SpecificAnalysis()
        {
            ProcessClientRequestIds();
            Renderer.WriteToFileDetailedView();
        }

        private static void DisplayByMonth()
        {
            ProcessClientRequestIds();
            Renderer.WriteToFileMonthView();
        }

        private static void ProcessClientRequestIds()
        {
            var clientRequestIdTotalCount = ClientRequestIdHelper.clientRequestInfoList.Count;
            var clientRequestIdCurrentCount = 1;

            if (Program.useSyncCalls)
            {
                foreach (var clientRequestInfo in ClientRequestIdHelper.clientRequestInfoList)
                {
                    Console.ForegroundColor = ConsoleColor.DarkBlue;
                    Console.WriteLine("Started submitting SRSData snd SRSOperations query for ClientRequestId: " + clientRequestInfo.Id);
                    QueryHelper.TriggerSRSDataErrorAndOperationAsyncCalls(clientRequestInfo);
                    Console.ForegroundColor = ConsoleColor.Blue;
                    Console.WriteLine("Submitted SRSData snd SRSOperations query for ClientRequestId: ( " + clientRequestIdCurrentCount++ + "/" + clientRequestIdTotalCount + " ) ClientRequestId: " + clientRequestInfo.Id);
                }

                clientRequestIdCurrentCount = 1;
                Parallel.ForEach(ClientRequestIdHelper.clientRequestInfoList, (clientRequestInfo) =>
                {
                    Console.ForegroundColor = ConsoleColor.Cyan;
                    Console.WriteLine("Started processing ClientRequestId: " + clientRequestInfo.Id);
                    QueryHelper.FillClientRequestInfoDetailsWithAsyncCalls(clientRequestInfo);
                    Console.ForegroundColor = ConsoleColor.Magenta;
                    Console.WriteLine("Finished processing ( " + clientRequestIdCurrentCount++ + "/" + clientRequestIdTotalCount + " ) ClientRequestId: " + clientRequestInfo.Id);
                });
            }
            else
            {
                Parallel.ForEach(ClientRequestIdHelper.clientRequestInfoList, (clientRequestInfo) =>
                {
                    Console.ForegroundColor = ConsoleColor.Cyan;
                    Console.WriteLine("Started processing ClientRequestId: " + clientRequestInfo.Id);
                    QueryHelper.FillClientRequestInfoDetails(clientRequestInfo);
                    Console.ForegroundColor = ConsoleColor.Magenta;
                    Console.WriteLine("Finished processing ( " + clientRequestIdCurrentCount++ + "/" + clientRequestIdTotalCount + " ) ClientRequestId: " + clientRequestInfo.Id);
                });

            }

        }


        private static void GenericAnalysis()
        {
            Parallel.ForEach(IssueHelper.IssueList, (issue) =>
            {
                QueryHelper.ProcessClientRequestInfoDetailsForIssue(issue);
            });

            using (StreamWriter file = File.CreateText(inMarketResultsFilePath))
            {

                file.WriteLine("---------------------------------------------------------- ClientRequestIds for issues----------------------------------------------------------");
                file.WriteLine();
                foreach (var issue in IssueHelper.IssueList)
                {
                    var affectedClientRequestIdInfos = ClientRequestIdHelper.GetAffectedClientRequestInfos(issue);
                    file.WriteLine("*********ClientRequestIDs affected by issue: " + issue.Type + ", Bug: " + issue.BugId + ", affected count:" + affectedClientRequestIdInfos.Count);
                    file.WriteLine();
                    foreach (var clientRequestInfo in affectedClientRequestIdInfos)
                    {
                        string clientRequestInfoStatement = clientRequestInfo.Id;
                        file.WriteLine(clientRequestInfoStatement);
                    }
                    file.WriteLine();
                }
            }
        }

        class SubscriptionComparer : IEqualityComparer<Subscription>
        {
            bool IEqualityComparer<Subscription>.Equals(Subscription x, Subscription y)
            {
                if (x?.Id == null || y?.Id == null)
                    return false;

                return (x.Id.Equals(y.Id, StringComparison.OrdinalIgnoreCase));
            }

            int IEqualityComparer<Subscription>.GetHashCode(Subscription obj)
            {
                if (obj == null || obj.Id == null)
                    return 0;

                return obj.Id.GetHashCode();
            }
        }
    }
}
