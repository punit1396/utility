using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HelloKusto
{
    class Constant
    {
        public const string ConnectionStringEurope = @"Data Source=https://asrcluswe.kusto.windows.net:443;Initial Catalog=ASRKustoDB_Europe;AAD Federated Security=True";
        public const string ConnectionStringUS = @"Data Source=https://asrcluscus.kusto.windows.net:443;Initial Catalog=ASRKustoDB_US;AAD Federated Security=True";
        public const string ConnectionStringAsia = @"Data Source=https://asrclussea.kusto.windows.net:443;Initial Catalog=ASRKustoDB_Asia;AAD Federated Security=True";
        public const string ConnectionStringInternal = @"Data Source=https://asrclus1.kusto.windows.net:443;Initial Catalog=ASRKustoDB;AAD Federated Security=True";
        public const string ConnectionStringMoonCake = @"https://asrclusmc.kusto.chinacloudapi.cn:443;Initial Catalog=NetDefaultDB;dSTS Federated Security=True";
        public const string ConnectionStringBlackForest = @"https://asrclusbf.kusto.cloudapi.de:443;Initial Catalog=NetDefaultDB;dSTS Federated Security=True";
        public const string ConnectionStringFairFax = @"https://asrclusff.kusto.usgovcloudapi.net:443;Initial Catalog=NetDefaultDB;dSTS Federated Security=True";
    }

    class QueryString 
    {
        public const string ErrorQuery = "{0} | where ClientRequestId == '{1}'" +
                        "| where Level < 3 " +
                        "| project PreciseTimeStamp , Message , Level, ClientRequestId " +
                        "| order by PreciseTimeStamp asc nulls last";
        public const string SRSOperationEventQuery = "{0} | where ClientRequestId == '{1}'" +
                        "| order by PreciseTimeStamp asc nulls last";
        public const string SubscriptionQuery = "{0}| where SubscriptionId == '{1}'";
        public const string GenericDataEventQuery = "SRSDataEvent | where (PreciseTimeStamp < ago({0}d) and PreciseTimeStamp >= ago({1}d))";
        public const string GenricMessagePredicateDataEventQuery = "Message contains '{0}'";
        public const string GenericDataEventProjectQueryString = "| where Level < 3| project ClientRequestId | summarize by ClientRequestId";
    }

    class TableName
    {
        public const string SRSDataEvent = "SRSDataEvent";
        public const string SRSOperationEvent = "SRSOperationEvent";
        public const string CustomerDataExtended = "CustomerDataExtended";
        public const string GatewayDiagnosticEvent = "GatewayDiagnosticEvent";
        public const string RcmDiagnosticEvent = "RcmDiagnosticEvent";
    }

    class ColumnName
    {
        public const string PreciseTimeStamp = "PreciseTimeStamp";
        public const string ClientRequestId = "ClientRequestId";
        public const string Message = "Message";
        public const string SubscriptionId = "SubscriptionId";
        public const string SubscriptionId1 = "SubscriptionId1";
        public const string ReplicationProviderId = "ReplicationProviderId";
        public const string StampName = "StampName";
        public const string Region = "Region";
        public const string ResourceId = "ResourceId";
        public const string ResourceId1 = "ResourceId1";
        public const string ScenarioName = "ScenarioName";
        public const string ObjectType = "ObjectType";
        public const string ObjectId = "ObjectId";
        public const string BillingType = "BillingType";
        public const string SubscriptionName = "SubscriptionName";
        public const string OfferType = "OfferType";
        public const string CustomerName = "CustomerName";
        public const string ServiceActivityId = "ServiceActivityId";
        public const string SRSOperationName = "SRSOperationName";
        public const string State = "State";

    }
}
