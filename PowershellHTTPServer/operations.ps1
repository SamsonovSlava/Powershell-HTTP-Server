$Computername = $env:COMPUTERNAME
$ADSIComp = [adsi]"WinNT://$Computername"
 
function CreateAccount {
    param (
        [String]$login,
        [String]$firstName,
        [String]$lastName,
        [String]$title
    )
    try {
        $NewUser = $ADSIComp.Create("User", $login)
        #Create password
        # $Password = Read-Host -Prompt "Enter password for $Username" -AsSecureString
        $Password = "`123qwerdfadfadfadLKJLJ" | ConvertTo-SecureString -AsPlainText -Force
        $BSTR = [system.runtime.interopservices.marshal]::SecureStringToBSTR($Password)
        $_password = [system.runtime.interopservices.marshal]::PtrToStringAuto($BSTR)
        #Set password on account
        $r = $NewUser.SetPassword(($_password))
        $r = $NewUser.put("FullName", "$firstName $lastName")
        $r = $NewUser.put("Description", $title)
        $r = $NewUser.SetInfo()
        $result = @{
            "ErrorCode" = 0;
        }
    }
    catch {
        $result = @{
            "ErrorCode" = 1;
            "ErrorDescr" = $_.Exception.Message;
        }
    }

    return $result
}
 
function DeleteAccount {
    param (
        [String]$login
    )
    try {
        $r = $ADSIComp.Delete('User', $login)
        $result = @{
            "ErrorCode" = 0;
        }
    }
    catch {
        $result = @{
            "ErrorCode" = 1;
            "ErrorDescr" = $_.Exception.Message;
        }
    }
    return $result
}
 
function SuspendAccount {
    param (
        [String]$login
    )
    $Disabled = 0x0002
    $newuser = [adsi]"WinNT://$Computername/$login"
    try {
        if ([boolean]($newuser.UserFlags.value -BAND $Disabled) -ne $true) {
            $newuser.userflags.value = $newuser.UserFlags.value -BOR $Disabled
        }
        $r = $newuser.SetInfo()
        $result = @{"ErrorCode" = 0;}
    }
    catch {
        $result = @{
            "ErrorCode" = 1;
            "ErrorDescr" = $_.Exception.Message;
        }
    }
    return $result
}
 
function RestoreAccount {
    param (
        [String]$login
    )
    $Enabled = 0x0002
    $newuser = [adsi]"WinNT://$Computername/$login"
    try {
        if ([boolean]($newuser.UserFlags.value -BAND $Enabled) -eq $true) {
            $newuser.userflags.value = $newuser.UserFlags.value -BXOR $Enabled
        }
        $r = $NewUser.SetInfo()
        $result = @{"ErrorCode" = 0;}
    }
    catch {
        $result = @{
            "ErrorCode" = 1;
            "ErrorDescr" = $_.Exception.Message;
        }
    }
    return $result
}
 
function ModifyAccount {
    param (
        [String]$login,
        [String]$firstName,
        [String]$lastName,
        [String]$title
    )
    try {
        $newuser = [adsi]"WinNT://$Computername/$login"
        $r = $NewUser.put("FullName", "$firstName $lastName")
        $r = $NewUser.put("Description", $title)
        $r = $NewUser.SetInfo()
        $result = @{
            "ErrorCode" = 0;
        }
    }
    catch {
        $result = @{
            "ErrorCode" = 1;
            "ErrorDescr" = $_.Exception.Message;
        }
    }
    return $result
}
 
function ChangePassword {
    param (
        [String]$login,
        [String]$newPassword
    )
    try {
        $newuser = [adsi]"WinNT://$Computername/$login"
        $Password = $newPassword | ConvertTo-SecureString -AsPlainText -Force
        $BSTR = [system.runtime.interopservices.marshal]::SecureStringToBSTR($Password)
        $_password = [system.runtime.interopservices.marshal]::PtrToStringAuto($BSTR)
        #Set password on account
        $r = $NewUser.SetPassword(($_password))
        $r = $NewUser.SetInfo()
        $result = @{
            "ErrorCode" = 0;
        }
    }
    catch {
        $result = @{
            "ErrorCode" = 1;
            "ErrorDescr" = $_.Exception.Message;
        }
    }
    return $result
}
 
function GetAccountByLogin {
    param (
        [String]$login
    )
    try {
        $newuser = [adsi]"WinNT://$Computername/$login"
        $fullName = $newuser.get("FullName")
        $title = $newuser.get("description")
        $result = @{
            "ErrorCode" = 0;
            "fullName" = $fullName;
            "title" = $title;
        }
    }
    catch {
        $result = @{
            "ErrorCode" = 1;
            "ErrorDescr" = $_.Exception.Message;
        }
    }
    return $result
}
 
# $result = CreateAccount -login "sasm111222" -firstName "¬¤чеслав" -lastName "—амсонов" -title "старший инженер"
 
# $result
# Write-Host $result.ErrorCode $result.ErrorDescr
 
# DeleteAccount -login "sam2"
# SuspendAccount -login "sam1"
# RestoreAccount -login "sam1"
# ModifyAccount -login "sam1" -firstName "new fn" -lastName "new ln" -title "nt"
# ChangePassword -login "sam1" -newPassword "KJHKH786786jgjgjhg@"
# $result = GetAccountByLogin -login "sam"
# Write-Host $result[0] $result[1]