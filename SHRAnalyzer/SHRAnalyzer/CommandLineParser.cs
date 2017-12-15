using CommandLine;
using CommandLine.Text;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;

namespace HelloKusto
{
    class CommandLineOptions
    {
        [Option('i', "clientRequestIdFilePath", MutuallyExclusiveSet ="WithClientRequestIdFile", Required = false,
           HelpText = "Full path of input file with clientRequest Ids to be analyzed. One clientrequestId per line.")]
        public string InputFile { get; set; }

        [Option('c', "clientRequestIdList", MutuallyExclusiveSet = "WithClientRequestIdList", Required = false,
           HelpText = "Comma separated clientRequest Ids to be analyzed. (Alternative for --clientRequestIdFilePath)")]
        public string InputList { get; set; }

        [Option('o', "resultsFilePath", Required = false,
           HelpText = "Full path of file where result of analysis would be generated.")]
        public string OutputFile { get; set; }

        [Option('m', "issueMapFilePath", Required = false,
            HelpText = "Full path of file with string maps and bug ids for known issues.")]
        public string IssueMapFile { get; set; }

        [Option("withDraLogs", DefaultValue = false,
          HelpText = "Get extended DRA logs if needed. Only for intances with error traces containing 'Microsoft.Carmine.WSManWrappers.WSManException'")]
        public bool WithDRALogs { get; set; }

        [Option("useAsyncKustoCalls", DefaultValue = false,
            HelpText = "Use async Kusto calls for the analysis.")]
        public bool UseAsyncKustoCalls { get; set; }

        [ParserState]
        public IParserState LastParserState { get; set; }

        [HelpOption('h',"help",HelpText = "Dispaly help.")]
        public string GetUsage()
        {
            StringBuilder helpText = new StringBuilder();
            helpText.AppendLine(HelpText.AutoBuild(this,(HelpText current) => HelpText.DefaultParsingErrorsHandler(this, current)));
            helpText.AppendLine();
            helpText.AppendLine("Examples:");
            helpText.AppendLine();
            helpText.AppendLine("\\\\idlsstore\\V2Writable\\avrai\\sharing\\SHRAnalyzer\\SHRAnalyzer.exe -i \"F:\\ClientRequestIdsFilePath.txt\" -o \"F:\\InMarketResultsFilePath.txt\"");
            helpText.AppendLine();
            helpText.AppendLine("\\\\idlsstore\\V2Writable\\avrai\\sharing\\SHRAnalyzer\\SHRAnalyzer.exe -i \"F:\\ClientRequestIdsFilePath.txt\" -o \"F:\\InMarketResultsFilePath.txt\" --withDraLogs");
            helpText.AppendLine();
            helpText.AppendLine("\\\\idlsstore\\V2Writable\\avrai\\sharing\\SHRAnalyzer\\SHRAnalyzer.exe --clientRequestIdFilePath=\"F:\\ClientRequestIdsFilePath.txt\" --resultsFilePath=\"F:\\InMarketResultsFilePath.txt\"");
            helpText.AppendLine();
            return helpText.ToString();
        }
    }
}
