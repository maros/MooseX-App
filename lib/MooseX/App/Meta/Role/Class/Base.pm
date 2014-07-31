# ============================================================================
package MooseX::App::Meta::Role::Class::Base;
# ============================================================================

use utf8;
use 5.010;

use namespace::autoclean;
use Moose::Role;

use MooseX::App::Utils;
use Path::Class;
use Module::Pluggable::Object;
use List::Util qw(max);
no if $] >= 5.018000, warnings => qw(experimental::smartmatch);

has 'app_messageclass' => (
    is          => 'rw',
    isa         => 'ClassName',
    lazy_build  => 1,
);

has 'app_namespace' => (
    is          => 'rw',
    isa         => 'MooseX::App::Types::List',
    coerce      => 1,
    lazy_build  => 1,
);

has 'app_base' => (
    is          => 'rw',
    isa         => 'Str',
    default     => sub { Path::Class::File->new($0)->basename },
);

has 'app_strict' => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 0,
);

has 'app_fuzzy' => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 1,
);

has 'app_command_name' => (
    is          => 'rw',
    isa         => 'CodeRef',
    default     => sub { \&MooseX::App::Utils::class_to_command },
);

has 'app_prefer_commandline' => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 0,
);

has 'app_commands' => (
    is          => 'rw',
    isa         => 'HashRef[Str]',
    traits      => ['Hash'],
    handles     => {
        command_register    => 'set', 
        command_get         => 'get',  
    },
    lazy_build  => 1,
);

sub _build_app_messageclass {
    my ($self) = @_;
    return 'MooseX::App::Message::Block'
}

sub _build_app_namespace {
    my ($self) = @_;
    return [ $self->name ];
}

sub _build_app_commands {
    my ($self) = @_;
    
    my @list;
    foreach my $namespace ( @{ $self->app_namespace } ) {
        push(@list,$self->command_scan_namespace($namespace));
    }
    
    return { @list };
}

sub command_scan_namespace {
    my ($self,$namespace) = @_;
    
    my $mpo = Module::Pluggable::Object->new(
        search_path => [ $namespace ],
    );
    
    my $commandsub = $self->app_command_name;

    my %return;
    foreach my $command_class ($mpo->plugins) {
        my $command_class_name =  substr($command_class,length($namespace)+2);
        
        next
            if $command_class_name =~ m/::/;
        
        $command_class_name =~ s/^\Q$namespace\E:://;
        $command_class_name =~ s/^.+::([^:]+)$/$1/;
        
        my $command = $commandsub->($command_class_name,$command_class);
        
        $return{$command} = $command_class;
    }
    
    return %return;
}

sub command_args {
    my ($self,$metaclass) = @_;
    
    $metaclass ||= $self;
    my $parsed_argv = MooseX::App::ParsedArgv->instance;
    
    # Process options
    my @attributes_option  = $self->command_usage_attributes($metaclass,'option');
    
    my ($return,$errors) = $self->command_parse_options(\@attributes_option);

    my %raw_error;
    foreach my $option ($parsed_argv->available('option')) {
        my $key = $option->key;
        my $raw = $option->original;
        my $message;
        next
            if defined $raw_error{$raw};
        
        if (length $key == 1
            && $raw =~ m/^-(\w+)$/) {
            POSSIBLE_ATTRIBUTES:
            foreach my $attribute ($self->command_usage_attributes($metaclass,[qw(option proto)])) {
                foreach my $name ($attribute->cmd_name_possible) {
                    # TODO fuzzy match
                    if ($name eq $1) {
                        $raw_error{$raw} = 1;
                        $message = "Did you mean '--$name'?";
                        last POSSIBLE_ATTRIBUTES;
                    }
                }
            }
        }
        
        my $error;
        if (defined $message) {
            $error = $self->command_message(
                header          => "Unknown option '".$raw."'", # LOCALIZE
                body            => $message,
                type            => "error",
            );
        } else {
            $error = $self->command_message(
                header          => "Unknown option '".$option->key."'", # LOCALIZE
                type            => "error",
            );
        }
        unshift(@{$errors},$error);
    }
    
    # Process params
    my @attributes_parameter  = $self->command_usage_attributes($metaclass,'parameter');

    foreach my $attribute (@attributes_parameter) {
        my $value = $parsed_argv->consume('parameter');
        last
            unless defined $value;

        my ($parameter_value,$parameter_errors) = $self->command_process_attribute($attribute,$value->key);
        push(@{$errors},@{$parameter_errors});
        $return->{$attribute->name} = $parameter_value;
    }
    
    # Handle all unconsumed parameters and options
    if ($self->app_strict || $metaclass->command_strict) {
        foreach my $parameter ($parsed_argv->available('parameter')) {
            unshift(@{$errors},
                $self->command_message(
                    header          => "Unknown parameter '".$parameter->key."'", # LOCALIZE
                    type            => "error",
                )
            );
        }
    }
    
    return ($return,$errors);
}

