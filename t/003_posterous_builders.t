
use Test::More tests => 2;
use Posterous;

# Test Posterous::_build_ua
ok(ref(Posterous->_build_ua) eq 'LWP::UserAgent',
    "Posterous::_build_ua returns a LWP::UserAgent instance");

# Test Posterous::_build_api_formats
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
