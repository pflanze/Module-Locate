use Module::Build;

Module::Build->new(
  module_name => 'Module::Locate',
  license     => 'perl',

  requires    => {
             'perl'                  => '5.6.1',
             'File::Spec::Functions' => 0,
             'IO::File'              => 0,
             'Carp'                  => 0,
  },
)->create_build_script;
