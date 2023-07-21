$AccountLockOutEvent = Get-EventLog -LogName "Security" -InstanceID 4740 -Newest 1
$LockedAccount = $($AccountLockOutEvent.ReplacementStrings[0])
$AccountLockOutEventTime = $AccountLockOutEvent.TimeGenerated
$AccountLockOutEventMessage = $AccountLockOutEvent.Message

# Find related 4625 event within 30 minutes prior to the lockout event
$Related4625Event = Get-EventLog -LogName "Security" -InstanceID 4625 | Where-Object {
    $_.ReplacementStrings[5] -eq $LockedAccount -and
    $_.TimeGenerated -gt $AccountLockOutEventTime.AddMinutes(-30) -and
    $_.TimeGenerated -lt $AccountLockOutEventTime
} | Sort-Object TimeGenerated -Descending | Select-Object -First 1

# Source workstation from the 4625 event
$SourceWorkstation = $Related4625Event.ReplacementStrings[13]

$messageParameters = @{
    Subject = "Account Locked Out: $LockedAccount"
    Body = "Account $LockedAccount was locked out on $AccountLockOutEventTime from the workstation $SourceWorkstation.`n`nEvent Details:`n`n$AccountLockOutEventMessage"
    From = "no-reply@autotrakk.com"
    To = "zyoung@autotrakk.com","mcowden@autotrakk.com"
    SmtpServer = "mailrelay.autotrakk.com"
}
Send-MailMessage @messageParameters
