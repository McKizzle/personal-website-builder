use warnings;
use strict;

# Use the script's directory as one of the library paths.
use FindBin '$Bin'; #returns path of script. 
use lib $Bin; 

use Data::Dumper;
use HTML::Template;
use Getopt::Long; #To input stuff. 
use File::Slurp;
use Cwd;
use Website::Directory;
use Website::Simple;

#~~~~~~~~~~~~~~~~~~~~~ GET ARGUMENTS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my $args = { 
    'path' => ''
};

GetOptions('p|path=s' => \$args->{'path'});

my $constants = {
    'master_dir'                => 'website_components',
    'master_template_file'      => 'master_template.htmltp',
    'master_template_css_files' => ['master_template.csstp'],
    'website_title'             => 'website_title.md',
    'page_navigation'           => 'page_navigation.md',
    'folder_name_is_page_name'  => 0
};

#print Dumper $constants;

#Folders to avoid when iterating through the website markdown documents and generating the website. 
my $reserved_folders = {
    'website_components'    => 1, 
}; 

#Extract all of the website content directories.  
my $dirs = Website::Directory::ls('path' => $args->{'path'}, 'ls_dir_only' => 1, 'exclude_files' => $reserved_folders, 'include_special' => 0);
my $docs = Website::Simple::slurp_markdown_documents('path' => $args->{'path'}, 'dirs' => $dirs);
my $tags = Website::Simple::slurp_tags('path' => $args->{'path'}, 'dirs' => $dirs);

# Now lets merge the tags to their respective documenets in the docs hash.
Website::Simple::merge_tags_with_documents $docs, $tags;

# Now lets split the document titles from the markdown.  
$docs = Website::Simple::split_titles_from_markdown($docs);

# Now that the user generated documents have been loaded. Lets begin loading the template items.
# my $html = Website::Simple::markdown_to_html(${$docs->{'AboutMe'}}{'content'});

#load the master template for later use. 
my $master_template = HTML::Template->new(filename => "$args->{'path'}/$constants->{'master_dir'}/$constants->{'master_template_file'}");
my $website_title = read_file("$args->{'path'}/$constants->{'master_dir'}/$constants->{'website_title'}");
$website_title = Website::Simple::markdown_to_html($website_title);
my $page_navigation = read_file("$args->{'path'}/$constants->{'master_dir'}/$constants->{'page_navigation'}");
$page_navigation = Website::Simple::markdown_to_html($page_navigation);

#print Dumper $website_title, $page_navigation;

#Convert all of the documents to html and write them to html files. 
# while doing that also build a tag index. 
#print Dumper $docs;
my %tags_to_docs =();
for(keys $docs) {
    my %document = %{$docs->{$_}};

    my $fn = (!$constants->{'folder_name_is_page_name'}) ? 'index' : $document{'file_name'};

    $document{'title'} = Website::Simple::markdown_to_html($document{'title'});
    $document{'content'} = Website::Simple::markdown_to_html($document{'content'});

    $master_template->param('page_content' => $document{'content'});
    $master_template->param('page_navigation' => $page_navigation);
    $master_template->param('page_css_links' => "<link href=\'$fn.css\' rel=\'stylesheet\' type=\'text/css\'>");
    $master_template->param('page_title' => $document{'title'});
    $master_template->param('website_title' => $website_title);

    local *FH;
    open (FH, ">$document{'computer_abs_path'}/$fn.html") or die "Cannot open temporary file: $!\n";

    print FH $master_template->output();

    close FH;

    #now copy the css styles over to their respective folders. 
    my $cp_results = `cp $args->{'path'}/$constants->{'master_dir'}/${$constants->{'master_template_css_files'}}[0] $document{'computer_abs_path'}/$fn.css`;

    #Now add this document name to the tags_to_docs hash. 
    my $doc_key = $_;
    for(@{$document{'tags'}}) {
        if($tags_to_docs{$_}) {
            push @{$tags_to_docs{$_}}, $doc_key;
        }
        else {
            $tags_to_docs{$_} = [$doc_key];
        }
    }
    $master_template->clear_params();
}
#print Dumper \%tags_to_docs;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Now lets go through and build the index page for the website.
my %index_doc = (
    'title' => Website::Simple::markdown_to_html("# Index"),
    'content' => ""
);
foreach my $tag (sort {$a cmp $b } (keys %tags_to_docs)) {
    my $content_addition = "\n\n## $tag\n";
 
    foreach my $doc_key (@{$tags_to_docs{$tag}}) {
        my %document = %{$docs->{$doc_key}};
        my $fn = (!$constants->{'folder_name_is_page_name'}) ? 'index' : $document{'file_name'};
        $fn .= ".html";
        
        my $doc_title = $document{'title'};
        $doc_title =~ s/^#\s*//;
        $doc_title =~ s/\s*$//; 
        
        $content_addition .= "- [$doc_title]($doc_key/$fn \"$doc_title\")\n";
    }

    $index_doc{'content'} .= $content_addition;
}
#print $index_doc{'content'}."\n\n";
$index_doc{'content'} = Website::Simple::markdown_to_html($index_doc{'content'});
#print $index_doc{'content'}."\n\n";

