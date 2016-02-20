# Use case: HTTP/1.0: GET until EOF
use warnings;
use strict;
use t::share;

@CheckPoint = (
    [ 'client', HTTP_SENT,  undef, 3], 'client: got HTTP_SENT (3 requests)',
    [ 'client', HTTP_RECV,  undef, 1], 'client: got HTTP_RECV',
    [ 'client', HTTP_RECV,  undef, 1], 'client: got HTTP_RECV',
    [ 'client', HTTP_RECV,  undef, 1], 'client: got HTTP_RECV',
    [ 'timeout',                    ], 'timeout: no EOF',
);
plan tests => 3 + @CheckPoint/2;


IO::Stream->new({
    host        => 'www.google.com',
    port        => 80,
    cb          => \&client,
    wait_for    => EOF|HTTP_SENT|HTTP_RECV,
    out_buf     => "GET / HTTP/1.1\nHost: www.google.com\n\n" x 3,
    in_buf_limit=> 102400,
    plugin      => [
        http        => IO::Stream::HTTP::Persistent->new(),
    ],
});

my $t_timeout;

EV::loop;


sub client {
    my ($io, $e, $err) = @_;
    my $http = $io->{plugin}{http};
    my $n
        = $e & HTTP_SENT ? @{ $http->{out_sizes} }
        : $e & HTTP_RECV ? @{ $http->{in_sizes}  }
        : undef;
    $http->{out_sizes} = [];
    $http->{in_sizes}  = [];
    checkpoint($e, $err, $n // ());
    if ($e & HTTP_RECV) {
        like($io->{in_buf}, qr{\AHTTP/\d+\.\d+ }, 'got reply from web server');
        $t_timeout = EV::timer 1, 0, \&timeout;
    }
    EV::unloop if $e & EOF || $err;
}

sub timeout {
    checkpoint();
    EV::unloop;
}
