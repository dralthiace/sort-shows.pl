#!/usr/bin/perl -w -U
use File::Copy::Recursive;
use File::Find;

### sort-shows.pl
###
### Version: 1.3
###
### Author: Brian Conklin (dralthiace@yahoo.com)
###
### This script will query the directory set below (DOWNLOAD_DIR) for any
### files that look like movies or tv shows.  The files will then be
### renamed and moved to the respective vieo directory. After all files
### are moved/renamed, the script will tell XMBC to update its video library.
###
###  Details:
###
### IDENTIFICATION:
### TV Shows are identified if they have the S##E## notation (season/episode)
### Movies are identified if they contain any of the following keywords:
###   dvdrip xvid divx h264 x264
### and have an avi or mkv extension.  Subtitle files (sub/srt) are moved also.
###
### MOVE:
### Files are moved to the directory specified below (TVSHOWS_DIR or MOVIES_DIR)
### TV Shows are moved to:
###   TVSHOWS_DIR/{show_name}/{show_name} - {season}/{file}
### Movies are moved to:
###   MOVIES_DIR/{file}
###
### RENAME:
### TV Show file names are normalized to be recognized by XBMC:
###   special characters are removed
###   capitalization changed to first character of each word
###   extra whitespace removed
###   spaces are converted to periods (.)
###   rest of name (after S##E##) is left alone (this can contain useful info)
### Movies are not renamed, only moved.


#############################
### CHANGE THESE!

# URL of your XBMC http interface
$XBMC_URL = "http://xbmc:xbmc\@10.0.1.12:8080";

# Local directory where your movies/shows download to
# This directory will be checked for new content each time
# the script is run. (do not add trailing slash)
$DOWNLOAD_DIR = '/Downloads';

# Local directory where movies/shows should be moved to.
# (do not add trailing slash)
$TVSHOWS_DIR = '/Videos/TV Shows';
$MOVIES_DIR = '/Videos/Movies';

# Run the script at an interval using cron. This example will check for new
# shows every 10 minutes and log the output of the script to /var/log.
#
# These 2 lines should be put on one line in your crontab -e
# */10 * * * * /usr/local/bin/sort-downloaded-shows.pl
#                                         >> /var/log/sort-downloaded-shows.log

#############################



### Don't change these
###Required for taint mode (no longer used)
#$ENV{"PATH"} = "";

###Turn off stdout buffering
$| = 1;

### Collect list of downloaded files (not recursive)
#commented and replace with a recursive solution below
#@files = <$DOWNLOAD_DIR/*>;
my @files;
find ( {wanted => sub {
	#return if ($File::Find::name =~ m/\.(?:Partial|Saved|/);
	return if -d;
	push @files, $File::Find::name;
     },
        #these lines used taint mode to ignore hidden directories, but
	#they caused many warnings and issues so I disabled taint mode
	untaint => 1,
	untaint_pattern => qr|^([^.].+)$|,
	untaint_skip => 1,
	}, $DOWNLOAD_DIR );

$movedFiles = 0;

