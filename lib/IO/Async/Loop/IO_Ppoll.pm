#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2007,2008 -- leonerd@leonerd.org.uk

package IO::Async::Loop::IO_Ppoll;

use strict;

our $VERSION = '0.01';

use IO::Async::Loop::IO_Poll 0.10;
use base qw( IO::Async::Loop::IO_Poll );

use Carp;

use IO::Ppoll qw( POLLIN POLLOUT POLLHUP );

use POSIX qw( EINTR SIG_BLOCK SIG_UNBLOCK sigprocmask );

=head1 NAME

L<IO::Async::Loop::IO_Ppoll> - a Loop using an C<IO::Ppoll> object

=head1 SYNOPSIS

 use IO::Async::Loop::IO_Ppoll;

 my $loop = IO::Async::Loop::IO_Ppoll->new();

 $loop->add( ... );
 $loop->attach_signal( HUP => sub { ... } );

 $loop->loop_forever();

=head1 DESCRIPTION

This subclass of C<IO::Async::Loop::IO_Poll> uses an C<IO::Ppoll> object 
instead of a C<IO::Poll> to perform read-ready and write-ready tests so that
they can be mixed with signal handling.

The C<ppoll()> system call atomically switches the process's signal mask,
performs a wait exactly as C<poll()> would, then switches it back. This allows
a process to block the signals it cares about, but switch in an empty signal
mask during the poll, allowing it to handle file IO and signals concurrently.

=head1 CONSTRUCTOR

=cut

=head2 $loop = IO::Async::Loop::IO_Ppoll->new( %args )

This function returns a new instance of a C<IO::Async::Loop::IO_Ppoll> object.
It takes the following named arguments:

=over 8

=item C<poll>

The C<IO::Ppoll> object to use for notification. Optional; if a value is not
given, a new C<IO::Ppoll> object will be constructed.

=back

=cut

sub new
{
   my $class = shift;
   my ( %args ) = @_;

   my $poll = delete $args{poll};

   $poll ||= IO::Ppoll->new();

   my $self = $class->SUPER::new( %args, poll => $poll );

   $self->{restore_SIG} = {};

   return $self;
}

=head1 METHODS

As this is a subclass of L<IO::Async::Loop::IO_Poll>, all of its methods are
inherited. Expect where noted below, all of the class's methods behave
identically to C<IO::Async::Loop::IO_Poll>.

=cut

sub DESTROY
{
   my $self = shift;

   foreach my $signal ( keys %{ $self->{restore_SIG} } ) {
      $self->detach_signal( $signal );
   }
}

=head2 $count = $loop->loop_once( $timeout )

This method calls the C<poll()> method on the stored C<IO::Ppoll> object,
passing in the value of C<$timeout>, and processes the results of that call.
It returns the total number of C<IO::Async::Notifier> callbacks invoked, or
C<undef> if the underlying C<poll()> method returned an error. If the
C<poll()> was interrupted by a signal, then 0 is returned instead.

=cut

sub loop_once
{
   my $self = shift;
   my ( $timeout ) = @_;

   $self->_adjust_timeout( \$timeout );

   my $poll = $self->{poll};

   my $pollret = $poll->poll( $timeout );
   return undef unless defined $pollret;

   return 0 if $pollret == -1 and $! == EINTR; # Caught signal
   return undef if $pollret == -1;             # Some other error

   return $self->post_poll();
}

# override
sub attach_signal
{
   my $self = shift;
   my ( $signal, $code ) = @_;

   exists $SIG{$signal} or croak "Unrecognised signal name $signal";

   # Don't allow anyone to trash an existing signal handler
   !defined $SIG{$signal} or !ref $SIG{$signal} or croak "Cannot override signal handler for $signal";

   $self->{restore_SIG}->{$signal} = $SIG{$signal};

   my $signum;
   {
      no strict 'refs';
      local @_;
      $signum = &{"POSIX::SIG$signal"};
   }

   sigprocmask( SIG_BLOCK, POSIX::SigSet->new( $signum ) );

   $SIG{$signal} = $code;
}

# override
sub detach_signal
{
   my $self = shift;
   my ( $signal ) = @_;

   exists $SIG{$signal} or croak "Unrecognised signal name $signal";

   # When we saved the original value, we might have got an undef. But %SIG
   # doesn't like having undef assigned back in, so we need to translate
   $SIG{$signal} = $self->{restore_SIG}->{$signal} || 'DEFAULT';

   delete $self->{restore_SIG}->{$signal};
   
   my $signum;
   {
      no strict 'refs';
      local @_;
      $signum = &{"POSIX::SIG$signal"};
   }

   sigprocmask( SIG_UNBLOCK, POSIX::SigSet->new( $signum ) );
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 SEE ALSO

=over 4

=item *

L<IO::Ppoll> - Object interface to Linux's C<ppoll()> call

=item *

L<IO::Async::Loop::IO_Poll> - a set using an C<IO::Poll> object

=back 

=head1 AUTHOR

Paul Evans E<lt>leonerd@leonerd.org.ukE<gt>
