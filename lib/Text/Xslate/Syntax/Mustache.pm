package Text::Xslate::Syntax::Mustache;
# cf. http://mustache.github.com/mustache.5.html
use 5.008_001;
use Any::Moose;

our $VERSION = '0.01';

use Text::Xslate::Util qw(p any_in);
use Scalar::Util ();

extends qw(Text::Xslate::Parser);

sub _build_identity_pattern {
    # XXX: "#" is hard-coded in the tokanizer
    return qr/(?: [A-Za-z_] [A-Za-z0-9_]* | \# )/xms;
}

# {{ mustache }}
sub _build_line_start { undef }
sub _build_tag_start  { '{{' }
sub _build_tag_end    { '}}' }

around trim_code => sub {
    my($super, $self, $code) = @_;

    if($code =~ /^\!/) { # multiline comments
        return '';
    }

    return $super->($self, $code);
};

#around split => sub {
#    my($super, $self, $input) = @_;
#
#    my $tokens_ref = $super->($self, $input);
#    for(my $i = 0; $i < @{$tokens_ref}; $i++) {
#        my $token = $tokens_ref->[$i];
#        # XXX: really bad know-how :(
#        if($token->[0] eq 'code'
#            && ( $token->[1] =~ m{\A \#}xms || $token->[1] =~ m{/ \z}xms )) {
#            splice @{$tokens_ref}, $i, 1, ['prechomp'], $token, ['postchomp'];
#            $i += 2;
#        }
#    }
#    return $tokens_ref;
#};

sub init_symbols {
    my($parser) = @_;

    # uses {expr} and &expr not to escape values
    $parser->symbol('{')->set_std(\&std_brace);
    $parser->symbol('&')->set_std(\&std_amp);

    # sections
    $parser->symbol('#')->set_std(\&std_pound);
    $parser->symbol('/')->is_block_end(1);
    $parser->symbol('.')->set_nud($parser->can('nud_variable'));

    # partials
    $parser->symbol('>')->set_std(\&std_gt);

    return;
}

sub default_nud {
    my($parser, $symbol) = @_;
    return $parser->nud_variable($symbol);
}

sub undefined_name {
    my($parser, $name) = @_;
    return $parser->symbol('(variable)')->clone(
        id => $name,
    );
}

sub as_list {
    my($parser, $name) = @_;

    my $is_array_ref = $parser->call(is_array_ref => $name);
    my $list0        = $parser->symbol('[')->clone(
        arity => 'composer',
        first => [],
    );
    my $list1        = $parser->symbol('[')->clone(
        arity => 'composer',
        first => [$name],
    );

    # $is_array_ref ? $name : $name ? $list1 : $list0
    my $c = $parser->symbol('#')->clone(
        arity  => 'if',
        first  => $name,
        second => $list1,
        third  => $list0,
    );
    return $parser->symbol('#')->clone(
        arity  => 'if',
        first  => $is_array_ref,
        second => $name,
        third  => $c,
    );
}

# {{#foo}} ... {{/foo}}
# ->
# for __make_list($foo) -> $_ { ... }
sub std_pound {
    my($parser, $symbol) = @_;
    my $name   = $parser->expression(0);
    my $block  = $parser->statements();
    $parser->advance('/');
    $parser->advance($name->id);
    return $symbol->clone(
        arity  => 'for',
        first  => $parser->as_list($name),
        second => [$parser->symbol('.')],
        third  => $block,
    );
}

sub print_raw {
    my($parser, $expr) = @_;
    return $parser->symbol('print_raw')->clone(
        arity => 'print',
        first => [$expr],
        line  => $parser->line,
    );
}

sub std_brace {
    my($parser, $symbol) = @_;
    return $parser->print_raw( $parser->nud_paren($symbol) );
}

sub std_amp {
    my($parser, undef) = @_;
    return $parser->print_raw( $parser->expression(0) );
}

# partials: {{> name}}
sub std_gt {
    my($parser, $symbol) = @_;
    if($parser->token->arity eq 'variable') {
        $parser->token->arity('name');
    }
    my $name = $parser->barename();
    p($name);
    return $symbol->clone(
        arity => 'include',
        id    => 'include',
        first => $name,
    );
}
1;
__END__

=head1 NAME

Text::Xslate::Syntax::Mustache - Perl extention to do something

=head1 VERSION

This document describes Text::Xslate::Syntax::Mustache version 0.01.

=head1 SYNOPSIS

    use Text::Xslate::Syntax::Mustache;

=head1 DESCRIPTION

# TODO

=head1 INTERFACE

# TODO

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Dist::Maker::Template::Default>

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Fuji, Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
