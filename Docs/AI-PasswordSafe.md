
# Breakglass with BeyondTrust Password Safe

This document explains how to set up **BeyondTrust Password Safe** for a **Category 2 break glass scenario**.

The first part covers the essential components for managing break glass accounts in PAM. The second part provides examples for account setup using **Active Directory**, **Linux password**, and **Linux SSH key pair**.

The goal is to configure Password Safe so that an API user can access only break glass accounts. This enables a script or program to copy passwords from PAM to a local vault for use when PAM is unavailable, ensuring administrative access to critical endpoints.

---

## Basic Setup in Password Safe

Password Safe uses filters to show only accounts designated for break glass purposes. This is achieved through:
- **Smart Rule**
- **Policies**
- **Features**
- **User Groups**

### Smart Rule
Create a Smart Rule to filter break glass accounts:

| Field              | Value                                                                 |
|--------------------|----------------------------------------------------------------------|
| Category           | Managed Accounts                                                    |
| Name               | Breakglass                                                         |
| Selection Criteria | Account Name → Starts with → `pws_Breakglass` (allows variations) |
| Actions            | Show managed accounts as Smart Group                               |

Additional criteria can be added for more granular filtering.

![Smart Rule](/Docs/PasswordSafe-SmartRule.png)

### Functional Accounts
Functional accounts are used to change passwords and SSH keys on endpoints. These accounts must have permissions to update other accounts. Examples include:

![Functional Account (AD)](/Docs/PasswordSafe-FunctionalAccount(AD).png) ![Functional Account (Linux)](/Docs/PasswordSafe-FunctionalAccount(Linux).png)


### Password Policy and SSH Key Policy
Define policies for password and SSH key generation:
- Password policy: Include uppercase, lowercase, numeric, and special characters. Recommended length: 32 characters.
- SSH Key policy: Uncheck **Encryption Enabled** to allow SSH private keys to be fetched without encryption.

![Password Policy](/Docs/PasswordSafe-PasswordPolicy.png)

![SSH Key Policy](/Docs/PasswordSafe-SSHKeyPolicy.png)


## Accessing Password Safe via API

To allow script access to the API, define:
- **API Registration**
- **API User**
- **API User Group**

### API Registration
Create an API registration and copy the key for use in the break glass script. Configure IP rules to permit access from the system running the script. Use CIDR for multiple systems.

![API Registration](/Docs/PasswordSafe-APIRegistration.png)

### API User
Create a local user for API access.

![User](/Docs/PasswordSafe-APIUser.png)

### API User Group
Create a user group for API access:

![Usergroup](/Docs/PasswordSafe-APIUserGroup-1.png)

**Enabled Features:**
- Asset Management (Read only)
- Password Safe Account Management (Full control)
- Password Safe System Management (Read only)

![Usergroup - Features](/Docs/PasswordSafe-APIUserGroup-2.png)

**Enabled Smart Groups:**
Assign the Smart Group **Breakglass** created earlier. Use the **Requestor** role with 24x7 auto-approve access policy.

![Usergroup - Smart Group](/Docs/PasswordSafe-APIUserGroup-3.png)

**Assigned Users:**
Add the `api_Breakglass` user to this group.

![Usergroup - Assigned Users](/Docs/PasswordSafe-APIUserGroup-4.png)

**API Registrations:**
Add the API registration defined earlier.

![Usergroup - API Registration](/Docs/PasswordSafe-APIUserGroup-5.png)

# Breakglass Accounts

Accounts in Password Safe exist on **Managed Systems**, which represent endpoint environments. Examples include **Active Directory**, **Linux (password authentication)**, and **Linux (SSH key pair)**. Other types of managed systems can also be defined in Password Safe.

Accounts are created as **Managed Accounts** on a Managed System. Each account type may have different options depending on the system. This guide focuses on PAM configuration; endpoint permissions are out of scope.

---

## Active Directory

### Managed System for Active Directory
Password Safe (SaaS) requires a connection broker with TLS for password changes in AD. Key settings:

| Field                     | Value            |
|---------------------------|------------------|
| Automatic Password Change | Enabled         |
| Password Policy           | pws_Breakglass  |
| Functional Account        | pws_Reconcile (AD) |

![Managed System - Active Directory](/Docs/PasswordSafe-ManagedSystems(AD).png)

### Managed Account for Active Directory
Create a managed account for the AD system. Important settings:

| Field                          | Value                  |
|--------------------------------|------------------------|
| Name                           | psw_Breakglass        |
| Automatic Password Change      | Enabled               |
| Password Policy                | pws_Breakglass        |
| Change Password Starting From  | Future date           |
| Change Password After Release  | Disabled              |
| API Enabled                    | Enabled               |
| Use Own Credentials            | Disabled (use functional account) or Enabled (own account) |

![Managed Account - Active Directory](/Docs/PasswordSafe-ManagedAccounts(AD).png)

---

## Linux (Password)

### Managed System for Linux (Password)
Configure the Linux system for password and/or SSH key authentication. Key settings:

| Field                     | Value                      |
|---------------------------|----------------------------|
| Automatic Password Change | Enabled                   |
| Password Policy           | pws_Breakglass            |
| Functional Account        | pws_Reconcile (Tomcat)    |
| Login Account             | pws_Reconcile (Tomcat)    |
| SSH Key Policy            | Breakglass (SSH Key Policy) |

![Managed System - Linux](/Docs/PasswordSafe-ManagedSystems(Linux).png)

### Managed Account for Linux (Password)
Create a managed account using password authentication:

| Field                          | Value                  |
|--------------------------------|------------------------|
| Name                           | psw_Breakglass        |
| Authentication Type            | Password              |
| Automatic Password Change      | Enabled               |
| Password Policy                | pws_Breakglass        |
| Change Password Starting From  | Future date           |
| Change Password After Release  | Disabled              |
| API Enabled                    | Enabled               |
| Use Own Credentials            | Disabled (use functional account) or Enabled (own account) |

![Managed Account - Linux (Password)](/Docs/PasswordSafe-ManagedAccounts(Linux-Password).png)

---

## Linux (SSH Key Pair)

### Managed System for Linux (SSH Key Pair)
Setup is the same as Linux (Password). See above.

### Managed Account for Linux (SSH Key Pair)
Create a managed account using SSH key pair. Note: Use a unique name if both password and SSH key authentication exist. Example settings:

| Field                          | Value                  |
|--------------------------------|------------------------|
| Name                           | psw_Breakglass-SSH    |
| Authentication Type            | SSH Key               |
| Login Account for SSH Sessions | Enabled               |
| Automatic Password Change      | Enabled               |
| Change Password Starting From  | Future date           |
| Change Password After Release  | Disabled              |
| Auto-Managed SSH Key           | Enabled               |
| API Enabled                    | Enabled               |
| Use Own Credentials            | Disabled (use functional account) or Enabled (own account) |

![Managed Account - Linux (SSH)](/Docs/PasswordSafe-ManagedAccounts(Linux-SSH).png)