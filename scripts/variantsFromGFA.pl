#!/usr/bin/perl -w

#
use strict;
use warnings;
use Data::Dumper;
#program version
my $VERSION="0.1";

my $gfa_file = shift;
my $chromInID = shift;

# parse gfa paths for checks and chromosome organization
my %chrs;
my %idCheck;
open IN, "$gfa_file";
while (my $l = <IN>) {
	chomp $l;
	my @s = split /\t/, $l;
	my $type = $s[0];
	if ($type eq 'P') {
		my $id = $s[1];
		my @s2 = split /\./, $id;
		my ($chr_id, $id_id);
		if ($chromInID) {
			$chr_id = pop @s2;
			$id_id = join('.',@s2);	
		} else {
			$chr_id = 'chr0';
			$id_id = join('.',@s2);
		}
		$chrs{$chr_id}{$id_id} = 1;
		$idCheck{$id_id}=1;
	}
}
close IN;

foreach my $id (keys %idCheck) {
	foreach my $chr (keys %chrs) {
		die "Chromosome $chr does not have an $id entry" unless $chrs{$chr}{$id};
	}
}

print "##fileformat=VCFvPanPipes\n";
print "##see https://github.com/USDA-ARS-GBRU/PanPipes\n";
print "##base graph: $gfa_file\n";
print "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t";
my @ids = keys %idCheck;
print(join("\t",@ids)."\n");
foreach my $chr (keys %chrs) {
	my %total;
	my %link;
	my %allele;
	my %seq;
	open IN, "$gfa_file";
	while (my $l = <IN>) {
		chomp $l;
		my @s = split /\t/, $l;
		my $type = $s[0];
		if ($type eq 'P') {
			my @s_id = split /\./, $s[1];
			my ($chr_id, $id);
			if ($chromInID) {
				$chr_id = pop @s_id;
				$id = join('.',@s_id);	
			} else {
				$chr_id = 'chr0';
				$id = join('.',@s_id);
			}
			next unless $chr_id eq $chr;
			my @s2 = split /,/,$s[2];
			my $i = 0;
			while ($i < (scalar(@s2) - 1)) {
				my $a = $s2[$i];
				my $b = $s2[$i+1];
				my $aSeg;
				my $aSign;
				my $bSeg;
				my $bSign;
				if ($a =~ /(\d+)([\+\-])/) {
					$aSeg = $1;
					$aSign = $2;
				}
				if ($b =~ /(\d+)([\+\-])/) {
					$bSeg = $1;
					$bSign = $2;
				}
				if ($aSign eq '-' && $bSign eq '-') { # double inversions counted in forward direction
					my $temp = $aSeg;
					$aSeg = $bSeg;
					$bSeg = $temp;
				} elsif ($aSign eq '-' && $bSign eq '+') { # sign must be added to differentiate from forward link
					$aSeg = $aSeg.$aSign;
					warn($aSeg);

				}
				unless (defined($link{$aSeg}{$bSeg})) { #works with 0 from line below
					$total{$aSeg}++ ;
					$link{$aSeg}{$bSeg} = $total{$aSeg} - 1; #gives allele code
				}
				$allele{$aSeg}{$id} = $bSeg;
				$i++;
			}

		} elsif ($type eq 'S') {
			$seq{$s[1]} = $s[2];
		}
	}
	close IN;
	#warn(Dumper(%link));
	# my %bin;
	# foreach (keys %total) {
	# 	$bin{$total{$_}}++;
	# }
	#
	# my @sort = sort {$a <=> $b} keys %bin;
	# foreach (@sort) {
	# 	print "$_\t$bin{$_}\n";
	# }
	foreach my $anchor (keys %total) {
		next unless $total{$anchor} > 1; #polymorphic
		my $ref;
		my @alt;
		foreach (keys %{$link{$anchor}}) {
			if ($link{$anchor}{$_} == 0) {
				$ref = $_;
			} else {
				push @alt, $_;
			}
		}
		#
		my $refSeq;
		my @altSeq;
		if (scalar(@alt) == 1 && scalar(keys %{$link{$ref}}) == 1 && scalar(keys %{$link{$alt[0]}}) == 1) {
			my @refL = keys %{$link{$ref}};
			my @altL = keys %{$link{$alt[0]}};
			my $refL = $refL[0];
			my $altL = $altL[0];
			if ($refL eq $alt[0]) {
				#insertion as ref
				$refSeq = $seq{$ref};
				@altSeq = ('-');
			} elsif ($altL eq $ref) {
				#deletion as ref
				$refSeq = '-';
				@altSeq = ($seq{$alt[0]});
			} elsif ($refL eq $altL) {
				#simple sub
				$refSeq = $seq{$ref};
				@altSeq = ($seq{$alt[0]});
			} else {
				$refSeq = "complex\.$ref";
				@altSeq = @alt;
			}
		} else {
				$refSeq = "multiPath\.$ref";
				@altSeq = @alt;
		}
		my @toPrint = ($chr, $anchor, "$ref\-$alt[0]", $refSeq, join(",",@altSeq), '.', '.','.','GT');
		foreach (@ids) {
			my $call = '.';
			$call = $link{$anchor}{$allele{$anchor}{$_}} if defined($allele{$anchor}{$_});
			push @toPrint, $call;
		}
		print(join("\t",@toPrint)."\n");
	}
}



