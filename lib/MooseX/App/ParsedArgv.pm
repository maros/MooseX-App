# ============================================================================
package MooseX::App::ParsedArgv;
# ============================================================================

use 5.010;
use utf8;

use Moose;

use Encode qw(decode);
use MooseX::App::ParsedArgv::Element;
no if $] >= 5.018000, warnings => qw(experimental::smartmatch);

my $SINGLETON;

has 'argv' => (
    is              => 'ro',
    isa             => 'ArrayRef[Str]',
    default         => sub {
        my @argv;
        @argv = eval {
            require I18N::Langinfo;
            I18N::Langinfo->import(qw(langinfo CODESET));
            my $codeset = langinfo(CODESET());
            # TODO Not sure if this is the right place?
            binmode(STDOUT, ":encoding(UTF-8)")
                if $codeset =~ m/^UTF-?8$/i;
            return map { decode($codeset,$_) } @ARGV;
        };
        # Fallback to standard
        if ($@) {
            @argv = @ARGV;
        }
        
        return \@argv;
    },
);

has 'hints' => (
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    default         => sub { [] },
); # Hints for the parser

has 'permute' => (
    is              => 'rw',
    isa             => 'Bool',
    default         => sub { 0 },
);

has 'elements' => (
    is              => 'ro',
    isa             => 'ArrayRef[MooseX::App::ParsedArgv::Element]',
    lazy            => 1,
    builder         => '_build_elements',
    clearer         => 'reset_elements',
);

sub BUILD {
    my ($self) = @_;
    $SINGLETON = $self;
    return $self;
}

sub instance {
    my ($class) = @_;
    unless (defined $SINGLETON) {
        return $class->new();
    }
    return $SINGLETON;
}

sub first_argv {
    my ($self) = @_;
    
    $self->reset_elements;
    return shift(@{$self->argv});
}

sub _build_elements {
    my ($self) = @_;
    
    my (@elements);

    my %options;
    my $lastkey;
    my $stopprocessing;
    
    foreach my $element (@{$self->argv}) {
        if ($stopprocessing) {
            push (@elements,MooseX::App::ParsedArgv::Element->new( 
                key => $element, 
                type => 'extra', 
            ));
        } else {
            given ($element) {
                # Flags
                when (m/^-([^-][[:alnum:]]*)$/) {
                    undef $lastkey;
                    foreach my $flag (split(//,$1)) {
                        unless (defined $options{$flag}) {
                            $options{$flag} = MooseX::App::ParsedArgv::Element->new( 
                                key => $flag, 
                                type => 'option',
                                raw => $element,
                            );
                            push(@elements,$options{$flag});
                        } else {
                            $options{$flag}->inc_occurence;
                        }
                        $lastkey = $options{$flag};
                    }
                }
                # Key-value combined
                when (m/^--([^-=][^=]*)=(.+)$/) {
                    undef $lastkey;
                    my ($key,$value) = ($1,$2);
                    unless (defined $options{$key}) {
                        $options{$key} = MooseX::App::ParsedArgv::Element->new(
                            key => $key,
                            type => 'option',
                            raw => $element,
                        );
                        push(@elements,$options{$key});
                    } else {
                        $options{$key}->inc_occurence;
                    }
                    $options{$key}->add_value($value);
                }
                # Key
                when (m/^--([^-].*)/) {
                    my $key = $1;
                    unless (defined $options{$key}) {
                        $options{$key} = MooseX::App::ParsedArgv::Element->new( 
                            key => $key, 
                            type => 'option',
                            raw => $element,
                        );
                        push(@elements,$options{$key});
                    } else {
                        $options{$key}->inc_occurence;
                    }
                    $lastkey = $options{$key};
                }
                # Extra values
                when ('--') {
                    undef $lastkey;
                    $stopprocessing = 1;
                }
                # Value
                default {
                    if (defined $lastkey) {
                        # No value 
                        if ($lastkey->key ~~ $self->hints) {
                            push(@elements,MooseX::App::ParsedArgv::Element->new( key => $element, type => 'parameter' ));
                        # Has value
                        } else {
                            $lastkey->add_value($element);
                        }
                        undef $lastkey;
                    } else {
                        push(@elements,MooseX::App::ParsedArgv::Element->new( key => $element, type => 'parameter' ));
                    }
                }
            } 
        }
    }
      
    return \@elements;
}

sub available {
    my ($self,$type) = @_;
    
    my @elements;
    foreach my $element (@{$self->elements}) {
        next
            if $element->consumed;
        next
            if defined $type 
            && $element->type ne $type;
        push(@elements,$element);
    }  
    return @elements; 
}

sub consume {
    my ($self,$type) = @_;
    
    foreach my $element (@{$self->elements}) {
        next
            if $element->consumed;
        next
            if defined $type 
            && $element->type ne $type;
        $element->consume;
        return $element;
    }  
    return; 
}

sub extra {
    my ($self) = @_;

    my @extra;
    foreach my $element (@{$self->elements}) {
        next
            if $element->consumed;
        next
            unless $element->type eq 'parameter'
            || $element->type eq 'extra';
        push(@extra,$element->key);
    }  
    
    return @extra;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

MooseX::App::ParsedArgv - Parses @ARGV

=head1 SYNOPSIS

 use MooseX::App::ParsedArgv;
 my $argv = MooseX::App::ParsedArgv->instance; 
 
 foreach my $option ($argv->available('option')) {
     say "Parsed ".$option->key;
 }

=head1 DESCRIPTION

This is a helper class that holds all options parsed from @ARGV. It is 
implemented as a singleton. Unless you are developing a MooseX::App plugin
you usually do not need to interact with this class.

=head1 METHODS

=head2 new

Create a new MooseX::App::ParsedArgv instance. Needs to be called as soon
as possible.

=head2 instance 

Get the current MooseX::App::ParsedArgv instance. If there is no instance
a new one will be created.

=head2 argv

Accessor for the initinal @ARGV. 

=head2 hints

ArrayRef of attributes that tells the parser which attributes should be 
regarded as flags without values.

=head2 first_argv

Shifts the current first element from @ARGV.

=head2 available

 my @options = $self->available($type);
 OR
 my @options = $self->available();

Returns an array of all parsed options or parameters that have not yet been consumed.
The array elements will be L<MooseX::App::ParsedArgv::Element> objects.

=head2 consume

 my $option = $self->consume($type);
 OR
 my $option = $self->consume();

Returns the first option/parameter of the local @ARGV that has not yet been 
consumed as a L<MooseX::App::ParsedArgv::Element> object.

=head2 elements

Returns all parsed options and parameters.

=head2 extra

Returns an array reference of unconsumed positional parameters and
extra values.

=cut