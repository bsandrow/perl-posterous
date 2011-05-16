package Posterous;

use common::sense;
use Moose;

use JSON qw/ decode_json /;
use Carp qw/ croak       /;

use Posterous::Request;
use URI::URL;
use LWP::UserAgent;

use constant baseurl => 'http://posterous.com';

has email       => ( is => 'rw', isa => 'Str', required => 1 );
has password    => ( is => 'rw', isa => 'Str', required => 1 );
has ua          => ( is => 'ro', isa => 'LWP::UserAgent', builder => '_build_ua');
has api_token   => ( is => 'rw', isa => 'Str', lazy_build => 1, builder => 'fetch_api_token');
has api_formats => (
    is => 'ro',
    isa => 'HashRef',
    builder => '_build_api_formats',
    traits => ['Hash'],
    handles => {
        get_api_format => 'get',
    },
);

sub _build_ua { return LWP::UserAgent->new(timeout => 10) }

sub _build_api_formats
{
    {
        auth_token           => '/api/2/auth/token',
        get_post             => '/api/2/users/%s/sites/%s/posts/%s',
        get_public_posts     => '/api/2/users/%s/sites/%s/posts/public',
        sites                => '/api/2/users/%s/sites',
        site                 => '/api/2/users/%s/sites/%s',
        delete_site          => '/api/2/users/%s/sites/%s',
        get_site_subscribers => '/api/2/users/1/sites/%s/subscribers',
    }
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

sub _api_url
{
    my ($self, $format_id, @params) = @_;
    return baseurl . sprintf($self->get_api_format($format_id), @params);
}

=head1 POSTEROUS API FUNCTIONS

=cut

=head2 fetch_api_token

Uses the email-password combination to grab an API access token from the
Posterous API. Rather than directly passing back the JSON-parsed structure,
pulls the api_token out of it (and therefore will return undef if it's not
there).

=cut

sub fetch_api_token
{
    my ($self) = @_;

    my $request = Posterous::Request->new(GET => $self->_api_url('auth_token'));
    $request->authorization_basic($self->email(), $self->password());

    my $response = $self->_fetch($request);
    return $response->{api_token};
}

=head2 sites ( $user )

Returns a list of data structures that each represents a site that is
associated with the specified user. $user defaults to 'me' (which is a shortcut
for the currently authorized user).

=cut

sub sites
{
    my ($self, $user) = @_;
    $user ||= 'me';

    my $request = Posterous::Request->new(GET => $self->_api_url('sites', $user));
    $request->add_api_token($self->api_token());

    my $response = $self->_fetch($request);
    return $response;
}

sub site
{
    my ($self, $user, $site) = @_;
    $user ||= 'me';
    $site ||= 'primary';

    my $request = Posterous::Request->new(GET => $self->_api_url('site', $user, $site));
    $request->add_api_token($self->api_token());

    my $response = $self->_fetch($request);
    return $response;
}

sub delete_site
{
    my ($self, $site, $user) = @_;
    croak "Error: delete_site requests a site to delete!" unless $site;
    $user ||= 'me';
    my $api_url = $self->_api_url('delete_site', $user, $site);
    my $request = Posterous::Request->new(DELETE => $api_url);
    $request->add_api_token($self->api_token());
    return $self->_fetch($request);
}

sub get_site_subscribers
{
    my ($self, $site) = @_;
    $site ||= 'primary';
    my $api_url = $self->_api_url('get_site_subscribers', $site);
    my $request = Posterous::Request->new(GET => $api_url);
    $request->add_api_token($self->api_token());
    return $self->_fetch($request);
}

=head1 FUNCTIONS - POSTS
=cut

=head2 get_public_posts ( $user, $site, %options )

Fetches all public posts for a site. Valid %options are: 'since_id,' 'page' and
'tag.' From the Posterous API docs:

    :page     => INT # page number for results set
    :since_id => INT # retrieve posts created after this id
    :tag      => String # retrieve posts with this tag

Returns the parsed JSON response from the API or else undef.

=cut

sub get_public_posts
{
    my ($self, $user, $site, %options) = @_;
    $user ||= 'me';
    $site ||= 'primary';
    foreach my $opt (keys %options) {
        croak "Error: $opt is not an option"
            unless any { "$_" eq "$opt" } ('since_id', 'page', 'tag');
    }
    my $api_url = $self->_api_url('get_public_posts', $user, $site);
    my $request = Posterous::Request->new(GET => $api_url);
    $request->add_get_pararms(\%options);
    return $self->_fetch($request);
}

=head2 get_post ($post_id, $user, $site)

=cut

sub get_post
{
    my ($self, $post_id, $user, $site) = @_;
    croak "Error: get_post requires post_id!" unless $post_id;
    $user ||= 'me';
    $site ||= 'primary';
    my $request =
        Posterous::Request->new(GET => $self->_api_url('get_post', $user, $site, $post_id));
    $request->add_api_token($self->api_token());
    return $self->_fetch($request);
}

__PACKAGE__->meta()->make_immutable();

1;

=head1 ATTRIBUTES

=head2 api_token

This is an attribute that lazy builds itself by pinging the Posterous API for
the api_token. This is mostly for internal use, but if you want to do something
like control B<when> the auth token is fetched, just accessing this attribute
will trigger that (the first time it's accessed).

=head1 FUNCTIONS

All functions are just wrappers around Posterous API calls that parse out the
returned JSON and return the data structures.

=head2 sites ($user)

Returns a list of dumps for all sites that a specific user has. $user defaults
to 'me.'

=head2 site ($user, $site)

Returns a dump of data about a specific user/site combination. $user defaults
to 'me' and $site defaults to 'primary.'

=head2 delete_site ($site, $user)

Delete the site specified by $site and $user. $user defaults to 'me,' but $site
is required because it would be 'dangerous' to just allow it to default to
'primary.' Auto-magically deleteing your primary site is probably a Bad
Thing (tm).

=head2 get_site_subscribers ($site)

Fetches the list of subscribers to the specified site.

=head2 subscribe_to_site ($site)

From the API documentation, "This will add the given site to the current users
subscriptions." $site defaults to 'primary.'

=head2 unsubscribe_site ($site)

From the API documentation: "This will remove the given site to the current
users subscriptions." $site defaults to 'primary.'

=cut
