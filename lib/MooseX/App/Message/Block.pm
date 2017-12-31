# ============================================================================
package MooseX::App::Message::Block;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose;

use MooseX::App::Utils;
use List::Util qw(first);
use Scalar::Util qw(weaken);

our %KEYWORDS = (
    _root       => {
        type        => 'block',
        children    => [qw(headline list paragraph raw)],
    },
    headline    => {
        type        => 'block',
        parents     => [qw(_root tag)],
        attr        => [qw(EMPTY error)],
    },
    list        => {
        type        => 'block',
        parents     => [qw(_root tag paragraph)],
        children    => [qw(item)],
        attr        => [qw(EMPTY error)],
    },
    item        => {
        type        => 'list',
        children    => [qw(key description)],
        parents     => [qw(list)],
    },
    key         => {
        type        => 'list',
        parents     => [qw(item)],
    },
    description => {
        type        => 'list',
        parents     => [qw(item)],
    },
    paragraph   => {
        type        => 'block',
        parents     => [qw(_root tag)],
        attr        => [qw(EMPTY error)],
    },
    tag         => {
        type        => 'semantic',
        attr        => ['ANY'],
        parents     => [qw(key description headline paragraph tag)]
    },
    raw         => {
        type        => 'block',
    },
);

my $KEYWORDS_RE = join('|', grep { ! m/^_/ } keys %KEYWORDS);

has 'parsed' => (
    is          => 'ro',
    isa         => 'HashRef',
    lazy_build  => 1,
    builder     => '_parse_block',
);

has 'block' => (
    is          => 'ro',
    isa         => 'MooseX::App::Types::MessageString',
    coerce      => 1,
    required    => 1,
);

sub raw {
    my ($class,$string) = @_;

    $string = '<raw>'.MooseX::App::Utils::string_to_entity($string).'</raw>';
    return $class->new(block => $string);
}

sub parse {
    my ($class,$string) = @_;

    return $class->new(block => $string);
}

sub _parse_block {
    my ($self) = @_;

    my $root    = { t => '_root', c => [] };
    my $current = $root;
    my $block   = $self->block;
    my $previous= 0;

    while ($block ne '') {
        my $keyword = $KEYWORDS{$current->{t}} || { type => 'root' };
        if ($block =~ s/\A
            (?<match>
                (?<text>[^><]+)
                |
                <(?<opening>$KEYWORDS_RE)(?:=(?<attr>\w+))?>
                |
                <\/(?<closing>$KEYWORDS_RE)>
                |
                (?<text>[><])
            )//sx) {
            # Prepended text
            my $text = $+{text};

            # Text block
            if (defined $text
                && $current->{t} ne 'list'
                && $current->{t} ne '_root') {
                my $previous = $current->{c}[-1];
                if (defined $previous
                    && $previous->{t} eq '_text') {
                    $previous->{v} .= $text;
                } elsif ($text ne '') {
                    push(@{$current->{c}},{ t => '_text', v => $text });
                }
            # Inside raw tag
            } elsif ($current->{t} eq 'raw'
                && defined $+{closing}
                && $+{closing} ne 'raw') {
                $current->{v} //= '';
                $current->{v} .= $+{match};
            # Opening tag
            } elsif (defined $+{opening}) {
                my $tag     = $+{opening};
                my $keyword = $KEYWORDS{$tag};
                # Check parent tag
                if ($keyword->{parents}
                    && ! first { $_ eq $current->{t} } @{$keyword->{parents}}) {
                    Moose->throw_error(
                        sprintf(
                            'Tag "%s" must be a child of %s, not "%s"',
                            $tag,
                            join(' or ',map { qq["$_"] } @{$keyword->{parents}}),
                            $current->{t}
                        )
                    );
                }
                # Check if child tag is allowed
                if ($KEYWORDS{$current->{t}}{children}
                    && ! first { $_ eq $tag } @{$KEYWORDS{$current->{t}}{children}}) {
                    Moose->throw_error(
                        sprintf(
                            'Tag "%s" can only contain %s, not "%s"',
                            $current->{t},
                            join(' or ',map { qq["$_"] } @{$KEYWORDS{$current->{t}}{children}}),
                            $tag
                        )
                    );
                }
                # Add new tag
                my $new = { t => $tag, c => [], p => $current };
                weaken($new->{p});
                $current->{c} ||= [];
                push(@{$current->{c}},$new);
                $current = $new;

                            say "MATCGED $current->{t}";
                if (defined $keyword->{attr}) {
                    my $match = 0;
                    foreach my $attr (@{$keyword->{attr}}) {
                        if ($attr eq 'ANY'
                            && defined $+{attr}) {
                            $match = 1;
                            last;
                        } elsif ($attr eq 'EMPTY'
                            && ! defined $+{attr}) {
                            $match = 1;
                            last;
                        } elsif (defined $+{attr}
                            && $attr eq $+{attr}) {
                            $match = 1;
                            last;
                        }
                    }
                    unless ($match) {
                        Moose->throw_error(
                            sprintf(
                                'Invalid attribute for tag "%s"',
                                $tag,
                            )
                        );
                    }
                    $current->{a} = $+{attr};
                } elsif (defined $+{attr}) {
                   Moose->throw_error(
                        sprintf(
                            'Tag "%s" has an attribute but expecting no attributes',
                            $tag,
                        )
                    );
                }

            # Closing tag
            } elsif (defined $+{closing}) {
                if ($+{closing} ne $current->{t}) {
                    Moose->throw_error(
                        sprintf(
                            'Closing tag mismatch. Got "%s" but expected "%s"',
                            $+{closing},
                            $current->{t}
                        )
                    );
                }
                $current = $current->{p};
            }
        } else {
            Moose->throw_error(
                sprintf(
                    'Cannot parse "%s"',
                    $block
                )
            );
        }
    }

    if ($root != $current) {
        Moose->throw_error(
            sprintf(
                'Missing closing tag for %s',
                $current->{t}
            )
        );
    }

    return $root;
}

__PACKAGE__->meta->make_immutable;
1;


#    <list></list>
#    <item></item>
#    <key></key>
#    <headline></headline>
#    <error></error>
#    <text></text>
#    <block></block>


#    <fg=green></fg>
#    <bg=rgb123></bg>
#    <underline></underline>
#    <reverse></reverse>
#    <bold></bold>
#    <indent></indent>

# # BLOCK 1
# <error>
#     <headline>Missing command</headline>
# </error>

# # BLOCK 2
# <headline>usage:</headline>
# <paragraph>
#      # Import a list of itans
#      console$ itan import --file itanlist.txt
# </paragraph>

# # BLOCK 3
# <headline>global options:</headline>
# <list>
#     <item>
#         <key>delete</key>
#         <text>Delete all invalid iTANs</text>
#     </item>
#     <item>
#         <key>delete</key>
#         <text>Delete all invalid iTANs</text>
#     </item>
# </list>

__END__

=encoding utf8

=head1 NAME

MooseX::App::Message::Block - Message block

=head1 DESCRIPTION

A simple message block with a header and body

=head1 METHODS

=head2 header

Read/set a header string

=head2 has_header

Check if a header is set

=head2 body

Read/set a body string

=head2 has_body

Check if a body is set

=head2 type

Read/set an arbitrary block type. Defaults to 'default'

=head2 stringify

Stringify a message block