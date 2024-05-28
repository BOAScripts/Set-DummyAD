# Powershell structure
- Param usage ? (install-adds or populate-ad)
- Function usage

# Share path definition
- Define Shares container drive/Path as a variable
- Better define Shares container name variable
- Better variable naming 
- Enable DFS ? [Efficient DFS Management with PowerShell Scripts](https://adamtheautomator.com/dfs-powershell-scripts/)

# Custom OUs
[ ] Should be able to go deeper. (loop through each `/`).  
[x] Array of arrays ? Instead of array of strings.  
[x] Groups and Users entries not defined in CustomOUs but in another variable? As they are important in the creation of the structure.

# Password management
- Instead of one main password, generate/export a random password per user.
    - psw protect the exported file, or something else? 
- Variables for `Change password at logon`, `User can change psw`, and `psw never expires`
- Password policy modification? (+ groups assign.)

# Users / Depts
- Internal >< External sub OUs with distinct roles / psw policy ? 
- Account expiration mgmt
- Names sanitization (I have those functions... why not using them?)
- Instead of random stupid desc. why not an array of possible roles per Dept ?

# Production ready ?
- What would this script needs to be used in a prod env.?
    - Is there even a demand for creating users in batch in an on-prem AD? There are batch imports but those should fit the current state/structure of the target AD.
    - Entra ID portage ?

# Groups 
- 1 GGS for all managers



