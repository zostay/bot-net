use strict;
use warnings;

package Bot::Net::Script::Bot;
use base qw/ App::CLI::Command /;

use Bot::Net;
use UNIVERSAL::require;

=head1 NAME

Bot::Net::Script::Bot - Startup the named bot

=head1 SYNOPSIS

  bin/botnet bot --name <bot name>

=head1 DESCRIPTION

This command will startup a single bot.

=head1 METHODS

=head2 actions

Returns the arguments used by this script. See L<App::CLI::Command>.

=cut

sub options {
    ( 'name=s' => 'name' );
}

=head2 run

Starts the bot program running.

=cut

sub run {
    my ($self, @args) = @_;

    if (!$self->{name} and @args and $args[0] !~ /^--/) {
        $self->{name} = shift @args;
    }

    defined $self->{name}
        or die "No bot name given with required --name option.\n";
    
    my $bot_config = Bot::Net->config->bot($self->{name});
    my $bot_name = $bot_config->{bot};

    defined $bot_name
        or die qq{Bot $self->{name} missing the "bot" configuration option.\n};

    my $bot_class = "Bot::Net::Bot::".$bot_name;
    $bot_class->require
        or die qq{Failed to load class $bot_class for bot $self->{name}: $@\n"};

    $bot_class->start($self->{name}, \@args);
}

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
