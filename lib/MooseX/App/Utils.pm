package MooseX::App::Utils;

use 5.010;
use utf8;
use strict;
use warnings;

use List::Util qw(max);

use Moose::Util::TypeConstraints;
use MooseX::App::Message::Builder;

my $ESCAPE_RE = qr/\e\[[\d;]*m/;

subtype 'MooseX::App::Types::List'
    => as 'ArrayRef';

coerce 'MooseX::App::Types::List'
    => from 'Str'
    => via { [$_] };

class_type 'MooseX::App::Types::Node'
    => { class => 'MooseX::App::Message::Node' };

subtype 'MooseX::App::Types::Output'
    => as 'ArrayRef[Str|MooseX::App::Types::Node]';

subtype 'MooseX::App::Types::NodeList'
    => as 'ArrayRef[MooseX::App::Types::Node]';

coerce 'MooseX::App::Types::NodeList'
    => from 'MooseX::App::Message::Node'
    => via { [$_] }
    => from 'Str'
    => via {
        return [ PARAGRAPH($_) ];
    }
    => from 'ArrayRef[Str]'
    => via {
        return [ map { PARAGRAPH($_) } @{$_} ];
    };

coerce 'MooseX::App::Types::Output'
    => from 'Str'
    => via { [ $_ ] }
    => from 'MooseX::App::Types::Node'
    => via { [ $_ ] };

subtype 'MooseX::App::Types::CmdTypes'
    => as enum([qw(proto option parameter)]);

subtype 'MooseX::App::Types::Env'
    => as 'Str'
    => where { m/^[A-Z0-9_]+$/ };

subtype 'MooseX::App::Types::Identifier'
    => as 'Str'
    => where {
        $_ eq '?'
        || (m/^[A-Za-z0-9][A-Za-z0-9_-]*$/ && m/[^-_]$/) };

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
                # TODO remove fomrat
                $pod{NAME} = _pod_formatting_codes($content);
            } else {
                my $content = _pod_node_to_text($element->children);
                next unless defined $content;
                chomp($content);
                $pod{uc($element->content)} = _pod_formatting_codes($content);
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
                    when (qr/^head(\d)/) {
                        push (@lines,"\n",TAG({ type => 'headline'.$1 },$node->content),\n");
                    }
                }
            }
        }
    }

    return
        unless scalar @lines;

    # Convert text markup
    my $return = join ("\n", grep { defined $_ } @lines);

    return $return;
}

sub _pod_formatting_codes {
    my ($text) = @_;

    $text =~ s|\n\n\n+|\n\n|g; # Max one empty line
    $text =~ s|I<([^>]+)>|TAG({ type=> 'italic'},${1})|ge;
    $text =~ s|B<([^>]+)>|TAG({ type=> 'bold'},${1})|ge;
    $text =~ s|C<([^>]+)>|TAG({ type=> 'code'},${1})|ge;
    $text =~ s|[LFSX]<([^>]+)>|$1|g;

    return $text;
}

sub build_list {
    my (@list) = @_;

    my @return;
    foreach my $element (@list) {
        if (ref($element) eq 'ARRAY') {
            if (scalar @{$element} == 2) {
                push(@return,ITEM(
                    KEY($element->[0]),
                    DESCRIPTION($element->[1]),
                );
            } else {
                push(@return,ITEM(
                    KEY($element->[0])
                ));
            }
        } else {
            push(@return,ITEM($element));
        }
    }

    return join("\n",LIST(@return));
}

sub string_length {
    my ($string) = @_;

    $string =~ s/$ESCAPE_RE//msg;
    $string =~ s/[^[:print:]\p{NonspacingMark}]//g;

    return length($string);
}

# Simple splitting of long sentences on whitespaces or punctuation
sub string_split {
    my ($max_length,$string) = @_;

    return
        unless defined $string;

    return $string
        if length $string <= $max_length;

    my (@lines,$line);
    $line = '';

    #TODO honour escape sequence
    foreach my $word (split(m/($ESCAPE_RE)|([^[:alnum:]])/,$string)) {
        next
            unless defined $word;
        if ($1 || string_length($line.$word) <= $max_length) {
            $line .= $word;
        } else {
            push(@lines,$line)
                if ($line ne '');
            $line = '';

            if (string_length($word) > $max_length) {
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
    #say "####";
    push(@lines,$line)
        if ($line ne '');

    @lines =  map { m/^\s*(.+?)\s*$/ ? $1 : $_  } @lines;

    return @lines;
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

Builds a list for the renderer. Expects either a list of strings,
or a list of array references for key-value pairs.

=cut
