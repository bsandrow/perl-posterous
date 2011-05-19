use Test::More tests => 25;
use Try::Tiny;
use Posterous;

########################################
#### Posterous::sites()
####
{
    no warnings 'redefine';

    my $request;
    local *Posterous::_fetch = sub {
        $request = $_[1];
        return { some_structure => 'goes here' };
    };

    my $api_token_was_called = 0;
    local *Posterous::api_token = sub {
        $api_token_was_called = 1;
        return 'API_TOKEN_GOES_HERE';
    };

    my $result;
    my $request_uri;
    my $api = Posterous->new(email => 'blah@example.com', password => 'PASS_GOES_HERE');

    $result = $api->sites();
    $request_uri = $request->uri()->as_string();

    ok(ref($request) eq 'Posterous::Request',
        'Passes a Posterous::Request object to Posterous::_fetch()');

    ok($request_uri =~ m{http://posterous\.com/api/2/users/\w+/sites},
        "Using the correct Posterous API url");

    ok($request_uri =~ m{/api/2/users/me/sites},
        "\$user defaults to 'me'");

    ok($request_uri =~ m{\?api_token=API_TOKEN_GOES_HERE$},
        "api_token ends up in the query");

    ok($api_token_was_called,
        "api_token attribute was called");

    is_deeply(
        $result,
        { some_structure => 'goes here' },
        "Return from Posterous::_fetch() is passed directly back");

    $result = $api->sites('my_user_name');
    $request_uri = $request->uri()->as_string();

    ok($request_uri =~ m{/api/2/users/my_user_name/sites},
        "Passed-in \$user is placed correctly in the API url");
}

########################################
#### Posterous::site()
####
{
    no warnings 'redefine';

    my $request;
    local *Posterous::_fetch = sub {
        $request = $_[1];
        return { some_structure => 'goes here' };
    };

    my $api_token_was_called = 0;
    local *Posterous::api_token = sub {
        $api_token_was_called = 1;
        return 'API_TOKEN_GOES_HERE';
    };

    my $result;
    my $request_uri;
    my $api = Posterous->new(email => 'blah@example.com', password => 'PASS_GOES_HERE');

    $result = $api->site();
    $request_uri = $request->uri()->as_string();

    ok(ref($request) eq 'Posterous::Request',
        'Passes a Posterous::Request object to Posterous::_fetch()');

    ok($request_uri =~ m{http://posterous\.com/api/2/users/\w+/sites/\w+},
        "Using the correct Posterous API url");

    ok($request_uri =~ m{/api/2/users/me/sites/primary},
        "\$user defaults to 'me' and \$site defaults to 'primary'");

    ok($request_uri =~ m{\?api_token=API_TOKEN_GOES_HERE$},
        "api_token ends up in the query");

    ok($api_token_was_called,
        "api_token attribute was called");

    is_deeply(
        $result,
        { some_structure => 'goes here' },
        "Return from Posterous::_fetch() is passed directly back");

    $result = $api->site('my_user_name', 'my_site');
    $request_uri = $request->uri()->as_string();

    ok($request_uri =~ m{/api/2/users/my_user_name/sites/my_site},
        "Passed-in \$user and \$site are placed correctly in the API url");
}

########################################
#### Posterous::create_site()
####
{
    no warnings 'redefine';

    my $request;
    local *Posterous::_fetch = sub {
        $request = $_[1];
        return { some_structure => 'goes here' };
    };
    my $api_token_was_called = 0;
    local *Posterous::api_token = sub {
        $api_token_was_called = 1;
        return 'API_TOKEN_GOES_HERE';
    };
    my $api = Posterous->new(email => 'test@example.com', password => 'pass');

    my $died = 0;
    try     { $api->create_site(); }
    catch   { $died = 1; }
    finally { ok($died,'create_site() croaks without a name'); };

    $died = 0;
    try     { $api->create_site(name => 'test'); }
    catch   { $died = 1; }
    finally { ok($died, 'create_site() croaks without a hostname'); };

    $api->create_site(name => 'test_site', hostname => 'subdomain');
    ok($api_token_was_called,
        "api_token() was called when running create_site()");

    ok($request->method() eq 'POST',
        "create_site() uses HTTP POST");

    my $url = $request->uri()->as_string();
    ok($url =~ m[http://posterous\.com],
        "create_site() uses the correct baseurl");
    ok($url =~ m[/api/2/users/[^/]+/sites],
        "create_site() uses the correct api url");
    ok($url =~ m[/api/2/users/me/sites],
        "create_site() defaults user to 'me'");
    ok($url =~ m/\?api_token=API_TOKEN_GOES_HERE$/,
        "create_site() adds api_token to request");

    my $content = $request->content();
    ok($content =~ m/(^|&)is_private=0(&|$)/,
        "create_site() defaults private to false");
    ok($content =~ m/(^|&)hostname=subdomain(&|$)/,
        "create_site() adds hostname to POST data");
    ok($content =~ m/(^|&)name=test_site(&|$)/,
        "create_site() adds name to POST data");

}
