#!/bin/bash

# Define paths
INSTALL_DIR="/home/steam/windrose"
APP_ID="4129620"

echo "=== Updating Windrose Dedicated Server ==="
/home/steam/steamcmd/steamcmd.sh +force_install_dir $INSTALL_DIR +login anonymous +@sSteamCmdForcePlatformType windows +app_update $APP_ID validate +quit

echo "=== Applying Steam DLL Fix ==="
mkdir -p $INSTALL_DIR/R5/Binaries/Win64/
cp /home/steam/steamcmd/steamclient64.dll $INSTALL_DIR/R5/Binaries/Win64/ 2>/dev/null || true

echo "=== Cleaning Up Ghost LOCK Files ==="
find $INSTALL_DIR/R5/Saved -name "LOCK" -delete 2>/dev/null || true

echo "=== Starting Virtual Display ==="
# Clean up old lock files from previous crashes
rm -f /tmp/.X99-lock

Xvfb :99 -screen 0 640x480x24:32 &
# Give the virtual monitor a second to initialize
sleep 2

echo "=== Launching Server ==="
cd $INSTALL_DIR

# 1. OVERRIDE: Turn Wine error logging back on so we can see what it's thinking
export WINEDEBUG=err+all

# 2. Add bash verbosity just for the execution step
set -x

# 3. Run the server
wine cmd /c StartServerForeground.bat

# 4. THE TRAP: Turn bash verbosity off
set +x

echo "================================================================"
echo " The batch file finished executing, but the container is alive! "
echo "================================================================"

# 5. Tail the Unreal Engine logs directly to your terminal.
# The -F flag forces tail to keep looking even if the file is created a few seconds late.
# We include /dev/null so tail never exits, keeping the container permanently awake!
tail -F $INSTALL_DIR/R5/Saved/Logs/*.log /dev/null
