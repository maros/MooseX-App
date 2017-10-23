# ============================================================================
package MooseX::App::Message::Renderer;
# ============================================================================
use utf8;
use 5.010;

use namespace::autoclean;
use Moose;

use List::Util qw(max);

has 'screen_width' => (
    is          => 'rw',
    isa         => 'Int',
    default     => 78,
);

has 'indent' => (
    is          => 'rw',
    isa         => 'Int',
    default     => 4,
);

no if $] >= 5.018000, warnings => qw(experimental::smartmatch);

# Format output text for fixed screen width
sub render_text {
    my ($self,$text,$indent) = @_;

    $text = MooseX::App::Utils::string_from_entity($text);

    $indent //= 0;
    if ($indent < 0) {
        return $text;
    }

    my $indent_pos = ($indent * $self->indent);
    my $max_length = $self->screen_width - $indent_pos;

    my @lines;
    foreach my $line (split(/\n/,$text)) {
        push(@lines,$self->_split_string($max_length,$line));
    }

    return join(
        "\n",
        map { (' ' x $indent_pos).$_ }
        @lines
    );
}

sub display_length {
    my ($string) = @_;

    $string =~ s/\e\[[\d;]*m//msg;
    $string =~ s/[^[:print:]]//g;

    return length($string);
}

sub render_list_key {
    my ($self,$value) = @_;
    return $value;
}

sub render_list_value {
    my ($self,$value) = @_;
    return $value;
}

# Format bullet list for fixed screen width
sub render_list {
    my ($self,$indent,$list,$list_indent) = @_;

    $list_indent            //= 0;
    $indent                 //= 0;
    my $space               = 2;
    my $max_length          = max(map { display_length($_->{k}) } @{$list});
    my $description_length  = $self->screen_width - $max_length - $space - ($self->indent * ($indent+$list_indent)) - 1;
    my $prefix_length       = $max_length + ($indent * $self->indent) + $space;
    my @return;

    # Loop all items
    foreach my $element (@{$list}) {
        my $description = $element->{v} // '';
        my @lines = $self->_split_string($description_length,$description);

        push (@return,
            (' ' x ($indent * $self->indent) )
            #.sprintf('%-*s  %s',
            #    $max_length,
            .$self->render_list_key($element->{k})
            .(' ' x ($max_length - display_length($element->{k}) + $space) )
            .$self->render_list_value(shift(@lines))
        );
        while (my $line = shift @lines) {
            push(@return,' ' x $prefix_length.$self->render_list_value($line));
        }
    }
    return join("\n",@return);
}

# Simple splitting of long sentences on whitespaces or punctuation
sub _split_string {
    my ($self,$max_length,$string) = @_;

    return
        unless defined $string;

    return $string
        if length $string <= $max_length;

    my (@lines,$line);
    $line = '';
    #TODO honour escape sequence
    foreach my $word (split(m/([^[:alnum:]])/,$string)) {
        if (display_length($line.$word) <= $max_length) {
            $line .= $word;
        } else {
            push(@lines,$line)
                if ($line ne '');
            $line = '';

            if (display_length($word) > $max_length) {
                my (@parts) = grep { $_ ne '' } split(/(.{$max_length})/,$word);
                my $lastline = pop(@parts);
                push(@lines,@parts);
                if (defined $lastline && $lastline ne '') {
                    $line = $lastline;
                }
            } else {
                $line = $word;
            }
        }
    }
    push(@lines,$line)
        if ($line ne '');

    @lines =  map { m/^\s*(.+?)\s*$/ ? $1 : $_  } @lines;

    return @lines;
}

__PACKAGE__->meta->make_immutable;
1;