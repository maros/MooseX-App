# ============================================================================
package MooseX::App::Plugin::BashCompletion::Role;
# ============================================================================

use 5.010;
use utf8;

use Moose::Role;

  
#sub execute {
#    my ($self, $opts, $args) = @_;
# 
#    my @commands = grep {
#        !/bashcomplete|-h|--help|-\?|help|commands/
#    } $self->app->command_names;
# 
#    my %command_map = ();
#    for my $cmd (@commands) {
#        $command_map{$cmd}
#            = [$self->app->plugin_for($cmd)->_attrs_to_options()];
#    }
# 
#    my $cmd_list = join ' ', @commands;
#    my $package  = __PACKAGE__;
#    my $prefix = $self->app->arg0;
#    $prefix =~ tr/./_/;
# 
#    print <<"EOT";
##!/bin/bash
# 
## Built with $package;
# 
#${prefix}_COMMANDS='help commands bashcomplete $cmd_list'
# 
#_${prefix}_macc_help() {
#    if [ \$COMP_CWORD = 2 ]; then
#        _${prefix}_compreply "\$${prefix}_COMMANDS"
#    else
#        COMPREPLY=()
#    fi
#}
# 
#_${prefix}_macc_commands() {
#    COMPREPLY=()
#}
# 
#_${prefix}_macc_bashcomplete() {
#    COMPREPLY=()
#}
# 
#EOT
# 
#    while (my ($c, $o) = each %command_map) {
#        print "_${prefix}_macc_$c() {\n    _compreply \"",
#            join(" ", map {"--" . $_->{name}} @$o),
#                "\"\n}\n\n";
#    }
# 
# 
#print <<"EOT";
# 
#_${prefix}_compreply() {
#    COMPREPLY=(\$(compgen -W "\$1" -- \${COMP_WORDS[COMP_CWORD]}))
#}
# 
#_${prefix}_macc() {
#    case \$COMP_CWORD in
#        0)
#            ;;
#        1)
#            _${prefix}_compreply "\$${prefix}_COMMANDS"
#            ;;
#        *)
#            eval _${prefix}_macc_\${COMP_WORDS[1]}
#             
#    esac
#}
# 
#EOT
# 
#    print "complete -o default -F _${prefix}_macc ", $self->app->arg0, "\n";
#}


1;