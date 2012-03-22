#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2007-2012 -- leonerd@leonerd.org.uk

package IO::Async::Loop::IO_Ppoll;

use strict;
use warnings;

use Carp;

our $VERSION = '0.06';

use base qw( IO::Async::Loop::Ppoll );

=head1 NAME

C<IO::Async::Loop::IO_Ppoll> - compatibility wrapper for
L<IO::Async::Loop::Ppoll>

=head1 DESCRIPTION

This class is a compatibility wrapper for programs that expect to find the
Loop subclass which uses L<IO::Ppoll> under this name. It was renamed to
C<IO::Async::Loop::Ppoll>. The API is exactly the same, only under a different
name.

Any program still referring to this class directly should be changed. This
object constructor will print a warning when the object is created.

Version 0.06 will likely be the last release of this distribution.

=cut

sub new
{
   carp "IO::Async::Loop::IO_Ppoll is deprecated, and now called IO::Async::Loop::Ppoll. Please update your code";
   shift->SUPER::new( @_ );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
