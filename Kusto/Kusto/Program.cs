using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Text;
//using CommandLine;
using Kusto.Data.Net.Client;

namespace HelloKusto
{
    class Program
    {
        static void Main(string[] args)
        {
            string inMarketResultsFilePath = Path.Combine(Path.GetDirectoryName(Environment.GetCommandLineArgs()[0]), "InMarketResultsFilePath" + ".txt");
            string clientRequestIdsFilePath = Path.Combine(Path.GetDirectoryName(Environment.GetCommandLineArgs()[0]), "ClientRequestIdsFilePath" + ".txt");
            string issueMapFilePath = Path.Combine(Path.GetDirectoryName(Environment.GetCommandLineArgs()[0]), "IssueMapFilePath" + ".txt");

            IssueHelper.Initialize(issueMapFilePath);
            ClientRequestIdHelper.Initialize(clientRequestIdsFilePath);

            var queryProviderEurope = KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringEurope);
            var queryProviderUS = KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringUS);
            var queryProviderAsia = KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringAsia);
            var queryProviderInternal = KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringInternal);
            var queryProviderMoonCake = KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringMoonCake);
            var queryProviderFairFax = KustoClientFactory.CreateCslQueryProvider(Constant.ConnectionStringFairFax);

            using (StreamWriter file = File.CreateText(inMarketResultsFilePath))
            {
                foreach (var clientRequestInfo in ClientRequestIdHelper.clientRequestInfoList)
                {
                    file.WriteLine("*************************************************** Error details of ClientRequestID: " + clientRequestInfo.Id + "***************************************************");
                    file.WriteLine();

                    string query = "SRSDataEvent | where ClientRequestId == '" + clientRequestInfo.Id + "'" +
                        "| where Level < 3 " +
                        "| project PreciseTimeStamp , Message , Level, ClientRequestId " +
                        "| order by PreciseTimeStamp asc nulls last";

                    var readerEurope = queryProviderEurope.ExecuteQuery(query);
                    var readerUS = queryProviderUS.ExecuteQuery(query);
                    var readerAsia = queryProviderAsia.ExecuteQuery(query);
                    var readerInternal = queryProviderInternal.ExecuteQuery(query);
                    //var readerMoonCake = queryProviderMoonCake.ExecuteQuery(query);
                    //var readerFairFax = queryProviderFairFax.ExecuteQuery(query);

                    var columnsEurope = Enumerable.Range(0, readerEurope.FieldCount)
                                    .Select(readerEurope.GetName)
                                    .ToList();
                    var columnsUS = Enumerable.Range(0, readerUS.FieldCount)
                                    .Select(readerUS.GetName)
                                    .ToList();
                    var columnsAsia = Enumerable.Range(0, readerAsia.FieldCount)
                                    .Select(readerAsia.GetName)
                                    .ToList();
                    var columnsInternal = Enumerable.Range(0, readerInternal.FieldCount)
                                    .Select(readerInternal.GetName)
                                    .ToList();
                    //var columnsMoonCake = Enumerable.Range(0, readerMoonCake.FieldCount)
                    //                .Select(readerMoonCake.GetName)
                    //                .ToList();
                    //var columnsFairFax = Enumerable.Range(0, readerFairFax.FieldCount)
                    //                .Select(readerFairFax.GetName)
                    //                .ToList();

                    StringBuilder content = new StringBuilder();

                    while (readerEurope.Read())
                    {
                        content.AppendLine(readerEurope[columnsEurope[1]].ToString());
                        content.AppendLine();
                    }
                    while (readerUS.Read())
                    {
                        content.AppendLine(readerUS[columnsUS[1]].ToString());
                        content.AppendLine();
                    }
                    while (readerAsia.Read())
                    {
                        content.AppendLine(readerAsia[columnsAsia[1]].ToString());
                        content.AppendLine();
                    }
                    while (readerInternal.Read())
                    {
                        content.AppendLine(readerInternal[columnsInternal[1]].ToString());
                        content.AppendLine();
                    }

                    //while (readerMoonCake.Read())
                    //{
                    //    var content = readerMoonCake[columnsMoonCake[1]];
                    //    file.WriteLine(readerMoonCake[columnsMoonCake[1]]);
                    //    file.WriteLine();
                    //}
                    //while (readerFairFax.Read())
                    //{
                    //    var content = readerFairFax[columnsFairFax[1]];
                    //    file.WriteLine(readerFairFax[columnsFairFax[1]]);
                    //    file.WriteLine();
                    //}

                    file.WriteLine(content.ToString());
                    file.WriteLine();

                    foreach (var issue in IssueHelper.GetMachingIssues(content.ToString()))
                    {
                        clientRequestInfo.AddIssue(issue);
                    }
                }

                // Writing ClientRequestId to Issue map to file
                file.WriteLine("---------------------------------------------------------- Issues for ClientRequestIds ----------------------------------------------------------");
                file.WriteLine();
                foreach (var clientRequestId in ClientRequestIdHelper.clientRequestInfoList)
                {
                    file.WriteLine("*********Issues found in ClientRequestID, " + clientRequestId.Id + ":");
                    file.WriteLine();

                    foreach (var issue in clientRequestId.Issues)
                    {
                        string issueStatement = "Issue: " + issue.Type + ", Bug: " + issue.BugId;
                        file.WriteLine(issueStatement);
                    }

                    file.WriteLine();
                }

                file.WriteLine("---------------------------------------------------------- ClientRequestIds for issues----------------------------------------------------------");
                file.WriteLine();
                foreach (var issue in IssueHelper.IssueList)
                {
                    file.WriteLine("*********ClientRequestIDs affected by issue: " + issue.Type + ", Bug: " + issue.BugId);
                    file.WriteLine();
                    foreach (var clientRequestInfo in ClientRequestIdHelper.GetAffectedClientRequestInfos(issue))
                    {
                        file.WriteLine(clientRequestInfo.Id);
                    }
                    file.WriteLine();
                }

            }
        }

        public static void PushToExcel(DataTableReader reader)
        {
            //string attachment = "attachment; filename=city.xls";
            //Response.ClearContent();
            //Response.AddHeader("content-disposition", attachment);
            //Response.ContentType = "application/vnd.ms-excel";
            //string tab = "";
            //foreach (DataColumn dc in dt.Columns)
            //{
            //    Response.Write(tab + dc.ColumnName);
            //    tab = "\t";
            //}
            //Response.Write("\n");
            //int i;
            //foreach (DataRow dr in dt.Rows)
            //{
            //    tab = "";
            //    for (i = 0; i < dt.Columns.Count; i++)
            //    {
            //        Response.Write(tab + dr[i].ToString());
            //        tab = "\t";
            //    }
            //    Response.Write("\n");
            //}
            //Response.End();
        }
    }

    //public class InputOptions
    //{
    //    public InputOptions(string[] args)
    //    {

    //    }

    //    #region Switch Properties
    //    [Option("F", true, 1)]
    //    [SwitchHelpText("First name of customer")]
    //    public string firstName { get; set; }
    //    [Switch("L", true, 2)]
    //    [SwitchHelpText("Last name of customer")]
    //    public LastNameEnum lastName { get; set; }
    //    [SwitchHelpText("The date of birth of customer")]
    //    [Switch("DOB", false, 3)]
    //    public DateTime DOB { get; set; }
    //    [Switch("T", false, 4, "bodega", "pizza shop")]
    //    public Type CustomerType { get; set; }
    //    #endregion

    //    public override Dictionary<Func<bool>, string> GetParamExceptionDictionary()
    //    {
    //        Dictionary<Func<bool>, string> _exceptionChecks = new Dictionary<Func<bool>, string>();

    //        Func<bool> _isDateInFuture = new Func<bool>(() => DateTime.Now <= this.DOB);

    //        _exceptionChecks.Add(_isDateInFuture, "Please choose a date of birth that is not in the future!");
    //        return _exceptionChecks;
    //    }

    //    [HelpText(0)]
    //    public string Description
    //    {
    //        get { return "Finds a customer in the database."; }
    //    }
    //    [HelpText(1, "Example")]
    //    public string ExampleText
    //    {
    //        get { return "This is an example: CustomerFinder.exe Yisrael Lax 11-28-1987"; }
    //    }
    //    [HelpText(2)]
    //    public override string Usage
    //    {
    //        get { return base.Usage; }
    //    }
    //    [HelpText(3, "Parameters")]
    //    public override string SwitchHelp
    //    {
    //        get { return base.SwitchHelp; }
    //    }
    //}
}
