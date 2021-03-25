#!/usr/bin/perl -w
use strict;
use Chart::Colors;
&usageinfo();

# cpan install Chart::Colors
# function: this tool will parse a graph .gfa file into Bandage for viewing the path name, path in color

# usage example: perl gfa_parser.pl -g gfa_graph_file  [-s short_path_name_T|F] -o [gfa_graph_file.csv ofr bandage]
#programmed by Xuewen Wang, version, 2021 Jan 5; 
# Current version:  20210105;
my %commandin = @ARGV;
if ((scalar @ARGV)%2 != 0){print "arguments must in pair";}
my $refin=$commandin{"-g"}; 
my $outputfile=$commandin{"-o"}||"$refin.csv";
my $shortpathname=$commandin{"-s"}||"F";
my $satfile=$outputfile.".sat1";
 unless(-e $refin){print "File $refin does not exist in the working directoty\n";}
 open(FILE, $refin) || die("Couldn't read file $refin\n");
 open(OUT, ">$outputfile")|| die (" Write output file $outputfile failed, please check\n"); 
 open(OUTsat, ">$satfile")|| die (" Summary file $satfile writing failed, pleasse check\n");

 my %path=();
 my %name=();
 my $ct=0;
while (my $seqinfo = <FILE>) {
	#if starting with "P", get the nodes: P	pathname	node,node	others
    if($seqinfo =~ m/^(P.+)\n/){;       
       my @seqIDcontn=split(/\t/,$seqinfo); 
       my $seqID=$seqIDcontn[1];
       my $nodes=$seqIDcontn[2];
       
       if(! exists $name{$seqID}){
          $ct++;
          $name{$seqID}="P".$ct;
       }
       
       my @node=split(/,/,$nodes);
       print OUTsat "Path name: $seqID\t";
       print OUTsat "Nodes #:",scalar @node,"\n";
       
       foreach my $n(@node){
          if(! exists $path{$n}){
            if($shortpathname eq "F"){
                $path{$n}=$seqID;
            }elsif($shortpathname eq "T"){
               $path{$n}=$name{$seqID};
            }
          }else{
            if($shortpathname eq "F"){
               $path{$n}=$path{$n}.'|'.$seqID;
            }elsif($shortpathname eq "T"){
               $path{$n}=$path{$n}.'|'.$name{$seqID};            
            }
		  }
       }
    }
} #end while

#colorize path
my $colors = new Chart::Colors();
my %pathcolor=();
print OUTsat "\nFull name:\t Short name\n";
foreach my $p(keys %name ){   
   my $nextcolor_hex=$colors->Next('hex');   
   #path
   if($shortpathname eq "F"){
         $pathcolor{$p}="#".$nextcolor_hex;
   }elsif($shortpathname eq "T"){
         $pathcolor{$name{$p}}="#".$nextcolor_hex; 
         print OUTsat $p,":\t",$name{$p},"\n";
         #print $name{$p}, "--->", $nextcolor_hex, "\n";
   }
}


#output
print OUT "node,path,color\n";
foreach my $nodelabel(sort keys %path){
     print OUT $nodelabel, ',',$path{$nodelabel},',';
     #1408,P1|P2
     if(exists $pathcolor{$path{$nodelabel}}){
         print OUT  $pathcolor{$path{$nodelabel}},"\n";
     }else{
         print OUT "grey\n";
     }
}


&runtime(\*OUTsat); #for run log information
close FILE;
close OUT;
close OUTsat;
print  "Done successfully\n";

sub usageinfo
 {
 my @usage=(); 
 $usage[0]="Function: Parse the graph file in .gfa. The output could be loaded into Bandage for viewing graph in automatized colorized path and path names\n";
 $usage[1]=" for    help: perl $0 ; \n";
 $usage[2]=" for running: perl $0 -g gfa_graph_file  [-s short_path_name_T|F] -o [gfa_graph_file.csv for Bandage]\n
 options:
 -g Name of the input file, in .gfa format;
 -s T will display the path name in a short name in P1, P2, ...; 
    F will display the full name in the original graph; default F
 -o Name of output file in .csv format; default in input_file.csv\n
 A file (.sats) summary of paths and nodes are generated.
 The output is in the same directory as the input file. Alternatively output file can be specified in the -o parameter.\n
 e.g. perl $0 -g  tifchr02_sim_gap.xmfa.gfa\n";
 $usage[3]="Author: Xuewen Wang\n";
 $usage[4]="Year 2020\n";
 unless(@ARGV){print @usage; exit;} 
 }
sub runtime() {
my $OUTfile=shift @_;
my $local_time = gmtime();
print {$OUTfile} "$0 was run and results were yielded at $local_time\n";
}
exit;

