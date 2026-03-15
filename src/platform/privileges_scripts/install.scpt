on run {daemon_file, agent_file, user}

  set sh1 to "echo " & quoted form of daemon_file & " > /Library/LaunchDaemons/site.sealoshzh.DeskLink_service.plist && chown root:wheel /Library/LaunchDaemons/site.sealoshzh.DeskLink_service.plist;"

  set sh2 to "echo " & quoted form of agent_file & " > /Library/LaunchAgents/site.sealoshzh.DeskLink_server.plist && chown root:wheel /Library/LaunchAgents/site.sealoshzh.DeskLink_server.plist;"

  set sh3 to "cp -rf /Users/" & user & "/Library/Preferences/site.sealoshzh.desklink/DeskLink.toml /var/root/Library/Preferences/site.sealoshzh.desklink/;"

  set sh4 to "cp -rf /Users/" & user & "/Library/Preferences/site.sealoshzh.desklink/DeskLink2.toml /var/root/Library/Preferences/site.sealoshzh.desklink/;"

  set sh5 to "launchctl load -w /Library/LaunchDaemons/site.sealoshzh.DeskLink_service.plist;"

  set sh to sh1 & sh2 & sh3 & sh4 & sh5

  do shell script sh with prompt "DeskLink wants to install daemon and agent" with administrator privileges
end run
