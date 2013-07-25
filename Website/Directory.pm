package Website::Directory;

use strict;
use warnings;
use Data::Dumper;
use Cwd;
use Cwd 'abs_path';

sub ls;
sub unlist_nondirectories;
sub unlist_hidden_files;
sub unlist_excluded_files;
sub unlist_parent;
sub unlist_current;

# The ls function plans to duplicate the useful features of the UNIX command 'ls'
#   PARAMETERS:
#       'path' => 'path/to/dir' (defaults to current working directory if left blank(
#       'ls_dir_only' => 0 (If set to 0 then list all files. Otherwise list directories only)
#       @TODO 'ls_nondir_only' => implement this later. 
#       'exclude_files' => \%hash_ref of files to exclude. The stucture of the hash needs to be in the form of 'file_name' => 1 
#       'include_special' => 0 (If set to 0 then do not display special files such as hidden files and special directories. Otherwise do list the files. )
#   RETURN:
#       An array of file names. In the future convert this into an array of hashes. 
sub ls {
    my $args = {@_};
    
    #Change to proper directory
    my $prev_cwd = getcwd();
    chdir abs_path($args->{'path'});

    opendir my $directory, './' or die "Couldn't open the directory. $!";

    #my $directories = [map {-d $_ && !/^\.{1,2}$/ ? ($_) : (); } readdir($directory)];
    my $files = [map {$_} readdir($directory)];
    
    # Extract the directories only if needed. 
    if ($args->{'ls_dir_only'}) {
        #print "Listing only directories\n";
        $files = unlist_nondirectories('path' => $args->{'path'}, 'files' => $files);
    } 
    #If special_files is false then unlist all special files.  
    if (!$args->{'include_special'}) {
        #print "Listing non hidden files.\n";
        $files = unlist_special_files('files' => $files); 
    }
    #Remove the files we want to exclude. 
    if ($args->{'exclude_files'}) {
        #print "Unlisting unwanted files. \n";
        $files = unlist_excluded_files('exclude_files' => $args->{'exclude_files'}, 'files' => $files); 
    }
    closedir($directory); 

    chdir abs_path($prev_cwd);
    return $files;
}

# An internal function that lists out the directories in a path. 
#   PARAMETERS:
#       'path' => 'path/to/dir'
#       'files' => @filesarray in the directory. 
sub unlist_nondirectories {
    my %args = @_;
 
    #Change to proper directory
    my $prev_cwd = getcwd();
    chdir abs_path($args{'path'});

    #Get only files that are directories. 
    my $files = [map {-d $_ ? ($_) : (); } @{$args{'files'}}];

    chdir abs_path($prev_cwd);

    return $files;
}

# Removes any special files from a list of files. 
#   PARAMETERS:
#       'files' => @filesarray in the directory. 
sub unlist_special_files { 
    my %args = (@_); 

    return [map { !/^\.{1}.*?/ ? ($_) : (); } @{$args{'files'}}];
}

# Removes any files that match up with the blacklist name. 
#   PARAMETERS:
#       'exclude_files' => $hashoffiles to exclude.
#       'files' => @filesarray in the directory. 
sub unlist_excluded_files { 
    my %args = (@_);

    return [map { 
        !(${$args{'exclude_files'}}{$_}) ? ($_) : ();
        } @{$args{'files'}}];
}

return 1;




