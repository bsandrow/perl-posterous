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
has last_response=>( is => 'rw', isa => 'HTTP::Response' );

sub _build_ua { return LWP::UserAgent->new(timeout => 10) }

sub _fetch
{
    my ($self, $request) = @_;

    my $response = $self->ua()->request($request);

    if ($ENV{DEBUG}) {
        use Data::Dumper;
        print Dumper($response);
    }

    $self->last_response($response);
    return undef unless $response->is_success();
    return decode_json $response->content();
}

sub _prepare_request
{
    my ($self, $request) = (shift, shift);
    my %options = (no_auth  => 0, no_token => 0, @_);
    $request->authorization_basic($self->email(), $self->password()) unless $options{no_auth};
    $request->add_api_token($self->api_token()) unless $options{no_token};
}

sub fetch_api_token
{
    my ($self) = @_;

    my $request = Posterous::Request->new(
        GET => sprintf("%s/api/2/auth/token", baseurl)
    );
    $self->_prepare_request($request, no_token => 1);

    my $response = $self->_fetch($request);
    return $response->{api_token};
}

sub sites
{
    my ($self, $user) = @_;
    $user ||= 'me';

    my $request = Posterous::Request->new(
        GET => sprintf("%s/api/2/users/%s/sites", baseurl, $user)
    );
    $self->_prepare_request($request);

    return $self->_fetch($request);
}

sub site
{
    my ($self, $user, $site) = @_;
    $user ||= 'me';
    $site ||= 'primary';

    my $request = Posterous::Request->new(
        GET => sprintf("%s/api/2/users/%s/sites/%s", baseurl, $user, $site)
    );
    $self->_prepare_request($request);

    return $self->_fetch($request);
}

sub create_site
{
    my $self = shift;
    my %options = (
        user        => 'me',
        is_private  => 0,
        name        => undef,
        hostname    => undef,
        @_
    );

    croak "create_site() requires a name"     unless $options{name};
    croak "create_site() requires a hostname" unless $options{hostname};

    my $request = Posterous::Request->new(
        POST => sprintf("%s/api/2/users/%s/sites", baseurl, $options{user})
    );
    $self->_prepare_request($request);
    $request->add_post_params({
        name        => $options{name},
        is_private  => $options{is_private},
        hostname    => $options{hostname},
    });
    return $self->_fetch($request);
}

sub delete_site
{
    my ($self, $site, $user) = @_;
    croak "Error: delete_site requests a site to delete!" unless $site;
    $user ||= 'me';
    my $request = Posterous::Request->new(
        DELETE => sprintf("%s/api/2/users/%s/sites/%s", baseurl, $user, $site)
    );
    $self->_prepare_request($request);
    return defined($self->_fetch($request));
}

sub get_site_subscribers
{
    my ($self, $user, $site) = @_;

    # XXX What's with the /api/2/users/1/sites stuff? Why '1' instead of 'me' as
    # an alias for the current user?

    # XXX The couple of times I've tried this api call against the live site,
    # I've gotten back 500 errors. Maybe I should contact them about this.

    $user ||= '1';
    $site ||= 'primary';
    my $request = Posterous::Request->new(
        GET => sprintf("%s/api/2/users/%s/sites/%s/subscribers", baseurl, $user, $site)
    );
    $self->_prepare_request($request);
    return $self->_fetch($request);
}

sub subscribe_to_site
{
    my ($self, $site, $user) = @_;
    $user ||= '1';
    $site ||= 'primary';
    my $request = Posterous::Request->new(
        GET => sprintf("%s/api/2/users/$user/sites/$site/subscribe", baseurl, $user, $site)
    );
    $self->_prepare_request($request);
    return $self->_fetch($request);
}

sub unsubscribe_from_site
{
    my ($self, $site, $user) = @_;
    $user ||= '1';
    $site ||= 'primary';
    my $request = Posterous::Request->new(
        GET => sprintf("%s/api/2/users/$user/sites/$site/unsubscribe", baseurl, $user, $site)
    );
    $self->_prepare_request($request);
    return $self->_fetch($request);
}

