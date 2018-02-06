using CommandLine;
using CommandLine.Text;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace HelloKusto
{
    class Renderer
    {
        public static void WriteToFileDetailedView()
        {
            using (StreamWriter file = File.CreateText(Program.inMarketResultsFilePath))
            {
                PrintErrorDetailsForClientRequestIds(file);
                PrintClientRequestIdsBySubscription(file);
                PrintClientRequestIdsByIssues(file);
            }
        }

        public static void WriteToFileMonthView()
        {
            using (StreamWriter file = File.CreateText(Program.inMarketResultsFilePath))
            {
                PrintClientRequestIdsByMonth(file);
                PrintClientRequestIdCountForIssuesByMonth(file);
                PrintClientRequestIdsByIssuesPerMonth(file);
            }
        }

        private static void PrintErrorDetailsForClientRequestIds(StreamWriter file)
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
                file.WriteLine(clientRequestInfo.SRSErrorContent.ToString());
                file.WriteLine();

                if (clientRequestInfo.DRAContent.Length > 1)
                {
                    file.WriteLine();
                    file.WriteLine("------- DRAEvents:");
                    file.WriteLine();
                    file.WriteLine(clientRequestInfo.DRAContent.ToString());
                    file.WriteLine();
                }

                if (clientRequestInfo.CBEngineTraceMessagesErrorContent.Length > 1)
                {
                    file.WriteLine();
                    file.WriteLine("------- CBEngineTraceMessagesErrorContent:");
                    file.WriteLine();
                    file.WriteLine(clientRequestInfo.CBEngineTraceMessagesErrorContent.ToString());
                    file.WriteLine();
                }

                if (clientRequestInfo.RCMErrorContent.Length > 1)
                {
                    file.WriteLine();
                    file.WriteLine("------- RcmDiagnosticEvent:");
                    file.WriteLine();
                    file.WriteLine(clientRequestInfo.RCMErrorContent.ToString());
                    file.WriteLine();
                }

                if (clientRequestInfo.GatewayErrorContent.Length > 1)
                {
                    file.WriteLine();
                    file.WriteLine("------- GatewayDiagnosticEvent:");
                    file.WriteLine();
                    file.WriteLine(clientRequestInfo.GatewayErrorContent.ToString());
                    file.WriteLine();
                }
            }
        }

        private static void PrintClientRequestIdsBySubscription(StreamWriter file)
        {
            var fullSubscriptionInfoList = ClientRequestIdHelper.clientRequestInfoList.Select(clientrequestId => clientrequestId.SubscriptionInfo);

            var subscriptionInfoList = fullSubscriptionInfoList != null ? fullSubscriptionInfoList.GroupBy(sub => sub.Id).Select(group => group.FirstOrDefault()) : new List<Subscription>();

            file.WriteLine("---------------------------------------------------------- ClientRequestIds for subscriptions----------------------------------------------------------");
            file.WriteLine();
            foreach (var subscriptionInfo in subscriptionInfoList)
            {
                var affectedClientRequestIdInfos = ClientRequestIdHelper.clientRequestInfoList.Where(clientRequestId => clientRequestId.SubscriptionInfo.Id == subscriptionInfo.Id);
                if (affectedClientRequestIdInfos != null && affectedClientRequestIdInfos.ToList().Count > 0)
                {
                    string subscriptionInfoStatement = "SubscriptionId: " + subscriptionInfo.Id + ", SubscriptionName: " + subscriptionInfo.SubscriptionName +
                        ", CustomerName: " + subscriptionInfo.CustomerName + ", BillingType: " + subscriptionInfo.BillingType +
                        ", OfferType: " + subscriptionInfo.OfferType;
                    file.WriteLine("*********ClientRequestIDs affected (Count: " + affectedClientRequestIdInfos.ToList().Count + ") for " + subscriptionInfoStatement);
                    file.WriteLine();
                    foreach (var clientRequestInfo in affectedClientRequestIdInfos.ToList())
                    {
                        var machingIssues = IssueHelper.GetMachingIssues(clientRequestInfo.ErrorContent.ToString());
                        string issueInfoStatement = "";
                        foreach (var issue in machingIssues)
                        {
                            issueInfoStatement += "| Issue:" + issue.Type + ", Bug:" + issue.BugId;
                        }

                        string clientRequestInfoStatement = string.IsNullOrEmpty(clientRequestInfo.StampName) ? clientRequestInfo.Id : clientRequestInfo.StampName.Split('-').First() + "   " + clientRequestInfo.Id;
                        file.WriteLine(clientRequestInfoStatement + issueInfoStatement);
                    }
                    file.WriteLine();
                }
            }
        }

        private static void PrintClientRequestIdsByIssues(StreamWriter file)
        {
            file.WriteLine("---------------------------------------------------------- ClientRequestIds for issues----------------------------------------------------------");
            file.WriteLine();
            foreach (var issue in IssueHelper.IssueList)
            {
                var affectedClientRequestIdInfos = ClientRequestIdHelper.GetAffectedClientRequestInfos(issue);
                if (affectedClientRequestIdInfos != null && affectedClientRequestIdInfos.Count > 0)
                {
                    file.WriteLine("*********ClientRequestIDs affected by issue: " + issue.Type + ", Bug: " + issue.BugId + ", Count: " + affectedClientRequestIdInfos.Count);
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

        private static void PrintClientRequestIdsByMonth(StreamWriter file)
        {
            DateTime currentTime = DateTime.Now;
            DateTime currentMonthStart = new DateTime(currentTime.Year, currentTime.Month, 1);
            DateTime oneMonthsAgo = currentMonthStart.AddMonths(-1);
            DateTime twoMonthsAgo = currentMonthStart.AddMonths(-2);
            DateTime threeMonthsAgo = currentMonthStart.AddMonths(-3);

            file.WriteLine("---------------------------------------------------------- ClientRequestIds: monthly display----------------------------------------------------------");
            PrintClientRequestIdsBetweenMonths(file, currentMonthStart, currentTime);
            PrintClientRequestIdsBetweenMonths(file, oneMonthsAgo, currentMonthStart);
            PrintClientRequestIdsBetweenMonths(file, twoMonthsAgo, oneMonthsAgo);
            PrintClientRequestIdsBetweenMonths(file, threeMonthsAgo, twoMonthsAgo);
            PrintClientRequestIdsBetweenMonths(file, DateTime.MinValue, threeMonthsAgo);
        }

        private static void PrintClientRequestIdCountForIssuesByMonth(StreamWriter file)
        {
            DateTime currentTime = DateTime.Now;
            DateTime currentMonthStart = new DateTime(currentTime.Year, currentTime.Month, 1);
            DateTime oneMonthsAgo = currentMonthStart.AddMonths(-1);
            DateTime twoMonthsAgo = currentMonthStart.AddMonths(-2);
            DateTime threeMonthsAgo = currentMonthStart.AddMonths(-3);

            file.WriteLine("---------------------------------------------------------- ClientRequestId count for issues: monthly display----------------------------------------------------------");
            file.WriteLine();
            if (PrintClientRequestIdsBetweenMonths(file, currentMonthStart, currentTime, false) > 0)
            {
                file.WriteLine("*********Between Date: '" + currentMonthStart.ToString("dddd, MMM dd yyyy") + "' and '" + currentTime.ToString("dddd, MMM dd yyyy") + "'");
                file.WriteLine();
                foreach (var issue in IssueHelper.IssueList)
                {
                    var affectedClientRequestIdInfos = ClientRequestIdHelper.GetAffectedClientRequestInfos(issue);
                    if (affectedClientRequestIdInfos != null && affectedClientRequestIdInfos.Count > 0)
                    {
                        file.WriteLine("Issue: " + issue.Type + ", Bug: " + issue.BugId + ", Affected ClientRequestId Count: " + PrintClientRequestIdsByIssuesBetweenMonths(file, issue, currentMonthStart, currentTime, false));
                        file.WriteLine();
                    }
                    else
                    {
                        continue;
                    }
                }
            }

            if (PrintClientRequestIdsBetweenMonths(file, oneMonthsAgo, currentMonthStart, false) > 0)
            {
                file.WriteLine("*********Between Date: '" + oneMonthsAgo.ToString("dddd, MMM dd yyyy") + "' and '" + currentMonthStart.ToString("dddd, MMM dd yyyy") + "'");
                file.WriteLine();
                foreach (var issue in IssueHelper.IssueList)
                {
                    var affectedClientRequestIdInfos = ClientRequestIdHelper.GetAffectedClientRequestInfos(issue);
                    if (affectedClientRequestIdInfos != null && affectedClientRequestIdInfos.Count > 0)
                    {
                        file.WriteLine("Issue: " + issue.Type + ", Bug: " + issue.BugId + ", Affected ClientRequestId Count: " + PrintClientRequestIdsByIssuesBetweenMonths(file, issue, oneMonthsAgo, currentMonthStart, false));
                        file.WriteLine();
                    }
                    else
                    {
                        continue;
                    }
                }
            }

            if (PrintClientRequestIdsBetweenMonths(file, twoMonthsAgo, oneMonthsAgo, false) > 0)
            {
                file.WriteLine("*********Between Date: '" + twoMonthsAgo.ToString("dddd, MMM dd yyyy") + "' and '" + oneMonthsAgo.ToString("dddd, MMM dd yyyy") + "'");
                file.WriteLine();
                foreach (var issue in IssueHelper.IssueList)
                {
                    var affectedClientRequestIdInfos = ClientRequestIdHelper.GetAffectedClientRequestInfos(issue);
                    if (affectedClientRequestIdInfos != null && affectedClientRequestIdInfos.Count > 0)
                    {
                        file.WriteLine("Issue: " + issue.Type + ", Bug: " + issue.BugId + ", Affected ClientRequestId Count: " + PrintClientRequestIdsByIssuesBetweenMonths(file, issue, twoMonthsAgo, oneMonthsAgo, false));
                        file.WriteLine();
                    }
                    else
                    {
                        continue;
                    }
                }
            }

            if (PrintClientRequestIdsBetweenMonths(file, threeMonthsAgo, twoMonthsAgo, false) > 0)
            {
                file.WriteLine("*********Between Date: '" + threeMonthsAgo.ToString("dddd, MMM dd yyyy") + "' and '" + twoMonthsAgo.ToString("dddd, MMM dd yyyy") + "'");
                file.WriteLine();
                foreach (var issue in IssueHelper.IssueList)
                {
                    var affectedClientRequestIdInfos = ClientRequestIdHelper.GetAffectedClientRequestInfos(issue);
                    if (affectedClientRequestIdInfos != null && affectedClientRequestIdInfos.Count > 0)
                    {
                        file.WriteLine("Issue: " + issue.Type + ", Bug: " + issue.BugId + ", Affected ClientRequestId Count: " + PrintClientRequestIdsByIssuesBetweenMonths(file, issue, threeMonthsAgo, twoMonthsAgo, false));
                        file.WriteLine();
                    }
                    else
                    {
                        continue;
                    }
                }
            }

            if (PrintClientRequestIdsBetweenMonths(file, DateTime.MinValue, threeMonthsAgo, false) > 0)
            {
                file.WriteLine("*********Between Date: '" + DateTime.MinValue.ToString("dddd, MMM dd yyyy") + "' and '" + threeMonthsAgo.ToString("dddd, MMM dd yyyy") + "'");
                file.WriteLine();
                foreach (var issue in IssueHelper.IssueList)
                {
                    var affectedClientRequestIdInfos = ClientRequestIdHelper.GetAffectedClientRequestInfos(issue);
                    if (affectedClientRequestIdInfos != null && affectedClientRequestIdInfos.Count > 0)
                    {
                        file.WriteLine("Issue: " + issue.Type + ", Bug: " + issue.BugId + ", Affected ClientRequestId Count: " + PrintClientRequestIdsByIssuesBetweenMonths(file, issue, DateTime.MinValue, threeMonthsAgo, false));
                        file.WriteLine();
                    }
                    else
                    {
                        continue;
                    }
                }
            }
        }

        private static void PrintClientRequestIdsByIssuesPerMonth(StreamWriter file)
        {
            DateTime currentTime = DateTime.Now;
            DateTime currentMonthStart = new DateTime(currentTime.Year, currentTime.Month, 1);
            DateTime oneMonthsAgo = currentMonthStart.AddMonths(-1);
            DateTime twoMonthsAgo = currentMonthStart.AddMonths(-2);
            DateTime threeMonthsAgo = currentMonthStart.AddMonths(-3);

            file.WriteLine("---------------------------------------------------------- ClientRequestIds for issues: monthly display----------------------------------------------------------");
            file.WriteLine();
            foreach (var issue in IssueHelper.IssueList)
            {
                var affectedClientRequestIdInfos = ClientRequestIdHelper.GetAffectedClientRequestInfos(issue);
                if (affectedClientRequestIdInfos != null && affectedClientRequestIdInfos.Count > 0)
                {
                    file.WriteLine("*********ClientRequestIDs affected by issue: " + issue.Type + ", Bug: " + issue.BugId + ", Count: " + affectedClientRequestIdInfos.Count);
                    file.WriteLine();
                }
                else
                {
                    continue;
                }

                PrintClientRequestIdsByIssuesBetweenMonths(file, issue, currentMonthStart, currentTime);
                PrintClientRequestIdsByIssuesBetweenMonths(file, issue, oneMonthsAgo, currentMonthStart);
                PrintClientRequestIdsByIssuesBetweenMonths(file, issue, twoMonthsAgo, oneMonthsAgo);
                PrintClientRequestIdsByIssuesBetweenMonths(file, issue, threeMonthsAgo, twoMonthsAgo);
                PrintClientRequestIdsByIssuesBetweenMonths(file, issue, DateTime.MinValue, threeMonthsAgo);
            }

            file.WriteLine("*********Uncategorised ClientRequestIDs: ");
            PrintUncategorizedClientRequestIdsByIssuesBetweenMonths(file, currentMonthStart, currentTime);
            PrintUncategorizedClientRequestIdsByIssuesBetweenMonths(file, oneMonthsAgo, currentMonthStart);
            PrintUncategorizedClientRequestIdsByIssuesBetweenMonths(file, twoMonthsAgo, oneMonthsAgo);
            PrintUncategorizedClientRequestIdsByIssuesBetweenMonths(file, threeMonthsAgo, twoMonthsAgo);
            PrintUncategorizedClientRequestIdsByIssuesBetweenMonths(file, DateTime.MinValue, threeMonthsAgo);
        }

        private static int PrintClientRequestIdsBetweenMonths(StreamWriter file, DateTime start, DateTime end, bool print = true)
        {
            var affectedClientRequestIdInfos = ClientRequestIdHelper.clientRequestInfoList.Where(x => x.PreciseTimeStamp >= start && x.PreciseTimeStamp < end);

            int count = affectedClientRequestIdInfos == null ? 0 : affectedClientRequestIdInfos.ToList().Count;
            if (print && affectedClientRequestIdInfos != null && affectedClientRequestIdInfos.ToList().Count > 0)
            {
                file.WriteLine("*********ClientRequestIDs between Date: '" + start.ToString("dddd, MMM dd yyyy") + "' and '" + end.ToString("dddd, MMM dd yyyy") + "', Count: " + affectedClientRequestIdInfos.ToList().Count);
                file.WriteLine();
                foreach (var clientRequestInfo in affectedClientRequestIdInfos.ToList())
                {
                    var machingIssues = IssueHelper.GetMachingIssues(clientRequestInfo.ErrorContent.ToString());
                    string issueInfoStatement = "";
                    foreach (var issue in machingIssues)
                    {
                        issueInfoStatement += "| Issue:" + issue.Type + ", Bug:" + issue.BugId;
                    }

                    string clientRequestInfoStatement = string.IsNullOrEmpty(clientRequestInfo.StampName) ? clientRequestInfo.Id : clientRequestInfo.StampName.Split('-').First() + "   " + clientRequestInfo.Id;
                    file.WriteLine(clientRequestInfoStatement + issueInfoStatement);
                }
                file.WriteLine();
            }

            return count;
        }

        private static int PrintClientRequestIdsByIssuesBetweenMonths(StreamWriter file, Issue issue, DateTime start, DateTime end, bool print = true)
        {
            var ClientRequestIdInfosInMonth = ClientRequestIdHelper.clientRequestInfoList.Where(x => x.PreciseTimeStamp >= start && x.PreciseTimeStamp < end);
            if (ClientRequestIdInfosInMonth == null || ClientRequestIdInfosInMonth.ToList().Count < 1)
            {
                return 0;
            }

            int count = 0;

            var affectedClientRequestIdInfos = ClientRequestIdHelper.GetAffectedClientRequestInfos(issue, ClientRequestIdInfosInMonth.ToList());
            count = affectedClientRequestIdInfos == null ? 0 : affectedClientRequestIdInfos.Count;
            if (print && affectedClientRequestIdInfos != null && affectedClientRequestIdInfos.Count > 0)
            {
                file.WriteLine("ClientRequestIDs between Date: '" + start.ToString("dddd, MMM dd yyyy") + "' and '" + end.ToString("dddd, MMM dd yyyy") + "' , Count: " + affectedClientRequestIdInfos.ToList().Count);
                file.WriteLine();
                foreach (var clientRequestInfo in affectedClientRequestIdInfos)
                {
                    string clientRequestInfoStatement = string.IsNullOrEmpty(clientRequestInfo.StampName) ? clientRequestInfo.Id : clientRequestInfo.StampName.Split('-').First() + "   " + clientRequestInfo.Id;
                    file.WriteLine(clientRequestInfoStatement);
                }
                file.WriteLine();
            }
            return count;
        }

        private static void PrintUncategorizedClientRequestIdsByIssuesBetweenMonths(StreamWriter file, DateTime start, DateTime end)
        {
            var ClientRequestIdInfosInMonth = ClientRequestIdHelper.clientRequestInfoList.Where(x => x.PreciseTimeStamp >= start && x.PreciseTimeStamp < end);
            if (ClientRequestIdInfosInMonth == null || ClientRequestIdInfosInMonth.ToList().Count < 1)
            {
                return;
            }
            bool flag = false;
            foreach (var clientRequestId in ClientRequestIdInfosInMonth)
            {
                var machingIssues = IssueHelper.GetMachingIssues(clientRequestId.ErrorContent.ToString());

                if (machingIssues == null || machingIssues.Count == 0)
                {
                    if (!flag)
                    {
                        file.WriteLine();
                        file.WriteLine("Between Date: '" + start.ToString("dddd, MMM dd yyyy") + "' and '" + end.ToString("dddd, MMM dd yyyy") + "'");
                        flag = true;
                    }
                    string clientRequestInfoStatement = string.IsNullOrEmpty(clientRequestId.StampName) ? clientRequestId.Id : clientRequestId.StampName.Split('-').First() + "   " + clientRequestId.Id;
                    file.WriteLine(clientRequestInfoStatement);
                }
            }
        }
    }
}
