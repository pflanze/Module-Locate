require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Module::Locate',
    VERSION_FROM   => 'lib/Module/Locate.pm',
    AUTHOR         => 'Dan Brook <cpan@broquaint.com>',
    PREREQ_PM      => {
                          'strict'                => 0,
                          'IO::File'              => 0,
                          'overload'              => 0,
                          'Carp'                  => 0,
                          'File::Spec::Functions' => 0,
                      },
    BUILD_REQUIRES => {
                          'Test::More'            => 0,
                      },

    META_MERGE => {
        resources => {
            repository => 'https://github.com/neilbowers/Module-Locate',
        },
    },

);
