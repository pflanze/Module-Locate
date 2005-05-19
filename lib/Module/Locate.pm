{
  package Module::Locate;

  $VERSION  = 1.6;
  $Cache    = 0;
  $Global   = 1;

  $ident_re = qr{[_a-z]\w*}i;
  $sep_re   = qr{'|::};
  $PkgRe    = qr{\A(?:$ident_re(?:$sep_re$ident_re)*)\z};

  @All      = qw(
    locate get_source acts_like_fh
    is_mod_loaded is_pkg_loaded
  );

  sub import {
    my $pkg = caller;
    my @args = @_[ 1 .. $#_ ];
    
    while(local $_ = shift @args) {
      *{ "$pkg\::$_" } = \&$_ and next
        if defined &$_;

      $Cache = shift @args, next
        if /^cache$/i;

      $Global = shift @args, next
        if /^global$/i;

      if(/^:all$/i) {
        *{ "$pkg\::$_" } = \&$_
          for @All;
        next;
      }

      warnings::warn("not in ".__PACKAGE__." import list: '$_'");
    }
  }

  use strict;
  use warnings;
  use warnings::register;

  use IO::File;
  use overload ();
  use Carp 'croak';
  use File::Spec::Functions 'catfile';
  
  sub get_source {
    my $pkg = $_[-1];

    my $f = locate($pkg);

    my $fh = ( acts_like_fh($f) ?
      $f
    :
      do { my $tmp = IO::File->new($f)
             or croak("invalid module '$pkg' [$f] - $!"); $tmp }
    );

    local $/;
    return <$fh>;
  }

  sub locate {
    my $pkg = $_[-1];

    croak("Null filename used")
      unless defined $pkg;
    croak("Invalid package name '$pkg'")
      unless $pkg =~ $Module::Locate::PkgRe;

    my($file, @dirs) = reverse split '::' => $pkg;
    my $path = catfile reverse(@dirs), "$file.pm";

    return $INC{$path}
      if   ( $Module::Locate::Cache and $Module::Locate::Global )
         and is_mod_loaded($path);

    my @paths;

    for(@INC) {
      if(ref $_) {
        my $ret = coderefs_in_INC($_, $path);

        next
          unless defined $ret;

        croak("invalid \@INC subroutine return $ret")
          unless acts_like_fh($ret);

        return $ret;
      }

      push @paths => catfile($_, $path)
        if -f catfile($_, $path);
    }

    return unless @paths > 0;

    $INC{$path} = $paths[0]
      if $Module::Locate::Global;

    return wantarray ? @paths : $INC{$path};
  }

  sub coderefs_in_INC {
    my($path, $c) = reverse @_;

    my $ret = ref($c) eq 'CODE' ?
      $c->( $c, $path )
    :
      ref($c) eq 'ARRAY' ?
        $c->[0]->( $c, $path )
      :
        UNIVERSAL::can($c, 'INC') ?
          $c->INC( $path )
        :
          warnings::warn("invalid reference in \@INC '$c'")
    ;

    return $ret;
  }

  sub acts_like_fh {
    no strict 'refs';
    return ( ref $_[0] and (
         ( ref $_[0] eq 'GLOB' and defined *{$_[0]}{IO} )
      or ( UNIVERSAL::isa($_[0], 'IO::Handle')          )
      or ( overload::Method($_[0], '<>')                )
    ) or ref \$_[0] eq 'GLOB' and defined *{$_[0]}{IO}  );
  }

  sub is_mod_loaded {
    my $mod  = shift;
    
    croak("Invalid package name '$mod'")
      unless $mod =~ $Module::Locate::PkgRe;
    
    ## it looks like %INC entries automagically use / as a separator
    my $path = join '/', split '::' => "$mod.pm";

    return exists $INC{$path} and defined $INC{$path};
  }

  sub is_pkg_loaded {
    my $pkg = shift;

    croak("Invalid package name '$pkg'")
      unless $pkg =~ $Module::Locate::PkgRe;

    my @tbls = map "${_}::", split('::' => $pkg);
    my $tbl  = \%main::;
    
    for(@tbls) {
      return unless exists $tbl->{$_};
      $tbl = $tbl->{$_};
    }
    
    return !!$pkg;
  }
}

q[ That better be make-up, and it better be good ];

=pod

=head1 NAME

Module::Locate - locate modules in the same fashion as C<require> and C<use>

=head1 SYNOPSIS

  use Module::Locate qw/ locate get_source /;

  plugin( locate "This::Module" );
  munge(  get_source "Another::Module::Here" );
  
  if(locate "Some::Module") {
    ## do stuff
  }

=head1 DESCRIPTION

Using C<locate()>, return the path that C<require> would find for a given
module (it can also return a filehandle if a reference in C<@INC> has been
used). This means you can test for the existence, or find the path for, modules
without having to evaluate the code they contain.

=head1 FUNCTIONS

=over 4

=item C<import>

Given function names, the appropriate functions will be exported into the
caller's package.

If C<:all> is passed then all subroutines are exported.

If C<Global =E<gt> BOOL> is passed, then the results for module
searches i.e using C<locate>, will also be stored in C<%INC>, like
C<require>. This is B<on> by default.

If C<Cache =E<gt> BOOL> is passed, then every subsequent search for a module
will just use the path stored in C<%INC>, as opposed to performing another
search. This is B<off> by default.

=item C<locate>

Given a module name as a string (in standard perl bareword format) locate the
path of the module. If called in a scalar context the first path found will be
returned, if called in a list context a list of paths where the module was
found. Also, if references have been placed in C<@INC> then a filehandle will
be returned, as defined in the C<require> documentation. An empty C<return> is
used if the module couldn't be located.

=item C<get_source>

When provided with a package name, retrieve the source of the module that is
found.

=item C<acts_like_fh>

Given a scalar, check if it behaves like a filehandle. Firstly it checks if it
is a bareword filehandle, then if it inherits from C<IO::Handle> and lastly if
it overloads the C<E<lt>E<gt>> operator. If this is missing any other standard
filehandle behaviour, please send me an e-mail.

=item C<is_mod_loaded>

Given a module (like C<locate()>), return true if the module has been loaded
(i.e exists in the C<%INC> hash).

=item C<is_pkg_loaded>

Given a package name (like C<locate()>), check if the package has an existing
symbol table loaded (checks by walking the C<%main::> stash).

=back

=head1 Changes

=over 4

=item 1.6

=over 8

=item *

fixed failing Win32 tests (thanks barbie!)

=back

=item 1.5

=over 8

=item *

added the ubiquitous C<Makefile.PL> (thanks C<Module::Build>!)

=back

=item 1.4

=over 8

=item *

now backward compatible with 5.00503

=back

=item 1.3

=over 8

=item *

Tidied up POD.

=item *

C<acts_like_fh()> now tests plain globs i.e C<*FH>

=back

=item 1.2

=over 8

=item *

No longer C<croak()>s when C<locate()> fails to find the module (which is much
nicer and is consistent with the documentation).

=item *

C<Build.PL> should now play nice with C<CPAN> installs

=back

=item 1.1

=over 8

=item *

fixed C<$PkgRe> to be functional

=item *

added C<is_mod_loaded()> and C<is_pkg_loaded()> functions

=item *

added ':all' C<import()> option

=item *

hopefully fixed b0rken CPAN make process ...

=back

=item 1.0

=over 8

=item *

Initial release

=back

=back

=head1 AUTHOR

Dan Brook C<< <cpan@broquaint.com> >>

=head1 SEE ALSO

L<perl>, C<use>, C<require>

=cut
