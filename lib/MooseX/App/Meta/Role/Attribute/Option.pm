# ============================================================================
package MooseX::App::Meta::Role::Attribute::Option;
# ============================================================================

use utf8;
use 5.010;

use namespace::autoclean;
use Moose::Role;
with qw(MooseX::Getopt::Meta::Attribute::Trait);

use Moose::Util::TypeConstraints;

subtype 'MooseX::App::Types::CmdAliases' => as 'ArrayRef';

coerce 'MooseX::App::Types::CmdAliases'
    => from 'Str'
        => via { [$_] };

no Moose::Util::TypeConstraints;

has 'cmd_tags' => (
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    predicate   => 'has_cmd_tags',
);

has 'cmd_proto' => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 0,
);

sub cmd_bool {
    my ($self) = @_; 
   
    if ($self->has_type_constraint
        && $self->type_constraint->is_a_type_of('Bool')) {
        
        # Bool and defaults to true 
        if ($self->has_default 
            && ! $self->is_default_a_coderef
            && $self->default == 1) {
            return 0;
        ## Bool and is required
        #} elsif (! $self->has_default
        #    && $self->is_required) {
        #    return 0; 
        }
        
        # Ordinary bool
        return 1;
    }
    
    return undef
}

sub cmd_names_get {
    my ($self) = @_;
    
    my @names;
    if ($self->has_cmd_flag) {
        push(@names,$self->cmd_flag);
    } else {
        push(@names,$self->name);
    }
    
    if ($self->has_cmd_aliases) {
        push(@names, @{$self->cmd_aliases});
    }
    
    my $bool = $self->cmd_bool();
    
    if (defined $bool
        && $bool == 0) {
        @names = map { 'no'.$_ } @names;
    }
    
    return @names;
}

sub cmd_tags_get {
    my ($self) = @_;
    
    my @tags;
    
    if ($self->is_required
        && ! $self->is_lazy_build
        && ! $self->has_default) {
        push(@tags,'Required')
    }
    
    if ($self->has_default && ! $self->is_default_a_coderef) {
        if ($self->has_type_constraint
            && $self->type_constraint->is_a_type_of('Bool')) {
#            if ($attribute->default) {
#                push(@tags,'Default:Enabled');
#            } else {
#                push(@tags,'Default:Disabled');
#            }
        } else {
            push(@tags,'Default:"'.$self->default.'"');
        }
    }
    
    if ($self->has_type_constraint) {
        my $type_constraint = $self->type_constraint;
        if ($type_constraint->is_subtype_of('ArrayRef')) {
            push(@tags,'Multiple');
        }
        unless ($self->should_coerce) {
            if ($type_constraint->is_a_type_of('Int')) {
                push(@tags,'Integer');
            } elsif ($type_constraint->is_a_type_of('Num')) {
                push(@tags ,'Number');
            } elsif ($type_constraint->is_a_type_of('Bool')) {
                push(@tags ,'Flag');
            }
        }
    }
    
    if ($self->can('cmd_tags')
        && $self->can('cmd_tags')
        && $self->has_cmd_tags) {
        push(@tags,@{$self->cmd_tags});
    }
    
    return @tags;
}

{
    package Moose::Meta::Attribute::Custom::Trait::AppOption;
    
    use strict;
    use warnings;
    
    sub register_implementation { return 'MooseX::App::Meta::Role::Attribute::Option' }
}

1;