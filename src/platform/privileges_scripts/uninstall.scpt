set sh1 to "launchctl unload -w /Library/LaunchDaemons/site.sealoshzh.DeskLink_service.plist;"
set sh2 to "/bin/rm /Library/LaunchDaemons/site.sealoshzh.DeskLink_service.plist;"
set sh3 to "/bin/rm /Library/LaunchAgents/site.sealoshzh.DeskLink_server.plist;"

set sh to sh1 & sh2 & sh3
do shell script sh with prompt "DeskLink wants to unload daemon" with administrator privileges
