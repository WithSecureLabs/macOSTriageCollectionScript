#!/bin/bash

###   ###   Section 1  ###    ###
# Global variables
section_1()
{
    ##Check if script is running as root
    if [[ $EUID -ne 0 ]]; then
        echo "[-] This script must be run as root"
        exit 1
    else
        #Check if full disk access was granted for terminal
        echo -n "[+] "
        system_profiler SPSoftwareDataType | grep "System Version"| sed -e 's/^[[:space:]]*//'
        echo "[?] Have you have enabled 'Full Disk Access' for Terminal in System Preferences/Security & Privacy on this host?"
        read -p "[?] Y/N? " -n 1 -r
        # Ask if the user enaled full disk access
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            ##Set Root directory
            RUN_DIR=$(pwd -P)
            HOSTNAME=$(hostname|md5)
            BASE="$(pwd -P)/$HOSTNAME$(date -u +"_%F_%H%M%S")/"

            ##Create temp root directory for collection
            echo 
            echo "[+] Creating temporary Collection Directory at $BASE and starting collection."
            mkdir -p $BASE
            cd $BASE

            echo
            echo "[!] NO FURTHER INTERACTION IS REQUIRED UNTIL COMPLETION."
            echo
        else
            echo
            echo "[-] Please enable full disk access to terminal for the duration of collection."
            exit 1
        fi
    fi
}

###   ###   END SECTION 1  ###    ###
########################################################################################################
###   ###   Section 2  ###    ###
section_2()
{
    ##Run sysdiagnose to collect system information
    # -f OUTPUT DIR
    # -n Do not tar result (not point spending time compressing twice)
    # -b Do not show resulting archive in finder
    # 
    sysdiagnose -f "$BASE" -nbSu 
}

###   ###   END SECTION 2  ###    ###
########################################################################################################
###   ###   Section 3  ###    ###

macos_file_listing()
{
    OUTPUT="$1"
    FILE_PATH="${*:2}"
    # echo $1
    # Insert the stat part
    stat -t "%F %T %z" -f '%i, %Sp, %l, %Sg, %Su, %z, %Sm, %Sa, %Sc, %SB, "%N"' "$FILE_PATH" | tr "\n" ", " >> "$OUTPUT";
    #  Insert the hash
    shasum -a 1 "$FILE_PATH" | awk -F " " ' {printf "\""$1"\","}' >> "$OUTPUT"; 
    file "$FILE_PATH" | awk -F ": " ' {print "\""$NF"\""}' >> "$OUTPUT"; 
}

echo_header()
{
    # Removes any prexisting file
    echo "Inode, Permissions, HardLinks, GroupName, UserName, Size(Bytes), LastModified, LastAccess, Changed, Birth, Path, Hash, Type" > "$1";
}

section_3()
{
    mkdir -p "$BASE/FileListings/"
    # Do the mass MFS style file - excluding external and mounted drives, this will take some time
    echo "[+] Note: This will take some time, be sure to check errors"
    export -f macos_file_listing
    export -f echo_header

    # Path listings
    # Users minus Music, Movies, Pictures, and iCloud
    echo_header "$BASE/FileListings/Users.csv"
    find -x /Users -path /Users/*/Library/Mobile\ Documents -prune -o -path /Users/*/Pictures -prune -o -path /Users/*/Music -prune -o -path /Users/*/Movies -prune -o -type f -exec bash -c 'macos_file_listing "$0" ${*:1}' "$BASE/FileListings/Users.csv" {} \; 
    # Library
    echo_header "$BASE/FileListings/Library.csv"
    find -x /Library -type f -exec bash -c 'macos_file_listing "$0" ${*:1}' "$BASE/FileListings/Library.csv" {} \; 
    # Applications
    echo_header "$BASE/FileListings/Applications.csv"
    find -x /Applications -type f -exec bash -c 'macos_file_listing "$0" ${*:1}' "$BASE/FileListings/Applications.csv" {} \; 
    # Private
    echo_header "$BASE/FileListings/Private.csv"
    find -x /private -type f -exec bash -c 'macos_file_listing "$0" ${*:1}' "$BASE/FileListings/Private.csv" {} \; 

    # Extension listings
    # JavaScript
    echo_header "$BASE/FileListings/JavaScript.csv"
    find -x / -path /System -prune -o -name "*.js" -type f -exec bash -c 'macos_file_listing "$0" ${*:1}' "$BASE/FileListings/JavaScript.csv" {} \; 
    # Python
    echo_header "$BASE/FileListings/Python.csv"
    find -x / -path /System -prune -o -name "*.py" -type f -exec bash -c 'macos_file_listing "$0" ${*:1}' "$BASE/FileListings/Python.csv" {} \; 
    # Ruby
    echo_header "$BASE/FileListings/Ruby.csv"
    find -x / -path /System -prune -o -name "*.rb" -type f -exec bash -c 'macos_file_listing "$0" ${*:1}' "$BASE/FileListings/Ruby.csv" {} \; 
    # Dylib
    echo_header "$BASE/FileListings/Dylib.csv"
    find -x / -path /System -prune -o -name "*.dylib" -type f -exec bash -c 'macos_file_listing "$0" ${*:1}' "$BASE/FileListings/Dylib.csv" {} \; 
}

