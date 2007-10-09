use strict;
use warnings;

package Bot::Net::Mixin::Server::IRC;

use Bot::Net::Mixin;

use POE qw/ Component::Server::IRC /;

=head1 NAME

Bot::Net::Mixin::Server::IRC - mixin class for building IRC servers

=head1 SYNOPSIS

  # Build a basic, no-frills IRC server 
  use strict;
  use warnings;
  package MyBotNet::Server::Main;

  use Bot::Net::Server;
  use Bot::Net::Mixin::Server::IRC;

  1;

=head1 DESCRIPTION

This is the mixin-class for L<Bot::Net> IRC servers. By using this class you create an IRC daemon:

  use Bot::Net::Server;             # define common Bot::Net server features
  use Bot::Net::Mixin::Server::IRC; # we're an IRC server

=head1 METHODS

=head2 setup

Setup a new IRC server.

=cut

sub setup {
    my $self  = shift;
    my $brain = shift;

    $brain->remember( [ 'ircd' ] => POE::Component::Server::IRC->spawn( 
        antiflood => 0,
        config    => $brain->recall( [ config => 'ircd_config' ] ),
        alias     => 'ircd',
    ));
}

=head2 default_configuration PACKAGE

Returns a base configuration for an IRC server daemon.

=cut

sub default_configuration {
    my $class   = shift;
    my $package = shift;

    return {
        ircd_config => {
            servername => lc Bot::Net->short_name_for_server($package) . '.irc',
            nicklen    => 15,
            network    => Bot::Net->config->new('ApplicationName'),
        },
        listeners => [
            { port => 6667 },
        ],
    };
}

=head1 POE STATES

=head2 on _start

At startup, this hanlder loads the information stored in the configuration file and configures the IRC daemon.

=cut

on _start => run {
    my $log  = recall 'log';
    my $ircd = recall 'ircd';

    # Start receiving server events
    post ircd => 'register';

    # Installing masks
    $log->info("Installing the masks...");
    my $masks = recall [ config => 'masks' ];
    for my $mask (@$masks) {
        $ircd->add_auth( %$mask );
    }

    # Installing operators
    $log->info("Installing the operators...");
    my $operators = recall [ config => 'operators' ];
    for my $operator (@$operators) {
        $ircd->add_operator( %$operator );
    }

    # Start a listener on the 'standard' IRC port.
    $log->info("Installing the listeners...");
    my $listeners = recall [ config => 'listeners' ];
    for my $listener (@$listeners) {
        $ircd->add_listener( %$listener );
    }

    undef;
};

=head2 on server quit

This causes the IRC daemon to close all connections and stop listening.

=cut

on server_quit => run {
    recall('ircd')->shutdown;
};

=head1 SEE ALSO

L<Bot::Net::Server>

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