sub get_public_posts
{
    my $self = shift;
    my %opts = (
        noauth => 0,
        page => 1,
        @_
    );
    my $site = delete($opts{site}) || 'primary';
    my $user = delete($opts{user}) || 'me';

    croak "'user = me' makes no sense if with no authentication."
        if $user eq 'me' && $opts{noauth};

    my $request = Posterous::Request->new(
        GET => sprintf('%s/api/2/users/%s/sites/%s/posts/public', baseurl, $user, $site)
    );

    $self->_prepare_request($request) unless delete $opts{noauth};

    $request->add_get_params(\%opts);
    return $self->_fetch($request);
}

__PACKAGE__->meta()->make_immutable();

1;

=head1 NAME

Posterous - API access to posterous.com

=head1 SYNOPSIS

    use strict;
    use Posterous;

    my $api = Posterous->new(email => 'user@example.com', password => 'MyPuppEDog');

    my $site = $api->get_site(); # your primary site

    my $posts = $api->get_public_posts(site => $site->{id}, page => 2);


=head1 POSTEROUS API: AUTH

=head2 fetch_api_token

Uses the email-password combination to grab an API access token from the
Posterous API. Rather than directly passing back the JSON-parsed structure,
pulls the api_token out of it (and therefore will return undef if it's not
there).

=head1 POSTEROUS API: SITES

=head2 sites ( $user )

Returns a list of data structures that each represents a site that is
associated with the specified user. $user defaults to 'me' (which is a shortcut
for the currently authorized user).

=head2 site ( $user, $site )

Returns a structured dataset for the specificed user/site combination. $user
defaults to the shortcut 'me' and $site defaults to the shortcut 'primary.'

=head2 create_site ( %options )

Creates a posterous site for a particular user.

Options:

    name        The name of the site (required)
    is_private  A boolean describing if the site if private or not. (default: 0)
    hostname    The sub-domain part of the full domain (e.g.
                {hostname}.posterous.com)
    user        The user to create the site for. (default: me)

Returns a data structure like:

    {
        "name"              : "twoism's posterous",
        "is_private"        : false,
        "full_hostname"     : "twoism.posterous.com",
        "posts_count"       : 224,
        "id"                : 1752789,
        "comment_permission": 2,
        "posts_url"         : "/api/2/users/637118/sites/1752789/posts"
    }

=head2 delete_site ( $site, $user )

Delete the site specified by $site and $user. $user defaults to 'me,' but $site
is required. I feel that it would be too easy to accidentally perform an
unintented destructive operation if $site defaulted to 'primary.' (And it would
be especially destructive because, presumably, you primary site is the most
important one to you). $site can either be the site id or hostname.

Returns a boolean depending on whether or not the site was successfully deleted.

=head2 get_site_subscribers ( $user, $site )

Fetch the list of subscribers to $site for $user. $user defaults to 'me' and
$site defaults to 'primary.' $site can either be a hostname or site id.

=head2 subscribe_to_site ( $site, $user )

Subscribes the current user to the specified site. $site defaults to 'primary,'
but that doesn't make particular sense (to be subscribed to your own primary
site), so you should probably specify a $site. $user defaults to '1,' and the
Posterous API docs don't specify whether or not a user option is acceptable. It
probably isn't, but I'm leaving the $user option in just in case the API
changes in the future.

=head2 unsubscribe_from_site ( $site, $user )

Unsubscribes the current user from the specified site. $site defaults to
'primary,' though you'll probably just want to set this to something. $user is
just here for added flexibility, and is not indended to be used at this time.
$user defaults to '1' (which is the only documented value in the API docs).

=head1 POSTEROUS API: POSTS

=head2 get_public_posts ( %options )

Fetches all public posts for a site. %options are:

=over 3

=item noauth

Controls whether or not the API request will be (or attempt to be)
authenticated. Since this API call doesn't require authentication (the posts
are I<public> after all), this allows access to this API call without any auth
info. Defaults to 0.

=item user

The user whose site to fetch posts from. Defaults to 'me' if authenticating,
otherwise requires a value.

=item site

The site to fetch posts from. Defaults to 'primary.'

=item page

The page number for the results set. Defaults to 1.

=item since_id

Retrieve posts created after this id

=item tag

Retrieve posts with this tag

=back

Returns the parsed JSON returned from the API. Otherwise, returns undef.

=head1 AUTHOR

Brandon Sandrowicz <bsandrow@gmail.com>

=head1 LICENSE

Licensed under the MIT license. See LICENSE file in distribution.

=cut
