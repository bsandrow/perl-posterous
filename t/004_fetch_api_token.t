use Test::More tests => 5;
use Posterous;

my @params;
no warnings 'redefine';
local *Posterous::_fetch = sub { @params = @_; {} };

my $api = Posterous->new(email => 'test@example.com', password => 'passw0rd');
my $result = $api->fetch_api_token();

my $request = $params[1];

ok(ref($request) eq 'Posterous::Request',
    "fetch_api_token() builds a Posterous::Request for _fetch()");

ok($request->uri()->as_string() eq "http://posterous.com/api/2/auth/token",
    "Uses the correct URI for the request");

ok($request->header('Authorization') eq "Basic dGVzdEBleGFtcGxlLmNvbTpwYXNzdzByZA==",
    "Adds the correct basic authorization to the request");

ok(!defined($result),
    "Returns the correct value from the _fetch() result");

local *Posterous::_fetch = sub { @params = @_; { api_token => 'my api token' } };
$result = $api->fetch_api_token();
ok($result eq 'my api token',
    "Returns the correct value from the _fetch() result");
