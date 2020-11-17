# macOSTriageCollectionScript
A triage data collection script for macOS that utilises sysdiagnose with a few additions to gather useful triage data for investigations. 

## What does the script collect?
Data collected includes:
* _sysdiagnose_, a utility on a vareity of macOS/iOS operating systems that collects 'system-wide diagnostic information'. Mostly used here for the log files and live data it collects.
* File listings, since APFS does not have a master file table like NTFS to get an idea of what exists on the file system we create several CSV files using a comination of _stat_, _shasum_, and _file_. The data collected can be used in conjunciton with threat intelligece feeds to identify malicious files by their file hash or to identify anomalous files. This is quite an intensive process so the script has a flag to run in a quick mode were this step is excluded.
* Browser data from Safari, Chome, and Firefox is gathered for the purpose of ruling out malicious downloads, phishing attacks, or to identify any suspicious browser extensions. 
* Bash/Zsh history is collected to determine what is usual activity, identify any anomalies or hands on keyboard activity.
* FSEvents, these are a volatile log source not to disimilar to the USN journal on a windows machine. Although rolled into the 'system_logs.logarchive' collected by _sysdiagnose_ they can be used to get a view on recent activity on the file system that might not yet be logged in the 'system_logs.logarchive'.
* Extended attribute collection utilises _xattr_ and _mdfind_ to locate and parse attributes to be saved in an Sqlite3 database. A file type for the attribute is determined and the data saved in hex, by deafult the only attributes collected are "kMDItemDownloadedDate" and "kMDItemWhereFroms" however adding additional attributes can be done by appending the _attributes_ array in the section_7 function.
* Several persistence mechanisms are also collected including LaunchAgents, LaunchDaemons, LoginItems, and Emond rules.
* Lastly some live data from _lsof_ is to identify any anomalous files, processes, or network connections. 

## Usage 
The script must be run as sudo to allow collection via sysdiagnose and a variety of file system locations, the script can only be run as sudo.
Terminal by deafult does not have access to a variety of locations it will need so you will need to enable 'full disk access' for Terminal. This can be done in system preferences under Security & Privacy > Privacy -> Full Disk Access, to confirm changes click the lock in the bottom left of the window and restart your Terminal session.
Should an error occur it will be saved to one of the *.errors files corresponding to a section of the collection.
Collected data is saved to a directory following this pattern *'md5 of hostname'\_YYYY-MM-DD\_HHMMSS/* in the current working directory. When collection has finished the data is compressed into a tar.gz named after the md5 of the hostname, the transformation of the hostname is to prevent any issues around special characters.

### Script flags:
'''
Quick mode: -q
    Include this flag when running the script to skip creating file listings.
Help: -h
    Print a short help message
'''

## Disclaimers
This script does not remove the data it collects after being compressed, this contains sensetive information ensure you securely delete after use.
The script, for ease of use, requires enabling full disk access to Terminal, It is reccomended to disable this access after collection.
Lastly the data collected should not be considered forensically sound.

_Tested on macOS 10.15_