use Test::More tests => 8;
use Try::Tiny;
use Posterous;

########################################
#### Posterous::get_public_posts()
####
{
    no warnings 'redefine';

    my $request;
    my $fetch_return = { retval => 666 };
    local *Posterous::_fetch = sub { $request = $_[1]; return $fetch_return };
    local *Posterous::api_token = sub { return 'aPiToKeN' };

    my $api = Posterous->new(email => 'test@example.com', 'password' => 'tru');

    $api->get_public_posts();
    ok($request->uri()->path() eq '/api/2/users/me/sites/primary/posts/public',
        'get_public_posts() uses correct $user and $site defaults');
    ok($request->uri()->query() eq 'api_token=aPiToKeN&page=1',
        'get_public_posts() uses correct option defaults and adds api_token');

    $api->get_public_posts(user => 'test_user', site => 'test-site');
    ok($request->uri()->path() eq '/api/2/users/test_user/sites/test-site/posts/public',
        'get_public_posts() correctly inserts $user and $site into request url');

    $api->get_public_posts(page => 2, since_id => 12345, tag => 'sale-item');
    my %actual_params = map { split '=', $_ } split '&', $request->uri()->query();
    my %expected_params = ( api_token => 'aPiToKeN',  page     => 2,
                            tag       => 'sale-item', since_id => 12345 );
    is_deeply(
        \%actual_params,
        \%expected_params,
        'get_public_posts() correctly handles optional params');

    $api->get_public_posts(noauth => 1, user => 'qwerty');
    ok($request->uri()->path() eq '/api/2/users/qwerty/sites/primary/posts/public',
        'get_public_posts() uses correct path when noauth is true');
    ok(!$request->header('Authentication'),
        'get_public_posts() adds no auth header when noauth is true');
    ok($request->uri()->query() eq 'page=1',
        'get_public_posts() adds no api_token when noauth is true');

    my $croaked = 0;
    try     { $api->get_public_posts(noauth => 1)   }
    catch   { $croaked = 1                          };
    ok($croaked,
        'get_public_posts() croaks when noauth is true, but user is "me"');
}