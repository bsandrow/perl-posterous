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

sub get_posts
{
    my $self = shift;
    my %opts = (
        public => 0,
        noauth => 0,
        page => 1,
        @_
    );
    my $site    = delete($opts{site}) || 'primary';
    my $user    = delete($opts{user}) || 'me';
    my $public  = delete($opts{public}) ? '/public' : '';

    croak "Cannot turn off authentication unless only fetching public posts"
        if $opts{noauth} && !$public;

    croak "'user = me' makes no sense if with no authentication."
        if $user eq 'me' && $opts{noauth};

    my $request = Posterous::Request->new(
        GET => sprintf('%s/api/2/users/%s/sites/%s/posts%s', baseurl, $user, $site, $public)
    );

    $self->_prepare_request($request) unless delete $opts{noauth};

    $request->add_get_params(\%opts);
    return $self->_fetch($request);
}

sub get_post
{
    my ($self, $post_id, $site, $user) = @_;
    $site ||= 'primary';
    $user ||= 'me';

    croak "A post id is required" unless $post_id;

    my $request = Posterous::Request->new(
        GET => sprintf('%s/api/2/users/%s/sites/%s/posts/%s', baseurl, $user, $site, $post_id)
    );
    $self->_prepare_request($request);
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

=head1 DESCRIPTION

A library for accessing Posterous through the Posterous API. Currently
incomplete, but all of the existing functions should work and are fully
unit-tested (as much as they actually can be without actually hitting
Posterous' servers).

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

Returns a dataset that describes the site.

=over

=item *

B<$user> - The user. (Default: me)

=item *

B<$site> - Defaults to 'primary'

=back

=head2 create_site ( %options )

Create a new posterous site for an existing user.

Options:

=over

=item *

B<name> - THe name of the site. Required.

=item *

B<is_private> - A boolean describing if the site is private or not. (Default: 0)

=item *

B<hostname> - The sub-domain part of the full domain (e.g. I<hostname>.posterous.com)

=item *

B<user> - The user to create the site for. (Default: me)

=back

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

Fetch the list of subscribers to $site for $user.

=over

=item *

B<$user> - The user. Defaults to 'me'.

=item *

B<$site> - Defaults to 'primary.'

=back

=head2 subscribe_to_site ( $site, $user )

Subscribes the current user to the specified site.

=over

=item *

B<$site> - The id of the site to subscribe to (or the shortcut 'primary').
Defaults to 'primary,' though that doesn't make too much sense for the use-case
of this API call.

=item *

B<$user> - The user field. Just here for added flexibility. Defaults to '1'
which is the only value that the API documents mention.

=back

=head2 unsubscribe_from_site ( $site, $user )

Unsubscribes the current user from the specified site. 

=over

=item *

B<$site> - The id of the site to unsubscribe from (or the shortcut 'primary').
Defaults to 'primary,' though that doesn't make too much sense for the use-case
of this API call.

=item *

B<$user> - The user field. Just here for added flexibility. Defaults to '1'
which is the only value that the API documents mention.

=back

=head1 POSTEROUS API: POSTS

=head2 get_posts ( %options )

Fetches all posts for a site. %options are:

=over

=item *

B<public> - Controls whether or not to only operate on public posts.

=item *

B<noauth> - Controls whether or not the API request will be (or attempt to be)
authenticated. Since the API call to get public posts doesn't require
authentication, it makes sense that someone might want to actually use it as
advertised. This option is thus here to be paired with the B<public> option. It
only makes sense when B<public> is true, and the call will croak when B<noauth>
is true if B<public> is not true. Defaults to 0.

=item *

B<user> - The user whose site to fetch posts from. Defaults to 'me' if
authenticating, otherwise requires a value.

=item *

B<site> - The site to fetch posts from. Defaults to 'primary.'

=item *

B<page> - The page number for the results set. Defaults to 1.

=item *

B<since_id> - Retrieve posts created after this id

=item *

B<tag> - Retrieve posts with this tag

=back

Returns the parsed JSON returned from the API. Otherwise, returns undef.

=head2 get_post ( $post_id, $site, $user )

Fetches a specific post.

=over

=item *

B<$post_id> - Required. The ID of the post to fetch.

=item *

B<$site> - Specify the site to fetch the post from. Optional. Defaults to
'primary,' otherwise needs to be a site ID.

=item *

B<$user> - Severely optional. Defaults to 'me.' 'me' is the only value that the API docs
talk about, but the request URL follows the pattern of some other URLs where
the $user can be selected. I've left this in to allow for some flexibility if
$user is ever needed as an option.

=back

=head1 AUTHOR

Brandon Sandrowicz <bsandrow@gmail.com>

=head1 LICENSE

Licensed under the MIT license. See LICENSE file in distribution.

=cut
