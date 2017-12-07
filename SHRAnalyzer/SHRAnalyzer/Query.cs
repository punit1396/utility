using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Kusto.Data.Common;
using Kusto.Data.Net.Client;

namespace HelloKusto
{
    class Query
    {
        public ICslQueryProvider QueryProvider;

        public Query(string connectionString)
        {
            this.QueryProvider = KustoClientFactory.CreateCslQueryProvider(connectionString);
        }

        public Query(ICslQueryProvider queryProvider)
        {
            this.QueryProvider = queryProvider;
        }

        public List<SRSDataEvent> ExecuteErrorQuery(string queryString)
        {
            var content = new List<SRSDataEvent>();
            try
            {
                var dataReader = this.QueryProvider.ExecuteQuery(queryString);

                while (dataReader.Read())
                {
                    var srsDataEvent = new SRSDataEvent();
                    srsDataEvent.Message = dataReader[ColumnName.Message].ToString();
                    content.Add(srsDataEvent);
                }
            }
            catch (Exception e)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Exception was thrown:");
                Console.WriteLine(e);
            }

            return content;
        }

        public List<SRSOperationEvent> ExecuteSRSOperationEventQuery(string queryString)
        {
            var content = new List<SRSOperationEvent>();
            try
            {
                var dataReader = this.QueryProvider.ExecuteQuery(queryString);

                while (dataReader.Read())
                {
                    var sRSOperationEvent = new SRSOperationEvent();
                    sRSOperationEvent.ScenarioName = dataReader[ColumnName.ScenarioName].ToString();
                    sRSOperationEvent.ObjectType = dataReader[ColumnName.ObjectType].ToString();
                    sRSOperationEvent.ObjectId = dataReader[ColumnName.ObjectId].ToString();
                    sRSOperationEvent.ReplicationProviderId = dataReader[ColumnName.ReplicationProviderId].ToString();
                    sRSOperationEvent.StampName = dataReader[ColumnName.StampName].ToString();
                    sRSOperationEvent.Region = dataReader[ColumnName.Region].ToString();
                    sRSOperationEvent.SubscriptionId = dataReader[ColumnName.SubscriptionId].ToString();
                    sRSOperationEvent.SubscriptionId1 = dataReader[ColumnName.SubscriptionId1].ToString();
                    sRSOperationEvent.ResourceId = dataReader[ColumnName.ResourceId1].ToString();
                    sRSOperationEvent.PreciseTimeStamp = dataReader[ColumnName.PreciseTimeStamp].ToString();
                    sRSOperationEvent.SRSOperationName = dataReader[ColumnName.SRSOperationName].ToString();
                    sRSOperationEvent.State = dataReader[ColumnName.State].ToString();
                    sRSOperationEvent.ServiceActivityId = dataReader[ColumnName.ServiceActivityId].ToString();
                    content.Add(sRSOperationEvent);
                }
            }
            catch (Exception e)
            {

                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Exception was thrown:");
                Console.WriteLine(e);
            }

            return content;
        }

        public Subscription ExecuteSubscriptionQuery(string subscriptionQuery)
        {
            var subscriptionInfo = new Subscription();
            try
            {
                var dataReader = this.QueryProvider.ExecuteQuery(subscriptionQuery);
                while (dataReader.Read())
                {
                    subscriptionInfo.Id = dataReader[ColumnName.SubscriptionId].ToString();
                    subscriptionInfo.BillingType = dataReader[ColumnName.BillingType].ToString();
                    subscriptionInfo.OfferType = dataReader[ColumnName.OfferType].ToString();
                    subscriptionInfo.CustomerName = dataReader[ColumnName.CustomerName].ToString();
                    subscriptionInfo.SubscriptionName = dataReader[ColumnName.SubscriptionName].ToString();
                }
            }
            catch (Exception e)
            {

                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Exception was thrown:");
                Console.WriteLine(e);
            }
            return subscriptionInfo;
        }

        public List<RcmDiagnosticEvent> ExecuteRCMQuery(string queryString)
        {
            var content = new List<RcmDiagnosticEvent>();
            try
            {
                var dataReader = this.QueryProvider.ExecuteQuery(queryString);

                while (dataReader.Read())
                {
                    var srsDataEvent = new RcmDiagnosticEvent();
                    srsDataEvent.Message = dataReader[ColumnName.Message].ToString();
                    content.Add(srsDataEvent);
                }
            }
            catch (Exception e)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Exception was thrown:");
                Console.WriteLine(e);
            }

