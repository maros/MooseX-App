# ============================================================================
package MooseX::App::Message::Renderer::Color;
# ============================================================================
use utf8;

use namespace::autoclean;
use Moose;
extends qw(MooseX::App::Message::Renderer::Basic);

use Term::ANSIColor qw();
use IO::Interactive qw(is_interactive);

BEGIN {
    if ($^O eq 'MSWin32') {
        Class::Load::try_load_class('Win32::Console::ANSI');
    }
};

sub _wrap_color {
    my ($color,$string) = @_;

    return $string
        unless is_interactive() # TODO cache
        && defined $color;

    return Term::ANSIColor::color($color)
        .$string
        .Term::ANSIColor::color('reset');
}

around 'render_node' => sub {
    my ($orig, $self,$block,$indent) = @_;

    my $ret = $orig->($self,$block,$indent);

    if ($block->{a}
        && $block->{a} eq 'error') {
        return _wrap_color('red',$ret);
    } elsif ($block->{t} eq 'headline') {
        return _wrap_color('bold',$ret);
    }
    return $ret;
};


sub render_tag {
    my ($self,$value,$tag) = @_;
    if ($tag eq 'attr' || $tag eq 'version') {
        return _wrap_color('green',$value);
    } elsif ($tag eq 'bold') {
        return  _wrap_color('bold',$value);
    } elsif ($tag eq 'italic') {
        return _wrap_color('italic',$value);
    } elsif ($tag eq 'code') {
        return '"'.$value.'"';
    }
    return $value;
}

sub render_list_key {
    my ($self,$value) = @_;
    return _wrap_color('yellow',$value);
}

sub render_list_value {
    my ($self,$value) = @_;
    return $value;
}

sub render_headline {
    my ($self,$value) = @_;
    return _wrap_color('bold',$value);
}

__PACKAGE__->meta->make_immutable;
1;