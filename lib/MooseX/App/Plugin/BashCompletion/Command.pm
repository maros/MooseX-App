# ============================================================================
package MooseX::App::Plugin::BashCompletion::Command;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose;
use MooseX::App::Command;

command_short_description q(Bash completion automator);

sub bash_completion {
    my ($self,$app) = @_;
    
    my %command_map;
    my $app_meta        = $app->meta;
    my $commands        = $app_meta->app_commands;
    my $command_list    = join (' ', keys %{$commands});
    my $package         = __PACKAGE__;
    my $prefix          = $app_meta->app_base;
    
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
    $year               += 1900;
    $mday               = sprintf('%02i',$mday);
    $mon                = sprintf('%02i',$mon+1);
    
    $prefix             =~ tr/./_/;
    
    while (my ($command,$command_class) = each %$commands) {
        Class::Load::load_class($command_class);
        #my @parameters = $app_meta->command_usage_attributes_list($command_class->meta,'parameter');
        my @options = $app_meta->command_usage_attributes_list($command_class->meta,[qw(option proto)]);
        $command_map{$command} = {
            #parameters  => [ map { $_->is_required } @parameters ],
            options     => [ map { $_->cmd_usage_name } @options ],
        };
    }
    
    my $syntax = '';;
    
    $syntax .= <<"EOT";
#!/bin/bash
 
# Built with $package on $year/$mon/$mday
 
${prefix}_COMMANDS='help $command_list'
 
_${prefix}_macc_help() {
    if [ \$COMP_CWORD = 2 ]; then
        _${prefix}_compreply "\$${prefix}_COMMANDS"
    else
        COMPREPLY=()
    fi
}

EOT
 
    while (my ($command, $data) = each %command_map) {
        $syntax .= "_${prefix}_macc_${command}() {\n    _${prefix}_compreply \"";
        #$syntax .= join(" ", @{$data->{parameters}});
        $syntax .= join(" ", @{$data->{options}});
        $syntax .= "\"\n}\n\n";
    }
 
    $syntax .= <<"EOT";
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
 
    $syntax .= "complete -o default -F _${prefix}_macc ". $app_meta->app_base. "\n";
    
    return MooseX::App::Message::Envelope->new(
        MooseX::App::Message::Block->new({ body => $syntax })
    );
}

__PACKAGE__->meta->make_immutable;
1;
