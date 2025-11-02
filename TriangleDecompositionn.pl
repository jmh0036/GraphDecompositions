use strict;
use warnings;

use Algorithm::DLX;
use Math::Combinatorics;

# K_3 decomp exists if n equiv 1 or 3 mod 6
# K_4 decomp may exist if n equiv 1 or 4 mod 12
my $order = 13;
my $decomp_order = 4;
my @required_blocks = (
    # [2, 3, 7],
    # [1, 5, 7],
    # [1, 3, 4],
    [1, 2, 3, 4],
);

# Main execution
my $dlx = Algorithm::DLX->new;
my @edges_covered = get_edges_from_blocks(\@required_blocks);
my %edge_columns = add_remaining_edges_to_dlx({
    dlx           => $dlx,
    order         => $order,
    edges_covered => \@edges_covered,
});
add_possible_blocks_to_dlx({
    dlx             => $dlx,
    order           => $order,
    decomp_order    => $decomp_order,
    required_blocks => \@required_blocks,
    edge_columns    => \%edge_columns,
    edges_covered   => \@edges_covered,
});

my $solutions = solve_and_print({
    dlx             => $dlx,
    required_blocks => \@required_blocks,
});

# Subroutines

=head2 get_edges_from_blocks

    my @edges = get_edges_from_blocks(\@blocks);

Extracts all edges from the given blocks.

=over 4

=item Arguments

=over 4

=item * C<$blocks> - Array reference of blocks (array references of vertices)

=back

=item Returns

List of edges in the format "vertex1 vertex2" (both directions included)

=back

=cut

sub get_edges_from_blocks {
    my ($blocks) = @_;
    my @edges;
    
    for my $block (@$blocks) {
        for my $i (0 .. $#$block - 1) {
            for my $j ($i+1 .. $#$block) {
                push @edges, "$block->[$i] $block->[$j]";
                push @edges, "$block->[$j] $block->[$i]";
            }
        }
    }
    
    return @edges;
}

=head2 add_remaining_edges_to_dlx

    my %edge_columns = add_remaining_edges_to_dlx({
        dlx           => $dlx,
        order         => $order,
        edges_covered => \@edges_covered,
    });

Creates columns in the DLX matrix for all edges not already covered by required blocks.

=over 4

=item Arguments

Hash reference with keys:

=over 4

=item * C<dlx> - Algorithm::DLX object

=item * C<order> - Size of the complete graph

=item * C<edges_covered> - Array reference of edges already covered

=back

=item Returns

Hash mapping edge strings to DLX column objects

=back

=cut

sub add_remaining_edges_to_dlx {
    my ($args) = @_;
    my $dlx = $args->{dlx};
    my $order = $args->{order};
    my $edges_covered = $args->{edges_covered};
    
    my %edges;
    
    my $complete_edgeset = Math::Combinatorics->new(
        count => 2,
        data  => [ 1 .. $order ],
    );
    
    while (my @edge = $complete_edgeset->next_combination) {
        my $edge_is_covered = grep { $_ eq "$edge[0] $edge[1]" } @$edges_covered;
        $edges{"$edge[0] $edge[1]"} = $dlx->add_column("@edge") unless $edge_is_covered;
    }
    
    return %edges;
}

=head2 add_possible_blocks_to_dlx

    add_possible_blocks_to_dlx({
        dlx             => $dlx,
        order           => $order,
        decomp_order    => $decomp_order,
        required_blocks => \@required_blocks,
        edge_columns    => \%edge_columns,
        edges_covered   => \@edges_covered,
    });

Generates all possible blocks and adds them as rows to the DLX matrix.

=over 4

=item Arguments

Hash reference with keys:

=over 4

=item * C<dlx> - Algorithm::DLX object

=item * C<order> - Size of the complete graph

=item * C<decomp_order> - Size of each subgraph

=item * C<required_blocks> - Array reference of required blocks

=item * C<edge_columns> - Hash reference mapping edges to DLX columns

=item * C<edges_covered> - Array reference of edges already covered

=back

=back

=cut

