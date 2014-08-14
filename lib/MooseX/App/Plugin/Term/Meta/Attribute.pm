# ============================================================================
package MooseX::App::Plugin::Term::Meta::Attribute;
# ============================================================================

use utf8;
use 5.010;

use namespace::autoclean;
use Moose::Role;

has 'cmd_term' => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 0,
);

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