<#
    NOTES
    ===========================================================================
    Created with:  Visual Studio Code
    Created on:    $(date)
    Created by:    Calvin Kohler-Katz
    Organization:  
    Filename:      get-lunchmenu.ps1
    ===========================================================================
    DESCRIPTION
        Get today's lunch menu and email.
        Aramark vendor site: http://www.aramarkcafe.com/layouts/canary_2010/locationhome.aspx?locationid=<location_id>
        Change Location ID to match your site.
#>

$location_id = "4044"
$smtp_server = 'smtp.domain.com'
$send_from = 'lunch@domain.com'

$recipients = @(
    'user@domain.com'
)
$mainurl = "http://www.aramarkcafe.com/layouts/canary_2010/locationhome.aspx?locationid=$location_id"

$dayid = 0
switch ((Get-Date).DayOfWeek) {
    'Friday' { $dayid = 6 }
    'Thursday' { $dayid = 5 }
    'Wednesday' { $dayid = 4 }
    'Tuesday' { $dayid = 3 }
    'Monday' { $dayid = 2 }
}

$webreq = Invoke-WebRequest $mainurl
$sidebar = $webreq.ParsedHtml.getElementById("sideBar_pnlWeeklyMenu")
if ($sidebar.innerHTML -match 'menuid=\d{5}') {
    $menuid = $Matches[0]
    $menuid = ($menuid -split "=")[1]

    $menuurl = "http://www.aramarkcafe.com/layouts/canary_2010/locationhome.aspx?locationid=$location_id&pageid=20&menuid=$menuid&dayid=$dayid"
    $webreq = Invoke-WebRequest $menuurl
    $html = $webreq.ParsedHtml.getElementById("content")
    $html = $html.getElementsByClassName("post-menu")
    $text = $html::innerText
    $text = $text -replace "Print Weekly Menu", ""
    $text = $text -replace "cal\s", "cal`r`n"
    $text = $text -replace "`r`nSoup", "`r`n`r`nSoup"
    $text = $text -replace "LTO:", "`r`nLTO:"
    $text = $text -replace "`r`nSalad", "`r`n`r`nSalad"
    $test = $test -replace "`r`nDesserts", "`r`n`r`nDesserts"

    Send-MailMessage -SmtpServer $smtp_server -Body $text -From $send_from -To $recipients -Subject ("Lunch Menu for " + (Get-Date).DayOfWeek) -Encoding Unicode
}
