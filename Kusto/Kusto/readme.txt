Kusto Management Client Library
===============================

Updated documentation can be found at:
https://kusto.azurewebsites.net/docs/api/kusto_management_client_library.html


What's new?
===========
Version 3.0.1 (05 JULY 2017):
* Fix Microsoft.WindowsAzure.Storage dependency declaration

Version 3.0.0 (05 JULY 2017):
* Upgrade Newtonsoft.Json to version 10.0.3 and Microsoft.WindowsAzure.Storage to version 8.1.4

Version 2.3.9 (20 JUNE 2017):
* Bug fix - fix hang when running inside 'Orleans' framework

Version 2.3.8 (15 JUNE 2017):
* NetworkCache: Added support for setting timer start refreshing time and cache refreshing timeout.

Version 2.3.7 (22 MAY 2017):
* KCSB - block sending corporate credentials when using basic authentication.

Version 2.3.6 (7 MAY 2017):
* Extend kusto ingestion error codes with 'NoError'.

Version 2.3.5 (27 APR 2017):
* Add kusto ingestion error codes.

Version 2.3.4 (09 APR 2017):
* Bug fix - support AAD token acquisition based-on application client ID and certificate thumbprint.

Version 2.3.3 (30 MAR 2017):
* Add Kusto Connection String validation.

Version 2.3.2 (16 MAR 2017):
* Target client library to .net 4.5 to enable customers that cannot use higher versions to use Kusto client.

Version 2.3.1 (13 FEB 2017):
* Support AAD Multi-Tenant access to Kusto for applications.

Version 2.3.0 (12 FEB 2017):
* Support AAD Multi-Tenant access to Kusto.

Version 2.2.10 (8 DEC 2016):
* Added Async version to all functions.

Version 2.2.9 (24 NOV 2016):
* Extend Azure Storage retry policy in order to handle IO exceptions.

Version 2.2.8 (16 NOV 2016):
* Extend Azure Storage retry policy in order to handle web and socket exceptions.

Version 2.2.7 (16 NOV 2016):
* Support Multi-Factor Authentication enforcement for AAD-based authentication.

Version 2.2.6 (2 NOV 2016):
* Explicit polling time to create database.

Version 2.2.5 (22 SEP 2016):
* Fix potential deadlock in 'ExecuteQuery' when running in IIS.

Version 2.2.4 (20 SEP 2016):
* Fix potential deadlock during AAD token acquisition.

Version 2.2.3 (18 SEP 2016):
* Security bug fix (client credentials leak to traces).

Version 2.2.2 (12 SEP 2016):
* Add create cluster command.

Version 2.2.1 (5 SEP 2016):
* Support dSTS-based application authentication.

Version 2.2.0 (4 SEP 2016):
* Add ExecuteControlCommand and ShowOperations functions.

Version 2.1.11 (17 AUG 2016):
* Fix typo.

Version 2.1.10 (17 AUG 2016):
* Add delete database command.

Version 2.1.9 (24 JUL 2016):
* Fix UI potential deadlock during AAD token acquisition.

Version 2.1.8 (20 JUL 2016):
* Upgrade ADAL's version from 2.14.2011511115 to 3.12.0

Version 2.1.7 (19 JUL 2016):
* Supporting dSTS-based authentication for Microsoft internal principals. More details can be found at https://kusto.azurewebsites.net/docs/concepts/concepts_security_authn_dsts.html.