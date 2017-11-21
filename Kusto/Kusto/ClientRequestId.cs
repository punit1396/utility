﻿using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace HelloKusto
{
    class ClientRequestInfo
    {
        public string Id;
        public StringBuilder ErrorContent;

        public ClientRequestInfo()
        {
            this.Id = "";
            this.ErrorContent = new StringBuilder();
        }

        public ClientRequestInfo(string id)
        {
            this.Id = id;
            this.ErrorContent = new StringBuilder();
        }

        public ClientRequestInfo(string id, StringBuilder errorContent)
        {
            this.Id = id;
            this.ErrorContent = errorContent;
        }

        public void AddErrorContent(StringBuilder errorContent)
        {
            this.ErrorContent.Append(errorContent);
        }

        public bool IfAffectedByIssue(Issue issue)
        {
            return IssueHelper.GetMachingIssues(this.ErrorContent.ToString()).Contains(issue);
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