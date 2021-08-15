# ============================================================================
package MooseX::App::Message::Builder;
# ============================================================================

use 5.010;
use utf8;
use strict;
use warnings;

my @TAGS = qw(Block Tag List Headline Item Paragraph);

use Moose::Exporter;
Moose::Exporter->build_import_methods(
    as_is               => [ map { uc } @TAGS ],
);

use MooseX::App::Message::Node;

sub BLOCK(@) {
    my (@elements) = @_;
    return MooseX::App::Message::Block->new(elements => \@elements);
}

sub TAG($@) {
    my ($type,@elements) = @_;
    return MooseX::App::Message::Tag->new(
        type     => $type,
        elements => \@elements
    );
}

sub LIST(@) {
    my (@elements) = @_;
    Moose->throw_error('LIST elements can only be MooseX::App::Message::Item')
        if (grep { ! blessed($_) || $_->isa('MooseX::App::Message::Item') } @elements;
    return MooseX::App::Message::List->new(elements => \@elements);
}

sub ITEM($;$) {
    my ($key,$value) = @_;
    return MooseX::App::Message::Item->new(key => $key, ($value ? (value => $value):()));
}

sub HEADLINE($$) {
    my ($type,$text) = @_;
    return MooseX::App::Message::Headline->new(type => $type, text => $text);
}

sub PARAGRAPH(@) {
    my (@elements) = @_;
    return MooseX::App::Message::Paragraph->new(elements => \@elements);
}

1;