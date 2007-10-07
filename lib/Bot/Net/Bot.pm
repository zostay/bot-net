use strict;
use warnings;

package Bot::Net::Bot;
use base qw/ Bot::Net::Mixin /;

use Bot::Net::Message;
use Class::Trigger;
use Data::Remember POE => Hybrid => [ ] => [ 'Memory' ];
use Data::Remember::Hybrid;
use POE qw/ Component::IRC::State /;
use POE::Declarative;
use Scalar::Util qw/ reftype /;

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

    # Re-export Class::Trigger
    qw/ add_trigger call_trigger last_trigger_results /,

    # Add in our own subs
    qw/ bot setup /,
);

=head1 NAME

Bot::Net::Bot - the base class for all Bot::Net bots

=head1 SYNOPSIS

  # An example for building an Eliza-based chatbot
  use strict;
  use warnings;

  use Bot::Net::Bot;
  use Bot::Net::Mixin::Bot::IRC;
  use Chatbot::Eliza; # available separately on CPAN

  on bot startup => run {
      remember eliza => Chatbot::Eliza->new;
  };

  on bot message_to_me => run {
      my $message = get ARG0;

      my $reply = recall('eliza')->transform( $message->text );
      yield reply_to_sender, $message, $reply;
  };

  1;

=head1 DESCRIPTION

This is the primary mixin-class for all L<Bot::Net> bots. You "inherit" all the features of this mixin by using the class:

  use Bot::Net::Bot; # This is a bot class now

Some things to know about how L<Bot::Net> bots work:

=over

=item *

There is a one-to-one relationship between packages and bot instances. If you want two bots that do the same thing, you will need two different packages. Fortunately, it's easy to clone a bot:

  package MyBotNet::Bot::Chatbot;
  use Bot::Net::Bot;

  # define some state handlers...
  
  package MyBotNet::Bot::Chatbot::Larry;
  use MyBotNet::Bot::Chatbot;

  package MyBotNet::Bot::Chatbot::Bob;
  use MyBotNet::Bot::Chatbot;

This defines three bots that all do the same thing--in this case, we probably only intend to invoke Larry and Bob, but you can do whatever you like.

=item *

TODO FIXME XXX Implement these things...

Make sure you use the C<botnet> command to help you out in this process.

  bin/botnet bot create Chatbot
  bin/botnet bot create Chatbot::Larry Chatbot
  bin/botnet bot create Chatbot::Bob Chatbot

This will create the scaffolding required to setup the classes mentioned in the previous bullet. You can then configure them to run:

  bin/botnet bot host Chatbot::Larry ServerA
  bin/botnet bot host Chatbot::Bob ServerB

=back

=head1 METHODS

=head2 import

Custom exporter for this mixin.

=cut

sub import {
    my $class = shift;

    $class->export_to_level(1, undef);
    $class->export_poe_declarative_to_level;
}

=head2 bot

This is a helper for L<POE::Declarative>. That lets you prefix "bot_" to your POE states. For example:

  on bot message_to_me => run { ... };

is the same as:

  on bot_message_to_me => run { ... };

It can also be used to yield messages:

  yield bot 'startup';

You may choose to use it or not.

=cut

sub bot($) { 'bot_'.shift }

=head1 setup

  MyBotNet::Bot::BotName->start;

This method is called to tell the bot to startup. It finds all the mixins that have been added into the class and calls the L</setup> method for each.

=cut

sub setup {
    my $class = shift;
    my $self = bless {}, $class;

    my $name = Bot::Net->short_name_for_bot($class);
    my $config_file = Bot::Net->config->bot_file($name);

    -f $config_file 
        or die qq{Bot startup failed, }
              .qq{no configuration found for $name: $config_file};

    my $brain = brain->new_heap;

    $brain->register_brain(
        config => [ YAML => file => $config_file ]
    );

    if (my $state_file = $brain->recall([ config => 'state_file' ])) {
        $brain->register_brain(
            state => [ DBM => file => $state_file ]
        );
    }

    $brain->remember([ 'name' ] => $name);
    $brain->remember([ 'log'  ] => $self->log);

    $self->call_trigger( on_setup => $brain );

    POE::Declarative->setup($self, $brain);
}

=head1 BOT STATES

=head2 on bot startup

Bots should implement this event to perform any startup tasks. This is bot-specific and mixins should not do anything with this event.

=head1 TRIGGERS

These triggers may be handled by mixin trigger handlers.

=head2 on_setup BRAIN

This is called before the POE kernel has started running. It is passed a reference to the brain plugin that will be stored in the session heap. Instead of calling the functional interface of L<Data::Remember>, mixins will need to make method calls instead (and make sure that the que's past are already normalized into arrays).

=head2 on_start

Called just after the kernel has started. The bot should be fully initialized by the time this trigger is called.

=head1 MIXIN STATES

The base mixin handles the following states.

=head2 on _start

Performs a number of setup tasks. Including:

=over

=item *

Register to receive messages from the IRC component.

=item *

Connect to the IRC server.

=item *

When finished, it fires the L</on bot startup> event.

=back

=cut

on _start => run {
    my $self = get OBJECT;
    my $name = recall 'name';
    my $log  = recall 'log';

    $log->info("Starting bot $name...");

    $self->call_trigger('on_start');

    yield bot 'startup';
};

=head2 on _default

Performs logging of unhandled events. All these logs are put into the DEBUG log, so they won't show up unless DEBUG logging is enabled in your L<Log::Log4perl> configuration.

=cut

on _default => run {
    my $log = recall 'log';
    my ($event, $args) = @_[ ARG0 .. $#_ ];
    my (@output);

    my $arg_number = 0;
    foreach (@$args) {
        SWITCH: {
            if ( ref($_) eq 'ARRAY' ) {
                push ( @output, "[", join ( ", ", @$_ ), "]" );
                last SWITCH;
            }
            if ( ref($_) eq 'HASH' ) {
                push ( @output, "{", join ( ", ", %$_ ), "}" );
                last SWITCH;
            }
            push ( @output, "'$_'" );
        }
        $arg_number++;
    }
    $log->debug("$event ". join( ' ', @output ));
    return 0;    # Don't handle signals.
};

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut
