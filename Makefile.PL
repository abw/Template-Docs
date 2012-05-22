use strict;
use warnings;
use FindBin qw( $Bin );
use File::Spec;
use ExtUtils::MakeMaker;

my %opts = (
    'NAME'           => 'Template-Docs',
    'VERSION'        => 0.02,
    'PMLIBDIRS'      => [ 'lib' ], 
    'PREREQ_PM'      => {
        'Badger'     => 0.09,
        'Template'   => 2.24,
        'Pod::POM'   => 0.15,
        'Text::Wrap' => 2001,
        'Template::Plugin::YAML' => 1.22,
    },
    'dist'           => {
        'COMPRESS'   => 'gzip',
        'SUFFIX'     => 'gz',
    },
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR   } = 'Andy Wardley <abw@wardley.org>';
    $opts{ ABSTRACT } = 'Template Toolkit HTML Documentation',
}

WriteMakefile( %opts );

#------------------------------------------------------------------------
# figure out where we are in the filesytem and define some relative paths
#------------------------------------------------------------------------

my $root   = $Bin;
my $etc    = File::Spec->catdir($root, 'etc');
my $bin    = File::Spec->catdir($root, 'bin');
my $meta   = File::Spec->catfile($root, 'metadata');
my $images = File::Spec->catfile($root, 'images');
my $html   = File::Spec->catfile($root, 'html');
my $config = File::Spec->catfile($etc, 'ttree.cfg');
my $httpd  = File::Spec->catfile($etc, 'httpd.conf');
my $build  = File::Spec->catfile($bin, 'build');

local *FH;

print STDERR "Generating $build build script\n";
open(FH, ">$build") || die "Cannot open $build: $!\n";
print FH <<EOF;
#!/bin/bash
#------------------------------------------------------------------------
# This script builds the HTML version of the documentation by calling out
# to ttree to process the HTML in 'templates/src', adding headers, 
# footers and other bits and pieces from 'templates/lib' and writing the 
# final output to the 'html' directory.
#
# WARNING: 
#  This script is generated when you run 'perl Makefile.PL'.  Any 
#  changes made here may be lost!
# 
# Written by Andy Wardley.  May 2006, updated May 2012.
#------------------------------------------------------------------------

ttree -f $config \$\@
echo
echo "Copying images into HTML directory"
cp -r $images $html
EOF
close(FH) || die "Cannot close $build: $!\n";
chmod 0755, $build;


print STDERR "Generating $config configuration file\n";
open(FH, ">$config") || die "Cannot open $config: $!\n";
print FH <<EOF;

#------------------------------------------------------------------------
# This is the ttree configuration file for building the documentation.
# It tells ttree to process all the HTML page templates in the 
# 'templates/pages' directory, adding headers, footers and other bits 
# and pieces from 'templates/library'.  The generated output os written
# to the 'html' directory.
#
# Use the bin/build script to build the site.  This invokes ttree 
# with the -f option which points it to this configuration file.
#
# Written by Andy Wardley.  May 2006, updated April 2007.
#
# WARNING:
#  This configuration file is generated when you run 
# 'perl Makefile.PL'.  Any changes made here may be lost!
# 
#------------------------------------------------------------------------

# source directory containing page templates
src = $root/templates/pages

# things to ignore when scanning the above directory
ignore  = (CVS|RCS|\.svn)
ignore  = ^#
ignore  = ~\$

# library directory containing reusable template components
lib = $root/templates/library

# destination directory for generated HTML pages
dest = $root/html

# specify dependency file
# depend_file = $root/etc/ttree.dep

# define variables pointing to the root and metadata directories
define rootdir = $root
define metadir = $meta

# directory containing additional Perl modules
perl5lib = $root/lib

# additional module path for our custom TT plugins
plugin_base = Template::Docs::Plugin

# configuration template which is pre-processed before each page template
pre_process = config/main

# wrapper template which is added around the generated page output
wrapper = site/wrapper

# general ttree processing flags
recursion     # allow templates to call themselves recursively
recurse       # recurse into sub-directories
verbose       # show what's going on

# uncomment the next line to enable debugging messages
# define debug = 1 

EOF
close(FH) || die "Cannot close $config: $!\n";


print STDERR "Generating $httpd configuration file\n";
open(FH, ">$httpd") || die "Cannot open $httpd: $!\n";
print FH <<EOF;
#------------------------------------------------------------------------
# This is the Apache configuration file for the Template Toolkit 
# documentation.  It points Apache to the right locations for the 
# HTML pages and images.
#
# You can include it into your main Apache httpd.conf file like this:
#
#     Include $httpd
#
# Written by Andy Wardley.  May 2007.
#
# WARNING:
#  This configuration file is generated when you run 
# 'perl Makefile.PL'.  Any changes made here may be lost!
# 
#------------------------------------------------------------------------

DocumentRoot              $root/html/
Alias          /images/   $root/images/

<Directory $root/html/>
    Options MultiViews Indexes FollowSymLinks
    AllowOverride None
    Order allow,deny
    Allow from all
</Directory>

<Directory $root/images/>
    Options Indexes
    AllowOverride None
    Order allow,deny
    Allow from all
</Directory>
EOF
close(FH) || die "Cannot close $httpd: $!\n";

__END__

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:


