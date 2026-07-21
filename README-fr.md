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

### Article
Contient les fichiers qui ont servi à élaborer l'article "Early Class Exclusion in Hyperdimensional Computing" pour la conférence DATE 2026.

• "Early Class Exclusion in Hyperdimensional Computing.pdf/.docx" : article scientifique

• "Figures article.pptx" : figures crées pour l'article

• "Feuilles de résultats.xlsx" : données utilisées pour l'article
    - Speedup obtenu à partir de l'équation (1) de l'article. Formule déduite des simulations VHDL
    - Accuracy obtenu à partir des simulations Matlab
    - Energy consumption obtenu à partir des simulations Synopsys Design Compiler. 
        - Nomenclature des tableaux :
            - dataset : ISOLET, MNIST, UCIHAR
            - k : nombre de classe (ISOLET=26, MNIST=10, UCIHAR=6)
            - D : dimension des hypervecteurs
            - d : dimension des segments
            - l : dimension des tranches
            - ACC : nombre d'accumulation par itération = d/l
        - Nomenclature des variables :
            - E, A : Energy, Area
            - PE, find, FSMD, test : Processing Element, findMax/findMin (équivalent), FSMD, Wald's test & Holm-Bonferri Method
            - d, s : consommation dynamique, consommation statique
            - cumul : somme des consommations statiques ou dynamiques jusqu'à l'itération
            - ∅, tot : unitaire, total
            - exemple1 : E_PE_d_tot = consommation énergétique dynamique de l'ensemble des Processing Element
            - exemple2 : E_s_tot = consommation totale statique des composants par itération
            - exemple3 : E_FSMD_d = consommation dynamique unitaire du FSMD
            - exemple4 : A_find = surface occupée par le composant findMax/findMin (équivalent)

• "Rapport SFE (simplifié).pdf" : rapport de stage de fin d'études rédigé à l'issue du projet, dans le cadre de mes études. Ce rapport peut éventuellement aider à la compréhension globale du projet, en tenant en compte que certaines données sont obsolètes (notamment celles de simulations énergétiques Synopsys, qui utilisaient des données à f=100MHz, tandis que l'article pour DATE comprend des données à f=500MHz). Il s'agit d'une version simplifiée de mon véritable rapport de SFE dont j'ai supprimé certaines parties jugées inutiles pour comprendre le projet.
