# ============================================================================
package MooseX::App::Plugin::Term::Meta::Attribute;
# ============================================================================

use utf8;
use 5.010;

use namespace::autoclean;
use Moose::Role;

no if $] >= 5.018000, warnings => qw(experimental::smartmatch);

use Term::ReadKey;

has 'cmd_term' => (
    is          => 'rw',
    isa         => 'Bool',
    default     => sub {0},
);

has 'cmd_term_label' => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_cmd_term_label',
);

sub cmd_term_label_full {
    my ($self) = @_;
    
    my $label = $self->cmd_term_label_name;
    my @tags;
    if ($self->is_required) {
        push(@tags,'Required');
    } else {
        push(@tags,'Optional');
    }
    
    if ($self->has_type_constraint) {
        my $type_constraint = $self->type_constraint;
        if ($type_constraint->is_a_type_of('Bool')) {
            push(@tags,'Y/N');
        } else {
            push(@tags,$self->cmd_type_constraint_description($type_constraint));
        }
    }
    # TODO; Handle type constraints
    if (scalar @tags) {
        $label .= ' ('.join(', ',@tags).')';
    }
    
    return $label;
}

sub cmd_term_label_name {
    my ($self) = @_;
    
    my $label;
    if ($self->has_cmd_term_label) {
        return $self->cmd_term_label;
    } elsif ($self->has_documentation) {
        return $self->documentation;
    } else {
        return $self->name;
    }
}

sub cmd_term_read {
    my ($self) = @_;
    
    if ($self->has_type_constraint 
        && $self->type_constraint->is_a_type_of('Bool')) {
        return $self->cmd_term_read_bool();
    } else {
        return $self->cmd_term_read_string();
    }
}

sub cmd_term_read_string {
    my ($self) = @_;
    
    my $label = $self->cmd_term_label_full;
    my $return;
    
    binmode STDIN,':encoding(UTF-8)';
    
    ReadMode 4; # change to raw input mode
    TRY_STRING:
    while (1) {
        print "\n"
            if defined $return 
            && $return !~ /^\s*$/;
        $return = '';
        if (defined $Term::ANSIColor::VERSION) {
            say Term::ANSIColor::color('white bold').$label.' :'.Term::ANSIColor::color('reset');
        } else {
            say $label.": ";
        }
        KEY_STRING: 
        while (1) {
            1 while defined ReadKey -1; # discard any previous input
            my $key = ReadKey 0; # read a single character
            given (ord($key)) {
                when (10) { # Enter
                    print "\n";
                    if ($return =~ m/^\s*$/) {
                        if ($self->is_required) {
                            next TRY_STRING;
                        } else {
                            $return = undef;
                            last TRY_STRING;
                        }
                    }
                    my $error = $self->cmd_type_constraint_check($return);
                    if ($error) {
                        if (defined $Term::ANSIColor::VERSION) {
                            say Term::ANSIColor::color('bright_red bold').$error.Term::ANSIColor::color('reset');
                        } else {
                            say $error;
                        }
                        next TRY_STRING;
                    } else {
                        last TRY_STRING; 
                    }
                }
                when (3) { # Ctrl-C
                    print "\n"
                        if $return !~ /^\s*$/;
                    ReadMode 0;
                    kill INT => $$; # Not sure ?
                    #next TRY_STRING; 
                }
                when (27) { # ESC
                    next TRY_STRING; 
                }
                when (127) { # Backspace
                    chop($return);
                    print "\b \b";
                }
                default {
                    if ($_ <= 31) { # ignore controll chars
                        next KEY_STRING;
                    }
                    $return .= $key;
                    print $key;
                }
            }
        }
    }
    ReadMode 0;
    
    return $return;
}

sub cmd_term_read_bool {
    my ($self) = @_;
    
    my $label = $self->cmd_term_label_full;
    my $return;
    
    ReadMode 4; # change to raw input mode
    TRY:
    while (1) {
        1 while defined ReadKey -1; # discard any previous input
        say "$label: ";
        my $key = ReadKey 0; # read a single character
        if ($key =~ /^[yn]$/i) {
            say uc($key);
            $return = uc($key) eq 'Y' ? 1:0;
            last;
        } elsif (ord($key) == 10 && ! $self->is_required) {
            last;
        }
    }
    ReadMode 0;
    
    return $return;
}

around 'cmd_tags_list' => sub {
    my $orig = shift;
    my ($self) = @_;
    
    my @tags = $self->$orig();
    
    push(@tags,'Term')
        if $self->can('cmd_term')
        && $self->cmd_term;
   
    return @tags;
};

{
    package Moose::Meta::Attribute::Custom::Trait::AppTerm;
    
    use strict;
    use warnings;
    
    sub register_implementation { return 'MooseX::App::Plugin::Term::Meta::Attribute' }
}

1;