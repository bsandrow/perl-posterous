use Test::More tests => 15;
use Try::Tiny;
use Posterous;

########################################
#### Posterous::get_posts()
####
{
    no warnings 'redefine';

    my $request;
    my $fetch_return = { retval => 666 };
    local *Posterous::_fetch = sub { $request = $_[1]; return $fetch_return };
    local *Posterous::api_token = sub { return 'aPiToKeN' };

    my $api = Posterous->new(email => 'test@example.com', 'password' => 'tru');

    $api->get_posts();
    ok($request->uri()->path() eq '/api/2/users/me/sites/primary/posts',
        'get_posts() uses correct $user and $site defaults');
    ok($request->uri()->query() eq 'api_token=aPiToKeN&page=1',
        'get_posts() uses correct option defaults and adds api_token');

    $api->get_posts(user => 'test_user', site => 'test-site');
    ok($request->uri()->path() eq '/api/2/users/test_user/sites/test-site/posts',
        'get_posts() correctly inserts $user and $site into request url');

    $api->get_posts(page => 2, since_id => 12345, tag => 'sale-item');
    my %actual_params = map { split '=', $_ } split '&', $request->uri()->query();
    my %expected_params = ( api_token => 'aPiToKeN',  page     => 2,
                            tag       => 'sale-item', since_id => 12345 );
    is_deeply(
        \%actual_params,
        \%expected_params,
        'get_posts() correctly handles optional params');

    $api->get_posts(public => 1);
    ok($request->uri()->path() eq '/api/2/users/me/sites/primary/posts/public',
        'get_posts() has correct request url when public => 1');

    $api->get_posts(noauth => 1, user => 'qwerty', public => 1);
    ok($request->uri()->path() eq '/api/2/users/qwerty/sites/primary/posts/public',
        'get_posts() uses correct path when noauth is true');
    ok(!$request->header('Authentication'),
        'get_posts() adds no auth header when noauth is true');
    ok($request->uri()->query() eq 'page=1',
        'get_posts() adds no api_token when noauth is true');

    my $croaked = 0;
    try     { $api->get_posts(noauth => 1, public => 1)   }
    catch   { $croaked = 1                                };
    ok($croaked,
        'get_posts() croaks when noauth is true, but user is "me"');

    $croaked = 0;
    try     { $api->get_posts(noauth => 1) }
    catch   { $croaked = 1                 };
    ok($croaked,
        'get_posts() croaks when noauth is true and public is false');
}

########################################
#### Posterous::get_post()
####
{
    no warnings 'redefine';

    my $request;
    my $fetch_return = { retval => 666 };
    local *Posterous::_fetch = sub { $request = $_[1]; return $fetch_return };
    local *Posterous::api_token = sub { return 'aPiToKeN' };

    my $api = Posterous->new(email => 'test@example.com', 'password' => 'tru');

    my $croaked = 0;
    try     { $api->get_post()  }
    catch   { $croaked = 1      };
    ok($croaked, 'get_post() dies when no post_id is given');

    $api->get_post(22);
    ok($request->uri->path() eq '/api/2/users/me/sites/primary/posts/22',
        'get_post() sets the correct defaults, path and inserts post_id correctly');
    ok($request->header('Authorization'),
        'get_post() sets the auth headers');
    ok($request->uri()->query() eq 'api_token=aPiToKeN',
        'get_post() sets api_token in params');

    $api->get_post(25, 1234);
    ok($request->uri->path() eq '/api/2/users/me/sites/1234/posts/25',
        'get_post() sets the defaults $user correctly, inserts $post_id and $site correctly');
}
