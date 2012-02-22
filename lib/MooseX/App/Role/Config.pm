package MooseX::App::Role::Config;

use 5.010;
use utf8;

use Moose::Role;
use MooseX::App::Role;

use MooseX::Types::Path::Class;
use Config::Any;

has 'config' => (
    is              => 'rw',
    isa             => 'Path::Class::File',
    coerce          => 1,
    predicate       => 'has_config',
    documentation   => q[Path to command config file],
);

has '_config_data' => (
    is              => 'rw',
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
        say "Could not find config file '".$config_file->stringify."'";
        say $meta->command_usage_command($command_class);
        return;
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