foreach $fullpath (@files) {
  #commented out in order to allow 720p videos
  #if( $fullpath =~ m/([-._ \w]+)[-._ ]S(\d{1,2})E(\d{1,2})[-._ ](?!720p)(.*)$/i ) {
  if( $fullpath =~ m/([-._ \w]+)[-._ ]S(\d{1,2})E(\d{1,2})[-._ ](.*\.avi)$/i ) {

	### Get Season number, turn to variable, then create a padded string
	### for output later.
	$season = $2;  $season += 0;  $padSeason = sprintf("%02d", $season);

	### Get Episode number, turn to variable, then create a padded string
	### for output later.
	$episode = $3;  $episode += 0; $padEpisode = sprintf("%02d", $episode);

	### Rest of file name, after show name, season, and episode numbers.
	$restOfFile = $4;

	### Get show name, change special characters to spaces.
	### Then change to lower case.
	### Then capitalize first letter of each word.
	$showname = $1;  $showname =~ s/[-._]/ /g ;
	$showname = lc($showname);
	$showname = join ' ', map { ucfirst($_) } split '\s', $showname;
	$showname =~ s/The Office Us/The Office/;

	### Not needed (gets original file name sans path)
	#$fullpath =~ m/\/([^\/]*)$/ ;
	#$origFilename = $1;

	### Convert spaces to periods (for file name later)
	$fileShowname = $showname;
	$fileShowname =~ s/\s/\./g ;

	### Change name of directory for some shows.  This is so XBMC
	### will recognize these shows when scrapping their info off
	### of thetvdb.org
	### Further exceptions can be added here as needed.
	$dirShowname = $showname;
	$dirShowname =~ s/Battlestar Galactica/Battlestar Galactica \(2003\)/;
	$dirShowname =~ s/The Office/The Office \(US\)/;

	### Delete any odd spaceing between episode number and episode title.
	$restOfFile =~ s/^- //;

	### Generate a destination file name from data parsed above.
	$destinationPath = "$TVSHOWS_DIR/" . $dirShowname . "/" . $showname . " - Season " . $season;
	$destinationFile = "" . $destinationPath . "/" . $fileShowname . ".S" . $padSeason . "E" . $padEpisode . "." . $restOfFile;

	print "Moving " . $fullpath . " to " . $destinationFile . "...";


	### Create the new directory tree if needed
	File::Copy::Recursive::pathmk( '' . $destinationPath ) or die "\nFailed to create destination directory: " . $destinationPath . ".\n";

	### Move the files to their new organized directory structure.
	### This function created directories as needed.
	### (Switch from fmove to fcopy for testing)
	#File::Copy::Recursive::fmove( $fullpath, $destinationFile ) or die "\nFailed to move " . $fullpath . " to " . $destinationFile . ".\n";

	$destinationFile_escaped = $destinationFile;
	$destinationFile_escaped =~ s/ /\\ /g;
	$destinationFile_escaped =~ s/\(/\\\(/g;
	$destinationFile_escaped =~ s/\)/\\\)/g;
	$destinationFile_escaped =~ s/\'/\\\'/g;
	$fullpath_escaped = $fullpath;
	$fullpath_escaped =~ s/ /\\ /g;
	$fullpath_escaped =~ s/\(/\\\(/g;
	$fullpath_escaped =~ s/\)/\\\)/g;
	$fullpath_escaped =~ s/\'/\\\'/g;
	system( "/bin/mv " . $fullpath_escaped . " " . $destinationFile_escaped ) == 0 or print "\nFailed to move " . $fullpath . " to " . $destinationFile . ".\n";
	wait();


	
	print "Succeeded.\n";

	$movedFiles = $movedFiles + 1;

	### For Debugging
	#print $destinationFile . "\n";
	#print $fileShowname . "\n";
	#print $padSeason . "\n";
	#print $showname . "\n";
	#print $season . "\n";
	#print $filename . "\n";
	#print $restOfFile . "\n";
	#print $fullpath . "\n";

  ### That was for TV Shows, this is for Movies
  } elsif( $fullpath =~ m/(?:dvdrip|xvid|divx|h264|x264)(.*)(?:\.avi|\.mkv|\.sub|\.srt)$/i ) {
	if( $fullpath !~ m/sample/i ) {
		$destinationFile = "$MOVIES_DIR/";
		$fullpath_escaped = $fullpath;
		$fullpath_escaped =~ s/ /\\ /g;
		$fullpath_escaped =~ s/\(/\\\(/g;
		$fullpath_escaped =~ s/\)/\\\)/g;
		print "Moving " . $fullpath . " to " . $destinationFile . "...";
		system( "/bin/mv " . $fullpath_escaped . " " . $destinationFile ) == 0 or print "\nFailed to move " . $fullpath . " to " . $destinationFile . ".\n";
		wait();

		print "Succeeded.\n";

		$movedFiles = $movedFiles + 1;
	}
  }
} 

if( $movedFiles >= 1 ) {
	print "Updateing library.\n";
	#Update the library on XBMC remotely via webservice
	system( "/usr/bin/wget -O /dev/null \"$XBMC_URL/xbmcCmds/xbmcHttp?command=ExecBuiltIn&parameter=XBMC.updatelibrary(video)\" 2>/dev/null 1>/dev/null" );
	wait();
}
