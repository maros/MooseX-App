# ============================================================================
package MooseX::App::ParsedArgv;
# ============================================================================

use 5.010;
use utf8;

use Moose;

use Encode qw(decode);

my $SINGLETON;

has 'argv' => (
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    lazy_build      => 1,
);

has 'fuzzy' => (
    is              => 'rw',
    isa             => 'Bool',
);

has 'hints' => (
    is              => 'rw',
    isa             => 'HashRef[Str]',
    default         => sub { {} },
);

has 'elements' => (
    is              => 'rw',
    isa             => 'ArrayRef[MooseX::App::ParsedArgv::Element]',
    lazy_build      => 1,
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
            push (@elements,MooseX::App::ParsedArgv::Element->new( key => $element, type => 'extra' ));
        } else {
            given ($element) {
                # Flags
                when (m/^-([^-][[:alnum:]]*)$/) {
                    undef $lastkey;
                    foreach my $flag (split(//,$1)) {
                        unless (defined $options{$flag}) {
                            $options{$flag} = MooseX::App::ParsedArgv::Element->new( key => $flag, type => 'option' );
                            push(@elements,$options{$flag});
                        }
                        $lastkey = $options{$flag};
                    }
                }
                # Key-value combined
                when (m/^--([^-=][^=]*)=(.+)$/) {
                    undef $lastkey;
                    my ($key,$value) = ($1,$2);
                    unless (defined $options{$key}) {
                        $options{$key} = MooseX::App::ParsedArgv::Element->new( key => $key, type => 'option' );
                        push(@elements,$options{$key});
                    }
                    $options{$key}->add_value($value);
                }
                # Key
                when (m/^--([^-].*)/) {
                    my $key = $1;
                    unless (defined $options{$key}) {
                        $options{$key} = MooseX::App::ParsedArgv::Element->new( key => $key, type => 'option' );
                        push(@elements,$options{$key});
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
                        # Is boolean # TODO handle fuzzy
                        if ($self->hints->{$lastkey->key}) {
                            push(@elements,MooseX::App::ParsedArgv::Element->new( key => $element, type => 'parameter' ));
                        # Not a boolean field
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

sub _build_argv {
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
    
    return \@extra;
}

{
    package MooseX::App::ParsedArgv::Element;
    use Moose;
    
    has 'key' => (
        is              => 'ro',
        isa             => 'Str',
        required        => 1,
    );
    
    has 'value' => (
        is              => 'rw',
        isa             => 'ArrayRef[Str]',
        traits          => ['Array'],
        default         => sub { [] },
        handles => {
            add_value       => 'push',
            has_values      => 'count',
            get_value       => 'get',
        }
    );
    
    has 'consumed' => (
        is              => 'rw',
        isa             => 'Bool',
        default         => 0,
    );
    
    has 'type' => (
        is              => 'rw',
        isa             => 'Str',
        required        => 1,
    );
    
    sub consume {
        my ($self,$attribute) = @_;
        
        Moose->throw_error('Element '.$self->type.' '.$self->key.' is already consumed')
            if $self->consumed;
        $self->consumed(1);  
        
        return $self; 
    }
    
    sub serialize {
        my ($self) = @_;
        given ($self->type) {
            when ('extra') { 
                return $self->key
            }
            when ('parameter') { 
                return $self->key
            }
            when ('option') { 
                my $key = (length $self->key == 1 ? '-':'--').$self->key;
                join(' ',map { $key.' '.$_ } @{$self->value});
            }
        }   
    }
    
    __PACKAGE__->meta->make_immutable();
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
 
 foreach my $option (@{$argv->options}) {
     say "Parsed ".$option->key;
 }

=head1 DESCRIPTION

This is a helper class that holds all options parsed from @ARGV. It is 
implemented as a singleton.

=head1 METHODS

=head2 new

Create a new MooseX::App::ParsedArgv instance 

=head2 instance 

Get the current MooseX::App::ParsedArgv instance. If there is no instance
a new one will be created.

=head2 parse

Parses the current arguments list 

=head2 available

 my @options = $self->available('options' OR 'parameters');

Returns an array of all parsed options or parameters that have not yet been consumed.

=head2 consume

 my $option = $self->consume('options' OR 'parameters');

Returns the first option/parameter of the local @ARGV that has not yet been 
consumed.

=head2 parameter

Returns all positional parameters

=head2 extra

Returns all extra values

=head2 options

Returns all options as MooseX::App::ParsedArgv::Option objects

=cut