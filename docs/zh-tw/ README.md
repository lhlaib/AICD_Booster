
<h1 align="center">AICD_Booster 🚀</h1>

<p align="center">
  <img alt="Rocky Linux" src="https://img.shields.io/badge/OS-Rocky%20Linux%208.x-10B981">
  <img alt="Bash" src="https://img.shields.io/badge/Scripts-Bash-4EAA25?logo=gnubash&logoColor=white">
  <img alt="Lmod" src="https://img.shields.io/badge/Env-Modules%20(Lmod)-6366F1">
  <img alt="LDAP/SSSD" src="https://img.shields.io/badge/Auth-LDAP%20%2B%20SSSD-0EA5E9">
  <img alt="XRDP" src="https://img.shields.io/badge/Remote-XRDP%20%2B%20Xfce-F59E0B">
  <a href="https://github.com/lhlaib/AICD_Booster"><img alt="GitHub Stars" src="https://img.shields.io/github/stars/lhlaib/AICD_Booster?style=social"></a>
  <a href="https://github.com/lhlaib"><img alt="GitHub Follow" src="https://img.shields.io/github/followers/lhlaib?label=Follow&style=social"></a>
</p>

<p align="center">
  <b>AICD_Booster</b> 是一套 <b>以自動化為核心、逐步執行（step-by-step）</b> 的部署工具包<br/>
  用於在 <b>Rocky Linux 8</b> 上建立 <b>標準化的 IC 設計（CAD）伺服器環境</b>。
</p>

---

## ✨ 為什麼要使用 AICD_Booster？

AICD_Booster 可以將一台全新的 Rocky Linux 8 主機，  
透過 **單一、結構化的安裝流程**，快速轉換為實驗室等級的 CAD 工作節點：

- 🧱 **標準化作業系統基線**：系統更新、套件庫、常用 CLI 工具、時區與實驗室預設設定  
- 🗄️ **儲存與效能最佳化**：NFS + Autofs + **FS-Cache**，加速遠端 EDA 存取  
- 🛡️ **安全性優先設計**：LDAP/SSSD、SSH 強化、PAM 暴力登入鎖定（faillock）、Firewall ACL、Fail2ban  
- 🖥️ **遠端圖形介面**：XRDP + Xfce，提供一致的 GUI 操作體驗  
- 🧩 **EDA 環境就緒**：完整的 32/64-bit 相依函式庫，支援新舊 EDA 工具  
- 🧑‍💻 **開發者體驗**：VS Code + 共用擴充套件，避免每位使用者重複安裝  
- 🧾 **文件安全性**：MyPDF 動態浮水印閱讀器，避免大量文件複製  
- 🐍 **離線 Python 工作流程**：uv + 預先部署 Python + wheelhouse，適用於無網路環境  
- 🧪 **可維運性**：每個安裝階段皆產生獨立 log，方便稽核與除錯  

> 如果這個專案幫你的實驗室省下了好幾週的摸索時間，  
> 請給我們一顆 ⭐，讓更多人能找到它。

---

## 🧰 你會拿到什麼？

整個系統集中在一個目錄：`rocky_package/`

| 項目 | 說明 | 是否需要修改 |
|---|---|---|
| `config.sh` | 🔧 所有部署參數（路徑、伺服器、政策） | ✅ 需要 |
| `functions.sh` | ⚙️ 共用函式庫 | ❌ 不建議 |
| `script/` | 🧩 分階段安裝腳本（00–09） | ▶️ 執行 |
| `template/` | 📄 設定檔樣板（sshd/sssd/firewall/rsyslog/profile/module/tool…） | ⚠️ 通常不需 |
| `log/` | 📜 各階段安裝紀錄 | 👀 檢視 |

---

## ✅ 系統需求

- Rocky Linux **8.x**
- 預設 Shell：**bash**
- 具備 `sudo` 權限
- 可連線至 DNF/CURL 來源與實驗室服務（NFS / FTP / LDAP）  
  （可為對外網路或內部 mirror）

---

## 🚀 快速開始

> 請在解壓後的 `rocky_package` 目錄中操作

### 1️⃣ 解壓安裝包

```bash
tar -xvf rocky_package.tar
cd rocky_package
```

### 2️⃣ 設定實驗室參數

```bash
vim config.sh
```

### 3️⃣ 產生實際設定檔（template → real config）

```bash
sudo bash script/00_create_setup.sh
```

### 4️⃣ 分階段安裝（**強烈建議**）