sub add_possible_blocks_to_dlx {
    my ($args) = @_;
    my $dlx = $args->{dlx};
    my $order = $args->{order};
    my $decomp_order = $args->{decomp_order};
    my $required_blocks = $args->{required_blocks};
    my $edge_columns = $args->{edge_columns};
    my $edges_covered = $args->{edges_covered};
    
    my $edges_per_block = $decomp_order * ($decomp_order - 1) / 2;
    
    my $blocks = Math::Combinatorics->new(
        count => $decomp_order,
        data  => [ 1 .. $order ],
    );
    
    while (my @block = $blocks->next_combination) {
        next if is_required_block(\@block, $required_blocks);
        
        my @edges = get_available_edges_for_block({
            block         => \@block,
            edge_columns  => $edge_columns,
            edges_covered => $edges_covered,
        });
        
        if (scalar @edges == $edges_per_block) {
            my @covered_edges = map { $edge_columns->{$_} } @edges;
            $dlx->add_row("@block", @covered_edges);
        }
    }
}

=head2 is_required_block

    my $is_required = is_required_block(\@block, \@required_blocks);

Checks if a block is in the list of required blocks.

=over 4

=item Arguments

=over 4

=item * C<$block> - Array reference representing a block

=item * C<$required_blocks> - Array reference of required blocks

=back

=item Returns

Boolean: true if the block is required, false otherwise

=back

=cut

sub is_required_block {
    my ($block, $required_blocks) = @_;
    my $block_str = join(' ', @$block);
    
    return grep { join(' ', @$_) eq $block_str } @$required_blocks;
}

=head2 get_available_edges_for_block

    my @edges = get_available_edges_for_block({
        block         => \@block,
        edge_columns  => \%edge_columns,
        edges_covered => \@edges_covered,
    });

Gets all edges within a block that are not already covered by required blocks.

=over 4

=item Arguments

Hash reference with keys:

=over 4

=item * C<block> - Array reference representing a block

=item * C<edge_columns> - Hash reference mapping edges to DLX columns

=item * C<edges_covered> - Array reference of edges already covered

=back

=item Returns

List of available edge strings for this block

=back

=cut

sub get_available_edges_for_block {
    my ($args) = @_;
    my $block = $args->{block};
    my $edge_columns = $args->{edge_columns};
    my $edges_covered = $args->{edges_covered};
    
    my @edges;
    my $decomp_order = scalar @$block;
    
    for my $i (0 .. $decomp_order - 1) {
        for my $j ($i+1 .. $decomp_order - 1) {
            my $edge_key;
            
            if (defined $edge_columns->{"$block->[$i] $block->[$j]"}) {
                $edge_key = "$block->[$i] $block->[$j]";
            } elsif (defined $edge_columns->{"$block->[$j] $block->[$i]"}) {
                $edge_key = "$block->[$j] $block->[$i]";
            } else {
                # Edge is already covered by required blocks
                next;
            }
            
            my $edge_is_covered = grep { $_ eq $edge_key } @$edges_covered;
            push @edges, $edge_key unless $edge_is_covered;
        }
    }
    
    return @edges;
}

=head2 solve_and_print

    my $solutions = solve_and_print({
        dlx             => $dlx,
        required_blocks => \@required_blocks,
    });

Solves the exact cover problem using DLX and prints the solutions.

=over 4

=item Arguments

Hash reference with keys:

=over 4

=item * C<dlx> - Algorithm::DLX object with the problem encoded

=item * C<required_blocks> - Array reference of required blocks to include

=back

=item Returns

Array reference of solutions found

=back

=cut

sub solve_and_print {
    my ($args) = @_;
    my $dlx = $args->{dlx};
    my $required_blocks = $args->{required_blocks};
    
    my $solutions = $dlx->solve(number_of_solutions => 1);
    
    unless (@$solutions) {
        print "No solutions found\n";
        return $solutions;
    }
    
    my $solution_count = 0;
    for my $solution (@$solutions) {
        $solution_count++;
        print "\n" unless $solution_count == 1;
        print "Solution $solution_count:\n";
        
        print_solution($solution, $required_blocks);
    }
    
    return $solutions;
}

=head2 print_solution

    print_solution($solution, \@required_blocks);

Prints a single solution in a readable format.

=over 4

=item Arguments

=over 4

=item * C<$solution> - Array reference of row names from DLX solution

=item * C<$required_blocks> - Array reference of required blocks

=back

=back

=cut

sub print_solution {
    my ($solution, $required_blocks) = @_;
    my @all_blocks = @$required_blocks;
    
    for my $block_str (@$solution) {
        my @block = split ' ', $block_str;
        push @all_blocks, \@block;
    }
    
    for my $block (@all_blocks) {
        print join(" ", @$block), "\n";
    }
}

1;

__END__