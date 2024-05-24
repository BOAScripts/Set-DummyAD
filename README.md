# Set-DummyAD.ps1

> /!\ THIS SCRIPT IS FOR A TEST/LAB ENVIRONMENT /!\

See warnings below

# Context

During my sysadmin formation I wanted to have a script to populate an Active Directory with dummy content.
So here is a `.ps1` script to install the ADDS roles, and if it's already done it will populate the AD with dummy content. 

The content generated comes from the `model.json` (structure of the AD), and the `1000names.csv` (user names).
- It follows some best practices (GGS, DLGS), and some design I find clean (everything what's not `Microsoft BuiltIn` in a `_ROOT` OU)
- It will install/generate:
    - ADDS roles if not already installed
    - OUs (from `model.json`, all OUs under a RootOU)
    - 1 OU per department in the `Users` OU
    - Groups (for each departments)
    - Random Users from `1000users.csv` (SAM, Upn, Display name, Description, Department, Group memberships, Managers)
        - Managers
        - Users
    - Shared folders for each departments 
        - Dept. Managers -> RW
        - Dept. Users -> RO

# Usage

1. On a windows server (tested on 2022)
2. `Set-executionPolicy -ExectionPolicy RemoteSigned` - if necessary
3. Download & extract release `.zip` file 
4. cd into the downloaded folder
5. Review `model.json`
6. `.\set-DummyAD.ps1`

# Warning 

- All the users will have `Test1234=` as their password. (defined in model.json)  
- If ADDS role is installed with this script the DSRM password is also `Test1234=` (uses the same password in model.json)
- This script is not for a production environment but a for a quick setup of an AD lab.

# Limitations

## Customize the user number generation

The provided .csv file is populated with a 1000 user names. If you try to customize this list or the `ManagersPerDept` and `UsersPerDept` value in the model.json. Make sure there is enough data to populate the departments

> ($ManagersPerDept + $UsersPerDept) * $nbrOfDepts > $nbrOfUsersInCSV

- eg (provided value in model.json):
- (1 + 10) * 7 > 1000
- 77 > 1000 => this is OK
    - eg (customized values in model.json)
    - (20 + 200) * 7 > 1000
    -  1540 > 1000 => this is NOT ok

## Customize the OUs

You can customize the OUs but:
- My script can't go deeper (:sadge:) than 2 level 
    - eg: "Computers/Servers" => OK
    - eg: "Computers/Server/001" => NOK
- Make sure you define the parent OU BEFORE the child OU in the list. Or the child OU generation will throw an error because the parent doesn't exist.

# Thanks to 

- [MCG](https://www.mcg.be/en)
- [Technobel](https://www.technobel.be/fr/)