            return content;
        }

        public List<GatewayDiagnosticEvent> ExecuteGatewayQuery(string queryString)
        {
            var content = new List<GatewayDiagnosticEvent>();
            try
            {
                var dataReader = this.QueryProvider.ExecuteQuery(queryString);

                while (dataReader.Read())
                {
                    var srsDataEvent = new GatewayDiagnosticEvent();
                    srsDataEvent.Message = dataReader[ColumnName.Message].ToString();
                    content.Add(srsDataEvent);
                }
            }
            catch (Exception e)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Exception was thrown:");
                Console.WriteLine(e);
            }

            return content;
        }

        public List<ClientRequestInfo> ExecuteGenericQuery(string genericQuery)
        {
            var clientRequestInfoList = new List<ClientRequestInfo>();
            try
            {
                var dataReader = this.QueryProvider.ExecuteQuery(genericQuery);
                while (dataReader.Read())
                {
                    var clientRequestInfo = new ClientRequestInfo();
                    clientRequestInfo.Id = dataReader[ColumnName.ClientRequestId].ToString();
                    clientRequestInfoList.Add(clientRequestInfo);
                }
            }
            catch (Exception e)
            {

                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Exception was thrown:");
                Console.WriteLine(e);
            }
            return clientRequestInfoList;
        }

        public List<CBEngineTraceMessages> ExecuteCBEngineTraceMessagesQuery(string queryString)
        {
            var content = new List<CBEngineTraceMessages>();
            try
            {
                var dataReader = this.QueryProvider.ExecuteQuery(queryString);

                while (dataReader.Read())
                {
                    var srsDataEvent = new CBEngineTraceMessages();
                    srsDataEvent.Message = dataReader[ColumnName.Message].ToString();
                    content.Add(srsDataEvent);
                }
            }
            catch (Exception e)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Exception was thrown:");
                Console.WriteLine(e);
            }

            return content;
        }
    }

    class QueryHelper
    {
        private static Dictionary<string, ICslQueryProvider> queryProviderDictionary;
        private static Dictionary<string, ICslQueryProvider> mabProviderDictionary;
        private static Dictionary<string, ICslQueryProvider> nationalQueryProviderDictionary;

        static QueryHelper()
        {
            queryProviderDictionary = new Dictionary<string, ICslQueryProvider>();
            nationalQueryProviderDictionary = new Dictionary<string, ICslQueryProvider>();
            mabProviderDictionary = new Dictionary<string, ICslQueryProvider>();
            queryProviderDictionary.Add("Europe", KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringEurope));
            queryProviderDictionary.Add("US", KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringUS));
            queryProviderDictionary.Add("Asia", KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringAsia));
            queryProviderDictionary.Add("Internal", KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringInternal));
            nationalQueryProviderDictionary.Add("MoonCake", KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringMoonCake));
            nationalQueryProviderDictionary.Add("BlackForest", KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringBlackForest));
            nationalQueryProviderDictionary.Add("FairFax", KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringFairFax));
            mabProviderDictionary.Add("MabWUS", KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringMabWUS));
            mabProviderDictionary.Add("MabWEU", KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringMabWEU));
            mabProviderDictionary.Add("MabProd1", KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringMabProd1));
            //mabProviderDictionary.Add("MabTest1", KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringMabTest1));
        }

        public static void FillClientRequestInfoDetails(ClientRequestInfo clientRequestInfo)
        {
            try
            {
                string errorQuery = string.Format(QueryString.ErrorQuery, TableName.SRSDataEvent, clientRequestInfo.Id);
                string sRSOperationEventQuery = string.Format(QueryString.SRSOperationEventQuery, TableName.SRSOperationEvent, clientRequestInfo.Id);
                
                var sRSDataEventList = new List<SRSDataEvent>();
                var sRSOperationEventList = new List<SRSOperationEvent>();

                Parallel.ForEach(queryProviderDictionary.Values, (queryProvider) =>
                {
                    var query = new Query(queryProvider);
                    sRSDataEventList.AddRange(query.ExecuteErrorQuery(errorQuery));
                    sRSOperationEventList.AddRange(query.ExecuteSRSOperationEventQuery(sRSOperationEventQuery));
                });

                //if (sRSOperationEventList.Count < 1 && sRSDataEventList.Count < 1)
                //{
                //    Parallel.ForEach(nationalQueryProviderDictionary.Values, (queryProvider) =>
                //    {
                //        var query = new Query(queryProvider);
                //        sRSDataEventList.AddRange(query.ExecuteErrorQuery(errorQuery));
                //        sRSOperationEventList.AddRange(query.ExecuteSRSOperationEventQuery(sRSOperationEventQuery));
                //    });
                //}

                foreach (var item in sRSDataEventList)
                {
                    clientRequestInfo.ErrorContent.AppendLine(item.Message);
                    clientRequestInfo.ErrorContent.AppendLine();
                }

                if (clientRequestInfo.ErrorContent.ToString().ToLower().Contains("Microsoft.Carmine.WSManWrappers.WSManException".ToLower()))
                {
                    var draEventList = new List<SRSDataEvent>();
                    string draEventQuery = TableName.SRSDataEvent + string.Format(QueryString.ClientRequestIdPredicate, clientRequestInfo.Id) + string.Format(QueryString.MessagePredicate, "DRA job logs are available") + QueryString.ProjectionStatement + QueryString.OrderStatement;

                    Parallel.ForEach(queryProviderDictionary.Values, (queryProvider) =>
                    {
                        var query = new Query(queryProvider);
                        draEventList.AddRange(query.ExecuteErrorQuery(draEventQuery));
                    });

                    foreach(var item in draEventList)
                    {
                        clientRequestInfo.DRAContent.AppendLine(item.Message);
                        clientRequestInfo.DRAContent.AppendLine();
                    }
                }

                if (clientRequestInfo.ErrorContent.ToString().ToLower().Contains("GatewayService-".ToLower()))
                {
                    var gatewayDiagnosticEventList = new List<GatewayDiagnosticEvent>();
                    string gatewayDiagnosticEventQuery = string.Format(QueryString.ErrorQuery, TableName.GatewayDiagnosticEvent, clientRequestInfo.Id);

                    Parallel.ForEach(queryProviderDictionary.Values, (queryProvider) =>
                    {
                        var query = new Query(queryProvider);
                        gatewayDiagnosticEventList.AddRange(query.ExecuteGatewayQuery(gatewayDiagnosticEventQuery));
                    });

                    foreach (var item in gatewayDiagnosticEventList)
                    {
                        clientRequestInfo.GatewayErrorContent.AppendLine(item.Message);
                        clientRequestInfo.GatewayErrorContent.AppendLine();
                    }
                }

                if (clientRequestInfo.ErrorContent.ToString().ToLower().Contains("RCM-".ToLower()))
                {
                    var rcmDiagnosticEventList = new List<RcmDiagnosticEvent>();
                    string rcmDiagnosticEventQuery = string.Format(QueryString.ErrorQuery, TableName.RcmDiagnosticEvent, clientRequestInfo.Id);

                    Parallel.ForEach(queryProviderDictionary.Values, (queryProvider) =>
                    {
                        var query = new Query(queryProvider);
                        rcmDiagnosticEventList.AddRange(query.ExecuteRCMQuery(rcmDiagnosticEventQuery));
                    });

                    foreach (var item in rcmDiagnosticEventList)
                    {
                        clientRequestInfo.RCMErrorContent.AppendLine(item.Message);
                        clientRequestInfo.RCMErrorContent.AppendLine();
                    }
                }

                clientRequestInfo.SubscriptionInfo = new Subscription();
                clientRequestInfo.SRSOperationEvents = sRSOperationEventList;
                clientRequestInfo.ScenarioName = sRSOperationEventList.FirstOrDefault(x => !string.IsNullOrEmpty(x.ScenarioName)).ScenarioName;
                clientRequestInfo.ObjectType = sRSOperationEventList.FirstOrDefault(x => !string.IsNullOrEmpty(x.ObjectType)).ObjectType;
                clientRequestInfo.ObjectId = sRSOperationEventList.FirstOrDefault(x => !string.IsNullOrEmpty(x.ObjectId)).ObjectId;
                clientRequestInfo.ReplicationProviderId = sRSOperationEventList.FirstOrDefault(x => !string.IsNullOrEmpty(x.ReplicationProviderId)).ReplicationProviderId;
                clientRequestInfo.StampName = sRSOperationEventList.FirstOrDefault(x => !string.IsNullOrEmpty(x.StampName)).StampName;
                clientRequestInfo.Region = sRSOperationEventList.FirstOrDefault(x => !string.IsNullOrEmpty(x.Region)).Region;
                var opEventTemp = sRSOperationEventList.FirstOrDefault(x => !string.IsNullOrEmpty(x.SubscriptionId));
                if (opEventTemp != null)
                {
                    clientRequestInfo.SubscriptionInfo.Id = opEventTemp.SubscriptionId;
                }
                else
                {
                    opEventTemp = sRSOperationEventList.FirstOrDefault(x => !string.IsNullOrEmpty(x.SubscriptionId1));
                    if (opEventTemp != null)
                    {
                        clientRequestInfo.SubscriptionInfo.Id = opEventTemp.SubscriptionId1;
                    }
                }
                clientRequestInfo.ResourceId = sRSOperationEventList.FirstOrDefault(x => !string.IsNullOrEmpty(x.ResourceId)).ResourceId;

                var IRFailedoperationEvent = sRSOperationEventList.FirstOrDefault(x => (x.ScenarioName != null && string.Compare(x.ScenarioName, "IrCompletion", StringComparison.OrdinalIgnoreCase) == 0) && (x.State != null && string.Compare(x.State, "Failed", StringComparison.OrdinalIgnoreCase) == 0));

                if(IRFailedoperationEvent != null)
                {
                    var cbEngineTraceMessagesList = new List<CBEngineTraceMessages>();
                    string cbEngineTraceMessagesQuery = string.Format(QueryString.cbEngineTraceMessagesQuery, TableName.CBEngineTraceMessages, clientRequestInfo.ObjectId);

                    Parallel.ForEach(mabProviderDictionary.Values, (queryProvider) =>
                    {
                        var query = new Query(queryProvider);
                        cbEngineTraceMessagesList.AddRange(query.ExecuteCBEngineTraceMessagesQuery(cbEngineTraceMessagesQuery));
                    });

                    foreach (var item in cbEngineTraceMessagesList)
                    {
                        clientRequestInfo.CBEngineTraceMessagesErrorContent.AppendLine(item.Message);
                        clientRequestInfo.CBEngineTraceMessagesErrorContent.AppendLine();
                    }
                }

                if (!string.IsNullOrEmpty(clientRequestInfo.SubscriptionInfo.Id))
                {
                    string subscriptionQuery = string.Format(QueryString.SubscriptionQuery, TableName.CustomerDataExtended, clientRequestInfo.SubscriptionInfo.Id);
                    var query = new Query(queryProviderDictionary["US"]);
                    clientRequestInfo.SubscriptionInfo = query.ExecuteSubscriptionQuery(subscriptionQuery);
                }
            }
            catch (Exception e)
            {

            }
        }

        public static void ProcessClientRequestInfoDetailsForIssue(Issue issue)
        {
            var clientRequestInfoList = new List<ClientRequestInfo>();
            List<string> genericQueryDBTimeMonthList = new List<string>();

            genericQueryDBTimeMonthList.Add(string.Format(QueryString.GenericDataEventQuery, "0", "30"));
            genericQueryDBTimeMonthList.Add(string.Format(QueryString.GenericDataEventQuery, "30", "60"));
            genericQueryDBTimeMonthList.Add(string.Format(QueryString.GenericDataEventQuery, "60", "90"));

            var genericQueryPredicate = "";
            if (issue.Symptoms != null && issue.Symptoms.Count > 0)
            {
                genericQueryPredicate = "|where " + string.Format(QueryString.GenricMessagePredicateDataEventQuery, issue.Symptoms.ElementAt(0));
                foreach (var symptom in issue.Symptoms.Skip(1))
                {
                    genericQueryPredicate += " and " + string.Format(QueryString.GenricMessagePredicateDataEventQuery, symptom);
                }
            }
            genericQueryPredicate += QueryString.GenericDataEventProjectQueryString;

            Parallel.ForEach(genericQueryDBTimeMonthList, (genericQueryDBTimeMonth) =>
            {
                var genericQuery = genericQueryDBTimeMonth + genericQueryPredicate;
                Parallel.ForEach(queryProviderDictionary.Values, (queryProvider) =>
                {
                    var query = new Query(queryProvider);
                    clientRequestInfoList.AddRange(query.ExecuteGenericQuery(genericQuery));
                });
            });

            foreach (var clientinfo in clientRequestInfoList)
            {
                clientinfo.issueList.Add(issue);
            }

            ClientRequestIdHelper.clientRequestInfoList.AddRange(clientRequestInfoList);
        }
    }
}
