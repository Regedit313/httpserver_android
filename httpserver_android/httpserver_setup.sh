
#!/data/data/com.termux/files/usr/bin/bash

clear

cd "$(dirname "$0")" || exit 1

APP_DIR="$(pwd -P)"
HTTP_DIR="/storage/emulated/0/FTPshare"

echo
echo "httpserver_android Setup / Update"
echo

echo "Updating Termux..."
echo

if ! pkg update -y; then
    echo
    echo "Error: Termux update failed."
    echo "Please check your internet connection and try again."
    echo
    read -p "Press Enter to continue..."
    exit 1
fi

if ! pkg upgrade -y; then
    echo
    echo "Error: Termux upgrade failed."
    echo "Please check your internet connection and try again."
    echo
    read -p "Press Enter to continue..."
    exit 1
fi

if [ ! -d ~/storage/shared ]; then
    echo
    echo "Setting up storage..."
    echo "If Android asks for permission, please allow it."
    echo

    if command -v termux-setup-storage >/dev/null 2>&1; then
        termux-setup-storage
    else
        echo
        echo "Warning: termux-setup-storage command was not found."
        echo "Storage access may not be configured correctly."
    fi
else
    echo
    echo "Storage is already configured."
fi

echo
echo "Creating/checking shared HTTP folder..."

if ! mkdir -p "$HTTP_DIR"; then
    echo
    echo "Error: cannot create FTPshare:"
    echo "$HTTP_DIR"
    echo "Please grant Termux storage access and run setup again."
    echo
    read -p "Press Enter to continue..."
    exit 1
fi

echo "Shared folder: $HTTP_DIR"
echo

echo "Installing Python..."

if ! pkg install -y python; then
    echo
    echo "Error: Python installation failed."
    echo
    read -p "Press Enter to continue..."
    exit 1
fi

hash -r

echo
echo "Installing/updating uploadserver..."

if ! python -m pip install -U uploadserver; then
    echo
    echo "Error: uploadserver installation failed."
    echo
    read -p "Press Enter to continue..."
    exit 1
fi

echo
echo "Checking uploadserver..."

if ! python -c 'import uploadserver'; then
    echo
    echo "Error: uploadserver is not available."
    echo
    read -p "Press Enter to continue..."
    exit 1
fi

echo "uploadserver is available."
echo

echo "Setting script permissions..."

chmod +x "$APP_DIR/httpserver.sh" 2>/dev/null
chmod +x "$APP_DIR/httpserver_setup.sh" 2>/dev/null
chmod +x "$APP_DIR/httpserver_termuxshortcut.sh" 2>/dev/null

echo
echo "Checking project files..."

missing=0

if [ ! -f "$APP_DIR/httpserver.sh" ]; then
    echo "- Missing: httpserver.sh"
    missing=1
fi

if [ ! -f "$APP_DIR/httpserver_setup.sh" ]; then
    echo "- Missing: httpserver_setup.sh"
    missing=1
fi

if [ ! -f "$APP_DIR/httpserver_termuxshortcut.sh" ]; then
    echo "- Missing: httpserver_termuxshortcut.sh"
    missing=1
fi

if [ ! -d "$HTTP_DIR" ]; then
    echo "- Missing: FTPshare"
    missing=1
fi

if [ "$missing" -ne 0 ]; then
    echo
    echo "Warning: one or more project files/folders are missing."
    echo
fi

echo
echo "Installation completed."
echo
echo "Shared HTTP folder:"
echo "$HTTP_DIR"
echo
echo "Start the server by launching:"
echo "$APP_DIR/httpserver.sh"
echo
echo "The server runs on port 8000."
echo "Files: http://<ANDROID_IP>:8000/"
echo "Upload: http://<ANDROID_IP>:8000/upload"
echo "Press CTRL+C to stop it."
echo
read -p "Press Enter to continue..."
