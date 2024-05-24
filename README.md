# Set-DummyAD.ps1

> /!\ THIS SCRIPT IS FOR A TEST/LAB ENVIRONMENT /!\

See warnings below

# Context

During my sysadmin formation I wanted to have a script to populate an Active Directory with dummy content.
So here is a `.ps1` script to install the ADDS roles on the server it's run, and if it's already done it will populate the AD with dummy content. 

The content generated comes from the `model.json` (structure of the AD), and the `1000names.csv` (user names).
- It follows some best practices (GGS, DLGS), and some design I find clean (everything what's not `Microsoft BuiltIn` in a `_ROOT` OU)
- It will install/generate:
    - ADDS roles if not already installed
    - OUs (from `model.json`, all OUs under a RootOU)
    - Groups (for each departments)
    - random Users from `1000users.csv` (SAM, Upn, Display name, Description, Department, Group memberships, Managers)
        - Managers
        - Users
    - Shared folders for each departments 
        - Dept. Managers -> FullControl
        - Dept. Users -> RW

# Usage

1. On a windows server (tested on 2022)
2. `Set-executionPolicy -ExectionPolicy RemoteSigned` (or `Unrestricted` ¯\\\_(ツ)\_/¯, this is a lab...)
3. Download & extract release `.zip` file 
4. cd into the `set-DummyAd` folder
5. `.\set-DummyAD.ps1`

# Warning 

- All the users will have `Test1234=` as their password. (defined in model.json)  
- If ADDS role is installed with this script the DSRM password is also `Test1234=` (uses the same password in model.json)
- This script is not for a production environment but a for a quick setup of an AD lab.

# Limitations

...

# Refs 

- [MCG](https://www.mcg.be/en)
- [Technobel](https://www.technobel.be/fr/)
