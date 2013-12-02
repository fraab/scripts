LanguageTool
============

A script that download automatically the zip version of LanguageTool. It adds shortcuts to the desktop and provides alias for the long original commands.

Usage
-----

    langtool [server | gui | cmd] [LanguageTool Options]
    langtool [-h | --help]
    langtool install [version]
    langtool uninstall

__OPTIONS:__

        -h | --help		Print this help and exit

__COMMANDS:__

   [server | gui | cmd] [LanguageTool Options]
    
         Parse [LanguageTool Options] to either the server, the standalone
         or the comamndline java executable of LanguageTool. If you do not
         specify one, the cmd command is used. Use --help in the
         [LanguageTool Options] part to see the usage text of the
         individual executables.
		
   install [version]
    
         Install LanguageTool to /opt, add script to
         /usr/local/bin and make shortcuts. If you do not specify a special
         version (e.g 1.8, 1.9, 2.1, 2.2, 2.3, ...) the last stable
         version is used.
    		
   uninstall
    
         Uninstall all files mentioned in the install command exept this
         script. Delete the script in /usr/local/bin yourself if you want.

   upgrade [version]
    
         An uninstall with a folloing install.