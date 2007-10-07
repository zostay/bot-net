use strict;
use warnings;

package Bot::Net::Mixin;
use base qw/ Bot::Net::Object POE::Declarative::Mixin /;

use Class::Trigger;
use Data::Remember POE => 'Memory';

require Exporter;
push our @ISA, 'Exporter';

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

  sub register_triggers {
      my $self = shift;

      $self->add_trigger( on_setup => sub { remember counter => 0 } );
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

Exports anything the module lists in it's C<@EXPORT> variable and calls the L</register_triggers> method of the mixin, if such a method exists.

=cut

sub import {
    my $self   = shift;
    my $caller = caller;

    $self->export_to_level(1, undef);

    if (my $triggers = $self->can('register_triggers')) {
        $triggers->($caller);
    }

    $self->export_poe_declarative_to_level(1);
}

=head1 MIXIN IMPLEMENTATIONS

A mixin may implement whatever POE states it wishes to using the L<POE::Declarative> interface. Those states will be imported into the calling package.

A mixin may also want to implement one or more triggers. It does this by providing a L</register_triggers> method which adds a trigger handler for one of the available triggers.

=head2 register_triggers CLASS

This is called when the mixin is used and passed the name of the package that is using this mixin. Your class may then implement any of the triggers provided by that class. The triggers available will depend upon the mixins used.

Triggers may be offered by your mixin or handled by your mixin. The triggers are defined using L<Class::Trigger>.

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
