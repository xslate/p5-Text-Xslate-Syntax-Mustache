#!perl -w
use strict;
use warnings FATAL => 'all';
use Test::More;

use Text::Xslate;
use JE;

my $m = Text::Xslate->new(
    syntax => 'Mustache',
    suffix => '.html',
    cache  => 0,
    path   => 'example',
);

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
    elsif(ref $obj eq 'JE::Function') {
        die 'not implemented';
    }
    elsif(ref $obj eq 'JE::Null') {
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

my @files    = glob('./example/*.js');
my @singles  = grep { !/partial/ } @files;
my @partials = grep {  /partial/ } @files;

foreach my $js(@singles) {
    my($name) = $js =~ /(\w+)\.js$/xms;
    note $name;

    my $je = JE->new();
    $je->eval(slurp($js));

    my $data = js2pl(values %{$je});

    is $m->render("$name.html", $data),
        slurp("./example/$name.txt"), $name
            or die explain($data);
}

done_testing;