my $fn = 'index';
$master_template->param('page_content' => $index_doc{'content'});
$master_template->param('page_navigation' => $page_navigation);
$master_template->param('page_css_links' => "<link href=\'$fn.css\' rel=\'stylesheet\' type=\'text/css\'>");
$master_template->param('page_title' => $index_doc{'title'});
$master_template->param('website_title' => $website_title);


local *FH;
open (FH, ">$args->{'path'}/$fn.html") or die "Cannot open temporary file: $!\n";

print FH $master_template->output();

close FH;
$master_template->clear_params();


#now copy the css styles over to their respective folders. 
my $cp_results = `cp $args->{'path'}/$constants->{'master_dir'}/${$constants->{'master_template_css_files'}}[0] $fn.css`;


#$, = ", ";
#print $master_template->param();
#print Dumper $html;


__END__

#TODO Tools needed. 
#   2. A function that generates an master index page based off of the folders and their tags. 


#TODO List of requirements
# 1. the 'website-components' will contain the components for the master template of the website. 
# 2. the index page will be the default home page. (aka there is a reserved 'Index' folder name. This cannot be used!! 
#   a. The index page will be built using the set of folders and tags. 
# 3. If a folder has a htmltp or csstp then override the master tp. But it must contain teh same components. 

# The css styles to import into the document. 
my $styles_to_use = ['website_components/master_template.csstp', 'website_components/master_template.csstp', 'website_components/master_template.csstp', 'website_components/master_template.csstp'];

my $page_css_links = undef; 
$page_css_links = join "\n", map {"<link href=\'$_\' rel=\'stylesheet\' type=\'text/css\'>"} @$styles_to_use;

#Now get the website title
my $website_title = "<h2> www.crmckay.com </h2>";

#Now get the navigatoin section of the website. 
my $page_navigation = `pandoc website_components/navigation.md`;

#First parse the markdown into html with pandoc. 
#print $website_navigation;

my $page_title = "<h1> Empty <h1>\n";
my $page_content = "Nuthin to say\n";

$template->param(website_title => $website_title);
$template->param(page_css_links => $page_css_links);
$template->param(page_navigation => $page_navigation);
$template->param(page_title => $page_title);
$template->param(page_content => $page_content);

#Write the content
print $template->output;

__END__ TESTING SCRAP
$, = ", "; #seperate items with comments in print statement.

print "Listing directories only while excluding certain files.\n";
my $listing = Directory::ls('path'=>$args->{'path'}, 'ls_dir_only'=>1, 'exclude_files'=>$reserved_folders, 'include_special'=>1);
print @$listing; print "\n----------------\n";


print "Listing directories only while excluding certain files. Also remove special directories.\n";
$listing = Directory::ls('path'=>$args->{'path'}, 'ls_dir_only'=>1, 'exclude_files'=>$reserved_folders, 'include_special'=>0);
print @$listing; print "\n----------------\n";

print "Exclude certain files only.\n";
$listing = Directory::ls('path'=>$args->{'path'}, 'ls_dir_only'=>0, 'exclude_files'=>$reserved_folders, 'include_special'=>1);
print @$listing; print "\n----------------\n";

print "List all files except for special files and excluded files.\n";
$listing = Directory::ls('path'=>$args->{'path'}, 'ls_dir_only'=>0, 'exclude_files'=>$reserved_folders, 'include_special'=>0);
print @$listing; print "\n----------------\n";


print "List all files.\n";
$listing = Directory::ls('path'=>$args->{'path'}, 'ls_dir_only'=>0, 'include_special'=>1);
print @$listing; print "\n----------------\n";
