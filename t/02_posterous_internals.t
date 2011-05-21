use Test::More tests => 15;
use Posterous;
use Posterous::Request;
use HTTP::Response;

########################################
#### Posterous::_build_ua
####
{
    ok(ref(Posterous->_build_ua) eq 'LWP::UserAgent',
        "Posterous::_build_ua returns a LWP::UserAgent instance");
}

########################################
#### Posterous::_build_api_formats
####
{
    is_deeply(
        Posterous->_build_api_formats(),
        {
            auth_token           => "/api/2/auth/token",
            get_post             => "/api/2/users/%s/sites/%s/posts/%s",
            get_public_posts     => "/api/2/users/%s/sites/%s/posts/public",
            sites                => "/api/2/users/%s/sites",
            site                 => "/api/2/users/%s/sites/%s",
            delete_site          => "/api/2/users/%s/sites/%s",
            get_site_subscribers => "/api/2/users/1/sites/%s/subscribers",
        },
        "Posterous::_build_api_formats returns the correct 'key => formatstr' pairs."
    );
}

########################################
#### Posterous::_api_url()
####
{
    no warnings 'redefine';

    my $api_format_key;
    my $api_format_return;
    local *Posterous::get_api_format = sub { $api_format_key = $_[1]; $api_format_return };

    my $api = Posterous->new(email => 'blah', password => 'blah');

    $api_format_return = "/%s,%s";
    my $result = $api->_api_url('test1','test2','test3');
    ok($api_format_key eq 'test1',
        "_api_url() uses first arg as api_format key");
    ok($result eq 'http://posterous.com/test2,test3',
        "_api_url() args 2+ as sprintf() inputs and includes baseurl");
}

########################################
#### Posterous::_fetch()
####
{
    no warnings 'redefine';

    my $api = Posterous->new(email => 'test@example.com', password => 'pass');

    my $request_passed_in;
    my $ua_request_called = 0;
    my $status_code = 200;
    my $content = '{"test":"test"}';
    local *LWP::UserAgent::request = sub {
        $ua_request_called = 1;
        $request_passed_in = $_[1];
        my $response = HTTP::Response->new();
        $response->{_rc} = $status_code;
        $response->{_content} = $content;
        return $response;
    };

    my $request = Posterous::Request->new(GET => 'http://example.com');
    $api->_fetch($request);
    ok($ua_request_called,
        'LWP::UserAgent::request() was called');

    $api->_fetch(1234567);
    ok($request_passed_in == 1234567,
        'The Posterous::Request passed in is the same one passed to LWP::UserAgent::request()');

    $response = $api->_fetch($request);
    is_deeply(
        $response,
        { test => 'test' },
        "HTTP response content is parsed as JSON, and the data structure returned");

    $content = '[{"test1":"foo","test2":"bar"},{"test3":"baz"}]';
    $response = $api->_fetch($request);
    is_deeply(
        $response,
        [ { test1 => 'foo', test2 => 'bar'}, { test3 => 'baz' } ],
        "HTTP response content is parsed as JSON, and the data structure returned");
}

########################################
#### Posterous::_prepare_request()
####
{
    no warnings 'redefine';
    no warnings 'once';

    my $api = Posterous->new(email => 'test@example.com', password => 'MyPass');

    my $auth_basic_called = 0;
    my @auth_basic_creds  = ();
    local *Posterous::Request::authorization_basic = sub {
        $auth_basic_called = 1;
        @auth_basic_creds = @_;
    };

    my $add_api_token_called = 0;
    local *Posterous::Request::add_api_token = sub {
        $add_api_token_called = 1;
        $my_api_token = $_[1];
    };

    local *Posterous::api_token = sub { 'ToKeN' };

    my $request = Posterous::Request->new(GET => 'http://example.com/');
    $api->_prepare_request($request);

    ok($auth_basic_called,
        "_prepare_request() adds basic authorization by default");
    ok($auth_basic_creds[1] && $auth_basic_creds[1] eq 'test@example.com',
        "_prepare_request() passes correct email value to authorization_basic()");
    ok($auth_basic_creds[2] && $auth_basic_creds[2] eq 'MyPass',
        "_prepare_request() passes correct password value to authorization_basic()");

    $auth_basic_called = 0;
    $api->_prepare_request($request, no_auth => 1);
    ok(!$auth_basic_called,
        "_prepare_request() does not add basic auth info when no_auth is true");

    $add_api_token_called = 0;
    $api->_prepare_request($request);
    ok($add_api_token_called,
        "_prepare_request() adds api_token to request");
    ok($my_api_token eq 'ToKeN',
        "_prepare_request() passes Posterous::api_token() value to "
        . "Posterous::Request::add_api_token()");

    $add_api_token_called = 0;
    $api->_prepare_request($request, no_token => 1);
    ok(!$add_api_token_called,
        "_prepare_request() does not add api_token to request when no_token is true");
}
