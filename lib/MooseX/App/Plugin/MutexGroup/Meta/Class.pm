package MooseX::App::Plugin::MutexGroup::Meta::Class;

use Moose::Role;
use namespace::autoclean;

around 'command_check_attributes' => sub {
   my ($orig, $self, $command_meta, $errors, $params) = @_;
   $command_meta ||= $self;

   my %mutex_groups;
   foreach my $attribute ( $self->command_usage_attributes($command_meta, 'all') ) {
      push @{$mutex_groups{$attribute->mutexgroup}}, $attribute
         if $attribute->can('mutexgroup') && defined $attribute->mutexgroup;
   }

   while ( my ($mutex_group, $options) = each %mutex_groups ) {
      my $initialized_options = grep { defined $params->{$_->name} } @$options;
      if ( $initialized_options > 1 ) {
         die "More than one attribute from mutexgroup $mutex_group" 
            . '(' . join(',', map { "'" . $_->name . "'" } @$options) . ')' 
            . " *cannot* be specified";
      }
      elsif ( $initialized_options == 0 ) {
         die "One attribute from mutexgroup $mutex_group" 
            . '(' . join(',', map { "'" . $_->name . "'" } @$options) . ')' 
            . " *must* be specified";
      }
   }

   return $self->$orig($command_meta, $errors, $params);
};

1;
