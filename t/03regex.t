use Test::More 'no_plan';

use strict;

use Module::Locate;

my %pkgs = qw[
  A 1
  0a 0
  foo 1
  f@o 0
  f-o 0
  
  foo:: 0
  foo::bar 1
  foo::0a 1
  foo::bar::baz::quux 1
  
  foo' 0
  foo'bar 1
  foo'0a 1
  foo'bar'baz'quux 1
];

my $res;
print "\n";

for(keys %pkgs) {
  $res = $_ =~ $Module::Locate::PkgRe ? 1 : 0;
  ok( $res == $pkgs{$_}, "new[$res]: $_" );
}
