package MooseX::App::Meta::Role::Class::Command;

use utf8;
use 5.010;

use Moose::Role;

#use Pod::Elemental;

has 'command_short_description' => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_command_short_description',
    lazy_build  => 1,
);

has 'command_long_description' => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_command_long_description',
    lazy_build  => 1,
);

sub _build_command_short_description {
    my ($self) = @_;
    
    return $self->_build_command_pod('command_short_description');
}

sub _build_command_long_description {
    my ($self) = @_;
    
    return $self->_build_command_pod('command_long_description');
}

sub _build_command_pod {
    my ($self) = @_;
    
    my $package_name = $self->name;
    $package_name =~ s/::/\//g;
    $package_name .= '.pm';
    return "POD for $package_name";
    
#    my $filename;
#    if (defined $INC{$package_name}) {
#        $filename = $INC{$package_name};
#        $filename =~ s/\/{2,}/\//g;
#    }
#    
#    return 
#        unless defined $filename;
#    
#    use Pod::Simple::SimpleTree;
#    my $parser = Pod::Simple::SimpleTree->new();
#    my $pod = $parser->parse_file( $filename );
#    
#    use Data::Dumper;
#    {
#      local $Data::Dumper::Maxdepth = 4;
#      warn __FILE__.':line'.__LINE__.':'.Dumper($pod->{root});
#    }
#    
#    my $document = Pod::Elemental->read_file($filename);
#    
#    use Pod::Elemental::Selectors qw(s_command s_flat);
#    use Pod::Elemental::Transformer::Nester;
#    
#    my $nester = Pod::Elemental::Transformer::Nester->new({
#        top_selector      => s_command('head1'),
#        content_selectors => [
#          s_command([ qw(head2 head3 head4) ]),
#          s_flat
#        ],
#      });
#        $nester->transform_node($document);
#    #      s_flat(),
#    #Pod::Elemental::Transformer::Pod5->new->transform_node($document);
#    
#    use Data::Dumper;
#    {
#      local $Data::Dumper::Maxdepth = 5;
#      die __FILE__.':line'.__LINE__.':'.Dumper($document);
#    }
#    
#    
#    
#    my $current_element;
#    foreach my $element (@{$document->children}) {
#        next
#            if $element->isa('Pod::Elemental::Element::Pod5::Nonpod');
#            
#        if ($element->isa('Pod::Elemental::Element::Pod5::Command')) {
#            next
#                unless $element->command =~ /^head\d/i;
#            
#            if ($element->content eq 'DESCRIPTION') {
#                $current_element = 'command_long_description';
#            } elsif ($element->content eq 'NAME') {
#                $current_element = 'command_short_description';
#            } elsif ($element->content eq 'SYNOPSIS' || $element->content eq 'USAGE') {
#                $current_element = 'command_usage';
#            }
#        } elsif ($element->isa('Pod::Elemental::Element::Pod5::Ordinary')) {
#
#            #warn $current_element;
#            warn '<X'.$element->as_pod_string.'X>';
#        
#        }
#        
#    }
    
}

#{
#    package Moose::Meta::Class::Custom::Trait::AppCommand;
#    sub register_implementation { 'MooseX::App::Meta::Role::Class::Command' }
#}

1;
