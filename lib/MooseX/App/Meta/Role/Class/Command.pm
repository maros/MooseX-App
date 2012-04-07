# ============================================================================
package MooseX::App::Meta::Role::Class::Command;
# ============================================================================

use utf8;
use 5.010;

use Moose::Role;

use Pod::Elemental;
use Pod::Elemental::Selectors qw();
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::Nester;

has 'command_short_description' => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    lazy_build  => 1,
);

has 'command_long_description' => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    lazy_build  => 1,
);

sub command_short_description_predicate {
    my ($self) = @_;  
    return $self->_command_description_predicate('command_short_description');
}

sub _build_command_short_description {
    my ($self) = @_;
    my %pod = $self->_build_command_pod();
    return $pod{'command_short_description'}
        if defined $pod{'command_short_description'};
}

sub command_long_description_predicate {
    my ($self) = @_;
    return $self->_command_description_predicate('command_long_description');
}

sub _build_command_long_description {
    my ($self) = @_;
    return $self->_build_command_pod();
    my %pod = $self->_build_command_pod();
    return $pod{'command_long_description'}
        if defined $pod{'command_long_description'};
}

sub _command_description_predicate {
    my ($self,$field) = @_;
    
    my $attribute = $self->meta->find_attribute_by_name($field);
    
    unless ($attribute->has_value($self)) {
        $self->_build_command_pod($field);
    }
        
    return (defined $attribute->get_value($self) ? 1:0);
}

sub _build_command_pod {
    my ($self) = @_;
    
    my $package_filename = $self->name;
    $package_filename =~ s/::/\//g;
    $package_filename .= '.pm';
    
    my $package_filepath;
    if (defined $INC{$package_filename}) {
        $package_filepath = $INC{$package_filename};
        $package_filepath =~ s/\/{2,}/\//g;
    }
    
    return 
        unless defined $package_filepath
        && -e $package_filepath;
    
    my $document = Pod::Elemental->read_file($package_filepath);
    
    Pod::Elemental::Transformer::Pod5->new->transform_node($document);
    
    my $nester_head = Pod::Elemental::Transformer::Nester->new({
        top_selector      => Pod::Elemental::Selectors::s_command('head1'),
        content_selectors => [ 
            Pod::Elemental::Selectors::s_command([ qw(head2 head3 head4 over back item) ]),
            Pod::Elemental::Selectors::s_flat() 
        ],
    });
    $document = $nester_head->transform_node($document);
    
    my %pod;
    foreach my $element (@{$document->children}) {
        next
            unless $element->isa('Pod::Elemental::Element::Nested')
            && $element->command eq 'head1';
        
        given ($element->content) {
            when('NAME') {
                my $name = $self->name;
                my $content = $self->_pod_node_to_text($element->children);
                $content =~ s/^$name(\s-)?\s//;
                $pod{command_short_description} = $content;
            }
            when([qw(DESCRIPTION OVERVIEW)]) {
                my $content = $self->_pod_node_to_text($element->children);
                $pod{command_long_description} = $content;
            }
        }
    }
    
    while (my ($key,$value) = each %pod) {
        my $meta_attribute = $self->meta->get_attribute($key);
        $meta_attribute->set_raw_value($self,$value);
    }
    
    return %pod;
}

sub _pod_node_to_text {
    my ($self,$node,$indent) = @_;
    
    unless (defined $indent) {
        my $indent_init = 0;
        $indent = \$indent_init;
    }
    
    my (@lines);
    if (ref $node eq 'ARRAY') {
        foreach my $element (@$node) {
            push (@lines, $self->_pod_node_to_text($element,$indent));
        }
        
    } else {
        given (ref($node)) {
            when ('Pod::Elemental::Element::Pod5::Ordinary') {
                 push (@lines,$node->content);
            }
            when ('Pod::Elemental::Element::Pod5::Verbatim') {
                push (@lines,$node->content);
            }
            when ('Pod::Elemental::Element::Pod5::Command') {
                given ($node->command) {
                    when ('over') {
                        ${$indent}++;
                    }
                    when ('item') {
                        push (@lines,('  ' x ($$indent-1)) . $node->content);
                    }
                    when ('back') {
                        ${$indent}--;
                    }
                }
            }
        }
    }
    
    return
        unless scalar @lines;
    
    my $return = join ("\n", grep { defined $_ } @lines);
    $return =~ s/I<([^>]+)>/_$1_/g;
    $return =~ s/B<([^>]+)>/*$1*/g;
    $return =~ s/[LCBI]<([^>]+)>/$1/g;
    $return =~ s/[LCBI]<([^>]+)>/$1/g;
    return $return;
}

#{
#    package Moose::Meta::Class::Custom::Trait::AppCommand;
#    sub register_implementation { 'MooseX::App::Meta::Role::Class::Command' }
#}

1;

__END__

=pod

=encoding utf8

=head1 NAME

MooseX::App::Meta::Role::Class::Command - Meta class role for command classes

=head1 DESCRIPTION

This meta class role will automatically be applied to all command classes.

=head1 ACCESSORS

=head2 command_short_description

Read/set the short command description. Will be extracted from the Pod NAME
section if not set.

=head2 command_long_description

Read/set the long command description. Will be extracted from the Pod 
DESCRIPTION or OVERVIEW section if not set.

=head1 METHODS

=head2 _build_command_pod

Parses the Pod from the command class.

=head2 _pod_node_to_text

 my $pod_text = $meta->_pod_node_to_text($pod_elemental,$indent);

Converts a Pod::Elemental::Element object to plain text.

=cut