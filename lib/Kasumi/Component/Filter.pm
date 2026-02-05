package Kasumi::Component::Filter;

use strict;
use warnings;
use English qw(-no_match_vars);

our $VERSION = '2.0';

sub new {
    my ($class) = @_;
    my $self = {};
    return bless $self, $class;
}

sub process_random_search {
    my ($self, $config) = @_;

    if (!$config -> {random_search}) {
        return;
    }

    my @random_words;

    my $wordlist_file = $config -> {wordlist} || 'wordlist.txt';
    my $wordlist_found = 0;

    if (-f $wordlist_file) {
        $wordlist_found = 1;
        print "[*] Loading keywords from: $wordlist_file\n";
        open my $fh, '<', $wordlist_file or do {
            my $error = $OS_ERROR;
            die "Cannot open wordlist file $wordlist_file: $error\n";
        };
        my @lines = <$fh>;
        close $fh or do {
            my $error = $OS_ERROR;
            warn "Warning: Failed to close $wordlist_file: $error\n";
        };

        foreach my $line (@lines) {
            chomp $line;

            if ($line =~ /^\s*$/smx) {
                next;
            }
            if ($line =~ /^\s*\#/smx) {
                next;
            }

            $line =~ s/^\s+|\s+$//gsmx;

            if ($line) {
                push @random_words, $line;
            }
        }

        if (@random_words) {
            print '[+] Loaded '
                . scalar @random_words
                . " keywords from wordlist\n";
        }
        if (!@random_words) {
            warn 'Warning: Wordlist file is empty, using fallback keywords'
                . "\n";
        }
    }
    if (!$wordlist_found) {
        if ($config -> {wordlist}) {
            die "Specified wordlist file not found: $wordlist_file\n";
        }
        print '[*] No wordlist file found, using built-in keywords' . "\n";
    }

    if (!@random_words) {
        @random_words = qw(
            batman superman spiderman ironman wonderwoman
            party celebration festival music concert event
            food pizza burger sushi pasta coffee lunch dinner
            movie film cinema netflix youtube series
            game gaming sports football basketball soccer
            travel vacation holiday beach mountain hotel
            work meeting project deadline report presentation
            weather sunny rainy cloudy snow storm
            book reading library novel author
            technology computer software hardware code programming
            health fitness gym exercise yoga running
            money finance budget investment crypto bitcoin
            car vehicle driving traffic parking uber
            home house apartment furniture kitchen
            school education student teacher learning university
            love family friend relationship happy
            news politics election government law
            science research experiment data analysis
            art music painting photography gallery
            fashion style clothing shoes shopping
            nature environment climate animal plant
            email message call chat slack
            important urgent help thanks
        );
    }

    my $random_keyword = $random_words[int rand @random_words];
    $config -> {keywords} = $random_keyword;
    print '[*] Random search mode enabled' . "\n";
    print "[*] Using random keyword: $random_keyword\n\n";

    return $random_keyword;
}

sub process_thread_extraction {
    my ($self, $messages, $api, $config) = @_;

    if (!$config -> {threads} || !@{$messages}) {
        return;
    }

    print "[*] Fetching thread replies for search results...\n";
    my $thread_count = 0;

    foreach my $msg (@{$messages}) {
        if ($msg -> {reply_count} && $msg -> {reply_count} > 0) {
            my $conv_id =
                $msg -> {conversation_id} || $msg -> {channel} -> {id};
            if ($conv_id) {

                require Kasumi::Component::Download;
                my $download = Kasumi::Component::Download -> new($api);
                my $replies =
                    $download -> get_thread_replies($conv_id, $msg -> {ts});
                if (@{$replies}) {
                    $msg -> {thread_replies} = $replies;
                    $thread_count++;
                }
                sleep 1;
            }
        }
    }

    if ($thread_count > 0) {
        print "[+] Extracted $thread_count threads\n";
    }

    return;
}

1;
