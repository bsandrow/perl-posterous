package Posterous::Request;

use base qw/ HTTP::Request /;

use URI::Escape;

sub add_api_token
{
    my ($self, $api_token) = @_;
    $self->add_get_params({ api_token => $api_token });
}

sub add_get_params
{
    my ($self, $params) = @_;
    my $uri = $self->uri();
    my @new_params =
        map { uri_escape($_) . "=" . uri_escape($params->{$_}) }
            (keys %$params);
    unshift @new_params, $uri->query() if $uri->query();
    $uri->query( join '&', @new_params );
}

sub add_post_params
{
    my ($self, $content) = @_;

    # Ripped from HTTP::Request::Common::POST()
    require URI;
    my $url = URI->new('http:');
    $url->query_form(ref($content) eq "HASH" ? %$content : @$content);
    $content = $url->query;

    $self->header('Content-Type' => 'application/x-www-form-urlencoded');
    $self->header('Content-Length' => length($content)) unless ref($content);
    $self->content($content);
}

1;
