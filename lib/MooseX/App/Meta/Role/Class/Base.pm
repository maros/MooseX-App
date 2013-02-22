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

has 'app_messageclass' => (
    is          => 'rw',
    isa         => 'ClassName',
    lazy_build  => 1,
);

has 'app_namespace' => (
    is          => 'rw',
    isa         => 'Str',
    lazy_build  => 1,
);

has 'app_base' => (
    is          => 'rw',
    isa         => 'Str',
    default     => sub { Path::Class::File->new($0)->basename },
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
    return $self->name;
}

sub _build_app_commands {
    my ($self) = @_;
    
    my $mpo = Module::Pluggable::Object->new(
        search_path => [ $self->app_namespace ],
    );
    
    my $namespace = $self->app_namespace;
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
    
    return \%return;
}

sub command_args {
    my ($self,$metaclass) = @_;
    
    $metaclass      ||= $self;
    my @attributes  = $self->command_usage_attributes_list($metaclass);
    
    my ($return,$errors) = $self->command_parse_options(\@attributes);
    my $parsed_argv = MooseX::App::ParsedArgv->instance;
    
    foreach my $option ($parsed_argv->options_available) {
        push(@{$errors},
            $self->command_message(
                header          => "Unknown option '".$option->key."'",
                type            => "error",
            )
        );
    }
    
    return ($return,$errors);
}

sub command_proto {
    my ($self,$metaclass) = @_;
    
    $metaclass   ||= $self;
    
    my @attributes;
    foreach my $attribute ($self->command_usage_attributes_list($metaclass)) {
        next
            unless $attribute->cmd_proto;
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
                && $option_to_attribute{$name} ne $attribute->name) {
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
    foreach my $option ($parsed_argv->options_available()) {
        if (my $attribute = $option_to_attribute{$option->key}) {
            $match->{$attribute->name} = $option->value;
            $option->consume($attribute);
        }
    }
    
    # Process fuzzy matches
    if ($self->app_fuzzy) {
        # Loop all options (sorted by length)
        foreach my $option (sort { length($b->key) <=> length($a->key) } $parsed_argv->options_available()) {

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
                    $option->consume($attribute);
                    $match->{$attribute->name} ||= [];
                    push(@{$match->{$attribute->name}},@{$option->value}); 
                }
                # Multiple matches
                default {
                    push(@errors,
                        $self->command_message(
                            header          => "Ambiguous option '".$option->key."'",
                            type            => "error",
                            body            => "Could be\n".MooseX::App::Utils::format_list(
                                map { [ $_->cmd_name_primary ] } 
                                sort 
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
        my $value;
        
        next
            unless exists $match->{$attribute->name};
        
        # Attribute with type constraint
        if ($attribute->has_type_constraint) {
            my $type_constraint = $attribute->type_constraint;
            
            if ($type_constraint->is_a_type_of('ArrayRef')) {
                $value = $match->{$attribute->name};
            } elsif ($type_constraint->is_a_type_of('HashRef')) {
                $value = {};
                foreach my $element (@{$match->{$attribute->name}}) {
                    if ($element =~ m/^([^=]+)=(.+?)$/) {
                        $value->{$1} ||= $2;
                    } else {
                        push(@errors,
                            $self->command_message(
                                header          => "Invalid value for '".$attribute->cmd_name_primary."'",
                                type            => "error",
                                body            => "Value must be supplied as 'key=value' (not '$element')",
                            )
                        );
                    }
                }
            } elsif ($type_constraint->is_a_type_of('Bool')) {
                $value = $attribute->cmd_is_bool; # TODO or 0 if no!
            } elsif ($type_constraint->is_a_type_of('Int')) {
                $value = $match->{$attribute->name}[-1];
            } else {
                $value = $match->{$attribute->name}[-1];
            }
            
            unless(defined $value) {
                push(@errors,
                    $self->command_message(
                        header          => "Missing value for '".$attribute->cmd_name_primary."'",
                        type            => "error",
                    )
                );
            } else {
                            
                my $coercion;
                if ($attribute->should_coerce
                    && $type_constraint->has_coercion) {
                    $coercion = $type_constraint->coercion;
                    $value = $coercion->coerce($value) // $value;
                }
                
                my $error = $self->command_check_attribute($attribute,$value);
                push(@errors,$error)
                    if $error;
            }
            
        } else {
             $value = $match->{$attribute->name}[-1];
        }
        
        $return->{$attribute->name} = $value;
    }
    
    return ($return,\@errors);
}

sub command_check_attribute {
    my ($self,$attribute,$value) = @_;
    
    return 
        unless ($attribute->has_type_constraint);
    my $type_constraint = $attribute->type_constraint;
    
    # Check type constraints
    unless ($type_constraint->check($value)) {
        my $message;
        
        # We have a custom message
        if ($type_constraint->has_message) {
            $message = $type_constraint->get_message($value);
        # No message
        } else {
            my $type_human = $self->command_type_constraint_description($type_constraint->name);
            if (defined $type_human) {
                $message = "Value must be ";
                if ($type_human =~ /^[aeiouy]/) {
                    $message .= "an $type_human";
                } else {
                    $message .= "a $type_human";
                }
                $message .= " (not '$value')";
            } else {
                $message = $type_constraint->get_message($value);
            }
        }
        
        return $self->command_message(
            header          => "Invalid value for '".$attribute->cmd_name_primary."'",
            type            => "error",
            body            => $message,
        );
    }
    
    return;
}


sub command_type_constraint_description {
    my ($self,$type_constraint_name) = @_;
    
    given ($type_constraint_name) {
        when ('Int') {
            return 'integer';
        }
        when ('Num') {
            return 'number';
        }
        when (/^ArrayRef\[(.*)\]$/) {
            return $self->command_type_constraint_description($1);
        }
        when ('HashRef') {
            return 'key-value pairs';
        }
        when (/^HashRef\[(.+)\]$/) {
            return 'key-value pairs with '.$self->command_type_constraint_description($1).' values';
        }
        when ('Str') {
            return 'string';
        }
    }
    
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
                        header          => "Unknown command '$command'",
                        type            => "error",
                    );
                }
                when (1) {
                    if ($self->app_fuzzy) {
                        return $candidate->[0];
                    } else {
                        return $self->command_message(
                            header          => "Unknown command '$command'",
                            type            => "error",
                            body            => "Did you mean '".$candidate->[0]."'?",
                        );
                    }
                }
                default {
                    return $self->command_message(
                        header          => "Ambiguous command '$command'",
                        type            => "error",
                        body            => "Which command did you mean?\n".MooseX::App::Utils::format_list(map { [ $_ ] } sort @{$candidate}),
                    );
                }
            }
        }
    }
}

