<#
.SYNOPSIS Importar ACL en SQL. Autor: Ariel De Salvo Propato.
.DESCRIPTION Script creado para importar los datos de las ACL de varios File Servers en un servidor SQL.
.NOTES Se debe contar con los nombres de los servidores que contienen los recursos compartidos y un motor de base de datos para realizar los Insert. 
.COMPONENT PowerShell - SQL DB. 
.Parameter Tabla Especificar la tabla donde se deben insertar las ACLs.
.Parameter Path Ruta del recurso compartido.
.Parameter Owner Atributo especifico de la ACL.
.Parameter FileSystemRights Atributo especifico de la ACL.
.Parameter AccessControlType Atributo especifico de la ACL.
.Parameter IdentityReference Atributo especifico de la ACL.
.Parameter IsInherited  Atributo especifico de la ACL. 
#>

#Función para insertar en la base de datos
#Modificar el INSERT INTO con la ruta correspondiente
function insert {
param($Tabla,$Path,$Owner,$FileSystemRights,$AccessControlType,$IdentityReference,$IsInherited)

$dataSource = ""
$user = ""
$pass = ""
$database = ""

$connectionString = “Server=$dataSource;uid=$user; pwd=$pass;Database=$database;Integrated Security=True;”

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()
$query = "INSERT INTO $($Tabla) ([Path],[Owner],[FileSystemRights],[AccessControlType],[IdentityReference],[IsInherited]) VALUES('$Path','$Owner','$FileSystemRights','$AccessControlType','$IdentityReference','$IsInherited')"
$command = $connection.CreateCommand()
$command.CommandText = $query
$command.executenonquery()
$connection.Close()
}

#Función para eliminar los datos en la base de datos
#Modificar el TRUNCATE TABLE con la ruta correspondiente
#Solo es necesario utilizar en caso de no contar con espacio o de no querer acumular.
function truncate {
param($Tabla)

$dataSource = ""
$user = ""
$pass = ""
$database = ""

$connectionString = “Server=$dataSource;uid=$user; pwd=$pass;Database=$database;Integrated Security=True;”

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()
$query = "TRUNCATE TABLE $($Tabla)"
$command = $connection.CreateCommand()
$command.CommandText = $query
$command.executenonquery()
$connection.Close()
}

#Declarar los nombres de los File Servers que se deben analizar.
$Servers = @(""
            ,""
            )

foreach($SRV in $Servers){
    #En caso de estar en un dominio, utilizar el FQDN.
    $NAS = $SRV+'dominio.com.ar'
    
    try
    {
        $Shares = Get-WmiObject -class Win32_Share -computer $NAS
    }catch{Write-Host "Error en el Get-WmiObject" -ForegroundColor Red}
    
    $BD = 'NAS_'+$($SRV)+'_LOG'
    truncate -Base $BD
    foreach ($itemShare in $Shares.Name){
        $Path = '\\'+$($NAS)+'\'+$($itemShare)
        try
        {
            $Acl = Get-ChildItem -Path $Path | Get-Acl
        }catch{Write-Host "Error en el Get-Acl" -ForegroundColor Red}
        foreach ($item in $Acl){
            foreach ($itemAccess in $item.Access){
                try
                   {
                       insert -Base $BD -Path $item.Path.Replace('Microsoft.PowerShell.Core\FileSystem::','') -Owner $item.Owner -FileSystemRights $itemAccess.FileSystemRights -AccessControlType $itemAccess.AccessControlType -IdentityReference $itemAccess.IdentityReference -IsInherited $itemAccess.IsInherited
                   }catch{Write-Host "Error en el instert" -ForegroundColor Yellow}
            }
        }
    }
}