
use Test::Simple tests => 3;
use Posterous::Request;

use vars qw($request $result);

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
