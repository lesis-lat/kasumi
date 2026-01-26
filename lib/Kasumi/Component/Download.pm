package Kasumi::Component::Download;

use strict;
use warnings;
use Readonly;
use JSON;

our $VERSION = '2.0';

Readonly my $BYTES_PER_KB => 1024;
Readonly my $KB_PER_MB    => 1024;

sub new {
    my ($class, $api) = @_;
    my $self = {api => $api};
    return bless $self, $class;
}

sub get_conversations {
    my ($self) = @_;

    my @all_conversations = ();
    my $cursor            = q{};
    my $first_iteration   = 1;

    while ($first_iteration || $cursor) {
        $first_iteration = 0;

        my $url    = 'https://slack.com/api/conversations.list';
        my $params = {
            types            => 'public_channel,private_channel,mpim,im',
            exclude_archived => 'true',
            limit            => 200,
        };

        if ($cursor) {
            $params -> {cursor} = $cursor;
        }

        my $response = $self -> {api} -> request('GET', $url, $params);

        if ($response -> {ok}) {
            if ($response -> {channels}
                && ref($response -> {channels}) eq 'ARRAY')
            {
                push @all_conversations, @{$response -> {channels}};
            }
            $cursor = $response -> {response_metadata}{next_cursor} || q{};
        }
        if (!$response -> {ok}) {
            my $error = $response -> {error} || 'unknown_error';
            die "Failed to fetch conversations: $error\n";
        }
    }

    return \@all_conversations;
}

sub get_conversation_history {
    my ($self, $channel_id, $oldest, $latest) = @_;

    my @all_messages    = ();
    my $cursor          = q{};
    my $first_iteration = 1;

    while ($first_iteration || $cursor) {
        $first_iteration = 0;

        my $url    = 'https://slack.com/api/conversations.history';
        my $params = {
            channel => $channel_id,
            limit   => 200,
        };

        if (defined $oldest) {
            $params -> {oldest} = $oldest;
        }
        if (defined $latest) {
            $params -> {latest} = $latest;
        }
        if ($cursor) {
            $params -> {cursor} = $cursor;
        }

        my $response = $self -> {api} -> request('GET', $url, $params);

        if ($response -> {ok}) {
            if ($response -> {messages}
                && ref($response -> {messages}) eq 'ARRAY')
            {
                push @all_messages, @{$response -> {messages}};
            }
            $cursor = $response -> {response_metadata}{next_cursor} || q{};
        }
        if (!$response -> {ok}) {
            my $error = $response -> {error} || 'unknown_error';
            warn "Warning: Failed to fetch history for $channel_id: $error\n";
            last;
        }

        sleep 1;
    }

    return \@all_messages;
}

sub get_thread_replies {
    my ($self, $channel_id, $thread_ts) = @_;

    my $url    = 'https://slack.com/api/conversations.replies';
    my $params = {
        channel => $channel_id,
        ts      => $thread_ts,
        limit   => 200,
    };

    my $response = $self -> {api} -> request('GET', $url, $params);

    if ($response -> {ok}) {
        if ($response -> {messages}
            && ref($response -> {messages}) eq 'ARRAY')
        {
            my @replies = @{$response -> {messages}};

            if (@replies) {
                shift @replies;
            }
            return \@replies;
        }
        return [];
    }

    my $error = $response -> {error} || 'unknown_error';
    warn "Warning: Failed to fetch thread replies for $thread_ts: $error\n";
    return [];
}

sub extract_threads_from_messages {
    my ($self, $conv_id, $messages) = @_;

    my $thread_count = 0;

    foreach my $msg (@{$messages}) {
        if (!$msg -> {reply_count} || $msg -> {reply_count} <= 0) {
            next;
        }

        my $replies = $self -> get_thread_replies($conv_id, $msg -> {ts});

        if (@{$replies}) {
            $msg -> {thread_replies} = $replies;
            $thread_count++;
        }

        sleep 1;
    }

    return $thread_count;
}

sub process {
    my ($self, $config) = @_;

    my @all_messages    = ();
    my $current_size_mb = 0;

    print "[*] Fetching conversations list...\n";
    my $conversations = $self -> get_conversations();
    print '[+] Found ' . scalar(@{$conversations}) . " conversations\n\n";

    foreach my $conv (@{$conversations}) {

        if ($config -> {download_all}
            && $current_size_mb >= $config -> {size_limit})
        {
            print '[!] Size limit reached ('
                . $config -> {size_limit}
                . " MB). Stopping extraction.\n";
            last;
        }

        my $conv_name = $conv -> {name} || $conv -> {id};
        my $conv_type = $self -> get_conversation_type($conv);

        print "[*] Processing $conv_type: $conv_name\n";
        if ($config -> {download_all}) {
            printf "[*] Current size: %.2f MB / %d MB\n", $current_size_mb,
                $config -> {size_limit};
        }

        my $messages =
            $self -> get_conversation_history($conv -> {id},
                $config -> {oldest}, $config -> {latest});

        if (@{$messages}) {
            print '[+] Found ' . scalar(@{$messages}) . " messages\n";

            if ($config -> {threads}) {
                my $thread_count =
                    $self -> extract_threads_from_messages($conv -> {id},
                        $messages);
                if ($thread_count > 0) {
                    print '[+] Extracted ' . $thread_count . " threads\n";
                }
            }

            foreach my $msg (@{$messages}) {
                $msg -> {conversation_name} = $conv_name;
                $msg -> {conversation_type} = $conv_type;
                $msg -> {conversation_id}   = $conv -> {id};
            }

            push @all_messages, @{$messages};

            if ($config -> {download_all}) {
                my $json_size = length encode_json \@all_messages;
                $current_size_mb = $json_size / ($BYTES_PER_KB * $KB_PER_MB);
            }
        }
        if (!@{$messages}) {
            print "[-] No messages found\n";
        }

        print "\n";

        sleep 1;
    }

    return \@all_messages;
}

sub get_conversation_type {
    my ($self, $conv) = @_;

    if ($conv -> {is_im}) {
        return 'Direct Message';
    }
    if ($conv -> {is_mpim}) {
        return 'Group Direct Message';
    }
    if ($conv -> {is_private}) {
        return 'Private Channel';
    }
    if ($conv -> {is_channel}) {
        return 'Public Channel';
    }
    return 'Unknown';
}

1;