sub command_proto {
    my ($self,$metaclass) = @_;
    
    $metaclass   ||= $self;
    
    my @attributes;
    foreach my $attribute ($self->command_usage_attributes($metaclass)) {
        next
            unless $attribute->does('AppOption')
            && $attribute->has_cmd_type
            && $attribute->cmd_type eq 'proto';
        push(@attributes,$attribute);
    }
    
    return $self->command_parse_options(\@attributes);
}

sub command_parse_options {
    my ($self,$attributes) = @_;
    
    # Build attribute lookup hash
    my %option_to_attribute;
    foreach my $attribute (@{$attributes}) {
        foreach my $name ($attribute->cmd_name_possible) {
            if (defined $option_to_attribute{$name}
                && $option_to_attribute{$name} != $attribute) {
                Moose->throw_error('Command line option conflict: '.$name);    
            }
            $option_to_attribute{$name} = $attribute;
        }
    }
    
    my $match = {};
    my $return = {};
    my @errors;
    
    # Get ARGV
    my $parsed_argv = MooseX::App::ParsedArgv->instance;
    
    # Loop all exact matches
    foreach my $option ($parsed_argv->available('option')) {
        if (my $attribute = $option_to_attribute{$option->key}) {
            $match->{$attribute->name} = $option->value;
            $option->consume($attribute);
        }
    }
    
    # Process fuzzy matches
    if ($self->app_fuzzy) {
        # Loop all options (sorted by length)
        foreach my $option (sort { length($b->key) <=> length($a->key) } $parsed_argv->available('option')) {

            # No fuzzy matching for one-letter flags
            my $option_length = length($option->key);
            next
                if $option_length == 1;
            
            my ($match_attributes) = [];
            
            
            # Try to match attributes
            foreach my $name (keys %option_to_attribute) {
                next
                    if ($option_length >= length($name));
                
                my $name_short = lc(substr($name,0,$option_length));
                
                # Partial match
                if (lc($option->key) eq $name_short) {
                    my $attribute = $option_to_attribute{$name};
                    unless (grep { $attribute == $_ } @{$match_attributes}) {
                        push(@{$match_attributes},$attribute);   
                    }
                }
            }
            
            given (scalar @{$match_attributes}) {
                # No match
                when(0) {}
                # One match
                when(1) {
                    my $attribute = $match_attributes->[0];
                    $option->consume();
                    $match->{$attribute->name} ||= [];
                    push(@{$match->{$attribute->name}},@{$option->value}); 
                }
                # Multiple matches
                default {
                    $option->consume();
                    push(@errors,
                        $self->command_message(
                            header          => "Ambiguous option '".$option->key."'", # LOCALIZE
                            type            => "error",
                            body            => "Could be\n".MooseX::App::Utils::format_list( # LOCALIZE
                                map { [ $_ ] } 
                                sort 
                                map { $_->cmd_name_primary } 
                                @{$match_attributes} 
                            ),
                        )
                    );
                }
            }
        }
    }
    
    # Check all attributes
    foreach my $attribute (@{$attributes}) {
        
        next
            unless exists $match->{$attribute->name};
        
        my ($value,$errors) = $self->command_process_attribute($attribute,$match->{$attribute->name});
        push(@errors,@{$errors});
        
        $return->{$attribute->name} = $value;
    }
    
    return ($return,\@errors);
}

