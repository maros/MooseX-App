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
sub _format_text {
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

# Format bullet list for fixed screen width
sub _format_list {
    my ($self,$indent,$list) = @_;

    $indent                 = $indent // 0;
    my $max_length          = max(map { length($_->{k}) } @{$list});
    my $description_length  = $self->screen_width - $max_length - 2 - ($self->indent * $indent) - 1;
    my $prefix_length       = $max_length + ($indent * $self->indent) + 2;
    my @return;

    # Loop all items
    foreach my $element (@{$list}) {
        my $description = $element->{v} // '';
        my @lines = $self->_split_string($description_length,$description);

        push (@return,(' ' x ($indent * $self->indent) ).sprintf('%-*s  %s',$max_length,$element->{k},shift(@lines)));
        while (my $line = shift (@lines)) {
            push(@return,' ' x $prefix_length.$line);
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
    foreach my $word (split(m/(\p{IsPunct}|\p{IsSpace})/,$string)) {
        if (length($line.$word) <= $max_length) {
            $line .= $word;
        } else {
            push(@lines,$line)
                if ($line ne '');
            $line = '';

            if (length($word) > $max_length) {
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