using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Net.Security;
using System.Threading;
using System.Threading.Tasks;

namespace ASRDelegatingHandler
{
    /// <summary>
    /// Modifies the URLs (endpoint and resourcenamespace) to be sent, based on
    /// the value passed.
    /// </summary>
    public class ASRDelegatingHandler : DelegatingHandler, ICloneable
    {
        string rpNamespace;
        string rdfeProxyUri;
        const string ArmUrlPattern = "/Subscriptions/";
        const string RPArmUrlPattern = "/Subscriptions/{0}/resourceGroups/{1}/providers/{2}";
        const string ASRArmUrlPattern = "/Subscriptions/{0}/resourceGroups/{1}/providers/{2}/{3}/{4}/{5}";

        public ASRDelegatingHandler(string rpNamespace = null, string rdfeProxyUri = null)
        {
            this.rdfeProxyUri = rdfeProxyUri;
            this.rpNamespace = rpNamespace;
        }

        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request, CancellationToken cancellationToken)
        {
            var originalRpNameSpace = GetProviderNameSpaceFromArmId(request.RequestUri.AbsoluteUri);

            // Modify only if provider is microsoft.recoveryservices
            if (originalRpNameSpace != null && originalRpNameSpace.ToLower().Contains("microsoft.recoveryservices"))
            {
                // To work with dev boxes
                if (!string.IsNullOrEmpty(rdfeProxyUri) && IfAsrUri(request.RequestUri.AbsoluteUri))
                {
                    // Setting Endpoint to RDFE Proxy
                    if (ServicePointManager.ServerCertificateValidationCallback == null)
                    {
                        ServicePointManager.ServerCertificateValidationCallback =
                            IgnoreCertificateErrorHandler;
                    }

                    request.RequestUri = new Uri(request.RequestUri.AbsoluteUri.Replace(
                        GetEndPoint(request.RequestUri.AbsoluteUri), rdfeProxyUri));
                }

                // To work with internal environments
                if (!string.IsNullOrEmpty(rpNamespace))
                {
                    request.RequestUri = new Uri(request.RequestUri.AbsoluteUri.Replace(
                        GetProviderNameSpaceFromArmId(request.RequestUri.AbsoluteUri), rpNamespace));
                }
            }

            return base.SendAsync(request, cancellationToken);
        }

        /// <summary>
        /// Clone the object.
        /// </summary>
        /// <returns></returns>
        public object Clone()
        {
            return new ASRDelegatingHandler(rpNamespace, rdfeProxyUri);
        }

        private static bool IgnoreCertificateErrorHandler
           (object sender,
           System.Security.Cryptography.X509Certificates.X509Certificate certificate,
           System.Security.Cryptography.X509Certificates.X509Chain chain,
           SslPolicyErrors sslPolicyErrors)
        {
            return true;
        }

        /// <summary>
        /// Returns the end point of the passed uri.
        /// </summary>
        /// <param name="uri"></param>
        /// <param name="format"></param>
        /// <returns></returns>
        public static string GetEndPoint(string uri, string format = ArmUrlPattern)
        {
            // Creates a new copy of the strings.
            string dataCopy = string.Copy(uri);
            string processFormat = string.Copy(format);

            try
            {
                List<string> tokens = new List<string>();
                string processData = string.Empty;

                if (string.IsNullOrEmpty(dataCopy))
                {
                    throw new Exception("Null and empty strings are not valid resource Ids - " + uri);
                }

                // First truncate data string to point from where format string starts.
                // We start from 1 index so that if url starts with / we avoid picking the first /.
                int firstTokenEnd = format.IndexOf("/", 1);
                int matchIndex = dataCopy.ToLower().IndexOf(format.Substring(0, firstTokenEnd).ToLower());

                if (matchIndex == -1)
                {
                    throw new Exception("Invalid resource Id - " + uri);
                }

                processData = dataCopy.Substring(0, matchIndex);
                return processData;
            }
            catch (Exception ex)
            {
                throw new Exception(
                    string.Format("Invalid resource Id - {0}. Exception - {1} ", uri, ex));
            }
        }

        /// <summary>
        /// Returns provider namespace from ARM id.
        /// </summary>
        /// <param name="data">ARM Id of the resource.</param>
        /// <returns>Provider namespace.</returns>
        public static string GetProviderNameSpaceFromArmId(string data)
        {
            try
            {
                return (UnFormatArmId(data, RPArmUrlPattern))[2];
            }
            catch(Exception)
            {
                return null;
            }
        }

        /// <summary>
        /// Check if Uri is targetted to ASR.
        /// </summary>
        /// <param name="uri"></param>
        /// <returns></returns>
        public static bool IfAsrUri(string uri)
        {
            try
            {
                var uriRpNameSpace = GetProviderNameSpaceFromArmId(uri).ToLower();
                
                if (uriRpNameSpace.Contains("microsoft.recoveryservices") &&
                    (UnFormatArmId(uri, ASRArmUrlPattern))[5].ToLower().StartsWith("replication"))
                {
                    return true;
                }
            }
            catch (Exception ex)
            {
                // Ignore exception and return default false
            }

            return false;
        }

        /// <summary>
        /// Returns tokens based on format provided. This works on ARM IDs only.
        /// </summary>
        /// <param name="data">String to unformat.</param>
        /// <param name="format">Format reference.</param>
        /// <returns>Array of string tokens.</returns>
        public static string[] UnFormatArmId(string data, string format)
        {
            // Creates a new copy of the strings.
            string dataCopy = string.Copy(data);
            string processFormat = string.Copy(format);

            try
            {
                List<string> tokens = new List<string>();
                string processData = string.Empty;

                if (string.IsNullOrEmpty(dataCopy))
                {
                    throw new Exception("Null and empty strings are not valid resource Ids - " + data);
                }

                // First truncate data string to point from where format string starts.
                // We start from 1 index so that if url starts with / we avoid picking the first /.
                int firstTokenEnd = format.IndexOf("/", 1);
                int matchIndex = dataCopy.ToLower().IndexOf(format.Substring(0, firstTokenEnd).ToLower());

                if (matchIndex == -1)
                {
                    throw new Exception("Invalid resource Id - " + data);
                }

                processData = dataCopy.Substring(matchIndex);

                int counter = 0;
                while (true)
                {
                    int markerStartIndex = processFormat.IndexOf("{" + counter + "}");

                    if (markerStartIndex == -1)
                    {
                        break;
                    }

                    int markerEndIndex = processData.IndexOf("/", markerStartIndex);

                    if (markerEndIndex == -1)
                    {
                        tokens.Add(processData.Substring(markerStartIndex));
                    }
                    else
                    {
                        tokens.Add(processData.Substring(markerStartIndex, markerEndIndex - markerStartIndex));
                        processData = processData.Substring(markerEndIndex);
                        processFormat = processFormat.Substring(markerStartIndex + 3);
                    }

                    counter++;
                }

                // Similar formats like /a/{0}/b/{1} and /c/{0}/d/{1} can return incorrect tokens
                // therefore, adding another check to ensure that the data is unformatted correctly.
                if (data.ToLower().Contains(string.Format(format, tokens.ToArray()).ToLower()))
                {
                    return tokens.ToArray();
                }
                else
                {
                    throw new Exception("Invalid resource Id - " + data);
                }
            }
            catch (Exception ex)
            {
                throw new Exception(
                    string.Format("Invalid resource Id - {0}. Exception - {1} ", data, ex));
            }
        }
    }
}
