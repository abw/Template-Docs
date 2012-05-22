use Badger
    Filesystem => 'Bin VFS',
    Rainbow    => [ANSI => 'red green yellow cyan'];
use ExtUtils::MakeMaker;
use Template;


#-----------------------------------------------------------------------------
# Generate the Makefile for the sake of completeness
#-----------------------------------------------------------------------------

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
# Process all the templates in templates/project to create project files
# that contain system-dependent paths, e.g. bin/build, etc/ttree.conf, etc.
#------------------------------------------------------------------------

print "Processing templates to generate project files\n";

my $root = Bin;
my $src  = $root->dir('templates', 'project');
my $vars = {
    root_dir    => $root,
    config_dir  => $root->dir('etc'),
    meta_dir    => $root->dir('metadata'),
    images_dir  => $root->dir('images'),
    html_dir    => $root->dir('html'),
};

my $tt = Template->new(
    INCLUDE_PATH => $src->absolute,
    OUTPUT_PATH  => $root->absolute,
    VARIABLES    => $vars,
);

my $files = $src->collect(
    files   => 1,
    dirs    => 0,
    in_dirs => 1,
);
my ($file, $path, $dest);

foreach $file (@$files) {
    # TT2 likes relative paths
    $path = $file->absolute;
    $path =~ s{^$src/}{};

    # process template and save output in corresponding file
    $tt->process($path, undef, $path)
        || die red("TT error processing $path: " . $tt->error());

    print STDERR green(" + $path\n");

    # give output file same permissions as input file
    $root->file($path)->chmod(
        $file->perms
    );
}

