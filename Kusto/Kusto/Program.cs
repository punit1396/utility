﻿using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
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

            if (args.Length >= 1)
            {
                clientRequestIdsFilePath = args[0];
            }

            if(args.Length >= 2)
            {
                inMarketResultsFilePath = args[1];
            }

            if(args.Length == 3)
            {
                issueMapFilePath = args[2];
            }

        
            IssueHelper.Initialize(issueMapFilePath);
            ClientRequestIdHelper.Initialize(clientRequestIdsFilePath);

            Parallel.ForEach(ClientRequestIdHelper.clientRequestInfoList, (clientRequestInfo) =>
            {
                StringBuilder content = new StringBuilder();
                content = QueryHelper.ExecuteErrorQuery(clientRequestInfo);

                clientRequestInfo.AddErrorContent(content);
            });

            using (StreamWriter file = File.CreateText(inMarketResultsFilePath))
            {
                foreach (var clientRequestInfo in ClientRequestIdHelper.clientRequestInfoList)
                {
                    file.WriteLine("*************************************************** Error details of ClientRequestID: " + clientRequestInfo.Id + "***************************************************");
                    file.WriteLine();

                    file.WriteLine(clientRequestInfo.ErrorContent.ToString());
                    file.WriteLine();
                }

                // Writing ClientRequestId to Issue map to file
                file.WriteLine("---------------------------------------------------------- Issues for ClientRequestIds ----------------------------------------------------------");
                file.WriteLine();
                foreach (var clientRequestId in ClientRequestIdHelper.clientRequestInfoList)
                {
                    file.WriteLine("*********Issues found in ClientRequestID, " + clientRequestId.Id + ":");
                    file.WriteLine();

                    foreach (var issue in IssueHelper.GetMachingIssues(clientRequestId.ErrorContent.ToString()))
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