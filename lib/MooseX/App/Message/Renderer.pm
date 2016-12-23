# ============================================================================
package MooseX::App::Message::Renderer;
# ============================================================================
use utf8;
use 5.010;

use namespace::autoclean;
use Moose;

use MooseX::App::Message::Renderer::Basic;


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
    my ($self,$text) = @_;

    my @lines;
    foreach my $line (split(/\n/,$text)) {
        push(@lines,$self->_split_string($self->screen_width - $self->indent,$line));
    }

    return join(
        "\n",
        map { (' ' x $self->indent).$_ }
        @lines
    );
}

# Format bullet list for fixed screen width
sub _format_list {
    my ($self,@list) = @_;

    my $max_length = max(map { length($_->[0]) } @list);
    my $description_length = $self->screen_width - $max_length - 7;
    my $prefix_length = $max_length + $self->indent + 2;
    my @return;

    # Loop all items
    foreach my $command (@list) {
        my $description = $command->[1] // '';
        my @lines = $self->_split_string($description_length,$description);
        push (@return,(' 'x $self->indent ).sprintf('%-*s  %s',$max_length,$command->[0],shift(@lines)));
        while (my $line = shift (@lines)) {
            push(@return,' 'x $prefix_length.$line);
        }
    }
    return join("\n",@return);
}

# Simple splitting of long sentences on whitespaces or punctuation
sub _split_string {
    my ($self,$maxlength,$string) = @_;

    return
        unless defined $string;

    return $string
        if length $string <= $maxlength;

    my (@lines,$line);
    $line = '';
    foreach my $word (split(m/(\p{IsPunct}|\p{IsSpace})/,$string)) {
        if (length($line.$word) <= $maxlength) {
            $line .= $word;
        } else {
            push(@lines,$line)
                if ($line ne '');
            $line = '';

            if (length($word) > $maxlength) {
                my (@parts) = grep { $_ ne '' } split(/(.{$maxlength})/,$word);
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

sub render {
    my ($self) = @_;
    ...
}

__PACKAGE__->meta->make_immutable;
1;