sub command_process_attribute {
    my ($self,$attribute,$raw) = @_;
    
    $raw = [$raw]
        unless ref($raw) eq 'ARRAY';
    
    my @errors;
    my $value;
    
    # Attribute with split
    if ($attribute->has_cmd_split) {
        my @raw_unfolded;
        foreach (@{$raw}) {
            push(@raw_unfolded,split($attribute->cmd_split,$_));
        }
        $raw = \@raw_unfolded;
    }
    
    # Attribute with type constraint
    if ($attribute->has_type_constraint) {
        my $type_constraint = $attribute->type_constraint;
        
        if ($type_constraint->is_a_type_of('ArrayRef')) {
            $value = $raw;
        } elsif ($type_constraint->is_a_type_of('HashRef')) {
            $value = {};
            foreach my $element (@{$raw}) {
                if ($element =~ m/^([^=]+)=(.+?)$/) {
                    $value->{$1} ||= $2;
                } else {
                    push(@errors,
                        $self->command_message(
                            header          => "Invalid value for '".$attribute->cmd_name_primary."'", # LOCALIZE
                            type            => "error",
                            body            => "Value must be supplied as 'key=value' (not '$element')", # LOCALIZE
                        )
                    );
                }
            }
        } elsif ($type_constraint->is_a_type_of('Bool')) {
            $value = $attribute->cmd_is_bool; # TODO or 0 if no!
        } elsif ($type_constraint->is_a_type_of('Int')) {
            $value = $raw->[-1];
        } else {
            $value = $raw->[-1];
        }
        
        unless(defined $value) {
            push(@errors,
                $self->command_message(
                    header          => "Missing value for '".$attribute->cmd_name_primary."'", # LOCALIZE
                    type            => "error",
                )
            );
        } else {
                        
            if ($attribute->should_coerce
                && $type_constraint->has_coercion) {
                my $coercion = $type_constraint->coercion;
                $value = $coercion->coerce($value) // $value;
            }
            my $error = $self->command_check_attribute($attribute,$value);
            push(@errors,$error)
                if $error;
        }
        
    } else {
         $value = $raw->[-1];
    }
    
    return ($value,\@errors);
}

sub command_check_attribute {
    my ($self,$attribute,$value) = @_;
    
    return 
        unless ($attribute->has_type_constraint);
    my $type_constraint = $attribute->type_constraint;
    
    # Check type constraints
    unless ($type_constraint->check($value)) {
        my $message;
        
        if (ref($value) eq 'ARRAY') {
            $value = join(', ',@$value);
        } elsif (ref($value) eq 'HASH') {
            $value = join(', ',map { $_.'='.$value->{$_} } keys %$value)
        }
        
        # We have a custom message
        if ($type_constraint->has_message) {
            $message = $type_constraint->get_message($value);
        # No message
        } else {
            my $message_human = $self->command_type_constraint_description($type_constraint);
            if (defined $message_human) {
                $message = "Value must be ". $message_human ." (not '$value')";
            } else {
                $message = $type_constraint->get_message($value);
            }
        }
        
        return $self->command_message(
            header          => "Invalid value for '".$attribute->cmd_name_primary."'", # LOCALIZE
            type            => "error",
            body            => $message,
        );
    }
    
    return;
}


