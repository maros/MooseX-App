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
    isa         => 'Str',
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

has 'app_commands' => (
    is          => 'rw',
    isa         => 'HashRef[Str]',
    traits      => ['Hash'],
    handles     => {
        command_register    => 'set',   
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
    
    my %return;
    foreach my $command_class ($mpo->plugins) {
        my $plugin_class_name =  substr($command_class,length($self->app_namespace)+2);
        next
            if $plugin_class_name =~ m/::/;
        my $command = MooseX::App::Utils::class_to_command($command_class,$self->app_namespace);
        $return{$command} = $command_class;
    }
    
    return \%return;
}

sub proto_command {
    my ($self) = @_;
    
    my $opt_parser = Getopt::Long::Parser->new( 
        config => [ qw( no_auto_help pass_through ) ] 
    );
    my $result = {};
    $opt_parser->getoptions(
        $self->proto_options($result)
    );
    return $result;
}

sub proto_options {
    my ($self,$result) = @_;
    
    $result->{help} = 0;
    return (
        "help|usage|?"      => \$result->{help},
    );
}

sub command_matching {
    my ($self,$command) = @_;
    
    my $commands = $self->app_commands;
    
    # Exact match
    if (defined $commands->{$command}) {
        return $command;
    # Fuzzy match
    } else {
        my @candidates;
        my $candidate_length = length($command);
        my $lc_command = lc($command);
        
        # Compare all commands to find matching candidates
        foreach my $command_name (keys %$commands) {
            my $lc_command_name = lc($command_name);
            if ($lc_command eq $lc_command_name) {
                return $command_name;
            }
            if ($lc_command eq substr($lc_command_name,0,$candidate_length)) {
                push(@candidates,$command_name);
            }
            
        }
        return (sort @candidates);
    }
}

sub command_message {
    my ($self,@args) = @_;
    my $messageclass = $self->app_messageclass;
    Class::MOP::load_class($messageclass);
    return $messageclass->new(@args);
}

sub command_usage_attributes_list {
    my ($self,$metaclass) = @_;
    
    $metaclass ||= $self;
    
    my @return;
    # TODO order by insertion order
    foreach my $attribute ($metaclass->get_all_attributes) {
        next
            unless $attribute->does('AppOption');
        push(@return,$attribute);
    }
    
    return @return;
}

sub command_usage_attributes_raw {
    my ($self,$metaclass) = @_;
    
    $metaclass ||= $self;
    
    my @attributes;
    foreach my $attribute ($self->command_usage_attributes_list($metaclass)) {
        
        my ($attribute_name,$attribute_description) = $self->command_usage_attribute_detail($attribute);
        
        push(@attributes,[$attribute_name,$attribute_description]);
    }
    
    return sort { $a->[0] cmp $b->[0] } @attributes;
}

sub command_usage_attribute_detail {
    my ($self,$attribute) = @_;
    
    my $name = $self->command_usage_attribute_name($attribute);
    my @tags = $self->command_usage_attribute_tags($attribute);
    my $description = ($attribute->has_documentation) ? $attribute->documentation : '';
    
    if (scalar @tags) {
        $description .= ' '
            if $description;
        $description .= '['.join('; ',@tags).']';
    }
    
    return ($name,$description);
}

sub command_usage_attribute_name {
    my ($self,$attribute) = @_;
    
    my @names;
    if ($attribute->can('cmd_flag')
        && $attribute->has_cmd_flag) {
        push(@names,$attribute->cmd_flag);
    } else {
        push(@names,$attribute->name);
    }
    
    if ($attribute->can('cmd_aliases')
        && $attribute->cmd_aliases) {
        push(@names, @{$attribute->cmd_aliases});
    }
    
    if ($attribute->has_type_constraint
        && $attribute->type_constraint->equals('Bool')) {
        if ($attribute->has_default 
            && ! $attribute->is_default_a_coderef
            && $attribute->default == 1) {
            @names = map { 'no'.$_ } @names;    
        } elsif (! $attribute->has_default
            && $attribute->is_required) {
            push(@names,map { 'no'.$_ } @names);        
        }
    }
    
    return join(' ', map { (length($_) == 1) ? "-$_":"--$_" } @names);
}

sub command_usage_attribute_tags {
    my ($self,$attribute) = @_;
    
    my @tags;
    
    if ($attribute->is_required
        && ! $attribute->is_lazy_build
        && ! $attribute->has_default) {
        push(@tags,'Required')
    }
    
    if ($attribute->has_default && ! $attribute->is_default_a_coderef) {
        if ($attribute->has_type_constraint
            && $attribute->type_constraint->equals('Bool')) {
#            if ($attribute->default) {
#                push(@tags,'Default:Enabled');
#            } else {
#                push(@tags,'Default:Disabled');
#            }
        } else {
            push(@tags,'Default:"'.$attribute->default.'"');
        }
    }
    
    if ($attribute->has_type_constraint) {
        my $type_constraint = $attribute->type_constraint;
        if ($type_constraint->is_subtype_of('ArrayRef')) {
            push(@tags,'Multiple');
        }
        unless ($attribute->should_coerce) {
            if ($type_constraint->equals('Int')) {
                push(@tags,'Integer');
            } elsif ($type_constraint->equals('Num')) {
                push(@tags ,'Number');
            } elsif ($type_constraint->equals('Bool')) {
                push(@tags ,'Flag');
            }
        }
    }
    
    if ($attribute->can('cmd_tags')
        && $attribute->can('cmd_tags')
        && $attribute->has_cmd_tags) {
        push(@tags,@{$attribute->cmd_tags});
    }
    
    return @tags;
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
    my ($self,$command) = @_;
    
    $command ||= 'command';
    
    my $caller = $self->app_base;
    
    return $self->command_message(
        header  => 'usage:',
        body    => MooseX::App::Utils::format_text("$caller $command [long options...]
$caller help
$caller $command --help"));
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
    push(@usage,$self->command_usage_header($command_name));
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
        Class::MOP::load_class($class);
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


#{
#    package Moose::Meta::Class::Custom::Trait::AppBase;
#    sub register_implementation { 'MooseX::App::Meta::Role::Class::Base' }
#}

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
the C<_build_app_messageclass> method.

=head2 app_namespace

Usually MooseX::App will take the package name of the base class as the 
namespace for commands. This namespace can be changed.

=head2 app_base

Usually MooseX::App will take the name of the calling wrapper script to 
construct the programm name in various help messages. This name can 
be changed via the app_base accessor.

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

=head2 command_usage_attribute_tags

 my (@tags) = $meta->command_usage_attribute_tags($metaattribute);

Returns a list of tags for the given attribute.

=head2 command_usage_attribute_name

 my ($name,$description) = $meta->command_usage_attribute_name($metaattribute);

Returns a name for a given meta attribute class.

=head2 command_usage_attribute_tag

 my @tags = $meta->command_usage_attribute_name($metaattribute);

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
 my $message = $meta->command_usage_header($command_name);

Returns a message containing the basic usage documentation

=head2 app_commands

 my $commands = $meta->app_commands;

Returns a hashref of command name and command class.

=head2 command_matching

 my @commands = $meta->command_matching($user_command_input);

Returns a list of command names matching the user input

=head2 proto_command

 my $result = $meta->proto_command();

Returns the proto command command-line options.

=head2 proto_options

 my @getopt_options = $meta->proto_command($result_hashref);

Sets the GetOpt::Long options for the proto command

=cut
