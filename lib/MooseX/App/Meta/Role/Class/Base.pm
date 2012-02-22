package MooseX::App::Meta::Role::Class::Base;

use utf8;
use 5.010;

use Moose::Role;

use MooseX::App::Utils;
use Path::Class;

has 'app_messageclass' => (
    is          => 'rw',
    isa         => 'Str',
    default     => 'MooseX::App::Message::Block',
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

sub _build_app_namespace {
    my ($self) = @_;
    return $self->name;
}

sub matching_commands {
    my ($self,$command) = @_;
    
    my %commands = $self->commands;
    
    # Exact match
    if (defined $commands{$command}) {
        return $command;
    # Fuzzy match
    } else {
        my @candidates;
        my $candidate_length = length($command);
        
        # Compare all commands to find matching candidates
        foreach my $command_name (keys %commands) {
            if (lc($command) eq lc($command_name)) {
                return $command_name;
            }
            if ($command eq substr($command_name,0,$candidate_length)) {
                push(@candidates,$command_name);
            }
        }
        return @candidates;
    }
}

sub command_message {
    my ($self,@args) = @_;
    my $messageclass = $self->app_messageclass;
    Class::MOP::load_class($messageclass);
    return $messageclass->new(@args);
}

sub commands {
    my ($self) = @_;
    
    my $mpo = Module::Pluggable::Object->new(
        search_path => [ $self->app_namespace ],
    );
    
    my %return;
    foreach my $command_class ($mpo->plugins) {
        my $command = MooseX::App::Utils::class_to_command($command_class,$self->app_namespace);
        $return{$command} = $command_class;
    }
    
    return %return;
}

sub command_usage_attributes_raw {
    my ($self,$metaclass) = @_;
    
    $metaclass ||= $self;
    
    my @attributes;
    foreach my $attribute ($metaclass->get_all_attributes) {
        next
            if $attribute->does('NoGetopt');
        
        my ($attribute_name,$attribute_description) = $self->command_usage_attribute_detail($attribute);
        
        push(@attributes,[$attribute_name,$attribute_description]);
    }
    
    return sort { $a->[0] cmp $b->[0] } @attributes;
}

sub command_usage_attribute_detail {
    my ($self,$attribute) = @_;
    
    my @names;
    if ($attribute->can('cmd_flag')) {
        push(@names,$attribute->cmd_flag);
    } else {
        push(@names,$attribute->name);
    }
    
    if ($attribute->can('cmd_aliases')
        && $attribute->cmd_aliases) {
        push(@names, @{$attribute->cmd_aliases});
    }
    my $name = join(' ', map { (length($_) == 1) ? "-$_":"--$_" } @names);
    
    my @tags = $self->command_usage_attribute_tags($attribute);
    my $description = ($attribute->has_documentation) ? $attribute->documentation : '';
    
    if (scalar @tags) {
        $description .= ' '
            if $description;
        $description .= '['.join('; ',@tags).']';
    }
    
    return ($name,$description);
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
        push(@tags,'Default:"'.$attribute->default.'"');
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
    
    if ($attribute->can('command_tags')
        && $attribute->can('has_command_tags')
        && $attribute->has_command_tags) {
        push(@tags,@{$attribute->command_tags});
    }
    
    return @tags;
}


sub command_usage_attributes {
    my ($self,$metaclass) = @_;
    
    return MooseX::App::Utils::format_list($self->command_usage_attributes_raw($metaclass));
}

sub command_usage_header {
    my ($self,$command) = @_;
    
    $command ||= 'command';
    
    my $caller = $self->app_base;
    
    return $self->command_message(
        header  => 'usage:',
        body    => qq[    $caller $command [long options...]
    $caller help
    $caller $command --help]);
}

sub command_usage_command {
    my ($self,$command_class) = @_;
    
    my $comand_name = MooseX::App::Utils::class_to_command($command_class,$self->app_namespace);
    
    my @usage;
    push (@usage,$self->command_usage_header($comand_name));
    
    if ($command_class->meta->can('command_long_description')
        && $command_class->meta->command_long_description) {
        push(@usage,
            $self->command_message(
                header  => 'description:',
                body    => MooseX::App::Utils::format_text($command_class->meta->command_long_description),
            )
        );
    } elsif ($command_class->meta->can('command_short_description')
        && $command_class->meta->command_short_description) {
        push(@usage,
            $self->command_message(
                header  => 'short description:',
                body    => MooseX::App::Utils::format_text($command_class->meta->command_short_description),
            )
        );
    }
    
    push (@usage,$self->command_message(
        header  => 'options:',
        body    => MooseX::App::Utils::format_list($self->command_usage_attributes_raw($command_class->meta)),
    ));
    
    return @usage;
}

sub command_usage_global {
    my ($self) = @_;
    
    my @commands;
    push(@commands,['help','Prints this usage information']);
    
    my %commands = $self->commands;
    
    while (my ($command,$class) = each %commands) {
        Class::MOP::load_class($class);
        my $description;
        $description = $class->meta->command_short_description
            if $class->meta->can('command_short_description');
        
        $description ||= '';
        push(@commands,[$command,$description]);
    }
    
    @commands = sort { $a->[0] cmp $b->[0] } @commands;
    my $global_options = $self->command_usage_attributes();
    
    my @usage;
    push (@usage,$self->command_usage_header());
    if ($global_options) {
        push (@usage,
            $self->command_message(
                header  => 'global options:',
                body    => $global_options,
            )
        );
    }
    
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