sub command_type_constraint_description {
    my ($self,$type_constraint,$singular) = @_;
    
    $singular //= 1;
    
    if ($type_constraint->isa('Moose::Meta::TypeConstraint::Enum')) {
        return 'one of these values: '.join(', ',@{$type_constraint->values});
    } elsif ($type_constraint->isa('Moose::Meta::TypeConstraint::Parameterized')) {
        my $from = $type_constraint->parameterized_from;
        if ($from->is_a_type_of('ArrayRef')) {
            return $self->command_type_constraint_description($type_constraint->type_parameter);
        } elsif ($from->is_a_type_of('HashRef')) {
            return 'key-value pairs of '.$self->command_type_constraint_description($type_constraint->type_parameter,0);
        }
    # TODO union
    } elsif ($type_constraint->equals('Int')) {
        return $singular ? 'an integer':'integers'; # LOCALIZE
    } elsif ($type_constraint->equals('Num')) {
        return $singular ? 'a number':'numbers'; # LOCALIZE
    } elsif ($type_constraint->equals('Str')) {
        return $singular ? 'a string':'strings';
    } elsif ($type_constraint->equals('HashRef')) {
        return 'key-value pairs'; # LOCALIZE
    }
    
    if ($type_constraint->has_parent) {
        return $self->command_type_constraint_description($type_constraint->parent);
    }
    
    return;
    
#    given ($type_constraint_name) {
#        when ('Int') {
#            return 'integer'; # LOCALIZE
#        }
#        when ('Num') {
#            
#        }
#        when (/^ArrayRef\[(.*)\]$/) {
#            return $self->command_type_constraint_description($1);
#        }
#        when ('HashRef') {
#            return 'key-value pairs'; # LOCALIZE
#        } 
#        when (/^HashRef\[(.+)\]$/) {
#            return 'key-value pairs with '.$self->command_type_constraint_description($1).' values'; # LOCALIZE
#        }
#        when ('Str') {
#            return 'string'; # LOCALIZE
#        }
#        default {
#            $type_constraint
#        }
#    }
    
    return;
}

sub command_candidates {
    my ($self,$command) = @_;
    
    my $lc_command = lc($command);
    my $commands = $self->app_commands;
    
    my @candidates;
    my $candidate_length = length($command);
    
    # Compare all commands to find matching candidates
    foreach my $command_name (keys %$commands) {
        if ($command_name eq $lc_command) {
            return $command_name;
        } elsif ($lc_command eq substr($command_name,0,$candidate_length)) {
            push(@candidates,$command_name);
        }
    }
    
    return [ sort @candidates ];
}

sub command_find {
    my ($self,$command) = @_;
    
    my $lc_command = lc($command);
    my $commands = $self->app_commands;
    
    # Exact match
    if (defined $commands->{$lc_command}) {
        return $lc_command;
    } else {
        my $candidate =  $self->command_candidates($command);
        
        if (ref $candidate eq '') {
            return $candidate;
        } else {
            given (scalar @{$candidate}) {
                when (0) {
                    return $self->command_message(
                        header          => "Unknown command '$command'", # LOCALIZE
                        type            => "error",
                    );
                }
                when (1) {
                    if ($self->app_fuzzy) {
                        return $candidate->[0];
                    } else {
                        return $self->command_message(
                            header          => "Unknown command '$command'", # LOCALIZE
                            type            => "error",
                            body            => "Did you mean '".$candidate->[0]."'?", # LOCALIZE
                        );
                    }
                }
                default {
                    return $self->command_message(
                        header          => "Ambiguous command '$command'", # LOCALIZE
                        type            => "error",
                        body            => "Which command did you mean?\n". # LOCALIZE
                            MooseX::App::Utils::format_list(map { [ $_ ] } sort @{$candidate}),
                    );
                }
            }
        }
    }
}

