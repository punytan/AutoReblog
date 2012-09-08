use strict;
use warnings;

use URI;
use Plack::Request;
use Plack::Builder;
use Plack::Session;
use OAuth::Lite::Consumer;
use Data::Dumper;

my $consumer_key    = $ENV{CONSUMER_KEY};
my $consumer_secret = $ENV{CONSUMER_SECRET};

die unless $consumer_key && $consumer_secret;

my $consumer = OAuth::Lite::Consumer->new(
    consumer_key       => $consumer_key,
    consumer_secret    => $consumer_secret,
    callback_url       => 'http://localhost:5000/callbaack',
    site               => 'http://www.tumblr.com/',
    request_token_path => 'http://www.tumblr.com/oauth/request_token',
    access_token_path  => 'http://www.tumblr.com/oauth/access_token',
    authorize_path     => 'http://www.tumblr.com/oauth/authorize',
);

builder {
    enable "Session";
    sub {
        my $req = Plack::Request->new(shift);
        my $session = Plack::Session->new($req->env);

        if ($req->path eq '/') {
            my $request_token = $consumer->get_request_token;
            warn Dumper {request_token => $request_token, consumer => $consumer};

            my $uri = URI->new($consumer->{authorize_path});
            $uri->query_form(oauth_token => $request_token->token);
            warn $uri;

            $session->set(request_token => $request_token);

            my $res = $req->new_response(302);
            $res->header(Pragma => 'no-cache');
            $res->location($uri);

            return $res->finalize;

        } elsif ($req->path eq '/callback') {
            my $params = $req->parameters;

            my $args = {
                token    => $session->get('request_token'),
                verifier => $params->{oauth_verifier},
            };

            my $access_token = $consumer->get_access_token(%$args);

            warn Dumper {
                args => $args,
                access_token => $access_token,
            };

            my $res = $req->new_response(200);
            $res->body(Dumper $access_token);
            return $res->finalize;

        } else {
            $req->new_response(404);
            $req->body("404 Not Found");
            return $req->finalize;
        }

    };
};
