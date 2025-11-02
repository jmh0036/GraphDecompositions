# Complete Graph Decomposition Tool

A Perl program that decomposes complete graphs (K_n) into edge-disjoint copies of smaller complete graphs (K_m) using the Dancing Links algorithm (DLX).

## What This Does

This tool finds decompositions of complete graphs. For example:
- Decompose K₉ into triangles (K₃)
- Decompose K₁₃ into K₄ subgraphs
- Decompose K₂₁ into K₅ subgraphs

You can also specify required blocks that must appear in the decomposition.

## Mathematical Background

A complete graph K_n has n vertices with edges connecting every pair of vertices. Not all decompositions exist - there are number-theoretic constraints:

- **K_n → K₃**: exists when n ≡ 1 or 3 (mod 6)
- **K_n → K₄**: exists when n ≡ 1 or 4 (mod 12)
- **K_n → K₅**: exists when n ≡ 1 or 5 (mod 20)

## Installation

### Step 1: Install Perlbrew

Perlbrew lets you install and manage multiple Perl versions without affecting your system Perl.

**On Linux/macOS:**
```bash
# Install perlbrew
curl -L https://install.perlbrew.pl | bash

# Add perlbrew to your shell (add this to ~/.bashrc or ~/.zshrc)
echo 'source ~/perl5/perlbrew/etc/bashrc' >> ~/.bashrc
source ~/.bashrc
```

**On Windows:**
Use WSL (Windows Subsystem for Linux) and follow the Linux instructions above, or use Strawberry Perl directly from https://strawberryperl.com/

### Step 2: Install Perl 5.40

```bash
# Install Perl 5.40 (this may take 10-20 minutes)
perlbrew install perl-5.40.0

# Switch to the new Perl version
perlbrew switch perl-5.40.0

# Verify installation
perl -v
```

### Step 3: Install cpanminus

cpanminus is a simple tool for installing Perl modules:

```bash
perlbrew install-cpanm
```

### Step 4: Install Required Modules

```bash
# Install the required Perl modules
cpanm Algorithm::DLX
cpanm Math::Combinatorics
```

## Usage

### Basic Configuration

Edit the configuration section at the top of the script:

```perl
# Configuration
my $order = 13;              # Size of the complete graph (K_n)
my $decomp_order = 4;        # Size of subgraphs (K_m)
my @required_blocks = (      # Optional: blocks that must appear
    [1, 2, 3, 4],
);
```

### Running the Program

```bash
perl TriangleDecompositionn.pl
```

### Example 1: Decompose K₉ into Triangles

```perl
my $order = 9;
my $decomp_order = 3;
my @required_blocks = (
    [2, 3, 7],
    [1, 5, 7],
    [1, 3, 4],
);
```

Output:
```
Solution 1:
2 3 7
1 5 7
1 3 4
3 5 6
3 8 9
1 2 8
1 6 9
2 4 6
2 5 9
4 5 8
4 7 9
6 7 8
```

### Example 2: Decompose K₁₃ into K₄

```perl
my $order = 13;
my $decomp_order = 4;
my @required_blocks = (
    [1, 2, 3, 4],
);
```

### Example 3: No Required Blocks

If you don't want to specify required blocks, just use an empty array:

```perl
my @required_blocks = ();
```

## Understanding the Output

Each line in the output represents one complete subgraph. The numbers are the vertices in that subgraph.

For a K₄ decomposition, each line has 4 vertices, and those 4 vertices form a complete graph (all 6 possible edges between them).

## Performance Considerations

The computational complexity grows rapidly:
- **K₁₃ → K₄**: ~715 possible blocks (fast)
- **K₂₁ → K₅**: ~20,000 possible blocks (moderate)
- **K₄₁ → K₅**: ~750,000 possible blocks (slow)

For large graphs, the solver may take considerable time or memory.

## Troubleshooting

### "No solutions found"
This likely means:
1. No decomposition exists for your chosen n and m
2. Your required blocks make a solution impossible
3. The values don't satisfy the mathematical constraints

### Module installation fails
```bash
# Try forcing installation
cpanm --force Algorithm::DLX

# Or install with verbose output to see errors
cpanm -v Algorithm::DLX
```

### "perl: command not found" after installation
Make sure you sourced the perlbrew configuration:
```bash
source ~/perl5/perlbrew/etc/bashrc
```

## Code Structure

The program is organized into these main subroutines:
- `get_edges_from_blocks()` - Extracts edges from required blocks
- `add_remaining_edges_to_dlx()` - Creates the DLX matrix columns
- `add_possible_blocks_to_dlx()` - Adds all possible subgraphs as rows
- `solve_and_print()` - Solves and displays the result

## References

- **Algorithm DLX**: Donald Knuth's Dancing Links algorithm for exact cover problems
- **Graph Decomposition Theory**: See design theory and combinatorics literature

## License

This tool is provided as-is for mathematical and educational purposes.