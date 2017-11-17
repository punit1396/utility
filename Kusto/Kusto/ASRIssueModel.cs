using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.WindowsAzure.Storage.Table;

namespace Kusto
{
    public class ASRIssueModel : TableEntity
    {

        //public ASRIssueModel()
        //{

        //}

        //public string DeviceId { get; set; }
        //public long CompanyId { get; set; }
        //public int CountOfFailure { get; set; }
        //public int CountOfSuccess { get; set; }
        //public string LastFailId { get; set; }
        //public string ErrorCode { get; set; }
        //public string OperationName { get; set; }
        //public bool PassedOnRetry { get; set; }
        //public string Record { get; set; }
        //public string SubscriptionId { get; set; }
        //public string OwnerName { get; set; }
        //public DateTime EndDate { get; set; }
        //public DateTime LastFailTime { get; set; }
        //public string CompanyName { get; set; }
        //public string GeoLocation { get; set; }
        //public string AgentGroupVersion { get; set; }
        //public string DeviceVersion { get; set; }
        //public bool IsOld { get; set; }
        //public string StampName { get; set; }
        //public string DeviceType { get; set; }
        //public string ServiceType { get; set; }
        //public string ErrorSource { get; set; }
        //public string ExtendedDetails { get; set; }
        //public string ExternalErrorCode { get; set; }
        //public DateTime WeekDate { get; set; }

        //public void Key()
        //{
        //    this.PartitionKey = "opstat";
        //    this.RowKey = this.WeekDate.Ticks.ToString() + "_0_" + this.CompanyId.ToString() + "_" + this.DeviceId + "_" + this.OperationName + "_" + this.ErrorCode;
        //}

        //public bool RegexMatch(string regex, string value, int index)
        //{
        //    try
        //    {
        //        if (this.LastFailId == "") return false;
        //        this.Log = new Log(this.LastFailId, this.EndDate);
        //        Log log = this.Log;
        //        foreach (var msg in log.Message)
        //        {
        //            foreach (Match m in Regex.Matches(msg, regex))
        //            {
        //                Console.Write(msg);
        //                return true;
        //            }
        //        }
        //        return false;
        //    }
        //    catch (Exception e)
        //    {
        //        string msg = "Rule Exception occured. Condition on: Log; Operation name: RegexMatch; Target value: " +
        //                     value + ";Index : " + index;
        //        new RuleLog(DateTime.UtcNow, Guid.NewGuid().ToString(), RuleLogType.RuleException, msg, e.Message);
        //        return false;
        //    }
        //}

        //public bool Contains(string entity, string value)
        //{
        //    try
        //    {
        //        if (this.LastFailId == "") return false;
        //        if (entity == "Log")
        //        {
        //            this.Log = new Log(this.LastFailId, value, this.EndDate);
        //            Log log = this.Log;
        //            if (Int32.Parse(Log.Message.SingleOrDefault()) > 0)
        //                return true;
        //        }
        //        else if (entity == "AgentTaskEvent")
        //        {
        //            this.AgentTaskEvent = new AgentTaskEvent(this.LastFailId, value);
        //            AgentTaskEvent log = this.AgentTaskEvent;
        //            if (Int32.Parse(AgentTaskEvent.Message.SingleOrDefault()) > 0)
        //                return true;
        //        }
        //        return false;
        //    }
        //    catch (Exception e)
        //    {
        //        string msg = "Rule Exception occured. Condition on: " + entity + "; Operation name: Contains; Target value: " +
        //                     value;
        //        new RuleLog(DateTime.UtcNow, Guid.NewGuid().ToString(), RuleLogType.RuleException, msg, e.Message);
        //        return false;
        //    }
        //}


    }

}
