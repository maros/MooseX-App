# ============================================================================
package MooseX::App::Message::Builder;
# ============================================================================

use 5.010;
use utf8;
use strict;
use warnings;

use Moose::Exporter;
Moose::Exporter->build_import_methods(
    as_is               => [ qw(BLOCK TAG LIST ITEM HEADLINE KEY DESCRIPTION PARAGRAPH RAW) ],
);

use MooseX::App::Message::Node;

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

sub BLOCK {}
sub TAG {}
sub LIST {}
sub ITEM {}
sub HEADLINE {}
sub KEY {}
sub DESCRIPTION {}
sub PARAGRAPH {}
sub RAW {}

1;