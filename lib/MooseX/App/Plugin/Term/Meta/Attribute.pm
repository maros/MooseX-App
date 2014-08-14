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

has 'cmd_term_label' => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_cmd_term_label',
);

sub cmd_term_label_full {
    my ($self) = @_;
    
    my $label = $self->cmd_term_label_name;
    my @tags = $self->cmd_tags_list();
    if (scalar @tags) {
        $label .= ' ('.join(', ',@tags).')';
    }
    $label .= ': ';
    
    return $label;
}

sub cmd_term_label_name {
    my ($self) = @_;
    
    my $label;
    if ($self->has_cmd_term_label) {
        return $self->cmd_term_label;
    } elsif ($self->has_documentation) {
        return $self->documentation;
    } else {
        $self->name;
    }
}

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