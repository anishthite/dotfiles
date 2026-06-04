#!/bin/bash

# Create LaunchAgent directory if it doesn't exist
mkdir -p ~/Library/LaunchAgents

# Create the LaunchAgent plist file
cat > ~/Library/LaunchAgents/com.alacritty.theme.switch.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.alacritty.theme.switch</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/anishthite/.config/alacritty/switch_theme.sh</string>
    </array>
    <key>WatchPaths</key>
    <array>
        <string>/Users/anishthite/Library/Preferences/.GlobalPreferences.plist</string>
    </array>
</dict>
</plist>
EOF

# Load the LaunchAgent
launchctl load ~/Library/LaunchAgents/com.alacritty.theme.switch.plist

echo "LaunchAgent created and loaded. Alacritty will now automatically switch themes based on system appearance."