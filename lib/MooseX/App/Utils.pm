package MooseX::App::Utils;

use 5.010;
use utf8;
use strict;
use warnings;

use List::Util qw(max);

use Moose::Util::TypeConstraints;

subtype 'MooseX::App::Types::List'
    => as 'ArrayRef';

coerce 'MooseX::App::Types::List'
    => from 'Str'
    => via { [$_] };

subtype 'MooseX::App::Types::CmdTypes'
    => as enum([qw(proto option parameter)]);

subtype 'MooseX::App::Types::MessageString'
    => as 'Str';

coerce 'MooseX::App::Types::MessageString'
    => from 'ArrayRef'
    => via { sprintf(@{$_}) };

subtype 'MooseX::App::Types::Env'
    => as 'Str'
    => where { m/^[A-Z0-9_]+$/ };

subtype 'MooseX::App::Types::Identifier'
    => as 'Str'
    => where {
        $_ eq '?'
        || (m/^[A-Za-z0-9][A-Za-z0-9_-]*$/ && m/[^-_]$/) };

subtype 'MooseX::App::Types::BlockList'
    => as 'ArrayRef[MooseX::App::Message::Block]';

coerce 'MooseX::App::Types::BlockList'
    => from 'MooseX::App::Message::Block'
    => via { [$_] }
    => from 'ArrayRef[Str]'
    => via {
        return [
            map { MooseX::App::Message::Block->parse($_) } @{$_}
        ]
    };

subtype 'MooseX::App::Types::IdentifierList'
    => as 'ArrayRef[MooseX::App::Types::Identifier]';

coerce 'MooseX::App::Types::IdentifierList'
    => from 'MooseX::App::Types::Identifier'
    => via { [$_] };

no Moose::Util::TypeConstraints;

no if $] >= 5.018000, warnings => qw/ experimental::smartmatch /;

# Default package name to command name translation function
sub class_to_command {
    my ($class) = @_;

    return
        unless defined $class;

    my @commands;
    foreach my $part (split /\s+/,$class) {
        my @parts = split( /_+|\b|(?<![A-Z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])/, $part );
        push (@commands,join('_',@parts));
    }
    return lc(join(" ",@commands));
}

# Try to get filename for a given package name
sub package_to_filename {
    my ($package) = @_;

    # Package to filename
    my $package_filename = $package;
    $package_filename =~ s/::/\//g;
    $package_filename .= '.pm';


    my $package_filepath;
    if (defined $INC{$package_filename}) {
        $package_filepath = $INC{$package_filename};
        $package_filepath =~ s/\/{2,}/\//g;
    }

    # No filename available
    return
        unless defined $package_filepath
        && -e $package_filepath;

    return $package_filepath;
}

# Parse pod
sub parse_pod {
    my ($package) = @_;

    my $package_filepath = package_to_filename($package);
    return
        unless $package_filepath;

    # Parse pod
    my $document = Pod::Elemental->read_file($package_filepath);

    Pod::Elemental::Transformer::Pod5->new->transform_node($document);

    my $nester_head = Pod::Elemental::Transformer::Nester->new({
        top_selector      => Pod::Elemental::Selectors::s_command('head1'),
        content_selectors => [
            Pod::Elemental::Selectors::s_command([ qw(head2 head3 head4 over back item) ]),
            Pod::Elemental::Selectors::s_flat()
        ],
    });
    $document = $nester_head->transform_node($document);

    # Process pod
    my %pod;
    foreach my $element (@{$document->children}) {
        # Distzilla ABSTRACT tag
        if ($element->isa('Pod::Elemental::Element::Pod5::Nonpod')) {
            if ($element->content =~ m/^\s*#+\s*ABSTRACT:\s*(.+)$/m) {
                $pod{ABSTRACT} ||= $1;
            }
        # Pod head1 sections
        } elsif ($element->isa('Pod::Elemental::Element::Nested')
            && $element->command eq 'head1') {

            if ($element->content eq 'NAME') {
                my $content = _pod_node_to_text($element->children);
                next unless defined $content;
                $content =~ s/^$package(\s-)?\s//;
                chomp($content);
                $pod{NAME} = $content;
            } else {
                my $content = _pod_node_to_text($element->children);
                next unless defined $content;
                chomp($content);
                $pod{uc($element->content)} = $content;
            }
        }
    }

    return %pod;
}

# Transform POD to simple markup
sub _pod_node_to_text {
    my ($node,$indent) = @_;

    unless (defined $indent) {
        my $indent_init = 0;
        $indent = \$indent_init;
    }

    my (@lines);
    if (ref $node eq 'ARRAY') {
        foreach my $element (@$node) {
            push (@lines,_pod_node_to_text($element,$indent));
        }

    } else {
        given (ref($node)) {
            when ('Pod::Elemental::Element::Pod5::Ordinary') {
                my $content = $node->content;
                return
                    if $content =~ m/^=cut/;
                $content =~ s/\n/ /g;
                $content =~ s/\s+/ /g;
                push (@lines,$content."\n");
            }
            when ('Pod::Elemental::Element::Pod5::Verbatim') {
                push (@lines,$node->content."\n");
            }
            when ('Pod::Elemental::Element::Pod5::Command') {
                given ($node->command) {
                    when ('over') {
                        ${$indent}++;
                    }
                    when ('item') {
                        push (@lines,('  ' x ($$indent-1)) . $node->content);
                    }
                    when ('back') {
                        push (@lines,"\n");
                        ${$indent}--;
                    }
                    when (qr/head\d/) {
                        push (@lines,"\n",$node->content,"\n");
                    }
                }
            }
        }
    }

    return
        unless scalar @lines;

    # Convert text markup
    my $return = join ("\n", grep { defined $_ } @lines);
    $return =~ s/\n\n\n+/\n\n/g; # Max one empty line
    $return =~ s/I<([^>]+)>/_$1_/g;
    $return =~ s/B<([^>]+)>/*$1*/g;
    $return =~ s/[LCBI]<([^>]+)>/$1/g;
    $return =~ s/[LCBI]<([^>]+)>/$1/g;
    return $return;
}

sub string_to_entity {
    my ($string) = @_;

    $string =~ s/>/&gt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/&/&amp;/g;

    return $string;
}

sub string_from_entity {
    my ($string) = @_;

    $string =~ s/&gt;/>/g;
    $string =~ s/&lt;/</g;
    $string =~ s/&amp;/&/g;

    return $string;
}

sub build_list {
    my (@list) = @_;

    my @return;
    foreach my $element (@list) {
        if (ref($element) eq 'ARRAY') {
            if (scalar @{$element} == 2) {
                push(@return,'<item><key>'.
                    string_to_entity($element->[0]).
                    '</key><description>'.
                    string_to_entity($element->[1]).
                    '</description></item>');
            } else {
                push(@return,'<item><key>'.
                    string_to_entity($element->[0]).
                    '</key></item>');
            }
        } else {
            push(@return,'<item>'.$element.'</item>');
        }
    }

    return join("\n",'<list>',@return,'</list>');
}

1;

=pod

=head1 NAME

MooseX::App::Utils - Utility functions

=head1 DESCRIPTION

This package holds various utility functions used by MooseX-App internally.
Unless you develop plugins you will not need to interact with this class.

=head1 FUNCTIONS

=head2 class_to_command

=head2 package_to_filename

Tries to determine the filename containing the given package name.

=head2 parse_pod

Parse POD for the given package.

=head2 build_list

TODO

=head2 string_to_entity

TODO

=head2 string_from_entity

TODO

=cut
