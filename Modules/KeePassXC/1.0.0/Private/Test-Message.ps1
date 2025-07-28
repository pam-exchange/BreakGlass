function Test-Message () {
    Param(
        $msg
    )

    # Write-Host "$($PSCmdlet.MyInvocation.MyCommand.Name): $msg"

    if ($msg.GetType().Name -eq "Object[]") {
        $msg= $msg[-1]
    }

    if ($msg.GetType().Name -eq "String") {
        $msg= $msg.replace("Enter password for new entry: ","")
        $msg= $msg.replace("Enter new password for entry: ","")
    }
    else {
        $msg= $msg.ToString()
    }


    switch -Regex ($msg) {

    'Successfully' 
        {
            #
            # Successfully...
            #	
            return $true
        }

    'Group .* not found' 
        {
            #
            # cmd: rmdir 
            # 
            # Group BreakGlass2 not found.
            #
            throw ( New-Object KeePassXCException( $EXCEPTION_NOT_FOUND, $msg))
        }

    'Group .* already exists'
        {
            #
            # cmd: mkdir
            #
            # Group BreakGlass already exists!
            #
            throw ( New-Object KeePassXCException( $EXCEPTION_DUPLICATE, $msg))
        }

    'Cannot find group'
        {
            #
            # cmd: ls 
            #
            # Cannot find group BreakGlass2.
            #
            throw ( New-Object KeePassXCException( $EXCEPTION_NOT_FOUND, $msg))
        }

    'Could not find entry with path'
        {
            #
            # cmd: show
            #
            # Could not find entry with path xxx
            #
            throw ( New-Object KeePassXCException( $EXCEPTION_NOT_FOUND, $msg))
        }

    'Could not create entry with path'
        {
            #
            # cmd: add
            #
            # Could not create entry with path BreakGlass/Server01.
            # Duplicate or invalid group
            #
            throw ( New-Object KeePassXCException( $EXCEPTION_DUPLICATE, $msg))
        }
    

    'Missing positional argument'
        {
            #
            # cmd: mkdir without group
            #
            # Error: Missing positional argument(s).
            #
            throw ( New-Object KeePassXCException( $EXCEPTION_INVALID_PARAMETER, $msg ) )		
	    }

    'database file may be corrupt' 
    {
            #
            # cmd: <any>
            #
            # Incorrect Master password
            #
            throw ( New-Object KeePassXCException( $EXCEPTION_NOT_AUTHORIZED, $msg ) )		
    }

    'Invalid credentials were provided'
        {
            #
            # cmd: <any>
            #
            # Wrong MasterPassword for database
            #
            # Error while reading the database: Invalid credentials were provided. Please try again.
            #
            throw ( New-Object KeePassXCException( $EXCEPTION_NOT_AUTHORIZED, $msg ) )		
	    }

    'Failed to load key file'
        {
            #
            # cmd: <any>
            # 
            # Keyfile not found (valid path)
            #
            # Error: Failed to load key file c:\tmp\Passwords2.keyfile: The system cannot find the file specified.
            #
            throw ( New-Object KeePassXCException( $EXCEPTION_NOT_FOUND, $msg) )		
	    }

    'Loading the key file failed'
        {
            #
            # cmd: <any>
            # 
            # Keyfile not found (invalid path)
            #
            # Error: Loading the key file failed
            #
            throw ( New-Object KeePassXCException( $EXCEPTION_INVALID_PARAMETER, $msg) )		
	    }

    'Failed to open database file'
        {
            #
            # cmd: <any>
            #
            # Database is not found
            #
            # Error: Failed to open database file c:\tmp\Passwords2.kdbx: not found
            #
            throw ( New-Object KeePassXCException( $EXCEPTION_NOT_FOUND, $msg) )
	    }

        
    'The system cannot find the path specified'
        {
            #
            # Create databse with invalid path
            #
            throw ( New-Object KeePassXCException( $EXCEPTION_INVALID_PARAMETER, $msg ) )
        }

    'Not a KeePass database'
        {
            #
            # cmd: <any>
            #
            # Database file is not KeePassXC file format
            #
            # Error while reading the database: Not a KeePass database.
            #
            throw ( New-Object KeePassXCException( $EXCEPTION_INVALID_FORMAT, $msg ) )
	    }

    default 
        {
            throw ( New-Object KeePassXCException( $EXCEPTION_GENERIC_ERROR, $msg) )
        }
    }

}
