# ============================================================================
package MooseX::App::Plugin::Config;
# ============================================================================

use 5.010;
use utf8;

use Moose::Role;
use MooseX::App::Role;

use MooseX::Types::Path::Class;
use Config::Any;

has 'config' => (
    is              => 'ro',
    isa             => 'Path::Class::File',
    coerce          => 1,
    predicate       => 'has_config',
    documentation   => q[Path to command config file],
);

has '_config_data' => (
    is              => 'ro',
    isa             => 'HashRef',
    predicate       => 'has_config_data',
    traits          => ['NoGetopt'],
);


around 'proto_options' => sub {
    my ($orig,$class,$result) = @_;
    
    $result->{config} = undef;
    my @return = $class->$orig($result);
    return (
        @return,
        'config=s'    => \$result->{config},
    )
};

around 'proto_command' => sub {
    my ($orig,$class,$command_class) = @_;
    
    my $result = $class->$orig($command_class);
    delete $result->{config}
        unless defined $result->{config};
    
    return $class->proto_config($command_class,$result);
};

sub proto_config {
    my ($class,$command_class,$result) = @_;
    
    
    # Check if we have a config
    return $result
        unless defined $result->{config};
    
    my $meta = $command_class->meta;
    
    # Read config 
    my $config_file = Path::Class::File->new($result->{config});
    
    unless (-e $config_file->stringify) {
        return MooseX::App::Message::Envelope->new(
            $meta->command_message(
                header          => "Could not find config file '".$config_file->stringify."'",
                type            => "error",
            ),
            $meta->command_usage_command($command_class),
        );
    }
    
    my $config_file_name = $config_file->stringify;
    my $configs = Config::Any->load_files({ 
        files   => [ $config_file_name ],
        use_ext => 1,
    });
    
    my $command_name = MooseX::App::Utils::class_to_command($command_class,$meta->app_namespace);
    
    my ($config_data) = values %{$configs->[0]};
    
    # Merge 
    $config_data->{global} ||= {};
    $config_data->{$command_name} ||= {};
    
    # Set config data
    $result->{config} = $result->{config};
    $result->{_config_data} = $config_data;
    
    # Lopp all attributes
    foreach my $attribute ($meta->get_all_attributes) {
        my $attribute_name = $attribute->name;
        next
            if $attribute_name eq 'config';
        $result->{$attribute_name} = $config_data->{global}{$attribute_name}
            if defined $config_data->{global}{$attribute_name};
        $result->{$attribute_name} = $config_data->{$command_name}{$attribute_name}
            if defined $config_data->{$command_name}{$attribute_name};
    }
    
    return $result;
};

1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Plugin::Config - Config files your MooseX::App appications

=head1 SYNOPSIS

In your base class:

 package MyApp;
 use MooseX::App qw(Config);
 
 has 'global_option' => (
     is          => 'rw',
     isa         => 'Int',
 );

In your command class:

 package MyApp::Some_Command;
 use MooseX::App::Command;
 extends qw(MyApp);
 
 has 'some_option' => (
     is          => 'rw',
     isa         => 'Str',
 );

Now create a config file (see L<Config::Any>) eg. a yaml file:

 ---
 global:
   global_option: 123
 some_command:
   global_option: 234
   some_option: "hello world"

The user can now call the program with a config file:

 bash$ myapp some_command --config /path/to/config.yml

=head1 METHODS

=head2 config

Read the config filename

=head2 _config_data

The full content of the loaded config file

=head1 SEE ALSO

L<Config::Any>

=cut