```bash
sudo bash script/01_initial.sh
sudo bash script/02_connection.sh
sudo bash script/03_update_env.sh
sudo bash script/04_install_eda.sh
sudo bash script/05_install_vscode.sh
sudo bash script/06_install_mypdf.sh   # 選用
sudo bash script/07_install_uv.sh      # 選用
# sudo bash script/09_clear_up.sh       # 選用
```

### 5️⃣ 一鍵安裝（進階使用者）

```bash
sudo bash script/rocky_runset.sh
```

> 初次部署、或新環境，**請務必使用分階段安裝**。

* * *

🧩 分階段流程總覽
----------

| Stage | Script | 功能 |
| --- | --- | --- |
| 00 | `00_create_setup.sh` | 依 `config.sh` 產生實際設定檔 |
| 01 | `01_initial.sh` | 系統基礎、套件、NFS/Autofs/FS-Cache、實驗室工具 |
| 02 | `02_connection.sh` | LDAP/SSSD、PAM、SSH、XRDP、Firewall、Fail2ban |
| 03 | `03_update_env.sh` | 時間同步、/etc 標準化、rsyslog、shell 環境 |
| 04 | `04_install_eda.sh` | Lmod + EDA 相依函式庫 |
| 05 | `05_install_vscode.sh` | VS Code + 共用擴充套件 |
| 06 | `06_install_mypdf.sh` | MyPDF 動態浮水印文件系統 |
| 07 | `07_install_uv.sh` | uv + 離線 Python |
| 09 | `09_clear_up.sh` | 清理安裝檔與 log（選用） |

* * *

⚙️ 設定重點（`config.sh`）
--------------------

### 📁 目錄結構

*   `DEPLOY_ROOT`（例：`/RAID2`）
*   `CAD_ROOT`
*   `BIN_ROOT`
*   `MODULE_ROOT`
*   `TOOL_ROOT`
*   `DOC_ROOT`
*   （選用）`COURSE_ROOT`, `MANAGER_ROOT`

### 🗄️ 儲存（NFS / FTP）

*   NFS：`NFS_SERVER`, `NFS_REMOTE`, `NFS_MOUNT`
*   FTP：`FTP_SERVER`, `FTP_REMOTE`, `FTP_MOUNT`, `FTP_LOCAL`

### 🔐 認證與安全

*   LDAP/SSSD：`SSSD_LDAP_URI`, `SSSD_LDAP_BASE`, `SSSD_BIND_DN`, `SSSD_BIND_PW`
*   PAM：`PAMD_DENY_COUNT`, `PAM_LOCK_TIME`
*   SSH：`SSH_SPEC_PORT`, `SSH_ALLOW_GROUPS_*`
*   XRDP：`XRDP_PORT`
*   Firewall：`FIREWALLD_WHITE_IP_LIST`
*   Fail2ban：`F2B_MAX_RETRY`, `F2B_BAN_TIME`

* * *

✅ 驗證清單（重要）
----------

### After `01_initial.sh`

```bash
timedatectl
df -h
/RAID2/bin/bye
```

### After `02_connection.sh`

```bash
systemctl status sssd
systemctl status sshd
systemctl status xrdp
```

### After `04_install_eda.sh`

```bash
module avail
```

### After `05_install_vscode.sh`

```bash
code-lab
```

* * *

🧯 問題排查
-------

每個階段都有對應 log：

```bash
ls log/
less log/02_connection.log
```

建議流程：

1.  修改 `config.sh`
2.  重跑 `00_create_setup.sh`
3.  只重跑失敗的 stage

* * *

🛡️ 安全建議
--------

*   ✅ LDAP/SSSD 集中帳號管理
*   ✅ PAM faillock 防暴力登入
*   ✅ SSH 非預設 Port + 群組限制
*   ✅ Firewall 白名單
*   ✅ Fail2ban IP 封鎖
*   ✅ 中央化 rsyslog 稽核

* * *

👥 貢獻者
------

感謝以下夥伴參與系統設計與文件撰寫 🙌

*   賴林鴻（[@lhlaib](https://github.com/lhlaib)）
*   蕭邦原（[@bonyuan](https://github.com/bonyuan)）

[![Contributors](https://contrib.rocks/image?repo=lhlaib/AICD_Booster)](https://github.com/lhlaib/AICD_Booster/graphs/contributors)

* * *

©2026 System Integration and Silicon Implementation Lab, NYCU  
All rights reserved. For educational use only.
