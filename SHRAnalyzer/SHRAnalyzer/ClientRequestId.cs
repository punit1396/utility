﻿using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace HelloKusto
{
    class ClientRequestInfo
    {
        public string Id;
        public StringBuilder ErrorContent = new StringBuilder();
        public StringBuilder SRSErrorContent = new StringBuilder();
        public StringBuilder DRAContent = new StringBuilder();
        public StringBuilder GatewayErrorContent = new StringBuilder();
        public StringBuilder RCMErrorContent = new StringBuilder();
        public StringBuilder CBEngineTraceMessagesErrorContent = new StringBuilder();
        public Subscription SubscriptionInfo = new Subscription();
        public string ReplicationProviderId;
        public string StampName;
        public string Region;
        public string ScenarioName;
        public string ObjectType;
        public string ObjectId;
        public string ResourceId;
        public DateTime PreciseTimeStamp = DateTime.MinValue;
        public List<SRSOperationEvent> SRSOperationEvents = new List<SRSOperationEvent>();
        public List<Issue> issueList = new List<Issue>();

        public ClientRequestInfo()
        {
            this.Id = "";
            this.SRSErrorContent = new StringBuilder();
        }

        public ClientRequestInfo(string id)
        {
            this.Id = id;
            this.SRSErrorContent = new StringBuilder();
        }

        public ClientRequestInfo(string id, StringBuilder errorContent)
        {
            this.Id = id;
            this.SRSErrorContent = errorContent;
        }

        public void AddErrorContent(StringBuilder errorContent)
        {
            this.SRSErrorContent.Append(errorContent);
        }

        public void AddErrorContent(string errorContent)
        {
            this.SRSErrorContent.Append(errorContent);
        }

        public bool IfAffectedByIssue(Issue issue)
        {
            var temp = this.SRSErrorContent.ToString() + this.DRAContent.ToString() + this.GatewayErrorContent.ToString() + this.RCMErrorContent.ToString() + this.CBEngineTraceMessagesErrorContent.ToString();
            return (this.issueList.Contains(issue) || IssueHelper.GetMachingIssues(temp).Contains(issue));
        }
    }

    static class ClientRequestIdHelper
    {
        public static List<ClientRequestInfo> clientRequestInfoList = new List<ClientRequestInfo>();
        public static void Initialize(string clientRequestIdsFilePath)
        {
            try
            {
                using (var reader = new StreamReader(clientRequestIdsFilePath))
                {
                    string line;
                    while ((line = reader.ReadLine()) != null)
                    {
                        clientRequestInfoList.Add(new ClientRequestInfo(line.Trim()));
                    }
                }
            }
            catch (Exception)
            {

            }

        }

        public static void Initialize(List<string> clientRequestIdList)
        {
            try
            {
                foreach (var clientRequesttId in clientRequestIdList)
                {
                    clientRequestInfoList.Add(new ClientRequestInfo(clientRequesttId.Trim()));
                }
            }
            catch (Exception)
            {

            }

        }

        public static List<ClientRequestInfo> GetAffectedClientRequestInfos(Issue issue)
        {
            List<ClientRequestInfo> clientRequestInfos = new List<ClientRequestInfo>();
            foreach (var clientRequestInfo in clientRequestInfoList)
            {
                if (clientRequestInfo.IfAffectedByIssue(issue))
                {
                    clientRequestInfos.Add(clientRequestInfo);
                }
            }

            return clientRequestInfos;
        }

        public static List<ClientRequestInfo> GetAffectedClientRequestInfos(Issue issue, List<ClientRequestInfo> passedClientRequestInfos)
        {
            List<ClientRequestInfo> clientRequestInfos = new List<ClientRequestInfo>();
            foreach (var clientRequestInfo in passedClientRequestInfos)
            {
                if (clientRequestInfo.IfAffectedByIssue(issue))
                {
                    clientRequestInfos.Add(clientRequestInfo);
                }
            }

            return clientRequestInfos;
        }
    }
}
