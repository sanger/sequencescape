# Intermediate files for DPL-554

This directory contains intermediate files for generating Sequencescape record loader files for the tag groups in the story [DPL-554 SS New tag sets for Chromium Library Plate Manifest template #3696](https://github.com/sanger/sequencescape/issues/3696)

The following CSV files are saved from the Google Document [10x Tagsets](https://docs.google.com/spreadsheets/d/1KB8vs2vhAkUkAooe9_bjaOyV1CuFDLU0vuzhWslahJc/edit?gid=331796148#gid=331796148). The 000 prefix is added to the files to be processed.

- 000 10x Tagsets - PN-1000212 Single Index Kit N Set A.csv
- 000 10x Tagsets - PN-1000215*PN-3000431* Dual Index Kit TT, Set A.csv
- 000 10x Tagsets - PN-1000250\_ Dual Index Kit TN, Set A.csv
- 000 10x Tagsets - PN-1000251\_ Dual Index Kit TS, Set A.csv
- 10x Tagsets - N-120262*PN-220103* Chromium i7 Multiplex Kit.csv
- 10x Tagsets - PN-1000084\_ Chromium i7 Multiplex Kit N, Set A.csv
- 10x Tagsets - PN-1000213*PN-2000240* Single Index Kit T Set A.csv
- 10x Tagsets - PN-1000242*PN-3000483* Dual Index Kit NT, Set A.csv
- 10x Tagsets - PN-1000243*PN-3000482* Dual Index Kit NN, Set A.csv

The following scripts are written to process the files. Which files they process is written in the scripts.

- dual215.rb
- dual250.rb
- dual251.rb
- single.rb

The following are the standard outputs of the scripts.

- dual215.yml
- dual250.yml
- dual251.yml
- single.yml
