# ============================================================================
package MooseX::App::Message::Node;
# ============================================================================


use 5.010;
use utf8;

use namespace::autoclean;
use Moose;

__PACKAGE__->meta->make_immutable;



    # _root       => {
    #     type        => 'block',
    #     children    => [qw(headline list paragraph raw)],
    # },
    # headline    => {
    #     type        => 'block',
    #     parents     => [qw(_root tag)],
    #     attr        => [qw(EMPTY error)],
    # },
    # list        => {
    #     type        => 'block',
    #     parents     => [qw(_root tag paragraph)],
    #     children    => [qw(item)],
    #     attr        => [qw(EMPTY error)],
    # },
    # item        => {
    #     type        => 'list',
    #     children    => [qw(key description)],
    #     parents     => [qw(list)],
    # },
    # key         => {
    #     type        => 'list',
    #     parents     => [qw(item)],
    # },
    # description => {
    #     type        => 'list',
    #     parents     => [qw(item)],
    # },
    # paragraph   => {
    #     type        => 'block',
    #     parents     => [qw(_root tag)],
    #     attr        => [qw(EMPTY error)],
    # },
    # tag         => {
    #     type        => 'semantic',
    #     attr        => ['ANY'],
    #     parents     => [qw(key description headline paragraph tag)]
    # },
    # raw         => {
    #     type        => 'block',
    # },
    
####
package MooseX::App::Message::Node::Block;

use namespace::autoclean;
use Moose;
extends qw(MooseX::App::Message::Node);
with qw(MooseX::App::Renderer::NodeChildren);

__PACKAGE__->meta->make_immutable;


package MooseX::App::Message::Node::Tag;

use namespace::autoclean;
use Moose;
extends qw(MooseX::App::Message::Node);
with qw(MooseX::App::Renderer::NodeChildren);

has 'type' => ( is => 'ro', required => 1 );

__PACKAGE__->meta->make_immutable;


#BLOCK TAG LIST ITEM HEADLINE KEY DESCRIPTION PARAGRAPH RAW

1;
