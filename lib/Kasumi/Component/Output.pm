package Kasumi::Component::Output;

use strict;
use warnings;
use English qw(-no_match_vars);
use JSON;

our $VERSION = '2.0';

sub new {
    my ($class) = @_;
    my $self = {};
    return bless $self, $class;
}

sub process {
    my ($self, $messages, $config) = @_;

    my $filename = $config -> {output_file};

    print "[*] Saving results to $filename...\n";

    my $json = JSON -> new -> pretty -> canonical;

    my $total_replies = 0;
    foreach my $message (@{$messages}) {
        if ($message -> {thread_replies}) {
            $total_replies += scalar @{$message -> {thread_replies}};
        }
    }

    my $threads_flag = JSON::false;
    if ($config -> {threads}) {
        $threads_flag = JSON::true;
    }

    my $output = $json -> encode(
        {
            extraction_date      => q{} . localtime(),
            total_messages       => scalar @{$messages},
            total_thread_replies => $total_replies,
            filters              => {
                keywords  => $config -> {keywords}  || undef,
                date_from => $config -> {date_from} || undef,
                date_to   => $config -> {date_to}   || undef,
                threads   => $threads_flag,
            },
            messages => $messages,
        }
    );

    open my $fh, '>:encoding(UTF-8)', $filename or do {
        my $error = $OS_ERROR;
        die "Cannot write to $filename: $error\n";
    };
    print {$fh} $output;
    close $fh or do {
        my $error = $OS_ERROR;
        warn "Warning: Failed to close $filename: $error\n";
    };

    print '[+] Extraction complete! Total messages: '
        . scalar @{$messages} . "\n";

    return 1;
}

1;