sub command_parser_hints {
    my ($self,$metaclass) = @_;
    
    $metaclass ||= $self;
    
    my %hints;
    my %names;
    foreach my $attribute ($self->command_usage_attributes($metaclass,[qw(option proto)])) {
        foreach my $name ($attribute->cmd_name_possible) {
            $names{$name} = { name => $attribute->name, bool => $attribute->cmd_is_bool };
            $hints{$name} = $names{$name};
        }
    }
    
    if ($self->app_fuzzy) {
        my $length = max(map { length($_) } keys %names) // 0;
        foreach my $l (reverse(1..$length)) {
            my %tmp;
            foreach my $name (keys %names) {
                next
                    if length($name) < $l;
                my $short_name = substr($name,0,$l);
                next
                    if defined $hints{$short_name};
                $tmp{$short_name} ||= [];
                next
                    if defined $tmp{$short_name}->[0]
                    && $tmp{$short_name}->[0]->{name} eq $names{$name}->{name};
                push(@{$tmp{$short_name}},$names{$name})
            }
            foreach my $short_name (keys %tmp) {
                next
                    if scalar @{$tmp{$short_name}} > 1;
                $hints{$short_name} = $tmp{$short_name}->[0];
            }
        }
    }
    
    my @return;
    foreach my $name (keys %hints) {
        next
            unless defined $hints{$name}->{bool};
        push(@return,$name);
    }
    
    return \@return;
}

sub command_message {
    my ($self,@args) = @_;
    my $messageclass = $self->app_messageclass;
    Class::Load::load_class($messageclass);
    return $messageclass->new(@args);
}

sub command_usage_attributes {
    my ($self,$metaclass,$types) = @_;
    
    $metaclass ||= $self;
    $types ||= [qw(option proto)];
    
    my @return;
    foreach my $attribute ($metaclass->get_all_attributes) {
        next
            unless $attribute->does('AppOption')
            && $attribute->has_cmd_type
            && $attribute->cmd_type ~~ $types;
        
        push(@return,$attribute);
    }
    
    return (sort { 
        $a->cmd_position <=> $b->cmd_position
    } @return);
}

sub command_usage_options {
    my ($self,$metaclass,$headline) = @_;
    
    $headline ||= 'options:'; # LOCALIZE
    $metaclass ||= $self;
    
    my @options;
    foreach my $attribute ($self->command_usage_attributes($metaclass,[qw(option proto)])) {
        push(@options,[
            $attribute->cmd_usage_name(),
            $attribute->cmd_usage_description()
        ]);
    }
    
    @options = sort { $a->[0] cmp $b->[0] } @options;
    
    return
        unless scalar @options > 0;
    
    return $self->command_message(
        header  => $headline,
        body    => MooseX::App::Utils::format_list(@options),
    );
}

sub command_usage_parameters {
    my ($self,$metaclass,$headline) = @_;
    
    $headline ||= 'parameter:'; # LOCALIZE
    $metaclass ||= $self;
    
    my @parameters;
    foreach my $attribute (     
        sort { $a->cmd_position <=> $b->cmd_position } 
             $self->command_usage_attributes($metaclass,'parameter')
    ) {
        push(@parameters,[
            $attribute->cmd_usage_name(),
            $attribute->cmd_usage_description()
        ]);
    }
    
    return
        unless scalar @parameters > 0;
    
    return $self->command_message(
        header  => $headline,
        body    => MooseX::App::Utils::format_list(@parameters),
    );
}

