
<h1 align="center">AICD_Booster 🚀</h1>

<p align="center">
  <img alt="Rocky Linux" src="https://img.shields.io/badge/OS-Rocky%20Linux%208.x-10B981">
  <img alt="Bash" src="https://img.shields.io/badge/Scripts-Bash-4EAA25?logo=gnubash&logoColor=white">
  <img alt="Lmod" src="https://img.shields.io/badge/Env-Modules%20(Lmod)-6366F1">
  <img alt="LDAP/SSSD" src="https://img.shields.io/badge/Auth-LDAP%20%2B%20SSSD-0EA5E9">
  <img alt="XRDP" src="https://img.shields.io/badge/Remote-XRDP%20%2B%20Xfce-F59E0B">
</p>
<p align="center">
  <a href="https://github.com/lhlaib/AICD_Booster"><img alt="GitHub Stars" src="https://img.shields.io/github/stars/lhlaib/AICD_Booster?style=social"></a>
  <a href="https://github.com/lhlaib"><img alt="GitHub Follow" src="https://img.shields.io/github/followers/lhlaib?label=Follow&style=social"></a>
</p>

<p align="center">
  <b>AICD_Booster</b> is a <b>step-by-step, automation-first deployment kit</b><br/>
  for building a <b>standardized IC design server environment</b> on <b>Rocky Linux 8</b>.
</p>

<p align="center">
    中文版說明請見：<a href="docs/zh-tw/README.md">  README.zh-tw.md</a>
</p>
.docs/zh-tw/README.md

---

## ✨ Why this repo?

AICD_Booster turns a fresh Rocky Linux 8 server into a lab-grade CAD node with a **single, structured workflow**:

- 🧱 **Standardized OS baseline**: updates, repos, essential tools, timezone, and lab defaults  
- 🗄️ **Storage + performance**: NFS + Autofs + **FS-Cache** for faster remote EDA workflows  
- 🛡️ **Security by design**: LDAP/SSSD, hardened SSH, PAM lockout (faillock), firewall ACL, fail2ban  
- 🖥️ **Remote GUI ready**: XRDP + Xfce with consistent global session behavior  
- 🧩 **EDA-ready dependencies**: comprehensive 32/64-bit library stack for legacy + modern binaries  
- 🧑‍💻 **Developer experience**: VS Code with centralized shared extensions + lab-wide defaults  
- 🧾 **Document security**: MyPDF dynamic watermark viewer (no per-user duplication)  
- 🐍 **Offline Python workflows**: uv + pre-seeded Python versions + wheelhouse for restricted networks  
- 🧪 **Operational transparency**: logs captured per stage for audits and troubleshooting  

> If this saves your lab weeks of trial-and-error, please ⭐ the repo. It helps others discover it.

---

## 🧰 What you get

A single package (`rocky_package/`) containing:

| Item | What it is | You edit it? |
|---|---|---|
| `config.sh` | 🔧 All deployment parameters (paths, servers, policies) | ✅ Yes |
| `functions.sh` | ⚙️ Shared helper functions | ❌ No |
| `script/` | 🧩 Staged installation scripts (00~09) | ✅ Run only |
| `template/` | 📄 Config templates (sshd/sssd/firewall/rsyslog/profile/modules/tools…) | ⚠️ Usually no |
| `log/` | 📜 One log per stage | ✅ Read/debug |

---

## ✅ Requirements

- Rocky Linux **8.x**
- Default shell: **bash**
- `sudo` privileges
- Network access for DNF/CURL and lab services (NFS/FTP/LDAP)  
  *(internet or local mirror is fine)*

---

## 🚀 Quick start

> Run from the extracted package root: `~/rocky_package`

### 1) Unpack the installer

```bash
tar -xvf rocky_package.tar
cd rocky_package
```

### 2) Configure your lab parameters

```bash
vim config.sh
```

### 3) Render templates → real configs

```bash
sudo bash script/00_create_setup.sh
```

### 4) Install (recommended: staged, debuggable)

```bash
sudo bash script/01_initial.sh        # OS baseline + repos + tools + NFS/Autofs/FS-Cache + utilities
sudo bash script/02_connection.sh     # LDAP/SSSD + PAM faillock + SSH + XRDP/Xfce + firewall + fail2ban
sudo bash script/03_update_env.sh     # chrony + /etc standardization + rsyslog + /etc/profile.d + sudoers + /etc/hosts
sudo bash script/04_install_eda.sh    # Lmod + modulefiles + EDA dependency kits (32/64-bit)
sudo bash script/05_install_vscode.sh # VS Code + shared extensions + code-lab + modulefile
sudo bash script/06_install_mypdf.sh  # MyPDF watermark viewer (optional)
sudo bash script/07_install_uv.sh     # uv + python versions + offline wheelhouse (optional)
# (optional) sudo bash script/09_clear_up.sh
```

