# uwe-sieber

[![Tests](https://github.com/seanmamasde/uwe-sieber/actions/workflows/ci.yml/badge.svg)](https://github.com/seanmamasde/uwe-sieber/actions/workflows/ci.yml) [![Sync](https://github.com/seanmamasde/uwe-sieber/actions/workflows/sync.yml/badge.svg)](https://github.com/seanmamasde/uwe-sieber/actions/workflows/sync.yml)

A [Scoop](https://scoop.sh) bucket for the Windows utilities by **[Uwe Sieber](https://www.uwe-sieber.de)**: USBDLM, USB Device Tree Viewer,
DriveCleanup, RemoveDrive and a long tail of device and storage tools.
Everything downloads from the author's own server.

```powershell
scoop bucket add uwe-sieber https://github.com/seanmamasde/uwe-sieber
scoop install uwe-sieber/usb-tree-view
```

## Licensing

The MIT licence here covers only the manifests and tooling, not the packaged
software. Most tools are freeware; the author allows commercial use but not
modification or redistribution through downloader wrappers.

**`com-port-man` and `usbdlm` are not freeware, and not free for private use.**
Free only for non-profit education and free public libraries; everyone else gets
30 days, then one licence per computer. Full terms ship inside each archive.

## Versions

Versions come from the executable's own `FileVersion`, not the product page,
which is often stale and disagrees with the shipped binary. Two tools carry no
version resource and fall back to the page version tagged `+web.N`.

One-off: `msg-box-man` reports `0.09.0073` where the page claimed `1.0`, so the
correct version is lower than what was published. Run
`scoop update msg-box-man --force` once.

## Maintenance

`bin\sync.ps1` is the only updater. Upstream serves every tool from a stable
filename, so it tracks ETag, Last-Modified and SHA-256 in `cache/downloads.csv`;
an unchanged download costs one HEAD. Manifests carry no `checkver` or
`autoupdate`; per-app exceptions live in `config/sync.json`. The
[Sync](.github/workflows/sync.yml) workflow runs it daily and commits if the
tests pass.

```powershell
.\bin\sync.ps1           # report only
.\bin\sync.ps1 -Apply    # write versions and hashes
.\bin\sync.ps1 -App ffc  # single manifest
.\bin\checkhashes.ps1    # verify recorded hashes
.\bin\checkurls.ps1      # verify download URLs resolve
.\bin\formatjson.ps1     # normalise manifest formatting
.\bin\test.ps1           # schema, formatting, line endings
```

`test.ps1` needs Pester (>= 5.2.0) and BuildHelpers (>= 2.0.1) and reads
`$env:SCOOP_HOME`. Run `formatjson.ps1` and `test.ps1` before a pull request.

Not packaged: DOS-era and Windows 9x material (DOSFon, UMBPCI, VESASav, Off5s,
DPMSTest, the `util.html` tools), `*_src.zip` source archives, frozen
Windows 2000/XP builds, and third-party utilities the author only mirrors.

## Apps (64)

| App | Description |
| --- | ----------- |
| `attach-vhd` | Attaches VHD, VHDX and ISO files and assigns a drive letter or mount point. |
| `autorun-settings` | Graphical editor for the Windows AutoRun and AutoPlay policy settings. |
| `bin-hex-dec` | Converter for hexadecimal, decimal and binary numbers. |
| `button-bar` | ButtonBar - configurable desktop shortcut bar inspired by the old Microsoft Office toolbar. |
| `close-window` | Closes windows matched by caption or window class. |
| `com-name-arbiter-tool` | Gives control over reserved COM port numbers. |
| `com-port-info` | Displays and manages COM ports and their device and bus properties. |
| `com-port-man` | Windows service that controls automatic COM port number assignment. |
| `compact-vhd` | Shrinks VHD files from the command line. |
| `console-black-fill` | Paints the area around a console window black. |
| `console-no-close` | Deactivates the close button of one or all console windows. |
| `create-file-tester` | Tests the Windows API call CreateFile with different flags. |
| `delete-dos-device` | Removes stale drive letter and other DOS device mappings. |
| `device-cleanup` | Bulk-removes non-present devices from the Windows device management. |
| `device-cleanup-cmd` | Scriptable command-line removal of non-present devices. |
| `drive-cleanup` | Removes non-present storage devices and their orphaned registry entries. |
| `eject-media` | Ejects the media from a drive without removing the whole device. |
| `eject-tcv` | Dismounts TrueCrypt and VeraCrypt volumes from the command line. |
| `fcb` | File Compare Binary - fast binary file comparison using direct disk I/O. |
| `ffb` | Flushes the write buffers of a storage volume or file. |
| `ffc` | Fast File Copy - large file copy utility with direct I/O and verification. |
| `file-cache-test` | Tests Windows file cache behaviour with different CreateFile flags. |
| `find-exe` | Shows the full path of the executable Windows would launch. |
| `fsf` | Find Same File - finds identical files and can replace duplicates with links. |
| `hid-run` | Starts an executable with a hidden window. |
| `ioctl-decoder` | Decodes Windows DeviceIoControl IOCTL and FSCTL codes. |
| `list-bth-devs` | Lists remembered and currently connected Bluetooth devices. |
| `list-com-ports` | Command-line version of COM Port Info. |
| `list-dos-devices` | Lists DOS device names and the kernel objects they point to. |
| `list-links` | Lists reparse points, symbolic links and hard links. |
| `list-usb-devs` | Lists attached USB devices or checks for a specific one. |
| `list-usb-drives` | Command-line companion to USB Drive Info that lists USB drives. |
| `load-media` | Loads a media into a drive or brings a volume online. |
| `log-foreground-window` | Logs the windows that take the input focus. |
| `log-window-at-point` | Logs windows that appear at a given screen position. |
| `mci-browser` | Simple DirectShow and MCI based audio and video player. |
| `md5-file` | Calculates the MD5 hash of a file, for use in USBDLM AutoRun validation. |
| `md5-text` | Calculates the MD5 hash of a text, for use in USBDLM password settings. |
| `mscope` | Long-term oscilloscope and data logger for Metex compatible multimeters. |
| `msg-box-man` | Automatically answers message boxes and automates arbitrary windows. |
| `nt-cache-setter` | Limits and trims the Windows file cache working set. |
| `otax` | Online Taxometer - dial-up connection timer with traffic aware automatic disconnect. |
| `pkt-komma` | Uses Caps Lock to switch the numeric keypad between comma and period. |
| `remount` | Reassigns drive letters and NTFS mount points. |
| `remove-drive` | Command-line tool that prepares drives for safe removal. |
| `rescan-devices` | Initiates a Plug and Play scan for hardware changes. |
| `restart-sr-dev` | Restarts safely removed devices that show problem code 21 or 47. |
| `restart-usb-port` | Restarts or power-cycles a USB port. |
| `run-as-system` | Starts a process in the SYSTEM account context. |
| `set-file-size` | Sets a file to an exact requested size. |
| `set-max-cpu-power` | Sets the maximum CPU power percentage of the active power plan. |
| `set-system-file-cache-size` | Command-line tool that limits the Windows file cache working set. |
| `sleep-ms` | Console program that waits for a given number of milliseconds. |
| `test-command-line` | Shows command line, working directory, privileges and window style of a started process. |
| `usb-drive-info` | Shows volumes, physical drives, bus topology and detailed USB storage information. |
| `usb-stor-max-transfer-len` | Tests and changes the USBSTOR MaximumTransferLength setting. |
| `usb-tree-view` | USB Device Tree Viewer - shows the USB controller, hub and device tree with detailed descriptors. |
| `usb-write-cache` | Configures the write cache and removal policy of USB storage devices. |
| `usbdlm` | USB Drive Letter Manager - Windows service that controls drive letter assignment for USB drives. |
| `usbdlm-remote` | USBDLM Remote Password Tool - sends a USBDLM password to a remote client. |
| `verify-disk` | Command-line tool that calls IOCTL_DISK_VERIFY to read-test a disk. |
| `watch-fat-dirty-bit` | Watches the FAT dirty bit of a volume. |
| `win-info` | Simple window inspector that reports window text and class. |
| `xp-system-restore` | Enables or disables Windows XP System Restore per drive. |
