# Run with AnyThing

This project provides a convenient way to run `acli.exe rovodev run`, `gemini`, or `claude` (via WSL) from any directory via a right-click context menu entry in Windows File Explorer.

## Features

*   **Context Menu Integration:** Adds "Run with RovoDev", "Run with Gemini", and "Run with Claude" options to the right-click context menu for directories and also to the empty space within a folder (background).

    ![Right Click Menu](images/right_click_menu.png)

*   **Automatic PowerShell Detection:** Automatically detects and uses `pwsh.exe` (PowerShell Core) or `powershell.exe` (Windows PowerShell).
*   **Administrator Privileges Check:** Ensures the installation script is run with necessary administrator privileges.
*   `acli.exe` executable (the script will prompt for its path if not found in the same directory, only for RovoDev option)
*   `gemini` command available in your system's PATH (only for Gemini option)
*   WSL (Windows Subsystem for Linux) with `claude` command available in Linux environment (only for Claude option)
    *   To find your claude command path, run `which claude` in WSL terminal

## Requirements

*   Windows Operating System
*   PowerShell (version 5.1 or PowerShell Core 7+)

## Installation

1.  **Download the project:** Clone or download this repository to your local machine.
2.  **Run the installation script:**
    *   Right-click on `install_run_with_AnyThing.ps1` and select "Run with PowerShell" or "Run as Administrator".
    *   The script will check for administrator privileges and prompt you if needed.

    ![PowerShell Installation Prompt](images/powershell_install.png)

    *   Follow the on-screen prompts to:
        1.  Choose whether to **Install** or **Uninstall** a context menu entry.
        2.  Select which command to manage: **RovoDev**, **Gemini**, or **Claude**.
        3.  Specify the context menu location: **Folder** (right-click on a folder) or **Background** (right-click on empty space inside a folder).
    *   If you choose 'RovoDev' and `acli.exe` is not found in the same directory as the script, you will be prompted to enter its full path (e.g., `C:\Program Files\RovoDev\acli.exe`).
    *   If you choose 'Claude', you will be prompted to enter the full path to the claude command in WSL. To find this path, run `which claude` in your WSL terminal.


## Uninstallation

To remove a "Run with RovoDev", "Run with Gemini", or "Run with Claude" context menu entry:

1.  **Run the installation script:** Follow the same steps as for installation, but choose **Uninstall** from the main menu. The script will guide you through removing the selected entry.

## How it Works

The `install_run_with_AnyThing.ps1` script performs the following actions:

1.  Checks if it's running with administrator privileges.
2.  Presents an interactive menu to the user to choose the desired action (Install/Uninstall), command (RovoDev/Gemini/Claude), and context menu location (Folder/Background).
3.  Detects the preferred PowerShell executable (`pwsh.exe` or `powershell.exe`).
4.  Based on the user's choices, it creates or removes the appropriate registry keys:
    *   `HKEY_CLASSES_ROOT\Directory\shell\Run with RovoDev` (for RovoDev option on folders)
    *   `HKEY_CLASSES_ROOT\Directory\shell\Run with RovoDev\command` (for RovoDev option on folders)
    *   `HKEY_CLASSES_ROOT\Directory\shell\Run with Gemini` (for Gemini option on folders)
    *   `HKEY_CLASSES_ROOT\Directory\shell\Run with Gemini\command` (for Gemini option on folders)
    *   `HKEY_CLASSES_ROOT\Directory\Background\shell\Run with RovoDev` (for RovoDev option on background)
    *   `HKEY_CLASSES_ROOT\Directory\Background\shell\Run with RovoDev\command` (for RovoDev option on background)
    *   `HKEY_CLASSES_ROOT\Directory\Background\shell\Run with Gemini` (for Gemini option on background)
    *   `HKEY_CLASSES_ROOT\Directory\Background\shell\Run with Gemini\command` (for Gemini option on background)
    *   `HKEY_CLASSES_ROOT\Directory\shell\Run with Claude` (for Claude option on folders)
    *   `HKEY_CLASSES_ROOT\Directory\shell\Run with Claude\command` (for Claude option on folders)
    *   `HKEY_CLASSES_ROOT\Directory\Background\shell\Run with Claude` (for Claude option on background)
    *   `HKEY_CLASSES_ROOT\Directory\Background\shell\Run with Claude\command` (for Claude option on background)
5.  Sets the default value of the chosen menu entry (e.g., "Run with RovoDev", "Run with Gemini", or "Run with Claude") and its icon to the PowerShell executable.
6.  Sets the default value of the `command` key to a PowerShell command that navigates to the selected directory and executes either `acli.exe rovodev run` (for RovoDev), `gemini` (for Gemini), or `claude` via WSL (for Claude).

## Features

*   **🎨 Beautiful Interface**: Modern text-based menu with emojis and colorful formatting
*   **🖥️ Interactive Experience**: Welcome screen and step-by-step guidance
*   **⚙️ Flexible Configuration**: Prompts for custom paths when needed
*   **🔄 Easy Management**: Install and uninstall with clear feedback messages 