use strict;
use warnings;

package Bot::Net::Server;
use base qw/ Bot::Net::Object /;

use Data::Remember Hybrid => [ [] => [ 'Memory' ] ];
use Regexp::Common qw/ delimited /;
use POE qw/ Component::Server::IRC /;
use POE::Declarative;

=head1 NAME

Bot::Net::Server - an IRC server to run your Bot::Net application on

=head1 SYNOPSIS

  MyBotNet::Server::Main->start;

=head1 DESCRIPTION

This is the base class for running your own IRC Server. It is based upon L<POE::Component::Server::IRC>.

=head1 METHODS

=head1 setup

Setup a new IRC server.

=cut

sub setup {
    my $class = shift;
    my $self  = bless {}, $class;

    my $name = Bot::Net->short_name_for_server($class);
    my $config_file = Bot::Net->config->server_file($name)
        or die qq{Server startup failed, no configuration found for $name. You may need to run "botnet server create $name" first.};

    brain->register_brain(
        config => [ YAML => file => $config_file ]
    );

    if (my $state_file = recall [ config => 'state_file' ]) {
        brain->register_brain(
            state => [ DBM => file => $state_file ]
        );
    }

    remember name => $name;
    remember ircd => POE::Component::Server::IRC->spawn( 
        antiflood => 0,
        config    => recall [ config => 'ircd_config' ],
        alias     => 'ircd',
    );

    POE::Declarative->setup($class, $self);
}

=head1 POE STATES

=head2 on _start

Handles session startup. At startup, it loads the information stored in the configuration file and sets up the NickServ bot.

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

=head2 on _default ARG0 .. ARGN

Performs logging for the general messages that are not handled by the system.

=cut

on _default => run {
    my ( $event, $args ) = @_[ ARG0 .. $#_ ];

    my $msg = "$event: ";
    foreach (@$args) {
        SWITCH: {
            if ( ref($_) eq 'ARRAY' ) {
                $msg .= "[". join ( ", ", @$_ ). "] ";
                last SWITCH;
            }
            if ( ref($_) eq 'HASH' ) {
                $msg .= "{". join ( ", ", %$_ ). "} ";
                last SWITCH;
            }
            $msg .= "'$_' ";
        }
    }
    recall('log')->debug($msg);
    return 0;    # Don't handle signals.
}

=head1 SEE ALSO

L<POE::Component::Server::IRC>

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
