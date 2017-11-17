using System;
using System.Collections.Generic;
using System.IO;

namespace HelloKusto
{
    class ClientRequestInfo
    {
        public string Id;
        public HashSet<Issue> Issues;

        public ClientRequestInfo()
        {
            Id = "";
            this.Issues = new HashSet<Issue>();
        }

        public ClientRequestInfo(string id)
        {
            this.Id = id;
            this.Issues = new HashSet<Issue>();
        }

        public ClientRequestInfo(string id, HashSet<Issue> issues)
        {
            this.Id = id;
            this.Issues = issues;
        }

        public void AddIssue(Issue issue)
        {
            this.Issues.Add(issue);
        }

        public bool IfAffectedByIssue(Issue issue)
        {
            return Issues.Contains(issue);
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
    }
}
