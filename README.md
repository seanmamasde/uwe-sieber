# uwe-sieber

[![Tests](https://github.com/seanmamasde/uwe-sieber/actions/workflows/ci.yml/badge.svg)](https://github.com/seanmamasde/uwe-sieber/actions/workflows/ci.yml) [![Excavator](https://github.com/seanmamasde/uwe-sieber/actions/workflows/excavator.yml/badge.svg)](https://github.com/seanmamasde/uwe-sieber/actions/workflows/excavator.yml)

A [Scoop](https://scoop.sh) bucket for the Windows utilities published by
**[Uwe Sieber](https://www.uwe-sieber.de)** -- the author of USBDLM, USB Device
Tree Viewer, DriveCleanup, RemoveDrive and a long tail of small, sharp
device- and storage-related tools.

Every manifest downloads its archive **directly from the author's own server**.
Nothing is re-hosted or repackaged.

## Installation

```powershell
scoop bucket add uwe-sieber https://github.com/seanmamasde/uwe-sieber
scoop install uwe-sieber/usb-tree-view
```

## Available apps (64)

| App | Description |
| --- | ----------- |
| `attach-vhd` | Attaches VHD, VHDX and ISO files and assigns a drive letter or mount point. |
| `autorun-settings` | Graphical editor for the Windows AutoRun and AutoPlay policy settings. |
| `bin-hex-dec` &dagger; | Converter for hexadecimal, decimal and binary numbers. |
| `button-bar` | ButtonBar - configurable desktop shortcut bar inspired by the old Microsoft Office toolbar. |
| `close-window` | Closes windows matched by caption or window class. |
| `com-name-arbiter-tool` | Gives control over reserved COM port numbers. |
| `com-port-info` | Displays and manages COM ports and their device and bus properties. |
| `com-port-man` | Windows service that controls automatic COM port number assignment. |
| `compact-vhd` | Shrinks VHD files from the command line. |
| `console-black-fill` &dagger; | Paints the area around a console window black. |
| `console-no-close` &dagger; | Deactivates the close button of one or all console windows. |
| `create-file-tester` &dagger; | Tests the Windows API call CreateFile with different flags. |
| `delete-dos-device` | Removes stale drive letter and other DOS device mappings. |
| `device-cleanup` | Bulk-removes non-present devices from the Windows device management. |
| `device-cleanup-cmd` | Scriptable command-line removal of non-present devices. |
| `drive-cleanup` | Removes non-present storage devices and their orphaned registry entries. |
| `eject-media` | Ejects the media from a drive without removing the whole device. |
| `eject-tcv` | Dismounts TrueCrypt and VeraCrypt volumes from the command line. |
| `fcb` | File Compare Binary - fast binary file comparison using direct disk I/O. |
| `ffb` | Flushes the write buffers of a storage volume or file. |
| `ffc` | Fast File Copy - large file copy utility with direct I/O and verification. |
| `file-cache-test` &dagger; | Tests Windows file cache behaviour with different CreateFile flags. |
| `find-exe` | Shows the full path of the executable Windows would launch. |
| `fsf` | Find Same File - finds identical files and can replace duplicates with links. |
| `hid-run` | Starts an executable with a hidden window. |
| `ioctl-decoder` &dagger; | Decodes Windows DeviceIoControl IOCTL and FSCTL codes. |
| `list-bth-devs` | Lists remembered and currently connected Bluetooth devices. |
| `list-com-ports` | Command-line version of COM Port Info. |
| `list-dos-devices` &dagger; | Lists DOS device names and the kernel objects they point to. |
| `list-links` | Lists reparse points, symbolic links and hard links. |
| `list-usb-devs` | Lists attached USB devices or checks for a specific one. |
| `list-usb-drives` | Command-line companion to USB Drive Info that lists USB drives. |
| `load-media` | Loads a media into a drive or brings a volume online. |
| `log-foreground-window` &dagger; | Logs the windows that take the input focus. |
| `log-window-at-point` &dagger; | Logs windows that appear at a given screen position. |
| `mci-browser` | Simple DirectShow and MCI based audio and video player. |
| `md5-file` &dagger; | Calculates the MD5 hash of a file, for use in USBDLM AutoRun validation. |
| `md5-text` &dagger; | Calculates the MD5 hash of a text, for use in USBDLM password settings. |
| `mscope` | Long-term oscilloscope and data logger for Metex compatible multimeters. |
| `msg-box-man` | Automatically answers message boxes and automates arbitrary windows. |
| `nt-cache-setter` &dagger; | Limits and trims the Windows file cache working set. |
| `otax` | Online Taxometer - dial-up connection timer with traffic aware automatic disconnect. |
| `pkt-komma` &dagger; | Uses Caps Lock to switch the numeric keypad between comma and period. |
| `remount` | Reassigns drive letters and NTFS mount points. |
| `remove-drive` | Command-line tool that prepares drives for safe removal. |
| `rescan-devices` &dagger; | Initiates a Plug and Play scan for hardware changes. |
| `restart-sr-dev` | Restarts safely removed devices that show problem code 21 or 47. |
| `restart-usb-port` | Restarts or power-cycles a USB port. |
| `run-as-system` | Starts a process in the SYSTEM account context. |
| `set-file-size` | Sets a file to an exact requested size. |
| `set-max-cpu-power` | Sets the maximum CPU power percentage of the active power plan. |
| `set-system-file-cache-size` &dagger; | Command-line tool that limits the Windows file cache working set. |
| `sleep-ms` &dagger; | Console program that waits for a given number of milliseconds. |
| `test-command-line` &dagger; | Shows command line, working directory, privileges and window style of a started process. |
| `usb-drive-info` | Shows volumes, physical drives, bus topology and detailed USB storage information. |
| `usb-stor-max-transfer-len` &dagger; | Tests and changes the USBSTOR MaximumTransferLength setting. |
| `usb-tree-view` | USB Device Tree Viewer - shows the USB controller, hub and device tree with detailed descriptors. |
| `usb-write-cache` | Configures the write cache and removal policy of USB storage devices. |
| `usbdlm` | USB Drive Letter Manager - Windows service that controls drive letter assignment for USB drives. |
| `usbdlm-remote` &dagger; | USBDLM Remote Password Tool - sends a USBDLM password to a remote client. |
| `verify-disk` | Command-line tool that calls IOCTL_DISK_VERIFY to read-test a disk. |
| `watch-fat-dirty-bit` &dagger; | Watches the FAT dirty bit of a volume. |
| `win-info` &dagger; | Simple window inspector that reports window text and class. |
| `xp-system-restore` &dagger; | Enables or disables Windows XP System Restore per drive. |

&dagger; Upstream publishes no reliable version string for this tool, so it has no
`checkver`/`autoupdate` block and is updated manually (22 of 64 apps).

## Licensing

**Read this before using these tools commercially.**

The MIT licence in this repository applies only to the manifests and tooling
here. The packaged software belongs to Uwe Sieber and carries his own terms:

* Most tools are **freeware**. The author permits commercial use and bundling,
  but prohibits modifying them or redistributing them through "downloader"
  wrappers. This bucket does neither -- Scoop fetches the original archive
  straight from the author's server.
* 2 packages are **not** freeware at all, and are not free for private use
  either:
  * `com-port-man`
  * `usbdlm`

  For these two, the author grants a free licence only to public schools,
  universities and other non-profit educational institutions, and to public
  libraries that are free to use. **Everyone else, private users included,**
  **gets 30 days to evaluate, after which one licence per computer must be**
  **purchased.** The exact terms ship as `*_Licence.txt` inside each archive,
  and each manifest repeats them as an install-time note.

If a tool is useful to you, consider [donating to the author](https://www.uwe-sieber.de).

## What is intentionally not packaged

The site also hosts material that does not make sense as a Scoop package, and
it has been left out on purpose:

* **DOSFon** bitmap console fonts (`.FON` files plus per-codepage installers).
* **UMBPCI**, a DOS / Windows 9x hardware UMB driver.
* **VESASav**, **Off5s** and **DPMSTest** -- a screensaver and DOS-era power
  management test utilities from 2000.
* Visual Basic **source archives** (`*_src.zip`).
* **Frozen legacy builds** kept only for Windows 2000 / XP compatibility, such
  as the older USBDLM, UsbTreeView and RemoveDrive downloads.
* The `util.html` DOS and Windows 9x tools, frozen since 2005.
* **UMBADD**, **UMBOPTI** and **UMBSIS**, which the author modified but did not
  write, plus third-party utilities he only mirrors.

## Maintenance

```powershell
.\bin\checkver.ps1 -u        # check upstream versions and auto-update manifests
.\bin\checkhashes.ps1        # verify the recorded hashes still match
.\bin\checkurls.ps1          # verify every download URL still resolves
.\bin\formatjson.ps1         # normalise manifest formatting
.\bin\missing-checkver.ps1   # list manifests without checkver
.\bin\test.ps1               # run the bucket test suite
```

## Contributing

Before opening a pull request, run:

```powershell
.\bin\formatjson.ps1   # normalise manifest formatting
.\bin\test.ps1         # schema, formatting and line-ending checks
.\bin\checkurls.ps1    # confirm every download URL still resolves
```

`bin\test.ps1` needs the `Pester` (>= 5.2.0) and `BuildHelpers` (>= 2.0.1)
modules, and reads `$env:SCOOP_HOME` to locate Scoop's own test harness.

A GitHub Actions [Excavator](.github/workflows/excavator.yml) workflow runs once
per day. Because upstream is a single small personal web server, it is
deliberately scheduled far less aggressively than the four-hour default used by
the large official buckets.

Upstream publishes no checksums, so `autoupdate` re-downloads each archive and
recomputes its SHA-256.
