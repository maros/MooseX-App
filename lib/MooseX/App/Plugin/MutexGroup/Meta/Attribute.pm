package MooseX::App::Plugin::MutexGroup::Meta::Attribute;

use Moose::Role;
use namespace::autoclean;

use Data::Dumper;

has 'mutexgroup' => (
   is      => 'ro',
   isa     => 'Str',
   default => 0,
);

around 'cmd_tags_list' => sub {
   my $orig = shift;
   my ($self) = @_;
   
   my @tags = $self->$orig();
   
   push(@tags,'MutexGroup')
      if $self->can('mutexgroup')
      && $self->mutexgroup;

   return @tags;
};

{
   package Moose::Meta::Attribute::Custom::Trait::AppMutexGroup;
     
   use strict;
   use warnings;
   
   sub register_implementation { return 'MooseX::App::Plugin::MutexGroup::Meta::Attribute' }
}

1;
