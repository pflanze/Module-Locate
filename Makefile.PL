require 5.005;

use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    NAME           => 'Module::Locate',
    VERSION_FROM   => 'lib/Module/Locate.pm',
    AUTHOR         => 'Dan Brook <cpan@broquaint.com>',
    LICENSE        => 'perl',
    PREREQ_PM      => {
                          'strict'                => 0,
                          'warnings'              => 0,
                          'IO::File'              => 0,
                          'overload'              => 0,
                          'Carp'                  => 0,
                          'File::Spec::Functions' => 0,
                      },
    BUILD_REQUIRES => {
                          'Test::More'            => 0,
                      },

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => '5.8.8')
        : ()
    ),

    META_MERGE => {
        resources => {
            repository => 'https://github.com/neilbowers/Module-Locate',
        },
    },

);
