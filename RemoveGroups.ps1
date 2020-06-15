<#
.SYNOPSIS Quita todos los grupos de un usuario. Autor: Ariel De Salvo Propato.
.DESCRIPTION Script creado para quitar todos los grupos de un usuario, contemplando que estos le dan permisos sobre aplicaciones o recursos.
.NOTES Se debe especificar en el "if" que grupos no se deben quitar. 
.COMPONENT PowerShell - Modulo de Active Directory. 
.Parameter DN Distinguished Name: utilizar para limitar a que usuarios debe aplicar.
#>

Import-Module ActiveDirectory

$DN = ""

$collection = Get-ADUser -Filter * | Where-Object{$_.DistinguishedName -like '*'+$DN}

foreach ($U in $collection.Name)
{
    try{
        $MemberOf= Get-ADUser -Identity $U -Properties * | Select-Object MemberOf
       }catch{Write-Host "No se pudo obtener el usuario: $($U)" -ForegroundColor Red}
    
       $Grupos = $MemberOf.MemberOf | Get-ADGroup | Select-Object Name

    foreach ($G in $Grupos.Name)
    {
        if($G -notlike 'Domain Users')
        {
            try{
                Remove-ADGroupMember -Identity $G -Members $U -Confirm:$false -Verbose
               }catch{Write-Host "No se pudo quitar el grupo: $($G) del usuario: $($U)" -ForegroundColor Red}             
        }
    }
}