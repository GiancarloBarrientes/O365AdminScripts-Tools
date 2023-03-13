#Importation of Module you will need a cloud admin account with Exchange admin
Import-Module Msonline
#Location of Functions that run the script
C:\PathTo\CloudExchange\ExchangeTermProcess\Functions\termFunct.ps1
#Connect to Exchange use cadm account with exchang privledge on with cloud admin account
Connect-ExchangeOnline
Connect-MsolService

$script:csvFile = import-csv "C:PathTo\CloudExchange\ExchangeTermProcess\Main\Data\TermData.csv"
#Functions for the Termination Process
AutoConvert2SharedInbox($csvFile)
AutoRemoveM365License($csvFile)
AutoOOOwCSV($csvFile)
AutoDelegateManager($csvFile)
