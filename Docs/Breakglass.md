# Breakglass and PAM

Privileged Access Management (PAM) is widely used in organizations to establish and control access to servers and applications for users with elevated privileges (e.g., administrators). Ideally, the login process to the server or application is automated without revealing credentials to the user. Additional security measures such as session recording and automatic credential rotation are typically built-in capabilities.

A natural question arises: **“How do you gain access to servers and applications when PAM is not available?”**

This scenario is called **Break Glass** or **Emergency Access**, and it is crucial for any critical system in an organization. PAM solutions are essential for privileged access to onboarded systems, making it extremely important to consider emergency access in various disaster scenarios.

Looking at Break Glass from a broader perspective, there are other situations beyond PAM outages that can also be considered break glass scenarios.

### Break Glass Categories
Break Glass can be divided into at least three categories related to PAM:

1. **PAM Admin Break Glass** – Emergency access for PAM application and supporting infrastructure.
2. **Privileged User Break Glass (PAM Unavailable)** – Temporary access to target systems when the normal access path via PAM is unavailable.
3. **Privileged User Break Glass (PAM Operational)** – Emergency access to targets where PAM is operational and used to provide break glass access to endpoints.

![Breakglass Categories](/Docs/BreakGlass-Categories.png)

When referring to break glass credentials, these can be **username & password** or **SSH key pairs**. The choice depends on the technology used for accessing servers and applications. Unless explicitly stated, these terms are used interchangeably.

### Recommendations for Implementing PAM-Related Break Glass Processes

1. **Address Break Glass Early** – When designing and implementing a PAM solution, ensure break glass is discussed with key stakeholders, covering all three categories.
2. **Design for All Categories** – Consider each category and type of break glass in this guidance. It is acceptable to exclude certain scenarios if justified, but omissions must be documented.
3. **Document and Validate** – No solution is complete until processes are thoroughly documented, verified, and validated end-to-end.
4. **Training and Playbooks** – Ensure relevant staff are trained and have access to break glass playbooks.
5. **Clarify Categories** – Always specify which break glass category you are addressing.
6. **Credential Rotation** – Define processes for rotating or changing credentials and validating break glass accounts.
7. **Close Access After Use** – All break glass processes should end with revoking access rights and/or rotating exposed credentials.
8. **Keep It Simple** – Break glass processes should be simple enough for users to perform autonomously.
9. **Secure Credentials** – Ensure break glass credentials and processes are protected from abuse.
10. **Raise Alerts** – Trigger alerts when break glass processes are invoked.
11. **Monitor Usage** – Alert when break glass credentials are used without initiating a break glass process.

## Store Break Glass Credentials

How are break glass credentials stored and accessed?

Passwords printed on paper and stored in a physical vault may work for manual entry, but SSH key pairs cannot be practically printed and retyped. Instead, consider storing credentials electronically on an encrypted external disk or USB drive. Test access to these devices regularly.

Use a local password vault (e.g., KeePass, 1Password) to store credentials securely. Consider storing a dedicated laptop in a physical safe with the vault software pre-installed and operational. Ensure the laptop OS and vault application are kept up to date. Rotate access credentials for both the vault and the laptop according to organizational policies.

## Accessing Break Glass Credentials

When accessing break glass credentials, will the user gain access to a single credential or multiple/all credentials? If all credentials are accessible (e.g., in KeePass), rotate all credentials after the event.

## Set and Rotate Break Glass Credentials

Credential changes should occur without a single user knowing the complete credentials. For manual password changes, consider split-key scenarios (e.g., 3 of 5 parts required). For SSH keys, define where keys are generated, how they are stored securely, and how public keys are distributed.

Always test and validate new credentials on endpoints. PAM can manage break glass accounts and validate credentials automatically, but this creates dependency. Ideally, PAM should provide an offline vault or export mechanism to a local vault. If unavailable, use PAM and vault APIs or CLI to create a secure script for syncing credentials.

Define in the break glass process:
- When credentials are changed.
- How changes are performed.
- How new credentials are tested and validated.
- How credentials are securely stored.

## Monitor Break Glass Credentials Usage

PAM solutions often record sessions for privileged access, but break glass accounts (categories 1 and 2) bypass PAM, eliminating session recording. Ensure servers and applications send login events or syslog messages to a SIEM solution. The SIEM should actively monitor and raise alerts when break glass credentials are used.

---

# PAM Admin Recovery of PAM (Category 1)

This scenario focuses on reactivating PAM services during disaster recovery. When PAM manages credentials and sessions, restoring PAM is critical. Evaluate **all** components required for PAM to function, including:
- PAM application and OS
- PAM database (if external)
- ESX server and hardware
- Network connectivity (switches)
- Supporting systems (Firewalls, AD, 2FA, DNS)

Ensure break glass credentials exist for the PAM application itself. The technical implementation depends on the PAM solution.

![Breakglass Scope](/Docs/BreakGlass-Scope.png)

---

# Break Glass for All Targets (Category 2)