sub command_message {
    my ($self,@args) = @_;
    my $messageclass = $self->app_messageclass;
    Class::Load::load_class($messageclass);
    return $messageclass->new(@args);
}

sub command_usage_attributes_list {
    my ($self,$metaclass) = @_;
    
    $metaclass ||= $self;
    
    my @return;
    # TODO order by insertion order
    foreach my $attribute ($metaclass->get_all_attributes) {
        next
            unless $attribute->does('AppOption')
            && $attribute->cmd_option;
        
        push(@return,$attribute);
    }
    
    return @return;
}

sub command_usage_attributes_raw {
    my ($self,$metaclass) = @_;
    
    $metaclass ||= $self;
    
    my @attributes;
    foreach my $attribute ($self->command_usage_attributes_list($metaclass)) {
        
        my ($attribute_name,$attribute_description) = $attribute->cmd_usage();
        
        push(@attributes,[$attribute_name,$attribute_description]);
    }
    
    @attributes = sort { $a->[0] cmp $b->[0] } @attributes;
    return @attributes;
}

sub command_usage_attributes {
    my ($self,$metaclass,$headline) = @_;
    
    $headline ||= 'options:';
    $metaclass ||= $self;
    
    my @attributes = $self->command_usage_attributes_raw($metaclass);
    
    return
        unless scalar @attributes > 1;
    
    return $self->command_message(
        header  => $headline,
        body    => MooseX::App::Utils::format_list(@attributes),
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
        $command_name = 'command';
    }
    
    $usage ||= MooseX::App::Utils::format_text("$caller $command_name [long options...]
$caller help
$caller $command_name --help");
    
    return $self->command_message(
        header  => 'usage:',
        body    => $usage,
    );
}

sub command_usage_description {
    my ($self,$command_meta_class) = @_;
    
    $command_meta_class ||= $self;
    
    if ($command_meta_class->can('command_long_description')
        && $command_meta_class->command_long_description_predicate) {
        return $self->command_message(
            header  => 'description:',
            body    => MooseX::App::Utils::format_text($command_meta_class->command_long_description),
        );
    } elsif ($command_meta_class->can('command_short_description')
        && $command_meta_class->command_short_description_predicate) {
        return $self->command_message(
            header  => 'short description:',
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
    push(@usage,$self->command_usage_description($command_meta_class));
    push(@usage,$self->command_usage_attributes($command_meta_class));
    
    return @usage;
}

sub command_usage_global {
    my ($self) = @_;
    
    my @commands;
    push(@commands,['help','Prints this usage information']);
    
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
    push (@usage,$self->command_usage_attributes($self,'global options:'));
    push (@usage,
        $self->command_message(
            header  => 'available commands:',
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
class. This documentation is only of interest if you intent to write
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
construct the programm name in various help messages. This name can 
be changed via the app_base accessor. Defaults to the base name of $0

=head2 app_fuzzy

Boolean attribute that controlls if command names and attributes should be 
matched exactly or fuzzy. Defaults to true.

=head2 app_command_name

Coderef attribute that controlls how package names are translated to command 
names and attributes. Defaults to &MooseX::App::Utils::class_to_command

=head1 METHODS

=head2 command_class_to_command

 my $command_moniker = $meta->command_class_to_command($command_class);

Returns the command moniker for the given command class name.

=head2 command_message

 my $message = $meta->command_message( header => $header, type => 'error', body => $message );

Generates a message object (based on L<app_messageclass>)

=head2 command_usage_attributes

 my $message = $meta->command_usage_attributes($metaclass,$headline);

Returns a message object containing the attribute documentation for a given
meta class.

=head2 command_usage_attributes_list

 my @attributes = $meta->command_usage_attributes($metaclass);

Returns a list of attributes/command options.

=head2 command_usage_attributes_raw

 my @attributes = $meta->command_usage_attributes_raw($metaclass);

Returns a list of attribute documentations for a given meta class.

=head2 command_usage_attribute_detail

 my ($name,$description) = $meta->command_usage_attribute_detail($metaattribute);

Returns a name and description for a given meta attribute class.

=head2 command_usage_attribute_tag

 my @tags = $meta->command_usage_attribute_tag($metaattribute);

Returns a list of tags for a given meta attribute class.

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

=head2 app_commands

 my $commands = $meta->app_commands;

Returns a hashref of command name and command class.

=head2 command_find

 my @commands = $meta->command_find($user_command_input);

Returns a list of command names matching the user input

=head2 command_candidates

 my $commands = $meta->command_candidates($user_command_input);

Returns either a single command or an arrayref of possibly matching commands.

=head2 command_proto

 my ($result,$errors) = $meta->command_proto();

Returns the proto command command line options.

=cut
