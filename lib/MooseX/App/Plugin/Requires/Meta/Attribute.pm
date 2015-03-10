# ============================================================================
package MooseX::App::Plugin::Requires::Meta::Attribute;
# ============================================================================

use Moose::Role;
use namespace::autoclean;

has 'requires' => (
   is      => 'ro',
   isa     => 'ArrayRef[Str]',
   default => sub { [] },
);

around 'cmd_tags_list' => sub {
   my $orig = shift;
   my ($self) = @_;
   
   my @tags = $self->$orig();
   
   push(@tags,'Requires')
      if $self->can('requires')
      && $self->requires;

   return @tags;
};

{
   package Moose::Meta::Attribute::Custom::Trait::AppRequires;
     
   use strict;
   use warnings;
   
   sub register_implementation { return 'MooseX::App::Plugin::Requires::Meta::Attribute' }
}

1;
