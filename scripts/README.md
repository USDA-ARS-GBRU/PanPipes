## variantsFromGFA.pl

#### Converts all variation represented in a GFA-formatted graph into a VCF-like file

The script is based on finding branch positions in the graph.  variantFromGFA.pl understands when a reverse orientation is the same variant as a forward variant and so produces biologically appropriate variants within long inversions that are ortholgous despite their structural difference.  This behavior constrasts to available tools that we know of.  

Example:
perl variantsFromGFA.pl myGraph.gfa 1 >variants.vcf

The script accepts two positional arguments: 

1) A GFA file, which must contain full contaentated paths for all chromosomes in the genome graph (see https://github.com/brianabernathy/xmfa_tools)
2) a binary flag indicating if chromosome names are added to the end of each genome in the graph.  If chromosome names are added, then they must be of the form 'genome1.chr1', where the chromosome name is the last string after splitting the total path name based on the period character.

Output is a VCF-like file, but instead of the positions field being in coordinates they are in segment name order.  If you have used xmfa_tools with sort (https://github.com/brianabernathy/xmfa_tools), this node order will reflect the primary sort reference that you specified (then secondary, etc.).  In other words, they are colinnear with the genome sequence of that reference.  Though these node numbers to not represent useful physical distances, they can easily be looked-up and converted using the 'vg find' command (https://github.com/vgteam/vg).  In the output, we refer to the POS field node as the 'focal node'.  'Allelic nodes', which serve as the REF and ALT fields, are the two possible branches extending from the focal node.  If these two branches return to the same node over the same unit distance, we use segment information to determine the explicit base change otherwise variants are encoded as 'complex' or 'multipath' with the relevant segment number suffix.  IMPORTANTLY, simple indels are encoded differently than conventional vcf format: instead of giving the reference base and the insertion (or vice versus for deletion), variantsFromGFA.pl uses the '-' character and the indel sequence.  We find this much more intuitive and in keeping with the variation graph concept, but this difference may break tools expecting a normal vcf.  In future incarnations, we hope to include a flag for allowing either output format.  In addition, Inversion variants can result in a negative sign suffix in the head node (POS) field. Conventionally, this field represents the position in the reference genome and negative values may cause issues with tools that use vcfs.  Note, the reciprocal variant of the inversion should be called regardless, so the variant information is still retained for most practical purposes.

For import into TASSEL:
'egrep -v '\t[ACGT]{2,}\t[ACGT]{2,}\t' rawFromGFA.vcf | egrep -v '\t-\d+\t' >forTassel.vcf'

## salmonella_5_pggb.sh 

A script to build a PGGB graph of 5 salmonella lines selected for maximum diversity. 

## sim_linear_graph_map_performance.sh

## identify_misaligned_sim_reads.py

## gfa_parser.pl

Command: 
`perl gfa_parser.pl -g gfa_graph_file  [-s short_path_name_T|F] -o [gfa_graph_file.csv for bandage]`

help file: 
gfa_parser_readme.pdf