sub command_usage_header {
    my ($self,$command_meta_class) = @_;
    
    my $caller = $self->app_base;
    
    my ($command_name,$usage);
    if ($command_meta_class) {
        $command_name = $self->command_class_to_command($command_meta_class->name);
        if ($command_meta_class->can('command_usage')
            && $command_meta_class->command_usage_predicate) {
            $usage = MooseX::App::Utils::format_text($command_meta_class->command_usage);
        }
    } else {
        $command_name = '<command>';
    }
    
    unless (defined $usage) {
        # LOCALIZE
        $usage = "$caller $command_name ";
        my @parameter= $self->command_usage_attributes($command_meta_class||$self,'parameter');
        foreach my $attribute (@parameter) {
            if ($attribute->is_required) {
                $usage .= "<".$attribute->cmd_usage_name.'> ';
            } else {
                $usage .= '['.$attribute->cmd_usage_name.'] ';
            }
        }
        $usage .= "[long options...]
$caller help
$caller $command_name --help";
        $usage = MooseX::App::Utils::format_text($usage);
    }
        
    return $self->command_message(
        header  => 'usage:', # LOCALIZE
        body    => $usage,
    );
}

sub command_usage_description {
    my ($self,$command_meta_class) = @_;
    
    $command_meta_class ||= $self;
    
    if ($command_meta_class->can('command_long_description')
        && $command_meta_class->command_long_description_predicate) {
        return $self->command_message(
            header  => 'description:', # LOCALIZE
            body    => MooseX::App::Utils::format_text($command_meta_class->command_long_description),
        );
    } elsif ($command_meta_class->can('command_short_description')
        && $command_meta_class->command_short_description_predicate) {
        return $self->command_message(
            header  => 'short description:', # LOCALIZE
            body    => MooseX::App::Utils::format_text($command_meta_class->command_short_description),
        );
    }
    return;
}

sub command_class_to_command {
    my ($self,$command_class) = @_;
    
    my $commands = $self->app_commands;
    foreach my $element (keys %$commands) {
        if ($command_class eq $commands->{$element}) {
            return $element;
        }
    }
    
    return;
}

sub command_usage_command {
    my ($self,$command_meta_class) = @_;
    
    $command_meta_class ||= $self;
    
    my $command_class = $command_meta_class->name;
    my $command_name = $self->command_class_to_command($command_class);
    
    my @usage;
    push(@usage,$self->command_usage_header($command_meta_class));
    push(@usage,$self->command_usage_description($command_meta_class,)); 
    push(@usage,$self->command_usage_parameters($command_meta_class,'parameters:')); # LOCALIZE
    push(@usage,$self->command_usage_options($command_meta_class,'options:')); # LOCALIZE
    
    return @usage;
}

