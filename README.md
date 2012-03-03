Info
----
**sort-shows.pl**  
Version: 1.3  
Author: Brian Conklin (dralthiace@yahoo.com)

This script will query the directory set below (DOWNLOAD_DIR) for any
files that look like movies or tv shows.  The files will then be
renamed and moved to the respective vieo directory. After all files
are moved/renamed, the script will tell XMBC to update its video library.

Details
-------

###IDENTIFICATION

TV Shows are identified if they have the S##E## notation (season/episode)
Movies are identified if they contain any of the following keywords:
  `dvdrip xvid divx h264 x264`
and have an avi or mkv extension.  Subtitle files (sub/srt) are moved also.

###MOVE

Files are moved to the directory specified below (TVSHOWS_DIR or MOVIES_DIR)
TV Shows are moved to:  
  `TVSHOWS_DIR/{show_name}/{show_name} - {season}/{file}`  
Movies are moved to:  
  `MOVIES_DIR/{file}`

###RENAME

TV Show file names are normalized to be recognized by XBMC:

* special characters are removed
* capitalization changed to first character of each word
* extra whitespace removed
* spaces are converted to periods (.)
* rest of name (after S##E##) is left alone (this can contain useful info)

Movies are not renamed, only moved.
