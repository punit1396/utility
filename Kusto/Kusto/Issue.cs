using System;
using System.Collections.Generic;
using System.IO;

namespace HelloKusto
{
    class Issue
    {
        public string Type;
        public string BugId;
        private HashSet<string> Symptoms;

        public Issue()
        {
            Type = "";
            BugId = "";
            this.Symptoms = new HashSet<string>();
        }

        public Issue(string issueType, string bugId, HashSet<string> symptoms)
        {
            this.Type = issueType;
            this.BugId = bugId;
            this.Symptoms = symptoms;
        }

        public void AddSymptom(string symptom)
        {
            this.Symptoms.Add(symptom);
        }

        public bool IfSymptomsMatch(string content)
        {
            bool IfSymptomsMatch = true;
            foreach (var symptom in Symptoms)
            {
                if (!content.ToString().ToLower().Contains(symptom.ToLower()))
                {
                    IfSymptomsMatch = false;
                    break;
                }
            }

            return IfSymptomsMatch;
        }
    }

    class IssueHelper
    {
        public static List<Issue> IssueList = new List<Issue>();
        public static void Initialize(string issueMapFilePath)
        {
            try
            {
                using (var reader = new StreamReader(issueMapFilePath))
                {
                    string line;
                    while ((line = reader.ReadLine()) != null)
                    {
                        var issueDetailsArray = line.Trim().Split('|');
                        var symptomsArray = issueDetailsArray[2].Split(',');
                        IssueList.Add(new Issue(issueDetailsArray[0], issueDetailsArray[1], new HashSet<string>(symptomsArray)));
                    }
                }
            }
            catch (Exception)
            {

            }
        }

        public static List<Issue> GetMachingIssues(string content)
        {
            List<Issue> issues = new List<Issue>();
            foreach(var issue in IssueList)
            {
                if(issue.IfSymptomsMatch(content))
                {
                    issues.Add(issue);
                }
            }

            return issues;
        }
    }
}
