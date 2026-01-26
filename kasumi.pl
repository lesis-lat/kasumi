#!/usr/bin/env perl

use strict;
use warnings;
use English qw(-no_match_vars);
use FindBin;
use lib "$FindBin::Bin/lib";

use Kasumi::Flow::Orchestrator;

our $VERSION = '2.0';

my $orchestrator = Kasumi::Flow::Orchestrator -> new();

my $success = eval {
    $orchestrator -> run(\@ARGV);
    1;
};

if (!$success) {
    my $error = $EVAL_ERROR;
    die "Fatal error: $error\n";
}

exit 0;
