use Test::More tests => 4;;
use Posterous;
use Posterous::Request;
use HTTP::Response;

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