### 5) Fast path (advanced / one-shot)

```bash
sudo bash script/rocky_runset.sh
```

> For first-time deployments, running scripts **one-by-one** is strongly recommended.

* * *

🧩 Staged flow (what each script does)
--------------------------------------

| Stage | Script | What it installs / configures |
| --- | --- | --- |
| 00 | `00_create_setup.sh` | Render templates using `config.sh` |
| 01 | `01_initial.sh` | OS baseline, repos, tools, NFS/Autofs/FS-Cache, lab utilities |
| 02 | `02_connection.sh` | LDAP/SSSD, PAM lockout, SSH rules/port, XRDP+Xfce, firewall ACL, fail2ban |
| 03 | `03_update_env.sh` | Chrony, `/etc` standardization, rsyslog, `/etc/profile.d`, sudoers, `/etc/hosts` |
| 04 | `04_install_eda.sh` | Lmod + modulefiles + EDA dependency libs (multi-arch) |
| 05 | `05_install_vscode.sh` | VS Code + shared extensions + `code-lab` launcher + modulefile |
| 06 | `06_install_mypdf.sh` | Secure doc hierarchy + MyPDF dynamic watermark viewer |
| 07 | `07_install_uv.sh` | uv + shared Python + offline wheelhouse |
| 09 | `09_clear_up.sh` | Cleanup setup materials + logs (optional) |

* * *

⚙️ Configuration (edit `config.sh`)
-----------------------------------

### 📁 Deployment paths (lab filesystem layout)

Common defaults (adjust to your lab):

*   `DEPLOY_ROOT` (e.g., `/RAID2`)
*   `CAD_ROOT` (e.g., `/RAID2/cad`)
*   `BIN_ROOT` (e.g., `/RAID2/bin`)
*   `MODULE_ROOT` (e.g., `/RAID2/modulefiles`)
*   `TOOL_ROOT` (e.g., `/RAID2/tool`)
*   `DOC_ROOT` (e.g., `/RAID2/WaterProof_PDF`)
*   Optional: `COURSE_ROOT`, `MANAGER_ROOT`

### 🗄️ Storage: NFS / FTP upload mount

*   NFS: `NFS_MOUNT`, `NFS_SERVER`, `NFS_REMOTE`
*   FTP: `FTP_MOUNT`, `FTP_SERVER`, `FTP_REMOTE`, `FTP_LOCAL`

Validate exports first:

```bash
showmount -e <nfs_server>
```

### 🔐 Auth & security

*   LDAP/SSSD: `SSSD_LDAP_URI`, `SSSD_LDAP_BASE`, `SSSD_BIND_DN`, `SSSD_BIND_PW`
*   PAM lockout: `PAMD_DENY_COUNT`, `PAM_LOCK_TIME`
*   SSH: `SSH_SPEC_PORT`, `SSH_ALLOW_GROUPS_*`
*   XRDP: `XRDP_PORT`, title text, group whitelist
*   Firewall ACL: `FIREWALLD_WHITE_IP_LIST`
*   Fail2ban: `F2B_MAX_RETRY`, `F2B_BAN_TIME`, `WHITE_IP_LIST`

### 🛰️ Environment & observability

*   Chrony: `CHRONY_SERVER`
*   Rsyslog: `RSYSLOGD_SERVER`, `RSYSLOGD_PORT`
*   Global shell UX: `template/profile.d/`

* * *

✅ Verification checklist (after each stage)
-------------------------------------------

### After `01_initial.sh` ✅

```bash
timedatectl
df -h
/RAID2/bin/bye
/RAID2/bin/force-logout   # or /RAID2/bin/fl
/RAID2/bin/task-manager   # or /RAID2/bin/tm
```

### After `02_connection.sh` ✅

```bash
systemctl status sssd
getent group <LDAP_GROUP>

systemctl status sshd
systemctl status xrdp
systemctl status firewalld
systemctl status fail2ban

sudo ss -tunlp | egrep 'sshd|xrdp'
```

### After `04_install_eda.sh` ✅

```bash
module avail    # or: ml av
ls -ld /usr/cad
rpm -q krb5-libs
```

### After `05_install_vscode.sh` ✅

```bash
code-lab
```

* * *

