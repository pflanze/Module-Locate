use Module::Build;

## get around b0rken CPAN
exec("$^X Build.PL && ./Build")
  if $ARGV[-1] eq 'Build';

Module::Build->new(
  module_name => 'Module::Locate',
  license     => 'perl',

  requires    => {
             'perl'                  => '5.005_03',
             'File::Spec::Functions' => 0,
             'IO::File'              => 0,
             'Carp'                  => 0,
  },
  create_makefile_pl => 'passthrough',
)->create_build_script;
