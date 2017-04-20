Function Get-CertExpire {
 
    <#
    .SYNOPSIS
    This cmdlet notifies users when a certificate is going to expire.
    .DESCRIPTION
    This cmdlet checks for certificate expiring within x date and sends an email to end user(s) in question.  The cmdlet also automates creating a hashed password which can only be unhashed by the current logged in user on that specific computer.
    .PARAMETER
    .EXAMPLE
    Get-CertExpire -notificationDays 4000 -emailUserName username -emailFromAddress sender@example.com -emailToAddress receipent@example.com -emailSubject "I'm a subject" -emailBody "I'm a body." -smtpServer smtp.server.provider -smtpPort [25, 465, 567]
    .NOTES
    .LINK
    .COMPONENT
    #>
     
    Param(
        [int]$notificationDays,
        [string]$emailUserName,
        [string]$emailFromAddress,
        [string[]]$emailToAddress,
        [string]$emailSubject,
        [string]$emailBody,
        [string]$smtpServer,
        [int]$smtpPort
    )
    Begin {
        $file = "$env:USERPROFILE\Desktop\Password.txt"
        if ((Get-ChildItem $file -ErrorAction SilentlyContinue) -eq $null)
            {
            $credential = Get-Credential
            $credential.Password | ConvertFrom-SecureString | Out-File $file
            }
    }
    Process{
        #Results Array
        $rpt = @()
  
        #Define Certificate Locations to Search
        $locations = @("Cert:\CurrentUser\My", "Cert:\LocalMachine\My")
  
        #Start Location Logic Loop
        foreach ($location in $locations)
            {
            CD $location  #Change directory to location
            $certificates = (Get-ChildItem -recurse)  #Gather All Certificates in Certficate Store
            foreach ($cert in $certificates)  #Loop through each certificate in certificate store.
                {
                    $now = (Get-Date)  #Get Current Date
                    $daysTilExpire = (New-TimeSpan -Start $now -End $cert.NotAfter).Days  #Find Out Dates til the Certificate is expired.
              
                    #Logic Section.  Looks to see if today's date is after the FROM date and before the TO date on the certificate, and checks if the certificate expires within 2000 days
                    if (
                        ($now -gt $cert.NotBefore) `
                         -and ($now -lt $cert.NotAfter) `
                         -and ($daysTilExpire.Days -lt $notificationDays)
                       )
                        #This section creates an object with multiple properties for the certificate currently being processed.  This then gets added to the results array.
                        {
                        $row = '' | Select-Object -Property 'hostname', 'subject', 'thumbprint', 'path', 'expirationDate', 'daysTilExpire'
                        $row.'hostname' = $env:COMPUTERNAME
                        $row.'subject' = $cert.Subject
                        $row.'thumbprint' = $cert.Thumbprint
                        $row.'path' = $location
                        $row.'expirationDate' = $cert.NotAfter
                        $row.'daysTilExpire' = $daysTilExpire
                        $rpt += $row
                        }
                 }
             }
       
        #Export Data to CSV
        $rpt | Export-CSV -Path "$env:USERPROFILE\Desktop\ExpiringCerts.csv" -Delimiter "|"  -NoTypeInformation
        $attachment = "$env:USERPROFILE\Desktop\ExpiringCerts.csv"
        $emailCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, (Get-Content $file | ConvertTo-SecureString)
  
        #Actually send the message with the Variables Listed
        if ($smtpPort -eq 25)
        {Send-MailMessage -From $emailFromAddress -To $emailToAddress -Subject $emailSubject -Body $emailBody -SmtpServer $smtpServer -Port $smtpPort -Credential $emailCreds -Attachments $attachment}
        else {Send-MailMessage -From $emailFromAddress -To $emailToAddress -Subject $emailSubject -Body $emailBody -SmtpServer $smtpServer -Port $smtpPort -Credential $emailCreds -Attachments $attachment -UseSsl}
    }
    End {
        Remove-Item $attachment
    }
}

Get-Help Get-CertExpire -Examples
update-help
Get-CertExpire -notificationDays 4000 -emailUserName zneuman -emailFromAddress zneuman@api-wi.com -emailToAddress zachary.neuman@ge.com -emailSubject "zomg certs" -emailBody "zomg more certs" -smtpServer mochila.api-wi.com -smtpPort 25