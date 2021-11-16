#!/usr/bin/perl -w
use strict;
use warnings;
my $VERSION="0.1";
use Data::Dumper;

#use Statistics::Basic qw(:all);
#use Math::Round qw(:all); #nearest or round
#use Math::Random;

my $imputed1 = shift;

open IN, "$imputed1";
my $head = <IN>;
print ($head);

my $first = <IN>;
chomp $first;
my @s = split /\t/, $first;
my @h = splice @s, 0, 11;
my @rest = splice @h, 4, 7; #same for all so doesn't matter that is never changed below
my $prevID = $h[0];
my $prevChr = $h[2];
my $start = $h[3];
my $startID = $prevID;
my $prevPos = $start;
my @prevS = @s;

while (my $l = <IN>) {
	chomp $l;
	my @s = split /\t/, $l;
	my @h = splice @s, 0, 11;
	my $id = $h[0];
	my $chr = $h[2];
	my $pos = $h[3];
	
	my $print = 0;
	my $i = 0;
	foreach (@s) {
		$print = 1 if $s[$i] ne $prevS[$i];
		$i++;
	}
	
	if ($print || $chr ne $prevChr) {
		print("$startID\|$prevID\tA/C\t$prevChr\t".int($prevPos + (($prevPos - $start) / 2))."\t".join("\t",@rest)."\t".join("\t",@prevS)."\n");
		$start = $pos;
		$startID = $id;
	}
	@prevS = @s;
	$prevPos = $pos;
	$prevChr = $chr;
	$prevID = $id;
}
print("$prevID\_end\tA/C\t$prevChr\t".$prevPos."\t".join("\t",@rest)."\t".join("\t",@prevS)."\n");


	
	
	
	
	