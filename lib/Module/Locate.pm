{
  package Module::Locate;

  $VERSION  = 1.0;
  $Cache    = 0;
  $Global   = 1;
  $PkgRe    = qr{ \A [_a-zA-Z]
                  (?:
                   (?: \w* )
                   (?:
                    (?: '|:: )
                    (?: \w+ )
                   )?
                  )* \z }x;

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

      warnings::warnif("not in ".__PACKAGE__." import list: '$_'");
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
      if     ( $Module::Locate::Cache and $Module::Locate::Global )
         and ( exists $INC{$path} and defined $INC{$path}         );

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

    croak("Can't locate $path in \@INC (\@INC contains: @INC")
      unless defined $paths[0];

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
          warnings::warnif("invalid reference in \@INC '$c'")
    ;

    return $ret;
  }

  sub acts_like_fh {
    no strict 'refs';
    return !!( ref $_[0] and (
         ( ref $_[0] eq 'GLOB' and defined *{$_[0]}{IO} )
      or ( UNIVERSAL::isa($_[0], 'IO::Handle')          )
      or ( overload::Method($_[0], '<>')                )
    ) );
  }
}

q[ The better be make-up, and it better be good ];

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
callers package.

If C<Global =E<gt> BOOL> is passed in, then the all the results for module
searche i.e using C<locate>, will also be stored in C<%INC>, just like
C<require>. This is B<on> by default.

If C<Cache =E<gt> BOOL> is passed in, then every subsequent search for a module
will just use the path stored in C<%INC>, as opposed to performing another
search. This is B<off> by default.

=item C<locate>

Given a module (in standard perl bareword format) locate the path of the module.
If called in a scalar context the first path found will be returned, if called
in a list context a list of paths where the module was found. Also, if
references have been placed in C<@INC> then a filehandle will be returned, as
defined in the C<require> documentation.

=item C<get_source>

When provided with a package name, retrieve the source of the C<.pm> that is
found.

=item C<acts_like_fh>

Given a scalar, check if it behaves like a filehandle. Firstly it checks if it
is a bareword filehandle, then if it inherits from C<IO::Handle> and lastly if
it overloads the C<E<lt>E<gt>> operator. If this is missing any other standard
filehandle behaviour, please send me an e-mail.

=back

=head1 Changes

=over 4

=item 1.0

=over 8

=item *

Initial release

=back

=back

=head1 AUTHOR

Dan Brook C<E<lt>broquaint@hotmail.comE<gt>>

=head1 SEE ALSO

C<perl>, C<use>, C<require>

=cut
