# ============================================================================
package MooseX::App::Plugin::BashCompletion::Command;
# ============================================================================

use 5.010;
use utf8;

use Moose;
use MooseX::App::Command;
with qw(MooseX::App::Base);

command_short_description q(Bash completion automator);

sub bash_completion {
    my ($self,$app) = @_;
    
    my %command_map;
    my $app_meta        = $app->meta;
    my %commands        = $app_meta->commands;
    my $command_list    = join (' ', keys %commands);
    my $package         = __PACKAGE__;
    my $prefix          = $app_meta->app_base;
    $prefix =~ tr/./_/;
    
    while (my ($command,$command_class) = each %commands) {
        Class::MOP::load_class($command_class);
        $command_map{$command} = [ $command_class->_attrs_to_options ];
    }
    
    print <<"EOT";
#!/bin/bash
 
# Built with $package;
 
${prefix}_COMMANDS='help $command_list'
 
_${prefix}_macc_help() {
    if [ \$COMP_CWORD = 2 ]; then
        _${prefix}_compreply "\$${prefix}_COMMANDS"
    else
        COMPREPLY=()
    fi
}

EOT
 
    while (my ($c, $o) = each %command_map) {
        print "_${prefix}_macc_$c() {\n    _compreply \"",
            join(" ", map {"--" . $_->{name}} @$o),
                "\"\n}\n\n";
    }
 
 
print <<"EOT";
_${prefix}_compreply() {
    COMPREPLY=(\$(compgen -W "\$1" -- \${COMP_WORDS[COMP_CWORD]}))
}
 
_${prefix}_macc() {
    case \$COMP_CWORD in
        0)
            ;;
        1)
            _${prefix}_compreply "\$${prefix}_COMMANDS"
            ;;
        *)
            eval _${prefix}_macc_\${COMP_WORDS[1]}
             
    esac
}
 
EOT
 
    print "complete -o default -F _${prefix}_macc ", $app_meta->app_base, "\n";
}

1;