# EARLY CLASS EXCLUSION IN HYPERDIMENSIONAL COMPUTING

Here is a summary of the files used during the project. Each section corresponds to a folder. The Synopsys files are missing (my Concordia license expired before I could retrieve them).

## My work environment
• Matlab 2022a
• ModelSim-Altera 10.1d
• Synopsys Design Compiler 2013

## Contents of the folders

### Matlab
Contains the Matlab programs used during the project.

• "Analyses préliminaires": preliminary analyses on the HDC that allowed us to develop the inference strategy described in the article. These experiments are based on the GitHub model [HDC-Language-Recognition](https://github.com/abbas-rahimi/HDC-Language-Recognition)
    - "A1_buildingModele.m": construction of the HDC model (encoding, training)
    - "workspace/ws_modele.mat": contains the trained class hypervectors and the encoded query hypervectors (from A1_buildingModele.m)
    - "A2_errByLang.m": study of the error rate by language of the simple inference strategy (Baseline A)
    - "A3_nbrCharTraining.m": study of the impact of the number of training characters on accuracy
    - "B*.m": analysis of different inference strategies (segmentation, threshold, iterative exclusion)
    - "C_benchmark.m": comparison of the different strategies analyzed. Iterative exclusion was identified as promising for an RTL implementation.

• "Comparaison des stratégies": Matlab program for comparing different inference strategies (proposed, baseline B, OMEN). The datasets were sourced from the [OMEN](https://github.com/y553546436/Omen-Artifact) GitHub and converted to .m format using the "export_to_mat.py" program.

• "Figures article": Matlab programs used to create some of the figures in the article.

### VHDL
Contains the VHDL programs developed as part of the project.

• "Baseline B": VHDL programs corresponding to baseline B described in the article. "PU.vhd" is the top level.

• "Proposed": VHDL programs corresponding to the proposed strategy described in the article. "PU.vhd" is the top level

### Article
Contains the files used to develop the article "Early Class Exclusion in Hyperdimensional Computing" for the DATE 2026 conference.

• "Early Class Exclusion in Hyperdimensional Computing.pdf/.docx": the scientific article

• "Figures article.pptx": figures created for the article

• "Feuilles de résultats.xlsx": data used for the article
    - Speedup obtained from equation (1) in the article. Formula derived from VHDL simulations
    - Accuracy obtained from Matlab simulations
    - Energy consumption obtained from Synopsys Design Compiler simulations
        - Tables nomenclature:
            - Dataset: ISOLET, MNIST, UCIHAR
            - k: Number of classes (ISOLET=26, MNIST=10, UCIHAR=6)
            - D: Hypervector dimension
            - d: Segment dimension
            - l: Slice dimension
            - ACC: Number of accumulations per iteration = d/l
        - Variables nomenclature:
            - E, A: Energy, Area
            - PE, find, FSMD, test: Processing Element, findMax/findMin (equivalent), FSMD, Wald's test & Holm-Bonferri Method
            - d, s: Dynamic consumption, Static consumption
            - Cumulative: Sum of static or dynamic consumption up to the iteration
            - ∅, tot: Unit, Total
            - example1: E_PE_d_tot = dynamic energy consumption of all Processing Elements
            - example2: E_s_tot = total static consumption of components per iteration
            - example3: E_FSMD_d = unit dynamic consumption of the FSMD
            - example4: A_find = area occupied by the findMax/findMin component (equivalent)

• "Rapport SFE (simplifié).pdf": final internship report written at the end of the project, as part of my studies. This report may help with the overall understanding of the project, taking into account that some data is outdated (notably the Synopsys energy simulations, which used data at f=100 MHz, while the article for DATE includes data at f=500 MHz). This is a simplified version of my actual SFE report, from which I removed certain parts deemed unnecessary for understanding the project.