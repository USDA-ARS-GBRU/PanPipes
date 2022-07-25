#!/bin/bash

./msa.construct.graph.sh
./index.graph.sh
./align.reads.sh
./genotype.samples.sh
./impute.samples.sh
