# Windows-remote-code
Token size walk around to execute remote code for windows devices

This powershell script creates a new AD Account, add it to a list of Microsoft based OS in administrators local group by using PSEXEC, and use it to execute remote code with powershell, it is usefull in case local admins have token size issue ad temp account is removed after code is executed.

Psexec is is part of systernal tools and can be downloaded from:

https://docs.microsoft.com/en-us/sysinternals/downloads/psexec
