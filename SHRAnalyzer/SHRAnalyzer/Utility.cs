using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HelloKusto
{
    static class Utility
    {
        enum ReplicationProviderName
        {
            A2A
        }

        public static string GetReplicationProviderName(string ReplicationProviderId)
        {
            string replicationProviderName;
            switch (ReplicationProviderId)
            {
                case "d9cbc2cd-8a3c-4222-bfa9-7fee17bb81bd":
                    replicationProviderName = ReplicationProviderName.A2A.ToString();
                    break;
                default:
                    replicationProviderName = ReplicationProviderId;
                    break;
            }

            return replicationProviderName;
        }
    }
}
