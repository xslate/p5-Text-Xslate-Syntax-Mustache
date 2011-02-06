#!perl -w
use strict;
use warnings FATAL => 'all';
use Test::More;

use Text::Xslate;
use JE;

# TODO: move to the core?
my $root;
{
    package _defer;
    use overload
        '""'  => sub { ::js2pl( scalar $_[0]->() ) },
        '@{}' => sub { ::js2pl( scalar $_[0]->() ) },
        fallback => 1;
}
sub defer(&) { bless $_[0], '_defer' }

sub js2pl {
    my($obj) = @_;
    ref($obj) or die explain $obj;

    if(ref $obj eq 'JE::Object') {
        my %hash = %{$obj};
        foreach my $value(values %hash) {
            $value = js2pl($value);
        }
        return \%hash;
    }
    elsif(ref $obj eq 'JE::Object::Array') {
        my @array = @{$obj};
        foreach my $value(@array) {
            $value = js2pl($value);
        }
        return \@array;
    }
    elsif(ref $obj eq 'JE::Object::Function') {
        return defer { $obj->apply($root) } ;
    }
    elsif(ref $obj eq 'JE::Null' or ref $obj eq 'JE::Undefined') {
       return undef;
    }
    return "$obj";
}

sub slurp {
    my($file) = @_;
    local $/;
    open my $fh, '<', $file or die "Failed to open($file): $!";
    return <$fh>;
}

my $m = Text::Xslate->new(
    syntax => 'Mustache',
    suffix => '.html',
    cache  => 0,
    path   => 'examples',
);


my @files    = glob('./examples/*.js');
my @singles  = grep { !/partial/ } @files;
my @partials = grep {  /partial/ } @files;

foreach my $js(@ARGV ? @ARGV : @singles) {
    my($name) = $js =~ /(\w+)\.js$/xms;
    note $name;

    my $je = JE->new();
    my $in = slurp $js;
    $je->eval($in);

    ($root) = values %{$je};
    my $data = js2pl($root);

    my $expected = slurp "./examples/$name.txt";
    $expected =~ s/&#39;/&apos;/g;

    diag $data->{empty} ? 'ok' : 'ng';

    is eval { $m->render("$name.html", $data) }, $expected, $name
            or die $in, explain([slurp("./examples/$name.html")]), $@;
}

done_testing;