###   ###   END SECTION 3  ###    ###
########################################################################################################
###   ###   Section 4   ###    ###
section_4()
{
    ##Get browser data - TODO Verify locations
    #src: https://www.dataforensics.org/mac-os-x-forensics-analysis/
    ##Get Safari Data
    mkdir -p "$BASE/BrowserData/Safari/"
    ##Safari File paths
    #TODO verify paths
    rsync -Raq /Users/*/Library/Safari/* "$BASE/BrowserData/Safari/."
    rsync -Raq /Users/*/Library/Caches/com.apple.Safari.SafeBrowsing/* "$BASE/BrowserData/Safari/."
    rsync -Raq /Users/*/Library/Cookies/Cookies.plist "$BASE/BrowserData/Safari/."
    rsync -Raq /Users/*/Library/Preferences/com.apple.Safari.plist "$BASE/BrowserData/Safari/."
    rsync -Raq /Users/*/Library/Saved\ Application\ State/com.apple.Safari.savedState/* "$BASE/BrowserData/Safari/."


    ##Get Chrome Data
    mkdir -p "$BASE/BrowserData/Chrome/"
    ##TODO get paths for history cookies plists etc
    rsync -Raq /Users/*/Library/Application\ Support/Google/Chrome/Default/* "$BASE/BrowserData/Chrome/."


    ##Get Firefox Data
    mkdir -p "$BASE/BrowserData/Firefox/"
    #TODO verify paths

    rsync -Raq /Users/*/Library/Application\ Support/Firefox/Profiles/*/Cookies.sqlite "$BASE/BrowserData/Firefox/."
    rsync -Raq /Users/*/Library/Application\ Support/Firefox/Profiles/*/Downloads.sqlite "$BASE/BrowserData/Firefox/."
    rsync -Raq /Users/*/Library/Application\ Support/Firefox/Profiles/*/Formhistory.sqlite "$BASE/BrowserData/Firefox/."
    rsync -Raq /Users/*/Library/Application\ Support/Firefox/Profiles/*/Places.sqlite "$BASE/BrowserData/Firefox/."

    # Add support for additional browsers in future
}
###   ###   END SECTION 4  ###    ###
########################################################################################################
section_5()
{
    ##Bash and ZSH History
    mkdir -p "$BASE/BashData/"

    # Also resolve links here
    rsync -RLaq /Users/*/.bash* "$BASE/BashData/."
    rsync -RLaq /Users/*/.zsh* "$BASE/BashData/."

    rsync -RLaq /var/root/.bash* "$BASE/BashData/."
    rsync -RLaq /var/root/.zsh* "$BASE/BashData/."
}
########################################################################################################
###   ###   Section 6   ###    ###


section_6()
{
    ##Get Fsevents in non external volumes
    mkdir "$BASE/FSEvents"
    mkdir "$BASE/FSEvents/"

    cp -a /.fseventsd/* "$BASE/FSEvents/"
}
###   ###   END SECTION 6   ###    ###
########################################################################################################
###   ###   Section 7   ###    ###
section_7()
{
    # Find on exteneded attriute
    ##Get Fsevents in non external volumes
    mkdir -p "$BASE/ExtendedAttributes"

    sql_create="CREATE TABLE attributes (filename TEXT, path TEXT, attribute TEXT, type TEXT, value BLOB);"

    echo $sql_create | sqlite3 -batch "$BASE/ExtendedAttributes/attributes.db"

    attributes=(
        "kMDItemDownloadedDate"
        "kMDItemWhereFroms"
    )
    for attribute in ${attributes[@]};
    do 
        mdfind "$attribute == *" -0 |
        while IFS= read -r -d '' path; do
            xattr "$path" |
            while IFS= read -r attriute_from_file; do
                # echo $attriute_from_file
                value=$(xattr -p "$attriute_from_file" "$path" | xxd -r -p)
                value_hex=$(echo $value | hexdump -ve '1/1 "%0.2X"')
                file_type=$(echo $value | file - | awk -F ": " '{print $NF}')
                
                echo "insert into attributes values(\"$(basename \"$path\")\",\"$path\",\"$attriute_from_file\",\"$file_type\",'$value_hex')" | sqlite3 "$BASE/ExtendedAttributes/attributes.db"
            done
        done
    done
}
###   ###   END SECTION 7   ###    ###
########################################################################################################
###   ###   Section 8   ###    ###
section_8()
{
    # LaunchAgents
    mkdir -p "$BASE/PersistenceMechanisms/LaunchAgents/"
    rsync -RLaq /Users/*/Library/LaunchAgents/* "$BASE/PersistenceMechanisms/LaunchAgents/."
    rsync -RLaq /Library/LaunchAgents/* "$BASE/PersistenceMechanisms/LaunchAgents/."
    rsync -RLaq /System/Library/LaunchAgents/* "$BASE/PersistenceMechanisms/LaunchAgents/."
    # Launch Daemons
    mkdir -p "$BASE/PersistenceMechanisms/LaunchDaemons/"
    rsync -RLaq /Library/LaunchDaemons/* "$BASE/PersistenceMechanisms/LaunchDaemons/."
    rsync -RLaq /System/Library/LaunchDaemons/* "$BASE/PersistenceMechanisms/LaunchDaemons/."
    # LoginItems
    mkdir -p "$BASE/PersistenceMechanisms/LoginItems/"
    rsync -RLaq /Users/*/Library/Application\ Support/com.apple.backgroundtaskmanagementagent/backgrounditems.btm "$BASE/PersistenceMechanisms/LoginItems/."
    # Profiles
    mkdir -p "$BASE/PersistenceMechanisms/ManagedProfiles/"
    rsync -RLaq /Library/Managed\ Profiles/*/*.plist "$BASE/PersistenceMechanisms/ManagedProfiles/."
    # Cron tabs
    mkdir -p "$BASE/PersistenceMechanisms/CronTabs/"
    rsync -RLaq /private/var/at/tabs/* "$BASE/PersistenceMechanisms/CronTabs/."
    # Emond rules
    mkdir -p "$BASE/PersistenceMechanisms/Emond/"
    rsync -RLaq /private/etc/emond.d/rules/* "$BASE/PersistenceMechanisms/Emond/."
    # Folder Actions
    mkdir -p "$BASE/PersistenceMechanisms/FolderActions/"
    rsync -RLaq /Users/*/Library/Application\ Support/com.apple.FolderActionsDispatcher.plist "$BASE/PersistenceMechanisms/FolderActions/."
    # LoginHook
    mkdir -p "$BASE/PersistenceMechanisms/LoginHook/"
    rsync -RLaq /Library/Preferences/com.apple.loginwindow.plist "$BASE/PersistenceMechanisms/LoginHook/."
    rsync -RLaq /Users/*/Library/Preferences/com.apple.loginwindow.plist "$BASE/PersistenceMechanisms/LoginHook/."
    rsync -RLaq /private/var/root/Library/Preferences/com.apple.loginwindow.plist "$BASE/PersistenceMechanisms/LoginHook/."
    
}
###   ###   END SECTION 8   ###    ###
########################################################################################################
###   ###   Section 9   ###    ###
section_9()
{
    mkdir -p "$BASE/LiveData/"
    lsof -i > "$BASE/LiveData/lsof-i"
    lsof > "$BASE/LiveData/lsof"
}
###   ###   END SECTION 9   ###    ###
########################################################################################################

###   ###   Start  ###    ###

#MAIN
echo "[!] Run -h to see options."
# Check ops
quick_mode=false
while getopts ":qh" opt; do    
    case ${opt} in
        q ) #Quick flag (not file listings)
            echo "[!] Running in quick mode, no file listings will be made."
            quick_mode=true
            ;;
        h ) #Echo help
            echo "[!] Help: Run with -q flag to skip file listings (quick mode)"
            exit 1
            ;;

        \? ) #Echo help
            echo "[!] Invalid option"
            exit 1
            ;;
    esac
done


# Keep system up
echo "[!] Starting 'caffeinate' to prevent system and disk idle sleeping."
caffeinate -im -w "$$" &

echo "[+] Starting 'section_1' (init)."
section_1

echo "[+] Starting 'section_2' (sysdiagnose)."
section_2

if [[ $quick_mode = false ]] 
then
    echo "[+] Starting 'section_3' (file listings)."
    section_3 2> "FileListings.errors"
else 
    echo "[-] Skipping 'section_3' (file listings)."
fi

echo "[+] Starting 'section_4' (browser data)"
section_4 2> "BrowserData.errors"

echo "[+] Starting 'section_5' (bash data)" 
section_5 2> "BashData.errors"

echo "[+] Starting 'section_6' (fsevents)" 
section_6 2> "FSEvents.errors"

echo "[+] Starting 'section_7' (extended attributes)" 
section_7 2> "ExtendedAttributes.errors"

echo "[+] Starting 'section_8' (persistence mechanisms)" 
section_8 2> "PersistenceMechanisms.errors"

echo "[+] Starting 'section_9' (live data)" 
section_9 2> "LiveData.errors"

###   ###   Zipping   ###   ###
echo "[+] Compressing collection."
tar -zcf "$RUN_DIR/$HOSTNAME.tar.gz" -C "$BASE" *
open "$RUN_DIR"
###   ###   END  ###    ###
echo "[!] Collection completed please ensure you do not leave collected files in unsecure locations and delete after use"
echo "[!] Please also ensure you disable 'Full Disk Access' for Terminal in System Preferences/Security & Privacy."
exit 0
###   ###   END  ###    ###