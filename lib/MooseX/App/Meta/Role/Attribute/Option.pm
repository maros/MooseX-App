# ============================================================================
package MooseX::App::Meta::Role::Attribute::Option;
# ============================================================================

use utf8;
use 5.010;

use namespace::autoclean;
use Moose::Role;

use Moose::Util::TypeConstraints;

subtype 'MooseX::App::Types::CmdAliases' 
    => as 'ArrayRef';

coerce 'MooseX::App::Types::CmdAliases'
    => from 'Str'
    => via { [$_] };

subtype 'MooseX::App::Types::CmdTypes' 
    => as enum([qw(proto option parameter)]);

has 'cmd_type' => (
    is          => 'rw',
    isa         => 'MooseX::App::Types::CmdTypes',
    predicate   => 'has_cmd_type',
);

has 'cmd_tags' => (
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    predicate   => 'has_cmd_tags',
);

has 'cmd_flag' => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_cmd_flag',
);

has 'cmd_aliases' => (
    is          => 'rw',
    isa         => 'MooseX::App::Types::CmdAliases',
    predicate   => 'has_cmd_aliases',
    coerce      => 1,
);

has 'cmd_split' => (
    is          => 'rw',
    isa         => union([qw(Str RegexpRef)]),
    predicate   => 'has_cmd_split',
);

has 'cmd_position' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

no Moose::Util::TypeConstraints;

my $GLOBAL_COUNTER = 1;

around 'new' => sub {
    my $orig = shift;
    my $class = shift;
    
    my $self = $class->$orig(@_);
    
    if ($self->has_cmd_type) {
        if ($self->cmd_position == 0) {
            $GLOBAL_COUNTER++;
            $self->cmd_position($GLOBAL_COUNTER);
        }
    }
    
    return $self;
};


sub cmd_is_bool {
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

sub cmd_usage_description {
    my ($self) = @_;
    
    my $description = ($self->has_documentation) ? $self->documentation : '';
    my @tags = $self->cmd_tags_list();
    if (scalar @tags) {
        $description .= ' '
            if $description;
        $description .= '['.join('; ',@tags).']';
    }
    return $description
}   
    
sub cmd_usage_name {
    my ($self) = @_;
    
    if ($self->cmd_type eq 'parameter') {
        return $self->cmd_name_primary;
    } else {
        return join(' ', 
            map { (length($_) == 1) ? "-$_":"--$_" } 
            $self->cmd_name_possible);
    }
}

sub cmd_name_primary {
    my ($self) = @_;
    
    if ($self->has_cmd_flag) {
        return $self->cmd_flag;
    } else {
        return $self->name;
    }
}

sub cmd_name_possible {
    my ($self) = @_;
    
    my @names = ($self->cmd_name_primary);
    
    if ($self->has_cmd_aliases) {
        push(@names, @{$self->cmd_aliases});
    }
    
    return @names;
}

sub cmd_tags_list {
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
            if ($self->has_cmd_split) {
                my $split = $self->cmd_split;
                if (ref($split) eq 'Regexp') {
                    $split = "$split";
                    $split =~ s/^\(\?\^\w*:(.+)\)$/$1/x;
                }
                push(@tags,'Multiple','Split by "'.$split.'"');
            } else {
                push(@tags,'Multiple');
            }
        } elsif ($type_constraint->is_a_type_of('HashRef')) {
            push(@tags,'Key-Value');
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

=pod

=encoding utf8

=head1 NAME

MooseX::App::Meta::Role::Attribute::Option - Meta attribute role for options

=head1 DESCRIPTION

This meta attribute role will automatically be applied to all attributes
that should be used as options.

=head1 ACCESSORS

=head2 cmd_flag

Use this name instead of the attribute name as the option name

=head2 cmd_type

Option to mark if this attribute should be used as an option or parameter value.

Allowed values are

=over

=item * option - Command line option

=item * proto - Command line option that should be processed first  (eg. a config-file option that sets other attribues)

=item * parameter - Positional parameter command line value

=back

=head2 cmd_aliases

Arrayref of alternative option names

=head2 cmd_tags

Extra option tags displayed in the usage information (in brackets)

=head2 cmd_position

Indicates the order of the parameters

=head2 cmd_split

Splits multiple values at the given separator string or regular expression. 
Only works in conjunction with an 'ArrayRef[*]' type constraint.

=head1 METHODS

These methods are only of interest to plugin authors.

=head2 cmd_name_possible

 my @names = $attribute->cmd_name_possible();

Returns a list of all possible option names.

=head2 cmd_name_primary

 my $name = $attribute->cmd_name_primary();

Returns the primary option name

=head2 cmd_usage_name

 my $name = $attribute->cmd_usage_name();

Returns the name as used by the usage text

=head2 cmd_usage_description

 my $name = $attribute->cmd_usage_description();

Returns the description as used by the usage text

=head2 cmd_tags_list

 my @tags = $attribute->cmd_tags_list();

Returns a list of tags

=head2 cmd_is_bool

 my $bool = $attribute->cmd_is_bool();

Returns true, false or undef depending on the type constraint and default
of the attribute:

=over

=item * undef: Does not have a boolean type constraint

=item * true: Has a boolean type constraint

=item * false: Has a boolean type constraint, and a true default value

=back

=cut

