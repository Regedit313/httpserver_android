
#!/data/data/com.termux/files/usr/bin/bash

cd "$(dirname "$0")" || exit 1

APP_DIR="$(pwd -P)"
HTTP_DIR="/storage/emulated/0/FTPshare"
HFS_CWD="$HOME/.hfs_httpserver_android"
HFS_PUBLIC_CWD="$HOME/.hfs_httpserver_public"

pause_screen() {
    echo
    read -r -p "Press Enter to continue..."
}

check_installation() {
    command -v node >/dev/null 2>&1 || return 1

    command -v hfs >/dev/null 2>&1 || return 1

    return 0
}

run_setup() {
    if [ ! -f "$APP_DIR/httpserver_setup.sh" ]; then
        echo
        echo "Error: setup file is missing:"
        echo "$APP_DIR/httpserver_setup.sh"
        pause_screen
        return 1
    fi

    bash "$APP_DIR/httpserver_setup.sh"
}

check_storage() {
    if [ ! -d "$HOME/storage/shared" ]; then
        echo
        echo "Setting up Android storage..."
        echo "If Android asks for permission, please allow it."
        echo

        if command -v termux-setup-storage >/dev/null 2>&1; then
            termux-setup-storage
        else
            echo "Warning: termux-setup-storage command was not found."
        fi
    fi
}

initial_check() {
    clear

    echo
    echo "httpserver_android"
    echo
    echo "Checking installation..."

    if ! check_installation; then
        echo
        echo "Node.js or HFS 3 is missing."
        echo "Running first-time setup automatically..."
        echo

        if ! run_setup; then
            echo
            echo "Automatic setup did not complete."
            echo "You can retry with option 9 when Internet is available."
            pause_screen
        fi
    else
        echo "Installation OK."
    fi

    check_storage

    mkdir -p "$HTTP_DIR" 2>/dev/null || true
}

start_server() {
    local mode="${1:-private}"
    local server_cwd

    clear

    echo
    echo "httpserver_android"
    echo

    if ! check_installation; then
        echo "HFS 3 is not installed."
        echo "Run Setup / Update (option 9)."
        pause_screen
        return
    fi

    if ! mkdir -p "$HTTP_DIR"; then
        echo "Error: cannot create FTPshare folder."
        echo "Check Android storage permission."
        pause_screen
        return
    fi

    if [ "$mode" = "public" ]; then
        server_cwd="$HFS_PUBLIC_CWD"
    else
        server_cwd="$HFS_CWD"
    fi

    if ! mkdir -p "$server_cwd"; then
        echo "Error: cannot create HFS configuration folder."
        pause_screen
        return
    fi

    # First installation only:
    # Create a private configuration restricted to logged-in users.
    # Never overwrite an existing HFS configuration.
    if [ "$mode" = "private" ] && [ ! -e "$HFS_CWD/config.yaml" ]; then

        if ! cat > "$HFS_CWD/config.yaml" <<EOF
vfs:
  source: "$HTTP_DIR/"
  can_read: "*"
  can_list: "*"
  can_upload: "*"
  can_delete: false
EOF
        then
            echo "Error: cannot initialize HFS configuration."
            pause_screen
            return
        fi

        echo
        echo "Private configuration initialized."
        echo "Create your accounts in the HFS admin panel."
        echo
    fi

    echo "Local HTTP address:"

    LOCAL_IP="$(node -e 'const s=require("dgram").createSocket("udp4");s.on("error",()=>s.close());s.connect(80,"8.8.8.8",()=>{console.log(s.address().address);s.close()})' 2>/dev/null)"

    if [ -n "$LOCAL_IP" ]; then
        echo "Browse / Upload: http://$LOCAL_IP:8000/"
    else
        echo "IP unavailable (check local network)."
    fi

    echo "On this phone: http://127.0.0.1:8000/"
    echo
    echo "HTTP port: 8000"
    echo
    echo "Shared folder:"
    echo "$HTTP_DIR"
    echo

    if [ "$mode" = "public" ]; then

        echo "Mode: PUBLIC ACCESS"
        echo "Anonymous browsing and upload enabled."
        echo "File deletion disabled."
        echo

    else

        echo "Mode: SAVED SETTINGS"
        echo "Using saved HFS accounts and permissions."
        echo

    fi

    echo "Press CTRL+C to stop the HTTP server."
    echo

    if [ "$mode" = "public" ]; then

        # Public mode uses a separate configuration folder.
        # Apply the original public permissions at every start.
        HFS_VFS="{\"source\":\"$HTTP_DIR/\",\"can_read\":true,\"can_list\":true,\"can_upload\":true,\"can_delete\":false}"

        exec hfs --cwd "$HFS_PUBLIC_CWD" --port 8000 --listen_interface 0.0.0.0 --open_browser_at_start false --vfs "$HFS_VFS"

    else

        # Private mode loads the saved HFS configuration.
        # No --vfs argument, so saved permissions are preserved.
        exec hfs --cwd "$HFS_CWD" --port 8000 --listen_interface 0.0.0.0 --open_browser_at_start false

    fi
}

start_public_server() {
    clear

    echo
    echo "httpserver_android"
    echo
    echo "========================================"
    echo "Start HTTP server - Public access"
    echo "========================================"
    echo
    echo "WARNING!"
    echo
    echo "No login or password will be required."
    echo
    echo "Anyone who can reach the server can:"
    echo "- Browse shared files"
    echo "- Download shared files"
    echo "- Upload new files"
    echo
    echo "File deletion will remain disabled."
    echo
    echo "1) Confirm and start"
    echo
    echo "0) Cancel"
    echo

    read -r -p "Choose what to do: " confirm

    case "$confirm" in

        1)
            start_server public
            ;;

        *)
            echo
            echo "Cancelled."
            pause_screen
            ;;

    esac
}

initial_check

while true; do
    clear

    echo
    echo "httpserver_android"
    echo
    echo
    echo "1) Start HTTP server (Saved settings)"
    echo
    echo
    echo "3) Start HTTP server (Public access)"
    echo
    echo
    echo "9) Run Setup / Update (required before first use)"
    echo
    echo "0) Exit"
    echo
    echo

    read -r -p "Choose what to do: " choice

    case "$choice" in

        1)
            start_server private
            ;;

        3)
            start_public_server
            ;;

        9)
            clear
            run_setup
            ;;

        0)
            clear
            exit 0
            ;;

        *)
            echo
            echo "Invalid choice."
            sleep 1
            ;;

    esac
done

