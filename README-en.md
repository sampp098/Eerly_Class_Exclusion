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
