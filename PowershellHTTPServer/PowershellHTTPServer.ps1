[Int] $Port = 8888
 
[String] $Url = ""
       
[System.Net.AuthenticationSchemes] $Auth = [System.Net.AuthenticationSchemes]::IntegratedWindowsAuthentication
clear
 
# Подключаем библиотеку функций работы с сервисом. Dot sourcing.
. .\\operations.ps1
 
function ConvertTo-Json20([object] $item){
    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer
    return $ps_js.Serialize($item)
}
 
function ConvertFrom-Json20([object] $item){
    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer
 
    #The comma operator is the array construction operator in PowerShell
    return ,$ps_js.DeserializeObject($item)
}
 
function ConvertTo-XML2([object] $hash) {
    $result = "
        <Objects>
            <Object>
                $(foreach ($kvpair in $hash.GetEnumerator()) {
                    "`n    <$($kvpair.Key)>$($kvpair.Value)</$($kvpair.Key)>"
                })
            </Object>
        </Objects>
    "
    return $result
}
 
$listener = New-Object System.Net.HttpListener
 
$prefix = "http://*:$Port/$Url"
$listener.Prefixes.Add($prefix)
 
# $listener.AuthenticationSchemes = $Auth
try {
    $listener.Start()
    Write-Host "Listening on $port..."
    while ($true) {
        $statusCode = 200
        $context = $listener.GetContext()
        $request = $context.Request
 
        # Обнуляем переменные чтобы их значения не передавались на следующий запрос
        $parameters = @{}
        $result = @{}
        $xmlData = [xml]
       
        # Если получен POST-запрос
        if($request.HasEntityBody) {
            $enc = [system.text.encoding]::UTF8
            $Reader = New-Object System.IO.StreamReader($request.InputStream, $enc)
            $data = $Reader.ReadToEnd()
            # Проверяем, что получен именно XML-запрос
            try {
                $xmlData = [xml]$data
            }
            catch {
                write-Host "[Error translating post request to XML object.]"
            }
            $parameters["command"] = $xmlData.DocRoot.Entry.command
            $parameters["login"] = $xmlData.DocRoot.Entry.uid
            $parameters["firstName"] = $xmlData.DocRoot.Entry.givenName
            $parameters["lastName"] = $xmlData.DocRoot.Entry.sn
            $parameters["title"] = $xmlData.DocRoot.Entry.title        
        }
        Write-Host "[Recieved request]:"
        $parameters
 
        $requestCommand = $parameters["command"]
        switch ($requestCommand) {
            "exit" {
                exit;
            }
            "create" {
                $login = $parameters["login"]
                $firstName = $parameters["firstName"]
                $lastName = $parameters["lastName"]
                $title = $parameters["title"]
                Write-Host "-----------------------------------------------------------------------------------------------------------------"
                write-Host "[Starting create account $login...]"
                $result = CreateAccount -login $login -firstName $firstName -lastName $lastName -title $title
                $ErrorCode = $result.ErrorCode
                $ErrorDescription = $result.ErrorDescr
                if ($ErrorCode -eq 0) {
                    Write-Host "Account created successfuly."
                } else {
                    Write-Host "Error: Can't create account $login. $ErrorDescription"
                }
                Write-Host "-----------------------------------------------------------------------------------------------------------------"
            }
            "delete" {
                $login = $parameters["login"]
                Write-Host "-----------------------------------------------------------------------------------------------------------------"
                write-Host "[Starting delete account $login...]"
                $result = DeleteAccount -login $login
                $ErrorCode = $result.ErrorCode
                $ErrorDescription = $result.ErrorDescr
                if ($ErrorCode -eq 0) {
                    Write-Host "Account deleted successfuly."
                } else {
                    Write-Host "Error: Can't delete account $login." $result.ErrorDescr
                }
                Write-Host "-----------------------------------------------------------------------------------------------------------------"
            }          
            "suspend" {
                $login = $parameters["login"]
                write-Host "[Starting suspend account $login...]"
                $result = SuspendAccount -login $login
                $ErrorCode = $result.ErrorCode
                $ErrorDescription = $result.ErrorDescr
                if ($ErrorCode -eq 0) {
                    Write-Host "Account suspended successfuly."
                } else {
                    Write-Host "Error: Can't suspend account $login. $ErrorDescription"
                }
                Write-Host "-----------------------------------------------------------------------------------------------------------------"
            }
            "restore" {
                $login = $parameters["login"]
                Write-Host "-----------------------------------------------------------------------------------------------------------------"
                write-Host "[Starting restore account $login...]"
                $result = RestoreAccount -login $login
                $ErrorCode = $result.ErrorCode
                $ErrorDescription = $result.ErrorDescr
                if ($ErrorCode -eq 0) {
                    Write-Host "Account restored successfuly."
                } else {
                    Write-Host "Error: Can't restore account $login." $ErrorDescription
                }
                Write-Host "-----------------------------------------------------------------------------------------------------------------"
            }          
            "modify" {
                $login = $parameters["login"]
                Write-Host "-----------------------------------------------------------------------------------------------------------------"
                write-Host "[Starting modification account $login...]"
                $firstName = $parameters["firstName"]
                $lastName = $parameters["lastName"]
                $title = $parameters["title"]
                $result = ModifyAccount -login $login -firstName $firstName -lastName $lastName -title $title
                $ErrorCode = $result.ErrorCode
                $ErrorDescription = $result.ErrorDescr
                if ($ErrorCode -eq 0) {
                    Write-Host "Account modified successfuly."
                } else {
                    Write-Host "Error: Can't modify account $login." $ErrorDescription
                }
                Write-Host "-----------------------------------------------------------------------------------------------------------------"
            }
            "changepassword" {
                $login = $parameters["login"]
                $newPwd = $parameters["newPassword"]
                Write-Host "-----------------------------------------------------------------------------------------------------------------"             
                write-Host "[Starting changepassword for account $login...]"
                $result = ChangePassword -login $login -newPassword $newPwd
                $ErrorCode = $result.ErrorCode
                $ErrorDescription = $result.ErrorDescr
                if ($ErrorCode -eq 0) {
                    Write-Host "Password changed successfuly."
                } else {
                    Write-Host "Error: Can't change password for account $login." $ErrorDescription
                }
                Write-Host "-----------------------------------------------------------------------------------------------------------------"             
            }
            "find" {
                Write-Host "-----------------------------------------------------------------------------------------------------------------" 
                $login = $parameters["login"]
                write-Host "[Searchin account $login...]"
                $result = GetAccountByLogin -login $login
                $ErrorCode = $result.ErrorCode
                $ErrorDescription = $result.ErrorDescr
                if ($ErrorCode -eq 0) {
                    Write-Host "Account found successfuly."
                } else {
                    Write-Host "Error: Can't find account $login." $ErrorDescription
                }
                Write-Host "-----------------------------------------------------------------------------------------------------------------"             
            }
        }
       
        # Преобразуем результат вызова метода в нужный формат XML или JSON
        #$xml = $result | ConvertTo-XML -NoTypeInformation
        #$commandOutput = $xml.OuterXml
        # $commandOutput = ConvertTo-Json20($result)
        $commandOutput = ConvertTo-XML2($result)
       
        $response = $context.Response
 
        $response.ContentType = "text/xml; charset=UTF-8"
        $response.ContentEncoding = [system.text.encoding]::utf8
       
        $response.StatusCode = $statusCode
 
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($commandOutput)
        # $buffer = [System.Text.Encoding]::GetEncoding(1251).GetBytes($commandOutput)
        $response.ContentLength64 = $buffer.Length
        $output = $response.OutputStream
        $output.Write($buffer,0,$buffer.Length)
        $output.Close()
   }
}
finally {
    $listener.Stop()
}