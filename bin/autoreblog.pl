#!/usr/bin/env perl

use sane;
use Encode;
use App::AutoReblog;
use Config::PP;

$Config::PP::DIR = $ARGV[0] || "$ENV{HOME}/.ppconfig";

my $google = config_get "google.com";
my $tumblr = config_get "tumblr.com";

App::AutoReblog->new(
    google => $google,
    tumblr => $tumblr,
)->run;

__END__

