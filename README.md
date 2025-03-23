# kraken_installer_tui

# Kraken Install TUI 🐙  

**Bash script** to automate the installation of **Kraken OS**, a custom Linux distribution. Handles disk partitioning, user setup, locale configuration, and system settings via CLI arguments.  

---

## 🚀 Features  
- Automated disk partitioning and filesystem setup.  
- Customizable user accounts, language, keyboard layout, and timezone.  
- Validation of input parameters for safety and compatibility.  
- Supports multiple languages and keyboard layouts.  

---

## 📥 Installation  
1. Clone the repository:  
   ```sh 
   git clone https://github.com/n1cef/kraken_installer_tui.git  
   cd kraken_installer_tui
    ```
   2.Make the script executable:
    ```sh
    chmod +x kraken_install.sh
    ```


    ## 🚀 Usage
  
      ```sh
     sudo ./kraken_install.sh disk_name home_on swap_on username userpass system_language keyboard_layout hostname time_zone 
      ```
    
   

    ## 🚀 Example:
  
    ```sh
    sudo ./kraken_install.sh /dev/sda yes yes n1cef passoword en_US.UTF-8 us kraken /Africa/Tunis  
    ```
 

## 📋 Parameters

| Parameter            | Description                                      | Valid Values                                                                 |
|----------------------|--------------------------------------------------|------------------------------------------------------------------------------|
| **`disk_name`**      | Full path to the target disk                     | `/dev/sda`, `/dev/nvme0n1`, `/dev/mmcblk0`                                  |
| **`home_on`**        | Create separate `/home` partition               | `yes` or `no`                                                               |
| **`swap_on`**        | Create swap partition                           | `yes` or `no`                                                               |
| **`username`**       | Primary user account name                       | Alphanumeric, lowercase (e.g. `n1cef`)                                     |
| **`userpass`**       | Password for primary user                       | Any valid string (use quotes for special characters)                        |
| **`system_language`**| System locale and language                      | `en_US.UTF-8`, `fr_FR.UTF-8`, `ar_SA.UTF-8`                                |
| **`keyboard_layout`**| Keyboard layout code                            | `us` (English), `fr` (French), `ar` (Arabic)                                |
| **`hostname`**       | System hostname                                 | Alphanumeric, no spaces (e.g. `kraken`)                                    |
| **`time_zone`**      | Timezone in `/Region/City` format               | `/Africa/Tunis`, `/Europe/Paris`, `/Asia/Dubai`                             |



 >[!IMPORTANT]
>Disk WARNING: This script will format the specified disk. Double-check the disk_name! 
 

##  📂 Related Projects
   <h3>Kraken Installer GUI: Qt6-based frontend for this script. [Kraken Installer GUI](https://github.com/n1cef/kraken_installer_gui) </h3>


   
