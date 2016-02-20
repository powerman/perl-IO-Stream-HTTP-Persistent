[![Build Status](https://travis-ci.org/powerman/perl-IO-Stream-HTTP-Persistent.svg?branch=master)](https://travis-ci.org/powerman/perl-IO-Stream-HTTP-Persistent)
[![Coverage Status](https://coveralls.io/repos/powerman/perl-IO-Stream-HTTP-Persistent/badge.svg?branch=master)](https://coveralls.io/r/powerman/perl-IO-Stream-HTTP-Persistent?branch=master)

# NAME

IO::Stream::HTTP::Persistent - HTTP persistent connections plugin

# VERSION

This document describes IO::Stream::HTTP::Persistent version v0.2.0

# SYNOPSIS

    use IO::Stream;
    use IO::Stream::HTTP::Persistent;

    IO::Stream->new({
        ...
        wait_for => EOF|HTTP_SENT|HTTP_RECV,
        cb => \&io,
        out_buf => join(q{}, @http_requests),
        ...
        plugin => [
            ...
            http    => IO::Stream::HTTP::Persistent->new(),
            ...
        ],
    });

    sub io {
        my ($io, $e, $err) = @_;
        my $http = $io->{plugin}{http};
        if ($e & HTTP_SENT) {
            printf "%d requests was sent\n", 0+@{ $http->{out_sizes} };
            $http->{out_sizes} = [];
        }
        if ($e & HTTP_RECV) {
            while (my $size = shift @{ $http->{in_sizes} }) {
                my $http_reply = substr $io->{in_buf}, 0, $size, q{};
                ...
            }
        }
        ...
    }

# DESCRIPTION

This module is plugin for [IO::Stream](https://metacpan.org/pod/IO::Stream) which allow you to process
complete HTTP requests and responses read/written by this stream.
It's useful only for persistent HTTP connections (HTTP/1.0 with Keep-Alive
and HTTP/1.1).

On usual HTTP/1.0 non-persistent connections it's ease to detect sent HTTP
request using SENT event and received HTTP response using EOF event.
But on persistent connections that's become much more complicated: to
detect end of single received HTTP response (or boundaries between several
received responses) you have to parse HTTP protocol, and when HTTP/1.1
Pipelining is used it's not easy to find out how many complete requests
was already sent.

This module will parse HTTP protocol for sent and received data, and will
generate non-standard events HTTP\_SENT and HTTP\_RECV when one or more
complete HTTP requests will be sent or HTTP responses received.
It will provide you with list of sizes for each sent request and received
response, which make it ease to find how many requests was sent or get
separate responses from {in\_buf}.

# EXPORTS

This modules doesn't export any functions/methods/variables, but it exports
some constants. There two groups of constants: events and errors
(which can be imported using tags ':Event' and ':Error').
By default all constants are exported.

Events:

    HTTP_SENT HTTP_RECV

Errors:

    HTTP_EREQINCOMPLETE HTTP_ERESINCOMPLETE

Errors are similar to $! - they're dualvars, having both textual and numeric
values.

# INTERFACE 

- new()

    Create and return new IO::Stream plugin object.

# PUBLIC FIELDS

- in\_sizes =\[\]
- out\_sizes =\[\]

    Size of each complete sent HTTP request or received HTTP response
    will be pushed into these fields.

    You can remove elements from these arrays if you need, but you should
    keep these fields in ARRAYREF format.

# EVENTS

- HTTP\_SENT
- HTTP\_RECV

    These non-standard events will be generated when one or more complete HTTP
    requests will be sent or one or more HTTP responses will be received.
    Their sizes will be push()ed into fields {out\_sizes} and {in\_sizes} before
    generating events.

    Instead of using these events you can use standard IN and OUT events and
    check is new items was added to {out\_sizes} and {in\_sizes}.

# ERRORS

- HTTP\_EREQINCOMPLETE

    All HTTP headers of one request MUST be appended to {out\_buf} using
    single $io->write(), otherwise you'll get HTTP\_EREQINCOMPLETE.
    It's safe to add request body after that using any amount of $io->write().

    You can safely continue I/O after receiving HTTP\_EREQINCOMPLETE, but after
    that error you'll not get HTTP\_SENT event and {out\_sizes} won't be updated
    anymore.

- HTTP\_ERESINCOMPLETE

    Unexpected EOF happens while receiving HTTP response.

# LIMITATIONS

- This plugin usually should be first (top) plugin in IO::Stream object's
plugin chain, because if upper plugins will somehow modify {in\_buf} or
{out\_buf} then values in {in\_sizes} and {out\_sizes} may become wrong.
- {out\_buf} MUST NOT be modified in any way except by appending new data.
- Partial HTTP response in {in\_buf} MUST NOT be modified.
It's safe to cut from start of {in\_buf} complete HTTP responses.

# SUPPORT

## Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at [https://github.com/powerman/perl-IO-Stream-HTTP-Persistent/issues](https://github.com/powerman/perl-IO-Stream-HTTP-Persistent/issues).
You will be notified automatically of any progress on your issue.

## Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

[https://github.com/powerman/perl-IO-Stream-HTTP-Persistent](https://github.com/powerman/perl-IO-Stream-HTTP-Persistent)

    git clone https://github.com/powerman/perl-IO-Stream-HTTP-Persistent.git

## Resources

- MetaCPAN Search

    [https://metacpan.org/search?q=IO-Stream-HTTP-Persistent](https://metacpan.org/search?q=IO-Stream-HTTP-Persistent)

- CPAN Ratings

    [http://cpanratings.perl.org/dist/IO-Stream-HTTP-Persistent](http://cpanratings.perl.org/dist/IO-Stream-HTTP-Persistent)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/IO-Stream-HTTP-Persistent](http://annocpan.org/dist/IO-Stream-HTTP-Persistent)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=IO-Stream-HTTP-Persistent](http://matrix.cpantesters.org/?dist=IO-Stream-HTTP-Persistent)

- CPANTS: A CPAN Testing Service (Kwalitee)

    [http://cpants.cpanauthors.org/dist/IO-Stream-HTTP-Persistent](http://cpants.cpanauthors.org/dist/IO-Stream-HTTP-Persistent)

# AUTHOR

Alex Efros &lt;powerman@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Alex Efros &lt;powerman@cpan.org>.

This is free software, licensed under:

    The MIT (X11) License
