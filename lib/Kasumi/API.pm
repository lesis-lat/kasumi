package Kasumi::API;

use strict;
use warnings;
use English qw(-no_match_vars);
use Readonly;
use LWP::UserAgent;
use JSON;
use HTTP::Request;

our $VERSION = '2.0';

Readonly my $JSON_PREVIEW_LENGTH => 500;

sub new {
    my ($class, $auth, $no_verify_ssl) = @_;

    my $verify_hostname = 1;
    if ($no_verify_ssl) {
        $verify_hostname = 0;
    }

    my $ua = LWP::UserAgent -> new(
        agent    => 'Kasumi/2.0',
        timeout  => 30,
        ssl_opts => {verify_hostname => $verify_hostname},
    );

    my $self = {
        ua   => $ua,
        auth => $auth,
    };

    if ($no_verify_ssl) {
        warn 'WARNING: SSL certificate verification is disabled. '
            . "Use only for testing!\n\n";
    }

    return bless $self, $class;
}

sub request {
    my ($self, $method, $url, $params) = @_;

    my $request;

    if ($method eq 'GET') {
        my $query = join q{&},
            map { $_ . q{=} . $self -> uri_escape($params -> {$_}) }
            keys %{$params};
        if ($query) {
            $url .= q{?} . $query;
        }
        $request = HTTP::Request -> new(GET => $url);
    }
    if ($method ne 'GET') {
        $request = HTTP::Request -> new(POST => $url);
        $request -> content_type('application/json');
        $request -> content(encode_json $params);
    }

    my $headers = $self -> {auth} -> get_headers();
    foreach my $header (keys %{$headers}) {
        $request -> header($header => $headers -> {$header});
    }

    my $response = $self -> {ua} -> request($request);

    if (!$response -> is_success) {
        die 'HTTP error: ' . $response -> status_line . "\n";
    }

    my $content = $response -> content;

    my $json_data = eval { decode_json $content; };

    if (!defined $json_data) {
        my $preview = substr $content, 0, $JSON_PREVIEW_LENGTH;
        my $length  = length $content;
        my $error   = $EVAL_ERROR;
        warn "JSON parsing error: $error\n";
        warn "Response length: $length bytes\n";
        warn "Response preview: $preview\n";
        warn "URL: $url\n";
        return {ok => 0, error => 'json_parse_error'};
    }

    return $json_data;
}

sub uri_escape {
    my ($self, $str) = @_;
    $str =~ s/ ( [^[:alnum:]\-_.~] ) /sprintf '%%%02X', ord $1/egsmx;
    return $str;
}

1;
