#!/usr/bin/perl -w
use strict;
use warnings;
my $VERSION="0.1";
use Data::Dumper;

##purpose: randomly redistribute reads that have an equivalent match elsewhere in the genome.  This equivalence is base on equal match score and MQ to the best placement.
##example: perl gafRedistribute.pl file.gaf >redist_file.gaf

my $file = shift;  #input gaf, see warning below

#warn("This script assumes you are using vg giraffe using -M >1 and a gaf file converted from vg using 'vg convert -G file.gam graph.xg >file.gaf'.  It also assumes reads are listed as pairs (after solo removal), forward then reverse, and the best (or one of best) match is listed first.")

#cleans out unpaired reads
my $priorBase = "";
my $priorDir = "";
my $priorLine = "";
open IN, "$file";
open OUT, ">temp_noSoloReads.gfa";
while (my $l = <IN>) {
	chomp $l;
	my @s = split /\t/, $l; 
	my $r1 = $s[0];
	my $dir; my $base;
	if ($r1 =~ /(.+)\/([12])/) {
		$base = $1;
		$dir = $2;
		#warn($dir);
	} else {
		warn("$r1 removed");
		next;
	}
	if ($base eq $priorBase && $dir == 2 && $priorDir == 1) {
		print OUT "$priorLine\n$l\n";
	} elsif ($dir == 1 && $priorDir == 1) {
		warn("solo read: $priorLine");
	} elsif ($dir == 2 && $base ne $priorBase) {
		warn("solo read: $l");
	}
	$priorLine = $l;
	$priorBase = $base;
	$priorDir = $dir;
}
close IN;
close OUT;

my %bestScore;
my %bestMQ;
my %lines;
open IN, "temp_noSoloReads.gfa";
while (my $l = <IN>) {
	chomp $l;
	my @s = split /\t/, $l;
	my $r1 = $s[0];
	my $score = $s[9];
	my $mq = $s[11];
	my $line = $l;
	$l = <IN>;
	chomp $l;
	@s = split /\t/, $l;
	my $r2 = $s[0];
	$score += $s[9];
	$mq += $s[11];
	$bestScore{"$r1\_$r2"} = $score unless $bestScore{"$r1\_$r2"};
	$bestMQ{"$r1\_$r2"} = $mq unless $bestMQ{"$r1\_$r2"};
	#warn("$r1\_$r2");
	push @{$lines{"$r1\_$r2"}}, "$line\n$l" if $score == $bestScore{"$r1\_$r2"} && $mq == $bestMQ{"$r1\_$r2"};
}
close IN;

foreach (keys %lines) {
	my @temp = @{$lines{"$_"}};
	#warn(Dumper(@temp));
	my $x = $temp[rand @temp];
	print "$x\n";
}

my $run = `rm temp_noSoloReads.gfa`;
