# ============================================================================
package MooseX::App::Plugin::Env::Meta::Attribute;
# ============================================================================

use utf8;
use 5.010;

use namespace::autoclean;
use Moose::Role;
use Moose::Util::TypeConstraints;
     
subtype 'MooseX::App::Types::Env',
    as 'Str',
    where { m/^[A-Z0-9_]+$/ };

no Moose::Util::TypeConstraints;

has 'cmd_env' => (
    is          => 'rw',
    isa         => 'MooseX::App::Types::Env',
    predicate   => 'has_cmd_env',
);

around 'cmd_tags_get' => sub {
    my $orig = shift;
    my ($self) = @_;
    
    my @tags = $self->$orig();
    
    push(@tags,'Env: '.$self->cmd_env)
        if $self->can('has_cmd_env')
        && $self->has_cmd_env;
   
    return @tags;
};

{
    package Moose::Meta::Attribute::Custom::Trait::AppEnv;
    
    use strict;
    use warnings;
    
    sub register_implementation { return 'MooseX::App::Plugin::Env::Meta::Attribute' }
}

1;