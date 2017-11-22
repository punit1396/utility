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
            var dataReader = this.QueryProvider.ExecuteQuery(queryString);

            while (dataReader.Read())
            {
                var srsDataEvent = new SRSDataEvent();
                srsDataEvent.Message = dataReader[ColumnName.Message].ToString();
                content.Add(srsDataEvent);
            }

            return content;
        }

        public List<SRSOperationEvent> ExecuteSRSOperationEventQuery(string queryString)
        {
            var content = new List<SRSOperationEvent>();
            var dataReader = this.QueryProvider.ExecuteQuery(queryString);

            while (dataReader.Read())
            {
                var sRSOperationEvent = new SRSOperationEvent();
                sRSOperationEvent.ScenarioName = dataReader[ColumnName.ScenarioName].ToString();
                sRSOperationEvent.ObjectType = dataReader[ColumnName.ObjectType].ToString();
                sRSOperationEvent.ObjectId = dataReader[ColumnName.ObjectId].ToString();
                sRSOperationEvent.ProviderGuid = dataReader[ColumnName.ProviderGuid].ToString();
                sRSOperationEvent.StampName = dataReader[ColumnName.StampName].ToString();
                sRSOperationEvent.Region = dataReader[ColumnName.Region].ToString();
                sRSOperationEvent.SubscriptionId = dataReader[ColumnName.SubscriptionId1].ToString();
                sRSOperationEvent.ResourceId = dataReader[ColumnName.ResourceId1].ToString();
                sRSOperationEvent.PreciseTimeStamp = dataReader[ColumnName.PreciseTimeStamp].ToString();
                sRSOperationEvent.SRSOperationName = dataReader[ColumnName.SRSOperationName].ToString();
                sRSOperationEvent.State = dataReader[ColumnName.State].ToString();
                sRSOperationEvent.ServiceActivityId = dataReader[ColumnName.ServiceActivityId].ToString();
                content.Add(sRSOperationEvent);
            }

            return content;
        }

        public Subscription ExecuteSubscriptionQuery(string subscriptionQuery)
        {
            var dataReader = this.QueryProvider.ExecuteQuery(subscriptionQuery);
            var subscriptionInfo = new Subscription();
            while (dataReader.Read())
            {
                subscriptionInfo.Id = dataReader[ColumnName.SubscriptionId].ToString();
                subscriptionInfo.BillingType = dataReader[ColumnName.BillingType].ToString();
                subscriptionInfo.OfferType = dataReader[ColumnName.OfferType].ToString();
                subscriptionInfo.CustomerName = dataReader[ColumnName.CustomerName].ToString();
                subscriptionInfo.SubscriptionName = dataReader[ColumnName.SubscriptionName].ToString();
            }
            return subscriptionInfo;
        }
    }

    class QueryHelper
    {
        private static Dictionary<string, ICslQueryProvider> queryProviderDictionary;

        static QueryHelper()
        {
            queryProviderDictionary = new Dictionary<string, ICslQueryProvider>();
            queryProviderDictionary.Add("Europe", KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringEurope));
            queryProviderDictionary.Add("US", KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringUS));
            queryProviderDictionary.Add("Asia", KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringAsia));
            queryProviderDictionary.Add("Internal", KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringInternal));
        }

        public static void FillClientRequestInfoDetails(ClientRequestInfo clientRequestInfo)
        {
            string errorQuery = string.Format(QueryString.ErrorQuery, clientRequestInfo.Id);
            string sRSOperationEventQuery = string.Format(QueryString.SRSOperationEventQuery, clientRequestInfo.Id);
            
            var sRSDataEventList = new List<SRSDataEvent>();
            var sRSOperationEventList = new List<SRSOperationEvent>();

            Parallel.ForEach(queryProviderDictionary.Values, (queryProvider) =>
            {
                var query = new Query(queryProvider);
                sRSDataEventList.AddRange(query.ExecuteErrorQuery(errorQuery));
                sRSOperationEventList.AddRange(query.ExecuteSRSOperationEventQuery(sRSOperationEventQuery));
            });

            var errorContent = new StringBuilder();
            foreach(var item in sRSDataEventList)
            {
                errorContent.AppendLine(item.Message);
                errorContent.AppendLine();
            }

            clientRequestInfo.AddErrorContent(errorContent);

            try
            {
                clientRequestInfo.SubscriptionInfo = new Subscription();
                clientRequestInfo.SRSOperationEvents = sRSOperationEventList;
                clientRequestInfo.ScenarioName = sRSOperationEventList.FirstOrDefault(x => !string.IsNullOrEmpty(x.ScenarioName)).ScenarioName;
                clientRequestInfo.ObjectType = sRSOperationEventList.FirstOrDefault(x => !string.IsNullOrEmpty(x.ObjectType)).ObjectType;
                clientRequestInfo.ObjectId = sRSOperationEventList.FirstOrDefault(x => !string.IsNullOrEmpty(x.ObjectId)).ObjectId;
                clientRequestInfo.ProviderGuid = sRSOperationEventList.FirstOrDefault(x => !string.IsNullOrEmpty(x.ProviderGuid)).ProviderGuid;
                clientRequestInfo.StampName = sRSOperationEventList.FirstOrDefault(x => !string.IsNullOrEmpty(x.StampName)).StampName;
                clientRequestInfo.Region = sRSOperationEventList.FirstOrDefault(x => !string.IsNullOrEmpty(x.Region)).Region;
                clientRequestInfo.SubscriptionInfo.Id = sRSOperationEventList.FirstOrDefault(x => !string.IsNullOrEmpty(x.SubscriptionId)).SubscriptionId;
                clientRequestInfo.ResourceId = sRSOperationEventList.FirstOrDefault(x => !string.IsNullOrEmpty(x.SubscriptionId)).ResourceId;

                if(!string.IsNullOrEmpty(clientRequestInfo.SubscriptionInfo.Id))
                {
                    string subscriptionQuery = string.Format(QueryString.SubscriptionQuery, clientRequestInfo.SubscriptionInfo.Id);
                    var query = new Query(queryProviderDictionary["US"]);
                    clientRequestInfo.SubscriptionInfo = query.ExecuteSubscriptionQuery(subscriptionQuery);
                }
            }
            catch(Exception)
            {

            }
        }
    }
}
