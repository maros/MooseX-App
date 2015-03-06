package MooseX::App::Plugin::MutexGroup;

use Moose::Role;
use namespace::autoclean;

sub plugin_metaroles {
   my ($self, $class) = @_;
   
   return {
      attribute => ['MooseX::App::Plugin::MutexGroup::Meta::Attribute'],
      class     => ['MooseX::App::Plugin::MutexGroup::Meta::Class'],
   }
}

1;
