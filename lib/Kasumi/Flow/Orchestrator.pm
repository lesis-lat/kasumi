package Kasumi::Flow::Orchestrator;

use strict;
use warnings;
use Readonly;
use Kasumi::Config;
use Kasumi::Auth;
use Kasumi::API;
use Kasumi::Component::Search;
use Kasumi::Component::Download;
use Kasumi::Component::Filter;
use Kasumi::Component::Context;
use Kasumi::Component::Output;

our $VERSION = '2.0';

Readonly my $MB_TO_GB => 1024;

sub new {
    my ($class) = @_;
    my $self = {
        config   => undef,
        auth     => undef,
        api      => undef,
        messages => [],
    };
    return bless $self, $class;
}

sub run {
    my ($self, $argv) = @_;

    print "[*] Initializing configuration...\n";
    my $config_component = Kasumi::Config -> new();
    my $config           = $config_component -> process($argv);
    $self -> {config} = $config;

    my $auth = Kasumi::Auth -> new();
    $auth -> process($config);
    $self -> {auth} = $auth;

    if ($config -> {download_all}) {
        print "[*] Download mode: Full extraction (all messages)\n";
        printf "[*] Current size: %.2f MB / %d MB\n", 0,
            $config -> {size_limit};
    }
    if (!$config -> {download_all}
        && ($config -> {keywords} || $config -> {random_search}))
    {
        print "[*] Download mode: Search mode (using Slack search API)\n";
    }

    my $api = Kasumi::API -> new($auth, $config -> {no_verify_ssl});
    $self -> {api} = $api;

    my $filter = Kasumi::Component::Filter -> new();
    if ($config -> {random_search}) {
        $filter -> process_random_search($config);
    }

    print "[*] Starting Slack message extraction...\n";
    print '[*] Keywords: ' . ($config -> {keywords} || 'none') . "\n";
    print '[*] Date range: '
        . ($config -> {date_from} || 'beginning') . ' to '
        . ($config -> {date_to}   || 'now') . "\n";
    my $thread_status = 'disabled';
    if ($config -> {threads}) {
        $thread_status = 'enabled';
    }
    print '[*] Thread extraction: ' . $thread_status . "\n";
    my $context_status = 'disabled';
    if ($config -> {context} > 0) {
        $context_status =
            $config -> {context} . ' messages before/after';
    }
    print '[*] Context extraction: ' . $context_status . "\n\n";

    my $messages;

    if ($config -> {keywords} && !$config -> {random_search}) {

        my $search = Kasumi::Component::Search -> new($api);
        $messages = $search -> process($config -> {keywords},
            $config -> {oldest}, $config -> {latest});

        $filter -> process_thread_extraction($messages, $api, $config);

        if ($config -> {context} > 0) {
            my $context = Kasumi::Component::Context -> new($api);
            $messages = $context -> process($messages, $config -> {context});
        }

    }
    if (!($config -> {keywords} && !$config -> {random_search})) {

        my $download = Kasumi::Component::Download -> new($api);
        $messages = $download -> process($config);
    }

    $self -> {messages} = $messages;

    my $output = Kasumi::Component::Output -> new();
    $output -> process($messages, $config);

    return 1;
}

sub get_messages {
    my ($self) = @_;
    return $self -> {messages};
}

sub get_config {
    my ($self) = @_;
    return $self -> {config};
}

1;
