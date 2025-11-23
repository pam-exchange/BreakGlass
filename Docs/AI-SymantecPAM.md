# Breakglass with Symantec PAM

This document describes how to set up **Symantec PAM** for a **Category 2 break glass scenario**.

The first part explains the components required to manage break glass accounts in PAM. The second part provides examples for account setup using **Active Directory**, **Linux password**, and **Linux SSH key pair**.

The goal is to configure PAM so that an API user can access only break glass accounts. This allows a script or program to copy passwords from PAM to a local vault for use when PAM is unavailable, ensuring administrative access to critical endpoints.

## Basic Setup in Symantec PAM

Symantec PAM uses filters to show only accounts designated for break glass purposes. This is achieved through:
- **Target Group**
- **Credential Manager Role**
- **Credential Manager User Group**

Assigning these to an API user ensures they can view passwords and SSH keys only for break glass accounts.

### Target Group
A **Target Group** filters accounts so only break glass accounts are visible. Groups can be static or dynamic. For a small number of accounts, a static group works well. Example filter: account name equals `breakglass`.

![Target Group](/Docs/SymantecPAM-TargetGroup.png)

### Credential Manager Role
Defines permissions for the API user, including:
- List/view servers, applications, and accounts
- Update password
- View password

![Credential Manager Role](/Docs/SymantecPAM-CMRole.png)

### Credential Manager User Group
Assign this group to the API user. It links the Target Group and Credential Manager Role permissions.

![Credential Manager User Group](/Docs/SymantecPAM-CMGroup.png)

### API User Role
Create a dedicated PAM Role for break glass. This role grants access to Credential Management features defined in the User Group.

![User Role](/Docs/SymantecPAM-Role.png)

### API User
Define the API user as either a domain or local user (example uses local).

![User #1](/Docs/SymantecPAM-User-1.png)

Assign the Breakglass role:
![User #2](/Docs/SymantecPAM-User-2.png)

Assign the Breakglass Credential Manager group:
![User #3](/Docs/SymantecPAM-User-3.png)

## Policies for Break Glass Usage

Policies should cover password complexity, viewing, and SSH key generation.

### Password Composition Policy (PCP)
Defines password length and complexity. Key points:
- Use strong, long passwords.
- Disable automatic password updates (uncheck Password Age enforcement). Updates are manual via break glass script.

![Password Composition Policy](/Docs/SymantecPAM-PCP.png)

### Password View Policy (PVP)
Controls actions before and after password release:
- Require reauthentication for interactive use.
- Updates handled manually by script.
- Consider email notifications and dual authorization.

![Password View Policy](/Docs/SymantecPAM-PVP.png)

### SSH Key Policy
Defines type and length of SSH key pairs.

![SSH Key-Pair Policy](/Docs/SymantecPAM-SSHKey-PairPolicy.png)

---

# Breakglass Accounts

## Active Directory

### Target Application
![TargetApplication - Active Directory](/Docs/SymantecPAM-TargetApplication(AD).png)

### Target Account
![TargetAccount - Active Directory](/Docs/SymantecPAM-TargetAccount(AD).png)

## Linux (Password)

### TargetApplication for Linux (Password)

![TargetApplication - Linux (password)](/Docs/SymantecPAM-TargetApplication-Linux(Password).png)

### TargetAccount for Linux (Password)

![TargetAccount - Linux (password](/Docs/SymantecPAM-TargetAccount-Linux(Password).png)

## Linux (SSH Key-Pair)

### TargetApplication for Linux (SSH Key-Pair)

![TargetApplication - Linux (SSH Key-Pair)](/Docs/SymantecPAM-TargetApplication-Linux(SSH)-1.png)
![TargetApplication - Linux (SSH Key-Pair)](/Docs/SymantecPAM-TargetApplication-Linux(SSH)-2.png)

### TargetAccount for Linux (SSH Key-Pair)

![TargetAccount - Linux (SSH Key-Pair](/Docs/SymantecPAM-TargetAccount-Linux(SSH).png)

