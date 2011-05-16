use Test::More tests => 7;
use Posterous;

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
