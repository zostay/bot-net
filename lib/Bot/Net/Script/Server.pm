use strict;
use warnings;

package Bot::Net::Script::Server;
use base qw/ App::CLI::Command /;

use Bot::Net::Server;

=head1 NAME

Bot::Net::Script::Server - Startup the Bot::Net IRC Daemon

=head1 SYNOPSIS

  bin/botnet server

=head1 DESCRIPTION

Starts the IRC daemon that is used to access the back-end features of Bot::Net. Once this daemon is started, you will probably want to start the workers that will connect to the IRC daemon.

=head1 METHODS

=head2 run

Runs the server.

=cut

sub run {
    my ($self, $arg) = @_;

    Bot::Net::Server->start($arg);
}

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