🧭 Installation by feature (configure → run → verify)
-----------------------------------------------------

This section is written like a playbook.

### 1) 🧱 Base system & storage (NFS / FTP Upload)

**Files involved**: `config.sh`, `script/01_initial.sh`

**Configure (`config.sh`)**

```bash
DEPLOY_ROOT=/RAID2
CAD_ROOT=/RAID2/cad

NFS_SERVER=10.0.0.10
NFS_REMOTE=/exports/cad
NFS_MOUNT=/RAID2/cad

FTP_SERVER=10.0.0.20
FTP_REMOTE=/upload
FTP_MOUNT=/RAID2/upload
```

**Run**

```bash
sudo bash script/01_initial.sh
```

**Verify**

```bash
df -h | grep RAID2
mount | grep nfs
ls /RAID2/cad
```

* * *

### 2) 🔐 LDAP authentication & account policy

**Files involved**: `config.sh`, `script/02_connection.sh`, `template/sssd.conf`

**Configure**

```bash
SSSD_LDAP_URI=ldap://ldap.school.edu.tw
SSSD_LDAP_BASE=dc=school,dc=edu,dc=tw
SSSD_BIND_DN=cn=admin,dc=school,dc=edu,dc=tw
SSSD_BIND_PW=your_password
```

**Run**

```bash
sudo bash script/02_connection.sh
```

**Verify**

```bash
systemctl status sssd
getent passwd <ldap_user>
getent group <ldap_group>
```

* * *

### 3) 🧷 SSH hardening & access control

**Files involved**: `config.sh`, `script/02_connection.sh`

**Configure**

```bash
SSH_SPEC_PORT=415
SSH_ALLOW_GROUPS_DEFAULT="students"
SSH_ALLOW_GROUPS_MANAGER="admins"
```

**Run**

```bash
sudo bash script/02_connection.sh
```

**Verify**

```bash
ss -tunlp | grep ssh
ssh -p 415 user@host
```

* * *

### 4) 🖥️ Remote Desktop (XRDP + Xfce)

**Files involved**: `config.sh`, `script/02_connection.sh`

**Configure**

```bash
XRDP_PORT=3389
XRDP_SESSION_GROUP=rdpusers
```

**Run**

```bash
sudo bash script/02_connection.sh
```

**Verify**

```bash
systemctl status xrdp
ss -tunlp | grep 3389
```

* * *

### 5) 🧰 Environment standardization (shell / time / logs)

**Files involved**: `script/03_update_env.sh`, `template/profile.d/`, `template/rsyslog.d/`

**Run**

```bash
sudo bash script/03_update_env.sh
```

**Verify**

```bash
date
alias
echo $MODULEPATH
```

* * *

### 6) 🧩 EDA environment (Lmod + dependencies)

**Files involved**: `script/04_install_eda.sh`, `template/modulefiles/`

**Run**

```bash
sudo bash script/04_install_eda.sh
```

**Verify**

```bash
module avail
module load cadence
ldd <eda_binary>
```

* * *

### 7) 🧑‍💻 VS Code (shared extensions)

**Files involved**: `script/05_install_vscode.sh`

**Run**

```bash
sudo bash script/05_install_vscode.sh
```

**Verify**

```bash
code-lab
```

* * *

🧯 Troubleshooting
------------------

Each stage produces a log file:

```bash
ls log/
less log/02_connection.log
```

Tips:

*   Always re-run `00_create_setup.sh` after changing `config.sh`
*   If one stage fails, fix + re-run that stage only
*   Don’t jump to `rocky_runset.sh` until staged install is stable

* * *

🛡️ Security checklist
----------------------

*   ✅ LDAP/SSSD for centralized identity + policy
*   ✅ PAM faillock to stop brute-force
*   ✅ SSH on a non-default port + group-based access
*   ✅ Firewall ACL whitelist for sensitive ports
*   ✅ Fail2ban for IP banning
*   ✅ Centralized rsyslog for audit trail

* * *

👥 Contributors
---------------

感謝以下夥伴協助本教學系統的撰寫與維護 🙌

*   賴林鴻（[@lhlaib](https://github.com/lhlaib)）
*   蕭邦原（[@bonyuan](https://github.com/bonyuan)）

[![Contributors](https://contrib.rocks/image?repo=lhlaib/AICD_Booster)](https://github.com/lhlaib/AICD_Booster/graphs/contributors)

* * *

📄 License / Usage
------------------

©2026 System Integration and Silicon Implementation Lab, NYCU  
All rights reserved. For educational use only.
