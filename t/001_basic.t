#!perl -w
use strict;
use Test::More;

use Text::Xslate;

my $m = Text::Xslate->new(
    syntax => 'Mustache',
    cache  => 0,
);

is $m->render_string('Hello, {{ MUSTACHE }} world!',
    { MUSTACHE => 'Mustache' }),
    'Hello, Mustache world!', 'a scalar';

is $m->render_string('Hello, {{! MUSTACHE }} world!',
    { MUSTACHE => 'Mustache' }),
    'Hello,  world!', 'a comment';

is $m->render_string('<{{#foo}}ok{{/foo}}>', { foo => 0 }), '<>';
is $m->render_string('<{{#foo}}ok{{/foo}}>', { foo => 1 }), '<ok>';
is $m->render_string('<{{#foo}}ok{{/foo}}>', { foo => [] }), '<>';
is $m->render_string('<{{#foo}}ok{{/foo}}>', { foo => [1] }), '<ok>';
is $m->render_string('<{{#foo}}ok{{/foo}}>', { foo => [1,2] }), '<okok>';

done_testing;
