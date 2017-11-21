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
        public const string ConnectionStringMoonCake = @"Data Source=https://asrclus.kusto.windows.net:443;Initial Catalog=ASRKustoDB;AAD Federated Security=True";
        public const string ConnectionStringFairFax = @"Data Source=https://asrclus.kusto.usgovcloudapi.net:443;Initial Catalog=ASRKustoDB_FF;AAD Federated Security=True";
    }

    class QueryString 
    {
        public const string ErrorQuery = "SRSDataEvent | where ClientRequestId == '{0}'" +
                        "| where Level < 3 " +
                        "| project PreciseTimeStamp , Message , Level, ClientRequestId " +
                        "| order by PreciseTimeStamp asc nulls last";

    };
}
