function Resolve-RoomScaleRoomInput {
	param(
		[Parameter(Mandatory = $true)][string]$Value,
		[Parameter(Mandatory = $true)][string]$ProjectRoot
	)

	$root = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
	$roomDirectory = [System.IO.Path]::GetFullPath((Join-Path $root 'rooms'))
	$inputValue = $Value.Trim()
	if ($inputValue -match '^[A-Za-z0-9][A-Za-z0-9_-]*$') {
		$roomId = $inputValue
		$file = [System.IO.Path]::GetFullPath((Join-Path $roomDirectory "$roomId.json"))
		if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
			throw "Room ID '$roomId' does not name an existing JSON file in rooms/."
		}
		return [pscustomobject]@{ RoomId = $roomId; File = $file; IsExplicitFile = $false }
	}

	if ([System.IO.Path]::IsPathRooted($inputValue)) {
		$file = [System.IO.Path]::GetFullPath($inputValue)
	} else {
		$file = [System.IO.Path]::GetFullPath((Join-Path $root $inputValue))
	}
	$rootPrefix = $root + [System.IO.Path]::DirectorySeparatorChar
	if (-not $file.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
		throw 'A RoomDefinition file must be inside the project directory.'
	}
	if ([System.IO.Path]::GetExtension($file) -ne '.json' -or -not (Test-Path -LiteralPath $file -PathType Leaf)) {
		throw "Room input must be an existing .json RoomDefinition file inside the project directory: $inputValue"
	}
	$roomId = [System.IO.Path]::GetFileNameWithoutExtension($file)
	if ($roomId -notmatch '^[A-Za-z0-9][A-Za-z0-9_-]*$') {
		throw 'A RoomDefinition filename must use letters, digits, underscores, or hyphens.'
	}
	return [pscustomobject]@{ RoomId = $roomId; File = $file; IsExplicitFile = $true }
}
