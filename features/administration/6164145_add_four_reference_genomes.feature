@study @reference_genome @wip
Feature: Listing available reference genomes
  Background:
    Given I am logged in as "user"
    And I am on the studies page

  Scenario Outline: Listing individual reference genomes
    Given a reference genome will appear in the reference genomes list "<Reference genome>"
    When I follow "<Reference genome>"
    Then I should see the reference genome for reference genome list "<Reference genome>"

    Examples:
      | Reference genome                              |
      | Not suitable for alignment                    |
      | Anopheles_gambiae (PEST)                      |
      | Bordetella_bronchiseptica (RB50)              |
      | Bordetella_pertussis (Tohama_I)               |
      | Brugia_malayi (AAQA01000000)                  |
      | Burkholderia_pseudomallei (K96243)            |
      | Caenorhabditis_elegans (101019)               |
      | Campylobacter_jejuni (NCTC11168)              |
      | Canis_familiaris (UCSC_BROAD2)                |
      | Chlamydia_trachomatis (L2b_UCH-1_proctitis)   |
      | Chlamydophila_abortus (S26_3)                 |
      | Citrobacter_rodentium (ICC168)                |
      | Clostridium_difficile (Strain_196)            |
      | Clostridium_difficile (Strain_630)            |
      | Danio_rerio (zv8_softmasked_dusted)           |
      | Danio_rerio (zv9)                             |
      | Drosophila_melanogaster (Release_5)           |
      | Echinococcus_multilocularis (20100601)        |
      | Escherichia_coli (K12)                        |
      | Gorilla_gorilla (gorilla)                     |
      | HIV_1 (Human_immunodeficiency_virus_1)        |
      | Haemophilus_influenzae (Rd_KW20)              |
      | Homo_sapiens (1000Genomes)                    |
      | Homo_sapiens (CGP_GRCh37.NCBI.allchr_MT)      |
      | Homo_sapiens (GRCh37_53)                      |
      | Homo_sapiens (NCBI36)                         |
      | Human_herpesvirus_4 (Wild_type)               |
      | Influenza_A (H1N1)                            |
      | Klebsiella_pneumoniae (NC_011283)             |
      | Leishmania_infantum (JPCM5)                   |
      | Leishmania_major (V5.2)                       |
      | Leptospira_interrogans (serovar_Copenhageni)  |
      | Mus_musculus (CGP_NCBI37)                     |
      | Mus_musculus (NCBI37)                         |
      | Mycobacterium_avium (paratuberculosis_K-10)   |
      | Mycobacterium_bovis (AF2122_97)               |
      | Mycobacterium_tuberculosis (H37Rv)            |
      | NPD_Chimera (20091028)                        |
      | NPD_Chimera (20091109)                        |
      | NPD_Chimera (20100310)                        |
      | NPD_Chimera (20100526)                        |
      | NPD_Chimera (20100608)                        |
      | NPD_Chimera (20100615)                        |
      | NPD_Chimera (20100622)                        |
      | NPD_Chimera (20100708)                        |
      | NPD_Chimera (20100803)                        |
      | NPD_Chimera (20100817)                        |
      | NPD_Chimera (20100818)                        |
      | NPD_Chimera (20100901)                        |
      | NPD_Chimera (20101019)                        |
      | Neisseria_gonorrhoeae (FA_1090)               |
      | Neisseria_meningitidis (FAM18)                |
      | Neisseria_meningitidis (MC58)                 |
      | PhiX (Illumina)                               |
      | PhiX (NC_001422)                              |
      | PhiX (Sanger-SNPs)                            |
      | Plasmodium_berghei (ANKA)                     |
      | Plasmodium_chabaudi (chabaudi)                |
      | Plasmodium_falciparum (3D7)                   |
      | Pseudomonas_fluorescens (Pf0-1)               |
      | Saccharomyces_cerevisiae (S288c)              |
      | Salmonella_bongori (12149)                    |
      | Salmonella_enterica (Enteritidis_P125109)     |
      | Salmonella_enterica (Paratyphi_A_AKU_12601)   |
      | Salmonella_enterica (Typhimurium_D23580)      |
      | Salmonella_enterica (Typhimurium_LT2)         |
      | Sarcophilus_harrisii (sc-v5.0)                |
      | Sarcophilus_harrisii (tdevil_phusion_v4.0)    |
      | Schistosoma_mansoni (20100601)                |
      | Shigella_sonnei (Ss046)                       |
      | Staphylococcus_aureus (MRSA252)               |
      | Staphylococcus_aureus (NCTC_8325)             |
      | Streptococcus_equi (4047)                     |
      | Streptococcus_pneumoniae (ATCC_700669)        |
      | Streptococcus_pyogenes (Manfredo)             |
      | Streptococcus_suis (BM407)                    |
      | Strongyloides_ratti (20100601)                |
      | Trypanosoma_brucei (927_230210)               |
      | Vibrio_cholerae (M66-2)                       |
      | Yersinia_enterocolitica (enterocolitica_8081) |
      | Yersinia_pseudotuberculosis (IP_31758)        |
