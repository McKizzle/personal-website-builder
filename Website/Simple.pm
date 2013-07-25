package Website::Simple;

use warnings;
use strict;
use Cwd;
use Cwd 'abs_path';

$Website::Simple::tag_file_ext = 'tgs';

#sub markdown_for_category_tags;
#sub markdown_for_markdown_without_meta_tags;
sub slurp_markdown_documents;
sub markdown_split_title;
sub slurp_tags;
#sub markdown_for_meta_tags;

# Load all of the .md documents for each website. Extract the meta tags from each markdown document.
#   PARAMETERS:
#       'path' => a string that contains the path to the root directory of the website. 
#       'dirs' => an array reference of the directories to slurp up markdown documents. 
# 
# @RETURN all of the markdown documents as a hash reference that contains the markdown text and the
#   extracted <meta> info. 
sub slurp_markdown_documents {
    use File::Slurp; 

    my %args = (@_);
    
    #Change the cwd to the desired 'root' folder. 
    my $prev_cwd = getcwd();
    chdir abs_path($args{'path'});

    my $documents = {};
    for(@{$args{'dirs'}}) {
        my $markdown = read_file("$_/$_.md");

        my $document = {
            'computer_abs_path'    => getcwd()."/$_",
            'webserver_abs_path'    => "/$_/",
            'file_name'         => "$_",
            'content'           => $markdown
        };

        $documents->{$_} = $document;
    }
    
    #Revert to original cwd. 
    chdir abs_path($prev_cwd);
    
    return $documents;
}

# Load all of the .md documents for each website. Extract the meta tags from each markdown document.
#   PARAMETERS:
#       'path' => a string that contains the path to the root directory of the website. 
#       'dirs' => an array reference of the directories to slurp up markdown documents. 
# 
# @RETURN return all of the tags associated with each directory aka each markdown document.   
sub slurp_tags {
    use File::Slurp; 

    my %args = (@_);
    
    #Change the cwd to the desired 'root' folder. 
    my $prev_cwd = getcwd();
    chdir abs_path($args{'path'});

    my $set_of_tags = {};
    my $tag_file_ext = $Website::Simple::tag_file_ext;
    for(@{$args{'dirs'}}) {
         my $tags = read_file("$_/tags.$Website::Simple::tag_file_ext"); 
         chomp $tags;
         $set_of_tags->{$_} = [split ',', $tags];
         $set_of_tags->{$_} = [map {$_ =~ s/^\s*//; $_ =~ s/\s*$//; $_} @{$set_of_tags->{$_}}];
    }
    
    #Revert to original cwd. 
    chdir abs_path($prev_cwd);
    
    return $set_of_tags;
}

# Takes in the hashes produced by slurp_markdown_documents and slurp_tags and merges them together by finding
# the matching keys in both hashes. Once keys are matched then it takes the tags and adds them to the tags key 
# for each sub-hash. 
#   @param the hash produced by slurp_markdown_documents.
#   @param the hash produced by slurp_tags.
#
#   @return the two hashes properly merged. The slurp_tags hash is going to be merged into the documents hash.
sub merge_tags_with_documents {
    my $docs = shift;
    my $tags = shift;

    foreach my $foldername (keys $tags) {
        $docs->{$foldername}->{'tags'} = $tags->{$foldername};
    }
}


# This function takes a set of markdown documents and splits out the titles. (not really sure if  that is the
# proper way to state it.)
#   @param hash reference to a set of slurped markdown documents. (expects a hash that has been outputted by 
#   slurp_markdown_documents)
#
#   @return a hash reference that contains all of the markdown documents with the titles and content seperated. 
sub split_titles_from_markdown {
    my $documents_hr = shift;
    
    # Iterate through each document and extract the title. 
    foreach my $doc_name (keys %$documents_hr) {
        my $document = $documents_hr->{$doc_name};
        while ($document->{'content'} =~ /(^#{1}\s*.*?\n)/gmi) {
            $document->{'title'} = $1;
            
            #Now remove the title from the content of the markdown. 

            $document->{'content'} =~ s/$1//gmi;
            last;
        }
    }

    return $documents_hr;
}

# This function takes in markdown and converts it to html. 
#   @param the markdown text to convert.  
#
#   @return the html conversion.
sub markdown_to_html {
    my $markdown = shift;

    my $temporary_file = "/tmp/markdown.tmp";

    local *FH;
    open (FH, ">$temporary_file") or die "Cannot open temporary file: $!\n";

    print FH $markdown;

    my $html = `pandoc $temporary_file`;
    
    close FH;

    return $html;
}

return 1;

__END__

SCRAP

# This function takes in markdown text finds meta tags and extracts the 'categories information
# a hash => array reference is returned. 
sub markdown_for_category_tags {
    my $markdown = shift; 
    
    my $tags = [];
    while ($markdown =~ /<meta\s+name=["]\s*categories\s*["]\s*content=["]([a-zA-Z,\s]+?)["]>/gmi) {
       push @$tags, map { $_ =~ s/^\s*//; $_ =~ s/\s*$//; $_} split(',', $1);
    }
    return $tags;
}

#Remove the meta tags from markdown text. 
sub markdown_for_markdown_without_meta_tags {
    my $markdown = shift; 
    $markdown =~ s/<meta\s+name=["]\s*categories\s*["]\s*content=["]([a-zA-Z,\s]+?)["]>//gmi;

    return $markdown;
}

# Extracts the meta tags from the markdown text. 
sub markdown_for_meta_tags {
    my $markdown = shift; 
    
    my $tags = '';
    while ($markdown =~ /(<meta\s+name=["]\s*categories\s*["]\s*content=["]([a-zA-Z,\s]+?)["]>)/gmi) {
       $tags .= "$1\n";
    }
    return $tags;  
}


