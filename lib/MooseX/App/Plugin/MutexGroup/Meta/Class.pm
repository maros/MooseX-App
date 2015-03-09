# ============================================================================
package MooseX::App::Plugin::MutexGroup::Meta::Class;
# ============================================================================

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
      my $initialized_options = 
         grep { defined $params->{ $_->cmd_name_primary } } @$options;
      if ( $initialized_options > 1 ) {
         my $error_msg = 
            "More than one attribute from mutexgroup $mutex_group" 
            . '(' . join(',', map { "'" . $_->cmd_name_primary . "'" } @$options) . ')' 
            . " *cannot* be specified";
         push @$errors,
            $self->command_message(
               header => $error_msg,
               type   => "error",
            );
      }
      elsif ( $initialized_options == 0 ) {
         my $error_msg = 
            "One attribute from mutexgroup $mutex_group" 
            . '(' . join(',', map { "'" . $_->cmd_name_primary . "'" } @$options) . ')' 
            . " *must* be specified";

         push @$errors,
            $self->command_message(
               header => $error_msg,
               type   => "error",
            );    
      }
   }

   return $self->$orig($command_meta, $errors, $params);
};

1;
