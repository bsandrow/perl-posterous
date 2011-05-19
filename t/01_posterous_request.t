use Test::Simple tests => 9;
use Posterous::Request;

use vars qw($request $result);

########################################
#### Posterous::Request::add_get_params()
####
{
    $request = Posterous::Request->new(GET => 'http://posterous.com/');
    $request->add_get_params({ test => '123' });
    $result = $request->uri()->as_string();
    ok(
        $result eq "http://posterous.com/?test=123",
        'Add query to URL with no query works'
    );

    $request = Posterous::Request->new(GET => 'http://posterous.com/?test=123');
    $request->add_get_params({ '123' => '345' });
    $result = $request->uri()->as_string();
    ok(
        $result eq "http://posterous.com/?test=123&123=345",
        'Add to pre-existing query (base case)'
    );

    $request = Posterous::Request->new(GET => 'http://posterous.com/?test=123');
    $request->add_get_params({ '12#4' => '3 & 5' });
    $result = $request->uri()->as_string();
    ok(
        $result eq "http://posterous.com/?test=123&12%234=3%20%26%205",
        'Special characters are escaped'
    );
}

########################################
#### Posterous::Request::add_api_token()
####
{
    $request = Posterous::Request->new(GET => 'http://posterous.com/');
    $request->add_api_token('TOKEN_BLAH');
    $result = $request->uri()->as_string();
    ok(
        $result eq "http://posterous.com/?api_token=TOKEN_BLAH",
        'Adding api_token to URL without a query'
    );

    $request = Posterous::Request->new(GET => 'http://posterous.com/?var=value');
    $request->add_api_token('TOKEN_BLAH');
    $result = $request->uri()->as_string();
    ok(
        $result eq "http://posterous.com/?var=value&api_token=TOKEN_BLAH",
        'Adding api_token to URL with a query'
    );

    $request = Posterous::Request->new(GET => 'http://posterous.com/?var=value');
    $request->add_api_token('TOKEN BLAH');
    $result = $request->uri()->as_string();
    ok(
        $result eq "http://posterous.com/?var=value&api_token=TOKEN%20BLAH",
        'api_token value is URI escaped'
    );
}

########################################
#### Posterous::Request::add_post_params()
####
{
    $request = Posterous::Request->new(POST => 'http://posterous.com/');
    $request->add_post_params({ test => '123' });
    $result = $request->content();
    ok(
        $result eq "test=123",
        'add_post_params() works in the base case'
    );

    $request = Posterous::Request->new(POST => 'http://posterous.com/');
    $request->add_post_params({ '123' => '345', test => '123'});
    $result = $request->content();
    ok(
        $result eq "123=345&test=123",
        "add_post_params() works for multiple keys"
    );

    $request = Posterous::Request->new(POST => 'http://posterous.com/');
    $request->add_post_params({ test => '123', '12#4' => '3 & 5' });
    $result = $request->content();
    ok(
        $result eq "test=123&12%234=3+%26+5",
        'add_post_params() escapes special characters'
    );
}