=head1 NAME

variantsFromGFA.pl

=head1 SYNOPSIS

Converts all variation represented in a GFA-formatted graph into a VCF-like file

=head1 DESCRIPTION

The script is based on finding branch positions in the graph.  variantFromGFA.pl understands when a reverse orientation is the same variant as a forward variant and so produces biologically appropriate variants within long inversions that are ortholgous despite their structural difference.  This behavior constrasts to available tools that we know of.  

Example:
perl variantsFromGFA.pl myGraph.gfa 1 >variants.vcf

The script accepts two positional arguments: 

1) A GFA file, which must contain full contaentated paths for all chromosomes in the genome graph (see https://github.com/brianabernathy/xmfa_tools)
2) a binary flag indicating if chromosome names are added to the end of each genome in the graph.  If chromosome names are added, then they must be of the form 'genome1.chr1', where the chromosome name is the last string after splitting the total path name based on the period character.

Output is a VCF-like file, but instead of the positions field being in coordinates they are in segment name order.  If you have used xmfa_tools with sort (https://github.com/brianabernathy/xmfa_tools), this node order will reflect the primary sort reference that you specified (then secondary, etc.).  In other words, they are colinnear with the genome sequence of that reference.  Though these node numbers to not represent useful physical distances, they can easily be looked-up and converted using the 'vg find' command (https://github.com/vgteam/vg).  In the output, we refer to the POS field node as the 'focal node'.  'Allelic nodes', which serve as the REF and ALT fields, are the two possible branches extending from the focal node.  If these two branches return to the same node over the same unit distance, we use segment information to determine the explicit base change otherwise variants are encoded as 'complex' or 'multipath' with the relevant segment number suffix.  IMPORTANTLY, simple indels are encoded differently than conventional vcf format: instead of giving the reference base and the insertion (or vice versus for deletion), variantsFromGFA.pl uses the '-' character and the indel sequence.  We find this much more intuitive and in keeping with the variation graph concept, but this difference may break tools expecting a normal vcf.  In future incarnations, we hope to include a flag for allowing either output format.  In addition, Inversion variants can result in a negative sign suffix in the head node (POS) field. Conventionally, this field represents the position in the reference genome and negative values may cause issues with tools that use vcfs.  Note, the reciprocal variant of the inversion should be called regardless, so the variant information is still retained for most practical purposes.
The following grep command can be used to remove and rows that represent likely confilcts with conventional vcf format:

For import into TASSEL:
'egrep -v '\t[ACGT]{2,}\t[ACGT]{2,}\t' rawFromGFA.vcf | egrep -v '\t-\d+\t' >forTassel.vcf'


  
=head1 SEE ALSO

	
=head1 AUTHOR


justin vaughn (jnvaughn@uga.edu)

=cut
