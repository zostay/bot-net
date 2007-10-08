use strict;
use warnings;

package Bot::Net::Mixin;
use base qw/ Bot::Net::Object POE::Declarative::Mixin /;

use Data::Remember POE => 'Memory';
use POE;
use POE::Declarative;

require Exporter;
push our @ISA, 'Exporter';

our @EXPORT = (
    # Re-export POE::Session constants
    qw/ OBJECT SESSION KERNEL HEAP STATE SENDER CALLER_FILE CALLER_LINE
        CALLER_STATE ARG0 ARG1 ARG2 ARG3 ARG4 ARG5 ARG6 ARG7 ARG8 ARG9 /,

    # Re-export POE::Declarative
    @POE::Declarative::EXPORT, 
    
    # Re-export Data::Remember
    qw/ remember recall forget brain /,
);

=head1 NAME

Bot::Net::Mixin - build complex objects my mixing components

=head1 SYNOPSIS

  # Define your own mixin
  use strict;
  use warnings;

  package MyBotNet::Mixin::Bot::Counter;
  use base qw/ Bot::Net::Mixin /;

  use Bot::Net::Mixin::Bot::Command;

  # Add a counter command to a bot

  sub setup {
      my $self  = shift;
      my $brain = shift;

      $brain->remember( [ 'counter' ] => 0 );
  }
  
  on bot command next => run {
      my $event = get ARG0;

      my $counter = recall 'counter' + 1;
      remember counter => $counter;

      yield reply_to_sender => $event => $counter;
  };

  1;

=head1 DESCRIPTION

This is the base class for all L<Bot::Net> mixins. It basically provides for a way of cataloging which mixins a class has added, tools for mixin setup, and magic for pulling mixin stuff into the importing package.

=head1 METHODS

=head2 import

Exports anything the module lists in it's C<@EXPORT> variable, if such a method exists.

=cut

sub import {
    my $self   = shift;
    my $caller = caller;

    $self->export_to_level(1, undef);

    # Sombody else is creating a new sweet custom mixin
    if ($self eq __PACKAGE__) {
        no strict 'refs';
        push @{ $caller . '::ISA' }, __PACKAGE__;
    }

    # Sombody is using somebody else's sweet custom mixin
    else {
        my $mixins = Bot::Net::Mixin::_mixins_for_package($caller);
        push @$mixins, $self;

        $self->export_poe_declarative_to_level(1);
    }
}

sub _mixins_for_package {
    my $package = shift;

    no strict 'refs';
    return ${ $package . '::_BOT_NET_MIXINS' } ||= [];
}

=head1 MIXIN IMPLEMENTATIONS

A mixin may implement whatever POE states it wishes to using the L<POE::Declarative> interface. Those states will be imported into the calling package.

If a mixin needs to perform any setup prior to L<POE::Kernel> startup, it may be do so by implementing a C<setup> method. It will be passed two arguments, the C<$self> variable for the class stored with the session and the L<Data::Remember> brain object that will be stored in the heap of the session being created. 

  sub setup {
      my $self  = shift;
      my $brain = shift;

      # Using the internal brain interface of Data::Remember, make sure to
      # be careful to use only array-based ques!
      $brain->remember( [ 'foo' ] => 'bar' );
  }

In general, however, your mixins can probably get away with performing initial setup in the C<_start> state.

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
