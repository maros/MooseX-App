package MooseX::App::Utils;

use 5.010;
use utf8;
use strict;
use warnings;

use String::CamelCase qw(camelize decamelize);
use List::Util qw(max);

our $SCREEN_WIDTH = 78;
our $INDENT = 4;

sub class_to_command {
    my ($class,$namespace) = @_;
    
    return 
        unless defined $class;
    
    $class = ref($class)
        if ref($class);
    
    $class =~ s/^\Q$namespace\E:://;
    $class =~ s/^.+::([^:]+)$/$1/;
    return decamelize($class);
}

sub command_to_class {
    my ($command,$namespace) = @_;
    
    return 
        unless defined $command;
    
    my $class = $namespace.'::'.camelize($command);
    
    return $class;
}

sub format_text {
    my ($text) = @_;
    
    my @lines = split_string($SCREEN_WIDTH-$INDENT,$text);
    
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
    
    @lines = map { s/^\s*(.+?)\s*$/$1/; $_ } @lines;
    
    return @lines;
}

1;
