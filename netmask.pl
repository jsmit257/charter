#
# usage: perl netmask.pl < sample-data
#
# take dotted quad netmasks from standard input, one per line and return the CIDR bitmask, 
# including -1 for invalid masks; quads with less than 4 elements are padded to the right with 
# zero's; script warns when the quad has more than 4 elements, or if any single element can't be
# treated as an unsigned 8-bit int (currently treats alpha chars as 0, see WARN below); quads can be
# padded with space, although we might want to change that; the whole operation would probably be 3
# lines in haskell
#
use strict;

sub initValues;

# input gets converted from netmask string to 32-bit integer; the keys in this hash are the 
# ints with consecutive "1"s in the most significant bits
my %bitmasks;

&initValues();

while (my $dotted = <>) { 

	chomp $dotted; # only needed to make the output ($dotted => $mask) print on one line

	my $intMask = 0;  # hoping this is a key into %bitmasks
	my @quads = split /\./, $dotted;

	# the for loop treats $dotted as the most significant bits in a 32-bit integer and pads missing
	# bits with 0 to the right, so we don't test $#quads == 3; more than 4 elements is definitely 
	# an error
	$#quads < 4 or warn "netmask '$dotted' is invalid"; # warn? die? ...

	foreach my $index (0..3) {
		# WARN: perl likes to treat non-numeric values as 0, whether its int(), sprintf(), 
		# 1*$alphaChar, etc; is it better to die() if non-numeric, or maybe try to get a hex value?
		# but then you'd have to decide if you could mix decimal values with hex in the same 
		# $dotted. i suppose it's a question for the business
		my $quad =$quads[$index];
		$quad > -1 and $quad < 256 or warn "invalid quad value $quad at index $index";
		$intMask += $quad << ((3 - $index) * 8);
	}

	# only bitstrings with consecutive "1"s in the MSBs, otherwise it would be:
	# ($bitstring =~ /01/ and -1)
	print "$dotted => " . ($bitmasks{$intMask} or -1) . "\n";

}

#
# initialize the bitmask hash; generating bitstrings for the set of all ints would be inefficient 
# for storage, but we only care about 32 keys; this is *not* the general purpose netmask_to_bits 
# recommended for C language implementations, but its simple, light and fast
#
sub initValues() {

	my $msb = 1 << 31;
	my $nextKey = $msb;

	foreach (1..32) {
		$bitmasks{$nextKey} = $_;
		$nextKey = $msb + ($nextKey >> 1);
	}

}

