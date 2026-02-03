package Kasumi::Component::Context;

use strict;
use warnings;

our $VERSION = '2.0';

sub new {
    my ($class, $api) = @_;
    my $self = {api => $api};
    return bless $self, $class;
}

sub process {
    my ($self, $messages, $context_size) = @_;

    if ($context_size <= 0) {
        return $messages;
    }

    print '[*] Fetching context messages '
        . "($context_size before and after each match)...\n";

    my @enriched_messages;
    my %seen_message_ids;

    foreach my $msg (@{$messages}) {
        my $channel_id =
            $msg -> {conversation_id} || $msg -> {channel} -> {id};
        my $msg_ts     = $msg -> {ts};

        if (!$channel_id || !$msg_ts) {
            next;
        }

        my $context_messages =
            $self -> get_context_messages($channel_id, $msg_ts, $context_size);

        if ($context_messages && @{$context_messages}) {
            foreach my $ctx_msg (@{$context_messages}) {
                my $msg_id = $ctx_msg -> {ts} . q{-} . $channel_id;

                if (!$seen_message_ids{$msg_id}) {
                    $ctx_msg -> {conversation_id} = $channel_id;
                    $ctx_msg -> {conversation_name} =
                        $msg -> {conversation_name}
                        || $msg -> {channel} -> {name};
                    $ctx_msg -> {is_context_message} =
                        ($ctx_msg -> {ts} ne $msg_ts);
                    if ($ctx_msg -> {is_context_message}) {
                        $ctx_msg -> {context_of} = $msg_ts;
                    }

                    push @enriched_messages, $ctx_msg;
                    $seen_message_ids{$msg_id} = 1;
                }
            }
        }

        sleep 1;
    }

    @enriched_messages =
        sort { $a -> {ts} <=> $b -> {ts} } @enriched_messages;

    print '[+] Total messages with context: '
        . scalar @enriched_messages . "\n";

    return \@enriched_messages;
}

sub get_context_messages {
    my ($self, $channel_id, $target_ts, $context_size) = @_;

    my @all_context_messages;

    my $before_messages =
        $self -> get_messages_before($channel_id, $target_ts, $context_size);
    if ($before_messages) {
        push @all_context_messages, @{$before_messages};
    }

    my $target_message = $self -> get_single_message($channel_id, $target_ts);
    if ($target_message) {
        push @all_context_messages, $target_message;
    }

    my $after_messages =
        $self -> get_messages_after($channel_id, $target_ts, $context_size);
    if ($after_messages) {
        push @all_context_messages, @{$after_messages};
    }

    return \@all_context_messages;
}

sub get_messages_before {
    my ($self, $channel_id, $target_ts, $count) = @_;

    my $url    = 'https://slack.com/api/conversations.history';
    my $params = {
        channel => $channel_id,
        latest  => $target_ts,
        limit   => $count + 1,
    };

    my $response = $self -> {api} -> request('GET', $url, $params);

    if ($response -> {ok} && $response -> {messages}) {
        my @messages = @{$response -> {messages}};
        shift @messages;
        return \@messages;
    }

    return [];
}

sub get_messages_after {
    my ($self, $channel_id, $target_ts, $count) = @_;

    my $url    = 'https://slack.com/api/conversations.history';
    my $params = {
        channel => $channel_id,
        oldest  => $target_ts,
        limit   => $count + 1,
    };

    my $response = $self -> {api} -> request('GET', $url, $params);

    if ($response -> {ok} && $response -> {messages}) {
        my @messages = reverse @{$response -> {messages}};
        shift @messages;
        return \@messages;
    }

    return [];
}

sub get_single_message {
    my ($self, $channel_id, $ts) = @_;

    my $url    = 'https://slack.com/api/conversations.history';
    my $params = {
        channel => $channel_id,
        latest  => $ts,
        oldest  => $ts,
        limit   => 1,
    };

    my $response = $self -> {api} -> request('GET', $url, $params);

    if ($response -> {ok}
        && $response -> {messages}
        && @{$response -> {messages}})
    {
        return $response -> {messages} -> [0];
    }

    return;
}

1;
