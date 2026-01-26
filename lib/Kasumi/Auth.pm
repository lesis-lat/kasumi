package Kasumi::Auth;

use strict;
use warnings;

our $VERSION = '2.0';

sub new {
    my ($class) = @_;
    my $self = {
        token           => q{},
        cookie_d        => q{},
        use_cookie_auth => 0,
    };
    return bless $self, $class;
}

sub process {
    my ($self, $config) = @_;

    $self -> {token}           = $config -> {token};
    $self -> {cookie_d}        = $config -> {cookie_d};
    $self -> {use_cookie_auth} = $config -> {use_cookie_auth};

    my $auth_message = "[*] Using OAuth token authentication\n";
    if ($self -> {use_cookie_auth}) {
        $auth_message = "[*] Using cookie-based authentication\n";
    }
    print $auth_message;

    return $self;
}

sub get_headers {
    my ($self) = @_;

    my %headers;

    $headers{Authorization} = 'Bearer ' . $self -> {token};
    if ($self -> {use_cookie_auth}) {
        $headers{Cookie} = 'd=' . $self -> {cookie_d} . '; d-s=' . time()
            . '; token=' . $self -> {token};
    }

    return \%headers;
}

sub get_token {
    my ($self) = @_;
    return $self -> {token};
}

1;
