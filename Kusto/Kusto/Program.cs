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
        static string inMarketResultsFilePath;
        static string clientRequestIdsFilePath;
        static string issueMapFilePath;
        static bool genericProcess;

        static void Main(string[] args)
        {
            inMarketResultsFilePath = Path.Combine(Path.GetDirectoryName(Environment.GetCommandLineArgs()[0]), "InMarketResultsFilePath" + ".txt");
            clientRequestIdsFilePath = Path.Combine(Path.GetDirectoryName(Environment.GetCommandLineArgs()[0]), "ClientRequestIdsFilePath" + ".txt");
            issueMapFilePath = Path.Combine(Path.GetDirectoryName(Environment.GetCommandLineArgs()[0]), "IssueMapFilePath" + ".txt");
            genericProcess = false;

            if (args.Length >= 1)
            {
                clientRequestIdsFilePath = args[0];
                if (args[0].ToString().ToLower() == "g" || args[0].ToString().ToLower() == "generic")
                {
                    genericProcess = true;
                }
            }

            if (args.Length >= 2)
            {
                inMarketResultsFilePath = args[1];
            }

            if (args.Length == 3)
            {
                issueMapFilePath = args[2];
            }

            if (genericProcess)
            {
                GenericAnalysis();
            }
            else
            {
                SpecificAnalysis();
            }
        }

        public static void GenericAnalysis()
        {
            IssueHelper.Initialize(issueMapFilePath);

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

        public static void SpecificAnalysis()
        {
            var currentForgroundColor = Console.ForegroundColor;
            IssueHelper.Initialize(issueMapFilePath);
            ClientRequestIdHelper.Initialize(clientRequestIdsFilePath);

            Console.ForegroundColor = ConsoleColor.DarkCyan;
            Console.WriteLine("Reading ClientRequestIds from: " + clientRequestIdsFilePath);
            Console.WriteLine("Reading IssueMaps from: " + issueMapFilePath);

            var clientRequestIdTotalCount = ClientRequestIdHelper.clientRequestInfoList.Count;
            var clientRequestIdCurrentCount = 1;
            Parallel.ForEach(ClientRequestIdHelper.clientRequestInfoList, (clientRequestInfo) =>
            {
                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.WriteLine("Started processing ClientRequestId: " + clientRequestInfo.Id);
                QueryHelper.FillClientRequestInfoDetails(clientRequestInfo);
                Console.ForegroundColor = ConsoleColor.Magenta;
                Console.WriteLine("Finished processing ( " + clientRequestIdCurrentCount++ + "/" + clientRequestIdTotalCount + " ) ClientRequestId: " + clientRequestInfo.Id);
            });

            using (StreamWriter file = File.CreateText(inMarketResultsFilePath))
            {
                foreach (var clientRequestInfo in ClientRequestIdHelper.clientRequestInfoList)
                {
                    file.WriteLine("*************************************************** Error details of ClientRequestID: " + clientRequestInfo.Id + "***************************************************");

                    var machingIssues = IssueHelper.GetMachingIssues(clientRequestInfo.ErrorContent.ToString());

                    string clientRequestInfoStatement = "ObjectType: " + clientRequestInfo.ObjectType + ", ObjectId: " + clientRequestInfo.ObjectId +
                        ", ScenarioName: " + clientRequestInfo.ScenarioName + ", ReplicationProvider: " + Utility.GetReplicationProviderName(clientRequestInfo.ReplicationProviderId) +
                        ", Region: " + clientRequestInfo.Region + ", ResourceId: " + clientRequestInfo.ResourceId + ", StampName: " + clientRequestInfo.StampName;
                    string subscriptionInfoStatement = "SubscriptionId: " + clientRequestInfo.SubscriptionInfo.Id + ", SubscriptionName: " + clientRequestInfo.SubscriptionInfo.SubscriptionName +
                        ", CustomerName: " + clientRequestInfo.SubscriptionInfo.CustomerName + ", BillingType: " + clientRequestInfo.SubscriptionInfo.BillingType +
                        ", OfferType: " + clientRequestInfo.SubscriptionInfo.OfferType;
                    file.WriteLine("------- Details:");
                    file.WriteLine(clientRequestInfoStatement);
                    file.WriteLine(subscriptionInfoStatement);
                    file.WriteLine();

                    foreach (var issue in machingIssues)
                    {
                        file.WriteLine("Issue: " + issue.Type + ", Bug: " + issue.BugId);
                    }

                    file.WriteLine();
                    file.WriteLine();
                    file.WriteLine("------- SRSOperationEvent:");
                    file.WriteLine();
                    foreach (var srsOperationEvent in clientRequestInfo.SRSOperationEvents)
                    {
                        file.WriteLine(srsOperationEvent.PreciseTimeStamp + "   " + srsOperationEvent.ServiceActivityId + "     " + srsOperationEvent.State + "   " + srsOperationEvent.SRSOperationName + "   " + srsOperationEvent.ScenarioName);
                    }
                    file.WriteLine();
                    file.WriteLine("------- SRSDataEvents:");
                    file.WriteLine();
                    file.WriteLine(clientRequestInfo.ErrorContent.ToString());
                    file.WriteLine();
                }

                file.WriteLine("---------------------------------------------------------- ClientRequestIds for issues----------------------------------------------------------");
                file.WriteLine();
                foreach (var issue in IssueHelper.IssueList)
                {
                    var affectedClientRequestIdInfos = ClientRequestIdHelper.GetAffectedClientRequestInfos(issue);
                    if (affectedClientRequestIdInfos != null && affectedClientRequestIdInfos.Count > 0)
                    {
                        file.WriteLine("*********ClientRequestIDs affected by issue: " + issue.Type + ", Bug: " + issue.BugId);
                        file.WriteLine();
                        foreach (var clientRequestInfo in affectedClientRequestIdInfos)
                        {
                            string clientRequestInfoStatement = string.IsNullOrEmpty(clientRequestInfo.StampName) ? clientRequestInfo.Id : clientRequestInfo.StampName.Split('-').First() + "   " + clientRequestInfo.Id;
                            file.WriteLine(clientRequestInfoStatement);
                        }
                        file.WriteLine();
                    }
                }
                file.WriteLine("*********Uncategorised ClientRequestIDs: ");
                foreach (var clientRequestId in ClientRequestIdHelper.clientRequestInfoList)
                {
                    var machingIssues = IssueHelper.GetMachingIssues(clientRequestId.ErrorContent.ToString());

                    if (machingIssues == null || machingIssues.Count == 0)
                    {
                        string clientRequestInfoStatement = string.IsNullOrEmpty(clientRequestId.StampName) ? clientRequestId.Id : clientRequestId.StampName.Split('-').First() + "   " + clientRequestId.Id;
                        file.WriteLine(clientRequestInfoStatement);
                    }
                }
            }


            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("Analysis is complete and output is generated at: " + inMarketResultsFilePath);
            Console.ForegroundColor = currentForgroundColor;
        }

    }
}
