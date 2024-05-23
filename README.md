# Set-DummyAD.ps1

# Context

During my sysadmin formation I wanted to have a script to populate an Active Directory with dummy content.
So here is a `.ps1` script to install the ADDS roles on the server it's run, and if it's already done it will popule the AD with dummy content. 

The content generated comes from the `model.json` (structure of the AD), and the `1000names.csv` for the user names.

# Usage

# Warning 

> /!\ IT'S MEANT TO USE IN A TEST/LAB ENVIRONMENT /!\

All the users will have `Test1234=` for their password.
This script is not for a production environment but a for a quick setup of an AD lab.

# Limitations

# Refs 