sub command_usage_global {
    my ($self) = @_;
    
    my @commands;
    push(@commands,['help','Prints this usage information']); # LOCALIZE
    
    my $commands = $self->app_commands;
    
    while (my ($command,$class) = each %$commands) {
        Class::Load::load_class($class);
        my $description;
        $description = $class->meta->command_short_description
            if $class->meta->can('command_short_description');
        
        $description ||= '';
        push(@commands,[$command,$description]);
    }
    
    @commands = sort { $a->[0] cmp $b->[0] } @commands;
    
    my @usage;
    push (@usage,$self->command_usage_header());
    push(@usage,$self->command_usage_parameters($self,'global parameters:')); # LOCALIZE
    push (@usage,$self->command_usage_options($self,'global options:')); # LOCALIZE
    push (@usage,
        $self->command_message(
            header  => 'available commands:', # LOCALIZE
            body    => MooseX::App::Utils::format_list(@commands),
        )
    );
    
    return @usage;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

MooseX::App::Meta::Role::Class::Base - Meta class role for application base class

=head1 DESCRIPTION

This meta class role will automatically be applied to the application base
class. This documentation is only of interest if you intend to write
plugins for MooseX-App.

=head1 ACCESSORS

=head2 app_messageclass

Message class for generating error messages. Defaults to
MooseX::App::Message::Block. The default can be overwritten by altering
the C<_build_app_messageclass> method. Defaults to MooseX::App::Message::Block

=head2 app_namespace

Usually MooseX::App will take the package name of the base class as the 
namespace for commands. This namespace can be changed.

=head2 app_base

Usually MooseX::App will take the name of the calling wrapper script to 
construct the program name in various help messages. This name can 
be changed via the app_base accessor. Defaults to the base name of $0

=head2 app_fuzzy

Boolean flag that controlls if command names and attributes should be 
matched exactly or fuzzy. Defaults to true.

=head2 app_command_name

Coderef attribute that controlls how package names are translated to command 
names and attributes. Defaults to &MooseX::App::Utils::class_to_command

=head2 app_commands

Hashref with command to command class map.

=head2 app_strict

Boolean flag that controls if an application with superfluous/unknown 
positional parameters should terminate with an error message or not. 
If disabled all extra parameters will be copied to the L<extra_argv> 
command class attribute.

=head2 app_prefer_commandline

By default, arguments passed to new_with_command and new_with_options have a 
higher priority than the command line options. This boolean flag will give 
the command line an higher priority.

=head1 METHODS

=head2 command_register

 $self->command_register($command_moniker,$command_class);

Registers an additional command

=head2 command_get

 my $command_class = $self->command_register($command_moniker);

Returns a command class for the given command moniker

=head2 command_class_to_command

 my $command_moniker = $meta->command_class_to_command($command_class);

Returns the command moniker for the given command class.

=head2 command_message

 my $message = $meta->command_message( 
    header  => $header, 
    type    => 'error', 
    body    => $message
 );

Generates a message object (using the class from L<app_messageclass>)

=head2 command_usage_attributes

 my @attributes = $meta->command_usage_attributes($metaclass);

Returns a list of attributes/command options for the given meta class.

=head2 command_usage_command

 my @messages = $meta->command_usage_command($command_metaclass);

Returns a list of messages containing the documentation for a given
command meta class.

=head2 command_usage_description

 my $message = $meta->command_usage_description($command_metaclass);

Returns a messages with the basic command description.

=head2 command_usage_global

 my @messages = $meta->command_usage_global();

Returns a list of messages containing the documentation for the application.

=head2 command_usage_header

 my $message = $meta->command_usage_header();
 my $message = $meta->command_usage_header($command_meta_class);

Returns a message containing the basic usage documentation

=head2 command_find

 my @commands = $meta->command_find($user_command_input);

Returns a list of command names matching the user input

=head2 command_candidates

 my $commands = $meta->command_candidates($user_command_input);

Returns either a single command or an arrayref of possibly matching commands.

=head2 command_proto

 my ($result,$errors) = $meta->command_proto($command_meta_class);

Returns all parsed options (as hashref) and erros (as arrayref) for the proto
command. Is a wrapper around L<command_parse_options>.

=head2 command_args

 my ($options,$errors) = $self->command_args($command_meta_class);

Returns all parsed options (as hashref) and erros (as arrayref) for the main
command. Is a wrapper around L<command_parse_options>.

=head2 command_parse_options

 my ($options,$errors) = $self->command_parse_options(\@attribute_metaclasses);

Tries to parse the selected attributes from @ARGV.

=head2 command_check_attribute

 my ($error) = $self->command_check_attribute($attribute_meta_class,$value);

Checks if a value is valid for the given attribute. Returns a message object
if a validation error occurs.

=head2 command_type_constraint_description

 my ($description) = $self->command_type_constraint_description($type_constraint);

Returns a human-readable type constraint description.

=head2 command_scan_namespace
 
 my %namespaces = $self->command_scan_namespace($namespace);

Scans a namespace for command classes. Returns a hash with command names
as keys and package names as values.

=head2 command_process_attributes

 my @attributes = $self->command_process_attributes($metaclass,[qw(option proto)]);
 my @attributes = $self->command_process_attributes($metaclass,'parameter');

Returns a list of all attributes with the given type

=head2 command_usage_options

 my $usage = $self->command_usage_options($metaclass,$headline);

Returns the options usage as a message object

=head2 command_usage_parameters

 my $usage = $self->command_usage_parameters($metaclass,$headline);

Returns the positional parameters usage as a message object
=cut
