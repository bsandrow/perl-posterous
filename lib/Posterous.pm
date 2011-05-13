package Posterous;

use common::sense;
use Moose;

use JSON qw/ decode_json /;

use URI::URL;
use LWP::UserAgent;

has email    => ( is => 'rw', isa => 'Str', required => 1 );
has password => ( is => 'rw', isa => 'Str', required => 1 );
has ua       => ( is => 'ro', isa => 'LWP::UserAgent', builder => '_build_ua');
has api_token=> ( is => 'rw', isa => 'Str', lazy_build => 1, builder => '_fetch_api_token');

sub _build_ua { return LWP::UserAgent->new(timeout => 10) }

sub _fetch_api_token
{
    my ($self) = @_;

    my $request = HTTP::Request->new(GET => 'http://posterous.com/api/2/auth/token');
    $request->authorization_basic($self->email(), $self->password());

    my $response = $self->_fetch($request);
    return $response->{api_token};
}

sub _add_api_token
{
    my ($self, $response) = @_;
    my $uri   = $response->uri();
    my $query = $url->query()
                . ($url->query() ? '&' : '?')
                . 'api_token='
                . $self->api_token();
    $url->query($query);
    $response->uri($uri);
    return $response;
}

sub _fetch
{
    my ($self, $request) = @_;

    my $response = $self->ua()->request($request);

    if ($ENV{DEBUG}) {
        use Data::Dumper;
        print Dumper($response);
    }

    return undef unless $response->is_success();
    return decode_json $response->content();
}

sub sites
{
    my ($self, $user) = @_;
    $user ||= 'me';

    my $request = HTTP::Request->new(GET => "http://posterous.com/api/2/users/$user/sites");
    $self->_add_api_token($request);

    my $response = $eslf->_fetch($request);
    return $response;
}

sub site
{
    my ($self, $user, $site) = @_;
    $user ||= 'me';
    $site ||= 'primary';

    my $request = HTTP::Request->new(GET => "http://posterous.com/api/2/users/$user/sites/$site");
    $self->_add_api_token($request);

    my $response = $self->_fetch($request);
    return $response;
}

__PACKAGE__->meta()->make_immutable();

1;

