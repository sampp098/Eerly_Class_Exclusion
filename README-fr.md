# EARLY CLASS EXCLUSION IN HYPERDIMENSIONAL COMPUTING

Voici un résumé des fichiers utilisés au cours du projet. Chaque section correspond à un dossier. Il manque les fichiers Synopsys (ma licence Concordia a expiré avant que je ne puisse récupérer les fichiers)

## Mon environnement de travail
• Matlab 2022a
• ModelSim-Altera 10.1d
• Synopsys Design Compiler 2013

## Contenus des dossiers

### Matlab
Contient les programmes Matlab utilisés au cours du projet.

• "Analyses préliminaires" : analyses préliminaires sur le HDC qui ont permis d'élaborer la stratégie d'inférence décrite par l'article. Ces expérimentations se basent sur le modèle GitHub [HDC-Language-Recognition](https://github.com/abbas-rahimi/HDC-Language-Recognition)
    - "A1_buildingModele.m" : construction du modèle HDC (encodage, entraînement)
    - "workspace/ws_modele.mat" : contient les hypervecteurs de classes entraînés et les hypervecteurs de requêtes encodés (issu de A1_buildingModele.m)
    - "A2_errByLang.m" : étude du taux d'erreur par langue de la stratégie d'inférence simple (Baseline A)
    - "A3_nbrCharTraining.m" : étude de l'impact du nombre de caractère d'entraînement sur la précision
    - "B*.m" : analyse de différentes stratégies d'inférence (segmentation, seuil, exclusion itérative)
    - "C_benchmark.m" : comparaison des différentes stratégies analysées. L'exclusion itérative a été retenue comme prometteuse pour une implémentation RTL

• "Comparaison des stratégies" : programme Matlab permettant de comparer différentes stratégies d'inférence (proposed, baseline B, OMEN). Les "datasets" proviennent du GitHub de l'article [OMEN](https://github.com/y553546436/Omen-Artifact) et ont été converti en format .m à l'aide du programme "export_to_mat.py"

• "Figures article" : programmes Matlab qui ont permis d'élaborer certaines figures de l'article

### VHDL
Contient les programmes VHDL élaborés dans le cadre du projet.

• "Baseline B" : programmes VHDL correspondant à la baseline B décrit par l'article. "PU.vhd" est le top level

• "Proposed" : programmes VHDL correspondant à la stratégie proposée décrite par l'article. "PU.vhd" est le top level
