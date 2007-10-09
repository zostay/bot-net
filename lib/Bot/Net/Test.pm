use strict;
use warnings;

package Bot::Net::Test;
use base qw/ Test::More Class::Data::Inheritable /;

use Bot::Net;
use Bot::Net::Mixin;

use File::Spec;
use Hash::Merge ();
use POE qw/ Wheel::Run /;

__PACKAGE__->mk_classdata('servers');
__PACKAGE__->mk_classdata('bots');

=head1 NAME

Bot::Net::Test - helper for building Bot::Net tests

=head1 SYNOPSIS

  use strict;
  use warnings;

  # Make this test script a bot
  use Bot::Net::Bot;
  use Bot::Net::Mixin::Bot::IRC;

  use Bot::Net::Test tests => 20;

  # Start the server in class MyBotNet::Server::Main
  Bot::Net::Test->start_server('Main');

  # Connect the bot in class MyBotNet::Bot::Count
  Bot::Net::Test->start_bot('Count');

  on bot connected => run {
      for ( 1 .. 10 ) {
          yield send_to => count => 'something';
      }
  };

  on bot message_to_me => run {
      my $event = get ARG0;
      my $count_expected = (recall('count') || 0) + 1;
      remember count => $count_expected;

      is($event->sender_nick, 'count');
      is($event->message, $count_expected);

      if ($count_expected == 10) {
          yield irc => quit => 'Test finished.';
      }
  };

  # Startup this bot
  Bot::Net::Test->run_test;

=head1 DESCRIPTION

Provides some tools to make testing your bots and servers a little easier. The typical pattern for using this class is to make your test script into a bot or server by implementing whichever set of mixins you need. 

You can start orther servers or bots using L</start_bot> or L</start_server. You can define any states you need to handle for testing. Then, you start that server or bot using L</run_test>.

Make sure that you tell your bot to shutdown when you're finished with your tests. (For example, for an IRC bot, you can issue a C<quit> or C<disconnect> state to the IRC POE component as showin the L</SYNOPSIS>.)

=head1 METHODS

=head2 import

Builds a test configuration for your test file.

=cut

sub import {
    my $class = shift;
    my $package = caller;

    no strict 'refs';
    ${ $package . '::CONFIG' } ||= {};

    $class->SUPER::import(@_);
}

=head2 start_server SERVER

Starts the named server. This server will shutdown when the test bot quits or when L</stop_server> is called.

=cut

sub start_server {
    my $class  = shift;
    my $server = shift;

    my $server_name = $server;
    $server_name =~ s/\W+/_/g;

    my $wheel = POE::Wheel::Run->new(
        Program     => File::Spec->catfile('bin', 'botnet'),
        ProgramArgs => [ qw/ run --server /, $server ],

        StdinEvent  => "server_${server_name}_stdin",
        StdoutEvent => "server_${server_name}_stdout",
        StderrEvent => "server_${server_name}_stderr",
    );

    $class->servers({}) unless $class->servers;
    $class->servers->{ $server } = $wheel;
}

=head2 stop_server SERVER

Stops the named server.

=cut

sub stop_server {
    my $class  = shift;
    my $server = shift;

    my $wheel = delete $class->servers->{ $server };
    $wheel->kill;
}

=head2 start_bot BOT

Starts the named bot. This bot will shutdown when the test bot quits or when L</stop_bot> is called.

=cut

sub start_bot {
    my $class = shift;
    my $bot   = shift;

    my $bot_name = $bot;
    $bot_name =~ s/\W+/_/g;

    my $wheel = POE::Wheel::Run->new(
        Program     => File::Spec->catfile('bin', 'botnet'),
        ProgramArgs => [ qw/ run --bot /, $bot ],

        StdinEvent  => "bot_${bot_name}_stdin",
        StdoutEvent => "bot_${bot_name}_stdout",
        StderrEvent => "bot_${bot_name}_stderr",
    );

    $class->bots({}) unless $class->bots;
    $class->bots->{ $bot } = $wheel;
}

=head2 stop_bot BOT

Stops the named bot.

=cut

sub stop_bot {
    my $class = shift;
    my $bot   = shift;

    my $wheel = delete $class->bots->{ $bot };
    $wheel->kill;
}

=head2 run_test

Tells the test to setup the bot or server and tell the L<POE> kernel to start the event loop.

=cut

sub run_test {
    my $class = shift;
    my $test  = caller;

    my @configs;
    for my $mixin (@{ Bot::Net::Mixin::_mixins_for_package($test) }) {
        push @configs, $mixin->default_configuration($test)
            if $mixin->can('default_configuration');
    }

    {
        no strict 'refs';
        ${ $test . '::CONFIG' } = Hash::Merge::merge( @configs );
    }

    $test->setup;
    POE::Kernel->run;
}

=head1 POE STATES

=head2 on [ bot quit, server quit ]

Shutdown any bots and servers that haven't yet been stopped.

=cut

on [ qw/ bot_quit server_quit / ] => run {
    my @wheels = (
        values %{ Bot::Net::Test->servers || {} },
        values %{ Bot::Net::Test->bots    || {} },
    );

    for my $wheel ( @wheels ) {
        $wheel->kill;
    }
};

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
