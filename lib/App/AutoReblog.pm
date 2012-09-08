package App::AutoReblog;
use sane;
our $VERSION = '0.04';

use JSON;
use LWP::UserAgent;
use WebService::Google::Reader;
use OAuth::Lite::Consumer;
use OAuth::Lite::Token;

sub new {
    my ($class, %args) = @_;

    bless {
        google => {
            username => $args{google}{username},
            password => $args{google}{password},
        },
        tumblr => {
            consumer_key        => $args{tumblr}{consumer_key},
            consumer_secret     => $args{tumblr}{consumer_secret},
            access_token        => $args{tumblr}{access_token},
            access_token_secret => $args{tumblr}{access_token_secret},
        },
        consumer => undef,
    }, $class;
}

sub api_key { shift->{tumblr}{consumer_key} };

sub run {
    my $self = shift;
    my $reader  = $self->reader;
    my @entries = $reader->starred(count => 100)->entries;
    my $base_hostname = $self->me;

    for my $item (@entries) {
        next unless $self->is_tumblr($item);
        $self->reblog($item, $base_hostname);
        $reader->unstar_entry($item);
    }
}

sub reader {
    my $self   = shift;
    my $google = $self->{google};

    WebService::Google::Reader->new(
        username => $google->{username},
        password => $google->{password},
        secure   => 1,
    );
}

sub consumer {
    my $self = shift;

    $self->{consumer} ||= do {
        my $tumblr = $self->{tumblr};

        my $consumer = OAuth::Lite::Consumer->new(
            consumer_key    => $tumblr->{consumer_key},
            consumer_secret => $tumblr->{consumer_secret},
        );

        my $token = OAuth::Lite::Token->new(
            token  => $tumblr->{access_token},
            secret => $tumblr->{access_token_secret},
        );

        $consumer->access_token($token);
        $consumer;
    };
}

sub me {
    my $self = shift;

    my $res = $self->consumer->post("http://api.tumblr.com/v2/user/info");

    $res->is_success or die "[tumblr] (me) " . $res->status_line;

    my $me = JSON::decode_json($res->decoded_content);

    URI->new($me->{response}{user}{blogs}[0]{url})->host;
}

sub reblog {
    my ($self, $item, $base_hostname) = @_;
    my $posts = $self->posts($item);

    return if $posts->{meta}{status} == 404;

    for my $post (@{ $posts->{response}{posts} }) {
        my $res = $self->consumer->request(
            method => 'POST',
            url    => "http://api.tumblr.com/v2/blog/$base_hostname/post/reblog",
            params => {
                id => $post->{id},
                reblog_key => $post->{reblog_key},
            },
        );

        $res->is_success or die "[tumblr] (reblog) " . $res->status_line;
    }
}

sub posts {
    my ($self, $item) = @_;
    my ($uri, $id) = $self->parse($item);
    my $host = $uri->host;

    my $res = LWP::UserAgent->new->get(
        "http://api.tumblr.com/v2/blog/$host/posts",
        id      => $id,
        api_key => $self->api_key,
    );

    JSON::decode_json($res->decoded_content);
}

sub parse {
    my ($self, $item) = @_;
    my $uri  = URI->new($item->link->href);
    my ($id) = ($uri =~ m{/(\d+)$});
    return ($uri, $id);
}

sub is_tumblr {
    my ($self, $item) = @_;
    my $uri = URI->new($item->link->href);
    return $uri->host =~ /\.tumblr\.com$/
        ? 1 : 0;
}

1;
__END__

=head1 NAME

App::AutoReblog -

=head1 SYNOPSIS

  use App::AutoReblog;

=head1 DESCRIPTION

App::AutoReblog is

=head1 AUTHOR

punytan E<lt>punytan@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
