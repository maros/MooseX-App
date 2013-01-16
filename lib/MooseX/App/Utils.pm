package MooseX::App::Utils;

use 5.010;
use utf8;
use strict;
use warnings;

use String::CamelCase qw(camelize decamelize);
use List::Util qw(max);
use Encode qw(decode);

our $SCREEN_WIDTH = 78;
our $INDENT = 4;

sub encoded_argv {
    my @local_argv = @_ || @ARGV;
    @local_argv = eval {
        require I18N::Langinfo;
        I18N::Langinfo->import(qw(langinfo CODESET));
        my $codeset = langinfo(CODESET());
        binmode(STDOUT, ":utf8")
            if $codeset =~ m/^UTF-?8$/i;
        return map { decode($codeset,$_) } @local_argv;
    };
    return @local_argv;
}

sub class_to_command {
    my ($class,$namespace) = @_;
    
    return 
        unless defined $class;
    
    $class = ref($class)
        if ref($class);
    
    $class =~ s/^\Q$namespace\E:://;
    $class =~ s/^.+::([^:]+)$/$1/;
    return lc(decamelize($class));
}

sub format_text {
    my ($text) = @_;
    
    my @lines;
    foreach my $line (split(/\n/,$text)) {
        push(@lines,split_string($SCREEN_WIDTH-$INDENT,$line));
    }
    
    return join(
        "\n",
        map { (' ' x $INDENT).$_ }
        @lines
    );
}

sub format_list {
    my (@list) = @_;
    
    my $max_length = max(map { length($_->[0]) } @list);
    my $description_length = $SCREEN_WIDTH - $max_length - 7;
    my $prefix_length = $max_length + $INDENT + 2;
    my @return;
    
    foreach my $command (@list) {
        my $description = $command->[1] // '';
        my @lines = split_string($description_length,$description);
        push (@return,(' 'x$INDENT).sprintf('%-*s  %s',$max_length,$command->[0],shift(@lines)));
        while (my $line = shift (@lines)) {
            push(@return,' 'x $prefix_length.$line);
        }
    }
    return join("\n",@return);
}

sub split_string {
    my ($maxlength, $string) = @_;
    
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

sub parse_pod {
    my ($package) = @_;
    
    my $package_filename = $package;
    $package_filename =~ s/::/\//g;
    $package_filename .= '.pm';
    
    my $package_filepath;
    if (defined $INC{$package_filename}) {
        $package_filepath = $INC{$package_filename};
        $package_filepath =~ s/\/{2,}/\//g;
    }
    
    return 
        unless defined $package_filepath
        && -e $package_filepath;
    
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
    
    my %pod;
    foreach my $element (@{$document->children}) {
        if ($element->isa('Pod::Elemental::Element::Pod5::Nonpod')) {
            if ($element->content =~ m/^\s*#+\s*ABSTRACT:\s*(.+)$/m) {
                $pod{ABSTRACT} ||= $1;
            }
        } elsif ($element->isa('Pod::Elemental::Element::Nested')
            && $element->command eq 'head1') {
        
            if ($element->content eq 'NAME') {
                my $content = _pod_node_to_text($element->children);
                $content =~ s/^$package(\s-)?\s//;
                chomp($content);
                $pod{NAME} = $content;
            } else {
                my $content = _pod_node_to_text($element->children);
                chomp($content);
                $pod{uc($element->content)} = $content; 
            }
        }
    }
        
    return %pod;
}

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
                }
            }
        }
    }
    
    return
        unless scalar @lines;
    
    my $return = join ("\n", grep { defined $_ } @lines);
    $return =~ s/\n\n\n+/\n\n/g; # Max one empty line
    $return =~ s/I<([^>]+)>/_$1_/g;
    $return =~ s/B<([^>]+)>/*$1*/g;
    $return =~ s/[LCBI]<([^>]+)>/$1/g;
    $return =~ s/[LCBI]<([^>]+)>/$1/g;
    return $return;
}


1;
