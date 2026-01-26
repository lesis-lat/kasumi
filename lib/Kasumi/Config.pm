package Kasumi::Config;

use strict;
use warnings;
use Getopt::Long;
use Time::Piece;

our $VERSION = '2.0';

sub new {
    my ($class) = @_;
    my $self = {config => {}};
    return bless $self, $class;
}

sub process {
    my ($self, $argv) = @_;

    my %config = (
        token         => q{},
        cookie_d      => q{},
        keywords      => q{},
        date_from     => q{},
        date_to       => q{},
        output_file   => 'slack_messages.json',
        threads       => 0,
        no_verify_ssl => 0,
        help          => 0,
        random_search => 0,
        wordlist      => q{},
        download_all  => 0,
        size_limit    => 1024,
        context       => 0,
    );

    GetOptions(
        'token=s'       => \$config{token},
        'cookie-d=s'    => \$config{cookie_d},
        'keywords=s'    => \$config{keywords},
        'from=s'        => \$config{date_from},
        'to=s'          => \$config{date_to},
        'output=s'      => \$config{output_file},
        'threads'       => \$config{threads},
        'no-verify-ssl' => \$config{no_verify_ssl},
        'random-search' => \$config{random_search},
        'wordlist=s'    => \$config{wordlist},
        'download-all'  => \$config{download_all},
        'size-limit=i'  => \$config{size_limit},
        'context=i'     => \$config{context},
        'help'          => \$config{help},
    ) or die "Error in command line arguments\n";

    if ($config{help} || !$config{token}) {
        $self -> print_usage();
        my $exit_code = 1;
        if ($config{help}) {
            $exit_code = 0;
        }
        exit $exit_code;
    }

    $config{use_cookie_auth} = ($config{token} =~ /^xoxc-/smx);
    if ($config{use_cookie_auth} && !$config{cookie_d}) {
        die 'Cookie-based authentication (xoxc- token) requires '
            . "--cookie-d parameter\n";
    }

    if ($config{download_all} && $config{keywords} && !$config{random_search}) {
        die "Error: --download-all and --keywords cannot be used together.\n"
            . 'Use --keywords for targeted search or --download-all '
            . "for complete extraction.\n";
    }

    if ($config{date_from}) {
        $config{oldest} = $self -> parse_date($config{date_from});
    }
    $config{latest} = time;
    if ($config{date_to}) {
        $config{latest} = $self -> parse_date($config{date_to});
    }

    $self -> {config} = \%config;
    return \%config;
}

sub parse_date {
    my ($self, $date_str) = @_;

    my $epoch = eval {
        my $t = Time::Piece -> strptime($date_str, '%Y-%m-%d');
        return $t -> epoch;
    };

    if (!defined $epoch) {
        die "Invalid date format: $date_str (use YYYY-MM-DD)\n";
    }

    return $epoch;
}

sub print_usage {
    print <<'USAGE';
Kasumi - Slack Message Extractor

Usage: perl kasumi.pl --token <TOKEN> [OPTIONS]

Required:
  --token <TOKEN>        Slack token (xoxp-... for OAuth, xoxc-... for cookie)

Optional (for cookie auth):
  --cookie-d <VALUE>     Required when using xoxc- token (d cookie value)

Search Options:
  --keywords <TEXT>      Search using Slack's native search API (efficient)
  --random-search        Use random keywords for searching (ignores --keywords)
  --wordlist <FILE>      Custom wordlist file for random search (default: wordlist.txt)
  --context <NUM>        Capture N messages before and after each match (e.g., --context 2)

Download Options:
  --download-all         Download ALL messages from all conversations (offline use)
  --size-limit <MB>      Size limit in MB for --download-all (default: 1024 = 1GB)

Other Options:
  --from <DATE>          Extract messages from this date (YYYY-MM-DD)
  --to <DATE>            Extract messages until this date (YYYY-MM-DD)
  --output <FILE>        Output JSON file (default: slack_messages.json)
  --threads              Extract thread replies for threaded messages
  --no-verify-ssl        Disable SSL certificate verification (testing only!)
  --help                 Show this help message

Examples:

  perl kasumi.pl --token xoxp-your-token --keywords "important"

  perl kasumi.pl --token xoxc-your-token --cookie-d xoxd-your-d-cookie --keywords "password"

  perl kasumi.pl --token xoxp-your-token --download-all

  perl kasumi.pl --token xoxp-your-token --download-all --size-limit 2048

  perl kasumi.pl --token xoxp-your-token --download-all --from 2024-01-01 --threads

  perl kasumi.pl --token xoxp-your-token --random-search

  perl kasumi.pl --token xoxp-your-token --random-search --wordlist my_words.txt

  perl kasumi.pl --token xoxp-your-token --keywords "password" --context 3

USAGE

    return;
}

1;
