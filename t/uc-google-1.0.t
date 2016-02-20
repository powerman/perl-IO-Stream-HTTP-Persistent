# Use case: HTTP/1.0: GET until EOF
use warnings;
use strict;
use t::share;

@CheckPoint = (
    [ 'client', HTTP_SENT,  undef   ], 'client: got HTTP_SENT',
    [ 'client', HTTP_RECV,  undef   ], 'client: got HTTP_RECV',
    [ 'client', EOF,        undef   ], 'client: got eof',
);
plan tests => 1 + @CheckPoint/2;


IO::Stream->new({
    host        => 'www.google.com',
    port        => 80,
    cb          => \&client,
    wait_for    => EOF|HTTP_SENT|HTTP_RECV,
    out_buf     => "GET / HTTP/1.0\nHost: www.google.com\n\n",
    in_buf_limit=> 102400,
    plugin      => [
        http        => IO::Stream::HTTP::Persistent->new(),
    ],
});

EV::loop;


sub client {
    my ($io, $e, $err) = @_;
    checkpoint($e, $err);
    if ($e & HTTP_RECV) {
        like($io->{in_buf}, qr{\AHTTP/\d+\.\d+ }, 'got reply from web server');
    }
    EV::unloop if $e & EOF || $err;
}

