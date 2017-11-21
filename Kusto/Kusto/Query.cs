using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
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

        public StringBuilder ExecuteErrorQuery(string queryString)
        {
            var content = new StringBuilder();
            var dataReader = this.QueryProvider.ExecuteQuery(queryString);
            var columns = Enumerable.Range(0, dataReader.FieldCount)
                .Select(dataReader.GetName)
                .ToList();

            while (dataReader.Read())
            {
                content.AppendLine(dataReader[columns[1]].ToString());
                content.AppendLine();
            }

            return content;
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

        public static StringBuilder ExecuteErrorQuery(ClientRequestInfo clientRequestInfo)
        {
            string queryString = string.Format(QueryString.ErrorQuery, clientRequestInfo.Id);
            StringBuilder content = new StringBuilder();

            Parallel.ForEach(queryProviderDictionary.Values, (queryProvider) =>
            {
                var query = new Query(queryProvider);
                content.Append(query.ExecuteErrorQuery(queryString));
            });

            return content;
        }
    }
}
