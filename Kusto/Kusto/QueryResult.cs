namespace HelloKusto
{
    class QueryResult
    {
        public string PreciseTimeStamp;
        public string ClientRequestId;
        public string Message;
        public string SubscriptionId;
        public string ProviderGuid;
        public string StampName;
        public string Region;
        public string ResourceId;
    }

    class SRSDataEvent : QueryResult
    {

    }

    class SRSOperationEvent : QueryResult
    {
        public string ScenarioName;
        public string ObjectType;
        public string ObjectId;
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
