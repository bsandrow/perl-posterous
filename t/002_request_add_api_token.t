
use Test::Simple tests => 3;
use Posterous::Request;

use vars qw($request $result);

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
