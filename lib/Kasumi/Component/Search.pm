package Kasumi::Component::Search;

use strict;
use warnings;

our $VERSION = '2.0';

sub new {
    my ($class, $api) = @_;
    my $self = {api => $api};
    return bless $self, $class;
}

sub process {
    my ($self, $query, $oldest, $latest) = @_;

    my @all_messages    = ();
    my $cursor          = q{};
    my $page            = 1;
    my $first_iteration = 1;

    print "[*] Searching Slack messages for: '$query'\n";

    while ($first_iteration || $cursor) {
        $first_iteration = 0;

        my $url    = 'https://slack.com/api/search.messages';
        my $params = {
            query => $query,
            count => 100,
            sort  => 'timestamp',
        };

        if ($cursor) {
            $params -> {cursor} = $cursor;
        }

        my $response = $self -> {api} -> request('GET', $url, $params);

        if ($response -> {ok}) {
            my $messages = $response -> {messages};

            if ($messages
                && $messages -> {matches}
                && ref $messages -> {matches} eq 'ARRAY')
            {
                foreach my $match (@{$messages -> {matches}}) {

                    my $msg_ts = $match -> {ts};
                    if (defined $oldest && $msg_ts < $oldest) {
                        next;
                    }
                    if (defined $latest && $msg_ts > $latest) {
                        next;
                    }

                    if ($match -> {channel}) {
                        $match -> {conversation_id} =
                            $match -> {channel} -> {id};
                        $match -> {conversation_name} =
                            $match -> {channel} -> {name};
                    }

                    push @all_messages, $match;
                }

                print "[+] Page $page: Found "
                    . scalar @{$messages -> {matches}}
                    . " results\n";
                $page++;
            }

            $cursor =
                $response -> {messages} -> {paging} -> {next_cursor} || q{};
        }
        if (!$response -> {ok}) {
            my $error = $response -> {error} || 'unknown_error';
            warn "Warning: Search failed: $error\n";
            last;
        }

        sleep 1;
    }

    print '[+] Total search results: ' . scalar @all_messages . "\n\n";

    return \@all_messages;
}

1;
