enum Ensure {
  Absent
  Present
}

[DscResource()]
class RenameBuiltinAccount {
  [DscProperty(Key)]
  [ValidateSet("Administrator", "Guest")]
  [string]$Username

  [DscProperty(Mandatory)]
  [Ensure] $Ensure

  [DscProperty(Mandatory)]
  [string] $NewUsername

  # [DscProperty(NotConfigurable)]
  # [Nullable[datetime]] $CreationTime

  [void] Set() {
    Write-Verbose "Renaming $($this.Username) Account"
    Rename-LocalUser -Name $this.Username -NewName $this.NewUsername
  }

  [bool] Test() {
    Write-Verbose "Getting $($this.Username) account"
    $account = Get-LocalUser -Name $this.Username -ErrorAction SilentlyContinue

    if ($account) {
      Write-Verbose "$($this.Username) Account exists"
      return $false
    }
    Else {
      Write-Verbose "$($this.Username) Account does not exist"
      return $true
    }
  }

  [RenameBuiltinAccount] Get() {
    $account = Get-LocalUser -Name $this.Username -ErrorAction SilentlyContinue
    $ensureReturn = If ($account) { 'Present' } Else { 'Absent' }
    return @{
      Username    = $this.Username
      Ensure      = $ensureReturn
      NewUsername = $this.NewUsername
    }
  }
}