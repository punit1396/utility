namespace HelloKusto
{
    class QueryResult
    {
        public string PreciseTimeStamp;
        public string ClientRequestId;
        public string Message;
        public string SubscriptionId;
        public string SubscriptionId1;
        public string ReplicationProviderId;
        public string StampName;
        public string Region;
        public string ResourceId;
        public string ServiceActivityId;
    }

    class SRSDataEvent : QueryResult
    {

    }

    class SRSOperationEvent : QueryResult
    {
        public string ScenarioName;
        public string ObjectType;
        public string ObjectId;
        public string SRSOperationName;
        public string State;

    }

    class RcmDiagnosticEvent : QueryResult
    {

    }
    class GatewayDiagnosticEvent : QueryResult
    {

    }

    class Subscription
    {
        public string Id;
        public string BillingType;
        public string SubscriptionName;
        public string OfferType;
        public string CustomerName;
    }
}
