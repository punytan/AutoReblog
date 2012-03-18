package App::AutoReblog;
use sane;
our $VERSION = '0.03';

use Carp;
use JSON;
use LWP::UserAgent;
use WebService::Google::Reader;

sub new {
    my ($class, %args) = @_;

    $args{tumblr}{api_key} ||=
        'YnPjExTByIKq3Orr5zeNp4X3MUNI0Ta6bT0dFRRH4jfXayrfHz';

    bless \%args, $class;
}

sub api_key { shift->{tumblr}{api_key} };

sub run {
    my $self = shift;
    my $reader  = $self->reader;
    my @entries = $reader->starred(count => 100)->entries;

    for my $item (@entries) {
        next unless $self->is_tumblr($item);
        $self->reblog($item);
        $reader->unstar_entry($item);
    }
}

sub reader {
    my ($self) = @_;
    WebService::Google::Reader->new(
        username => $self->{google}{username},
        password => $self->{google}{password},
        secure   => 1,
    );
}

sub reblog {
    my ($self, $item) = @_;

    my $posts = $self->posts($item);
    for my $post (@{ $posts->{response}{posts} }) {
        my $res = LWP::UserAgent->new->post(
            'http://www.tumblr.com/api/reblog', {
                email        => $self->{tumblr}{email},
                password     => $self->{tumblr}{password},
                'post-id'    => $post->{id},
                'reblog-key' => $post->{reblog_key},
            }
        );

        $res->is_success or Carp::croak $res->status_line;
    }
}

sub posts {
    my ($self, $item) = @_;
    my ($uri, $id) = $self->parse($item);
    my $host = $uri->host;

    my $api = URI->new("http://api.tumblr.com/v2/blog/$host/posts");
    $api->query_form(
        api_key => $self->api_key,
        id => $id,
    );

    my $res = LWP::UserAgent->new->get($api);
    if ($res->is_success) {
        return JSON::decode_json $res->content;
    } else {
        Carp::croak "Failed to access tumblr, " . $res->status_line;
    }
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
