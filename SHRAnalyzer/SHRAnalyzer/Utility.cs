using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HelloKusto
{
    /// <summary>
    /// Replication Provider Type.
    /// </summary>
    public enum ReplicationProviderType
    {
        /// <summary>
        /// Hyper-V Replica for SP1.
        /// </summary>
        HyperVReplica2012,

        /// <summary>
        /// Hyper-V Replica for blue.
        /// </summary>
        HyperVReplica2012R2,

        /// <summary>
        /// Hyper-V Replica for Azure.
        /// </summary>
        HyperVReplicaAzure,

        /// <summary>
        /// InMage for Azure V2.
        /// </summary>
        InMageAzureV2,

        /// <summary>
        /// InMage replication provider (E2E).
        /// </summary>
        InMage,

        /// <summary>
        /// InMage Azure provider v1
        /// </summary>
        InMageAzure,

        /// <summary>
        /// SAN provider.
        /// </summary>
        San,

        /// <summary>
        /// SQL always on provider.
        /// </summary>
        SqlAlwaysOn,

        /// <summary>
        /// WVR provider.
        /// </summary>
        Wvr,

        /// <summary>
        /// A2A provider.
        /// </summary>
        A2A,

        /// <summary>
        /// VMware Cbt provider.
        /// </summary>
        VMwareCbt
    }

    /// <summary>
    /// Class holding the Ids of the currently supported providers.
    /// </summary>
    public static class WellKnownProviders
    {
        /// <summary>
        /// Id of the Hyper-V Replica 2012 provider.
        /// </summary>
        public const string HyperVReplica = "6c11a271-07bc-4ec4-bf1b-82b2189f980f";

        /// <summary>
        /// Id of the Hyper-V Replica 2012 R2 provider.
        /// </summary>
        public const string HyperVReplicaBlue = "9208701f-5eaa-45c9-ad8a-0d8d097264ef";

        /// <summary>
        /// Id of the Hyper-V Replica Azure provider.
        /// </summary>
        public const string HyperVReplicaAzure = "371f87f9-53e5-429f-b10b-f14700a4b137";

        /// <summary>
        /// Id of the SAN provider.
        /// </summary>
        public const string San = "fef69a22-3c9f-45fe-beeb-1796c1ce1654";

        /// <summary>
        /// Id of the InMage (Vmware to Azure) provider.
        /// </summary>
        public const string InMageAzure = "b5733d78-9ca5-4b41-9906-3646848dee46";

        /// <summary>
        /// Id of the Wvr provider.
        /// </summary>
        public const string Wvr = "b35241c5-7d83-4c59-b9a7-91e66c3cacd2";

        /// <summary>
        /// Id of the Sql AlwaysOn provider.
        /// </summary>
        public const string SqlAlwaysOn = "7ee648dd-d1ce-4ffc-9f1c-1d3ff357bb36";

        /// <summary>
        /// Id of the InMage Azure V2 provider.
        /// </summary>
        public const string InMageAzureV2 = "c42d7660-b374-4d4b-afb0-e7c67b53e20c";

        /// <summary>
        /// Id of the InMage provider.
        /// </summary>
        public const string InMage = "b68561cf-6b85-4e83-ad51-eb13013ff659";

        /// <summary>
        /// Id of the A2A provider.
        /// </summary>
        public const string A2A = "d9cbc2cd-8a3c-4222-bfa9-7fee17bb81bd";

        /// <summary>
        /// Id of the VMware Cbt provider.
        /// </summary>
        public const string VMwareCbt = "6c7da455-506f-43ff-a16a-8eb101aebb70";

        /// <summary>
        /// Key-Value pairs of all known provider Ids and their type.
        /// </summary>
        private static Dictionary<string, string> providerIds = new Dictionary<string, string>
            {
                { HyperVReplica, "HyperVReplica" },
                { HyperVReplicaBlue, "HyperVReplicaBlue" },
                { HyperVReplicaAzure, "HyperVReplicaAzure" },
                { San, "San" },
                { Wvr, "Wvr" },
                { InMage, "InMage" },
                { InMageAzure, "InMageAzure" },
                { InMageAzureV2, "InMageAzureV2" },
                { SqlAlwaysOn, "SqlAlwaysOn" },
                { A2A, "A2A" },
                { VMwareCbt, "VMwareCbt" }
            };

        /// <summary>
        /// Gets dictionary of all known provider Ids.
        /// </summary>
        public static Dictionary<string, string> ProviderIds
        {
            get
            {
                return providerIds;
            }
        }

        /// <summary>
        /// Checks if the specified protection unit id is the replication provider Id too
        /// which happens for VMM 2012 SP1.
        /// </summary>
        /// <param name="puId">PU id to match with exiting well known providers.</param>
        /// <returns>True if id is well know provider False otherwise.</returns>
        public static bool IsVmm2012Sp1ProviderId(string puId)
        {
            return string.Compare(puId, HyperVReplica) == 0 ||
                string.Compare(puId, HyperVReplicaBlue) == 0;
        }
    }

    static class Utility
    {
        /// <summary>
        /// Value to be sent if replication provider Id could not be found in the map.
        /// </summary>
        private const string UnknownReplicationProviderId = "Other";

        /// <summary>
        /// Replication provider map.
        /// </summary>
        private static Dictionary<string, string> replicationProviderNameMap =
            new Dictionary<string, string>()
            {
                { WellKnownProviders.HyperVReplicaBlue, ReplicationProviderType.HyperVReplica2012R2.ToString() },
                { WellKnownProviders.HyperVReplica, ReplicationProviderType.HyperVReplica2012.ToString() },
                { WellKnownProviders.HyperVReplicaAzure, ReplicationProviderType.HyperVReplicaAzure.ToString() },
                { WellKnownProviders.InMage, ReplicationProviderType.InMage.ToString() },
                { WellKnownProviders.InMageAzure, ReplicationProviderType.InMageAzure.ToString() },
                { WellKnownProviders.InMageAzureV2, ReplicationProviderType.InMageAzureV2.ToString() },
                { WellKnownProviders.San, ReplicationProviderType.San.ToString() },
                { WellKnownProviders.SqlAlwaysOn, ReplicationProviderType.SqlAlwaysOn.ToString() },
                { WellKnownProviders.Wvr, ReplicationProviderType.Wvr.ToString() },
                { WellKnownProviders.A2A, ReplicationProviderType.A2A.ToString() },
                { WellKnownProviders.VMwareCbt, ReplicationProviderType.VMwareCbt.ToString() }
            };

        

        public static string GetReplicationProviderName(string ReplicationProviderId)
        {
            string replicationProviderName = "";
            try
            {
                if (!string.IsNullOrEmpty(ReplicationProviderId) && replicationProviderNameMap.ContainsKey(ReplicationProviderId))
                {
                    replicationProviderName = replicationProviderNameMap[ReplicationProviderId];
                }
                else
                {
                    replicationProviderName = ReplicationProviderId;
                }

            }
            catch (Exception e)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Exception was thrown:");
                Console.WriteLine(e);
            }

            return replicationProviderName;
        }
    }
}
