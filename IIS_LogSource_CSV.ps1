$MsgSourceTypeID = (Invoke-Sqlcmd -ServerInstance 'localhost' -Database LogRhythmEMDB -Query "SELECT MsgSourceTypeID FROM MsgSourceType WHERE Name = 'Flat File - Microsoft IIS W3C File'").MsgSourceTypeID
$MsgSourceDateFormatID = (Invoke-Sqlcmd -ServerInstance 'localhost' -Database LogRhythmEMDB -Query "SELECT MsgSourceDateFormatID FROM MsgSourceDateFormat WHERE Name = 'Microsoft IIS W3C File'").MsgSourceDateFormatID

$servers = Import-Csv -Path 'C:\LogRhythm\IIS.csv'
"Count: $($servers.Count)"


Foreach($server in $servers){
    #$server = $servers[0]
    if ($server.Site -eq 'Default Web Site'){
        $msgSourceName = "$($server.Name) MS IIS W3C Log"
    }
    else{
        $msgSourceName = "$($server.Name) $($server.Site) IIS W3C Log"
    }
    $HostID = (Invoke-Sqlcmd -ServerInstance 'localhost' -Database LogRhythmEMDB -Query "SELECT HostID FROM Host WHERE Name = '$($server.Name)'" ).HostID
    $Query = "
    DECLARE	@return_value int,
		@MsgSourceID int
    EXEC	@return_value = LogRhythm_EMDB_MsgSource_Insert
		@SystemMonitorID = 2,
		@HostID = $($HostID),
		@MsgSourceTypeID = 84,
		@Name = N'$($msgSourceName)',
		@ShortDesc = '',
		@LongDesc = '',
		@MsgSourceDateFormatID = 4,
		@CollectionDepth = -1,
		@MsgsPerCycle = 100,
		@FilePath = N'$($server.Share)',
		@MonitorStart = '',
		@MonitorStop = '',
		@DefMsgTTL = 0,
		@DefMsgArchiveMode = 1,
		@MPEMode = 1,
		@MPEPolicyID = -84,
		@IsVirtual = 0,
		@RecordStatus = 1,
		@LogMartMode = 13627388,
		@UDLAConnectionString = '',
		@UDLAStateField = '',
		@UDLAStateFieldType = 0,
		@UDLAStateFieldConversion = '',
		@UDLAQueryStatement = '',
		@UDLAOutputFormat = '',
		@UDLAUniqueIdentifier = '',
		@UDLAMsgDateField = '',
		@UDLAGetUTCDateStatement = '',
		@PersistentConnection = 0,
		@MaxLogDate = '1900-01-01 00:00:00.000',
		@Status = 1,
		@MsgRegexStart = N'^\d{4}-\d{2}-\d{2}',
		@MsgRegexDelimeter = '',
		@MsgRegexEnd = '',
		@RecursionDepth = 0,
		@IsDirectory = 1,
		@Inclusions = N'*.log',
		@Exclusions = '',
		@Parameter1 = 0,
		@Parameter2 = 0,
		@Parameter3 = 0,
		@Parameter4 = 0,
		@StatePosition = NULL,
		@StateLastUpdated = 0,
		@CompressionType = 0,
		@UDLAConnectionType = 0,
		@CollectionThreadTimeout = 120,
        @MsgSourceID = @MsgSourceID OUTPUT
        SELECT	@MsgSourceID as N'@MsgSourceID', @return_value as N'@return_value'"
    Invoke-Sqlcmd -ServerInstance 'localhost' -Database LogRhythmEMDB -Query $Query
}


