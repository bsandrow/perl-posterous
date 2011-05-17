use Test::More tests => 2;
use Posterous;

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