This scenario represents a **Category 2 break glass situation**. Users obtain break glass credentials for a server or application and use them to establish a session from their desktop to the endpoint.

For both standalone and domain-joined servers and applications, consider creating a **dedicated break glass user**. This user account is managed through the break glass process. Depending on the nature of the outage triggering the break glass process, Active Directory validation may not be possible, so local break glass users should be considered.

Regardless of whether the break glass credential is for a local or domain user, it is essential to **test and validate firewall rules** to ensure connections from users’ desktops to endpoints are allowed. These rules may not exist permanently, but in a break glass scenario, they must be created or enabled to permit access.

It is strongly recommended to **change break glass credentials after they have been disclosed to a user**. The critical factor is not whether the credentials were used, but that a user had access to them. If all break glass credentials are stored in a local vault and a user potentially accessed them all, then all credentials should be rotated.

The process of changing break glass credentials can be manual, involving multiple audit points and separation of duties. Consider using PAM as a mechanism to rotate break glass credentials and export them to secure storage. For systems and applications where PAM cannot or should not manage break glass credentials, handle updates manually.

Regardless of the update method, it is crucial to **test and validate new credentials** as part of the sign-off process.


## Domain-Joined Credentials

For systems and applications using Active Directory (or LDAP) for authentication, assume PAM maintains passwords for privileged accounts and that only the PAM service is unavailable while the rest of the infrastructure remains operational.

In such cases, consider allowing an **Active Directory administrator** to change passwords for privileged accounts in AD for users requiring administrator access to servers or applications.

Although these accounts are managed by PAM, PAM is temporarily unavailable. Until PAM is restored, the user can use the privileged account directly and temporarily knows the password. When PAM becomes operational again, it should verify all managed credentials. If mismatches are detected, PAM should update credentials to align with its automation processes.

Even in a break glass scenario, the process of changing credentials must remain consistent with PAM’s automated workflows to ensure security and compliance.


---

# Using PAM as Break Glass Mechanism (Category 3)

This scenario represents a **Category 3 break glass situation**.

Assume PAM is highly redundant, making a complete outage negligible. Also assume administrators have their own personal administrative credentials for day-to-day operations.

If, for any reason, their personal privileged credentials fail, PAM can provide access to servers or applications using a break glass credential. In essence, PAM itself becomes the mechanism for break glass access to endpoints.

Such a setup requires a robust high-availability architecture and is typically combined with a break glass process for recovering PAM itself (Category 1).

During normal day-to-day administration, connections to servers and applications occur without PAM. Therefore, **audit logging and event monitoring** should be in place, as PAM session recording is not available for these activities. However, when performing a break glass session through PAM, **session recording should be enabled**, since the break glass account is likely a generic, non-personal user.

---

# Break Glass for Some PAM Solutions

This section describes a **Category 1 break glass scenario** for specific PAM solutions—how to restore PAM operation. There are many PAM solutions available commercially; the descriptions here are not endorsements or recommendations.

## BeyondTrust Password Safe

BeyondTrust Password Safe (PWS) includes built-in administrator accounts named **`btadmin`** and **`biadmin`** (names can be customized). Key details:

- **`btadmin`**: Appliance administrator for OS and appliance application. By default, this username is also used for OS login. Additional local administrators can be created at the OS level.
- **`biadmin`**: Application administrator.
- **`buadmin`**: Companion account required for appliance updates. While not essential for break glass, it must be available for PAM administrators.

All these accounts—**`btadmin`** (appliance and OS level) and **`biadmin`** (application level)—are local users and default administrators. At the appliance level, only one administrator exists, and new users cannot be created. At OS and application levels, multiple administrators can be added. These local accounts are considered break glass credentials.

Break glass credentials for underlying and supporting components must also be available. This includes, but is not limited to:
- ESX (vSphere/vCenter)
- ESX hardware (iLO)
- Network switches
- DNS

When changing passwords for PAM administrative accounts, validate that Password Safe remains fully functional. Update configurations for any components using these accounts if necessary.

## Symantec PAM

Symantec PAM is deployed as an appliance. Access to the operating system is restricted to Symantec Support and requires cooperation with a PAM administrator.

Symantec PAM provides two access levels:

- **Configuration-only access**: Connect to `https://<hostname>/config/` and log in as **`config`**. The default password is `config` and should be changed immediately. New users cannot be created for this level. The **`super`** user can be renamed.

- **Full access**: Connect to `https://<hostname>/` and log in as **`super`**. The default password is `super` and must be changed at first login. Local or domain users with full access permissions can be defined.

Cluster considerations:
- The **`config`** user is unique to each appliance; password changes are not synchronized across cluster members.
- The **`super`** user password is synchronized across cluster members.

Both **`config`** and **`super`** accounts are break glass credentials.

Advanced setup option:
- Deploy two independent PAM environments (not clustered) and configure each to manage the **`super`** account of the other. This creates mutual management, where each PAM system acts as a target for the other.

