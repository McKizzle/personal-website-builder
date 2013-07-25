# Installed Components
This application was built and tested using Perl 5.18. I used perlbrew to setup my environment. 

## Modules Needed
A list of modules the will need to be installed on CPAN. Run ``perl -MCPAN -e shell`` instead. It is guaranteed to run CPAN for the correct version of Perl. 

  * File::chdir
  * HTML::Template

# Execution

## UNIX and Linux
To run this script type

~~~~~~~~~~~~~~~~~~~~~~~~
perl build-website.pl -p path/to/root/directory/of/website/
~~~~~~~~~~~~~~~~~~~~~~~~

# Website Directory Setup. 
To create a website the website folder must obey the following rules. 

  1. First it needs to have a ``website_components`` folder. 
  2. The ``website_components`` folder must have a master html template file. It must also include a master css file. 
  3. Each page must have it's own directory. The directory needs to contain the following files.  
    a. ``DirectoryName.md``
    b. ``tags.tgs``
    c. The ``DirectoryName.md`` is a markdown file. The program finds the first title line and uses it for the title of the document.  
    e. The directory name will also be the name of the html document. 

# TODO 
  - Still not very customizable. Fix this. 
  - Allow custom templates per page. 
  - Allow the program to recursively traverse the website folder.  


