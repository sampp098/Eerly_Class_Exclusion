function message = C_benchmark
  assignin('base','performanceComparison', @performanceComparison);
  assignin('base','testSegmentation', @testSegmentation);
  assignin('base','testThresholdDyn', @testThresholdDyn);
  assignin('base','testSimpleExclusion', @testSimpleExclusion);
  assignin('base','testCumulExclusionOne', @testCumulExclusionOne);
  assignin('base','testCumulExclusionHalf', @testCumulExclusionHalf);
  assignin('base','testCumulExclusionTier', @testCumulExclusionTier);
  message='Done importing functions to workspace';
end

%% DUPLICATION DES DIFFÉRENTES STRATÉGIES À COMPARER

% Précision et temps d'exécution pour un segment
function statsSegmentation = testSegmentation(langAM, testingHV, S)
    arguments
        langAM
        testingHV
        S = 3000
    end
    tic

    % Correspondance des langues
    langLabels = {'afr', 'bul', 'ces', 'dan', 'nld', 'deu', 'eng', 'est', 'fin', 'fra', 'ell', 'hun', 'ita', 'lav', 'lit', 'pol', 'por', 'ron', 'slk', 'slv', 'spa', 'swe'};
    langMap = containers.Map;
	langMap ('bg') = 'bul';	langMap ('cs') = 'ces';	langMap ('da') = 'dan';	
    langMap ('nl') = 'nld';	langMap ('de') = 'deu';	langMap ('en') = 'eng';	
    langMap ('et') = 'est';	langMap ('fi') = 'fin';	langMap ('fr') = 'fra';	
    langMap ('el') = 'ell';	langMap ('hu') = 'hun';	langMap ('it') = 'ita';	
    langMap ('lv') = 'lav';	langMap ('lt') = 'lit';	langMap ('pl') = 'pol';	
    langMap ('pt') = 'por';	langMap ('ro') = 'ron';	langMap ('sk') = 'slk';	
    langMap ('sl') = 'slv';	langMap ('es') = 'spa';	langMap ('sv') = 'swe';

    % Dimensions des données
    numLangs = length(langLabels); % Nombre de langues
    total = length(testingHV);     % Nombre de vecteurs de test

    % Nombre de bonne prédiction
    correct = 0;

    % Nombre de calcul d'angle pour les statistiques
    cosAngleCalls = 0;
    
    % Boucler pour chaque vecteur de test
    for i=1: 1: total
        fileName = testingHV{i, 1};
        textHV = testingHV{i, 2};
		actualLabel = fileName(1:2);
        
        % Segmentation du HV de requête
        segmentTextHV = textHV(1:S);
        
        % Prédiction de la langue avec segmentation S
        maxAngle = -1;
        for k = 1:1:numLangs

            % Segmentation de la langue en cours
            actualLang = langAM(char(langLabels (k)));
            segmentActualLang = actualLang(1:S);

            % Calcul de l'angle
            angle = dot(segmentActualLang, segmentTextHV) / (norm(segmentActualLang) * norm(segmentTextHV));
            cosAngleCalls = cosAngleCalls + 1;

            if (angle > maxAngle)
	            maxAngle = angle;
	            predicLang = char (langLabels (k));
            end
        end

        % Vérification si la prédiction est correcte
        if predicLang == langMap(actualLabel)
            correct = correct + 1;
        end
    end

    % Calcul de la précision
    accuracy = correct / total;

    % Temps d'exécution
    executionTime = toc;
    
    % Calcul des statistiques de consommation
    totalBits = cosAngleCalls * S;
    statsSegmentation = struct(...
        'accuracy', accuracy, ...
        'cosAngleCalls', cosAngleCalls, ...
        'totalBits', totalBits, ...
        'executionTime', executionTime); 
end

% Seuil dynamique
function statsThresholdDyn = testThresholdDyn(langAM, testingHV, S, threshold_in, th_factor_in)
    arguments
        langAM
        testingHV
        S = 3000
        threshold_in = 0.15
        th_factor_in = 1.2
    end
    tic

    % Correspondance des langues
    langLabels = {'afr', 'bul', 'ces', 'dan', 'nld', 'deu', 'eng', 'est', 'fin', 'fra', 'ell', 'hun', 'ita', 'lav', 'lit', 'pol', 'por', 'ron', 'slk', 'slv', 'spa', 'swe'};
    langMap = containers.Map;
	langMap ('bg') = 'bul';	langMap ('cs') = 'ces';	langMap ('da') = 'dan';	
    langMap ('nl') = 'nld';	langMap ('de') = 'deu';	langMap ('en') = 'eng';	
    langMap ('et') = 'est';	langMap ('fi') = 'fin';	langMap ('fr') = 'fra';	
    langMap ('el') = 'ell';	langMap ('hu') = 'hun';	langMap ('it') = 'ita';	
    langMap ('lv') = 'lav';	langMap ('lt') = 'lit';	langMap ('pl') = 'pol';	
    langMap ('pt') = 'por';	langMap ('ro') = 'ron';	langMap ('sk') = 'slk';	
    langMap ('sl') = 'slv';	langMap ('es') = 'spa';	langMap ('sv') = 'swe';

    % Dimensions des données
    D = length(testingHV{1, 2}); % Longueur des hypervecteurs
    numSegments = floor(D / S);  % Nombre de segments par hypervecteur
    total = length(testingHV);   % Nombre de vecteurs de test

    % Nombre de bonne prédiction
    correct = 0;

    % Nombre de calcul d'angle pour les statistiques
    cosAngleCalls = 0;
    
    % Boucler pour chaque vecteur de test
    for i=1: 1: total
        fileName = testingHV{i, 1};
        textHV = testingHV{i, 2};
		actualLabel = fileName(1:2);

        % Seuils dynamiques
        threshold = threshold_in;
        th_factor = th_factor_in;
        
        % Liste des langues valides pour l'HV en cours
        validLangs = langLabels;

        % Boucler pour chaque segmentation S si nécessaire
        for j = 1:numSegments

            % Segmentation du HV de requête
            segmentStart = (j - 1) * S + 1;
            segmentEnd = j * S;
            segmentTextHV = textHV(segmentStart:segmentEnd);

            % Liste des index des langues à supprimer
            idxValidLangs = 1;

            % Prédiction de la langue avec segmentation S
            maxAngle = -1;
            for k = validLangs

                % Segmentation de la langue en cours
                actualLang = langAM(char(k));
                segmentActualLang = actualLang(segmentStart:segmentEnd);

                % Calcul de l'angle
                angle = dot(segmentActualLang, segmentTextHV) / (norm(segmentActualLang) * norm(segmentTextHV));
                cosAngleCalls = cosAngleCalls + 1;

                % Enregistrement des langues proches de la langue réelle selon le seuil en cours
                if (angle < threshold)
                    validLangs(idxValidLangs) = [];
                    idxValidLangs = idxValidLangs - 1;
                end

                if (angle > maxAngle)
		            maxAngle = angle;
		            predicLang = char (k);
                end

                idxValidLangs = idxValidLangs + 1;
            end

            % Passe au HV suivant lorsqu'il ne reste plus qu'une langue valide
            if (length(validLangs) < 1)
                break;
            end

            % Ajustement du seuil
            threshold = threshold * th_factor;
        end

        % Vérification si la prédiction est correcte
        if predicLang == langMap(actualLabel)
            correct = correct + 1;
        end
    end

    % Calcul de la précision par langue par segmentation S
    accuracy = correct / total;

    % Temps d'exécution pour les statistiques
    executionTime = toc;

    % Calcul des statistiques de consommation
    totalBits = cosAngleCalls * S;
    statsThresholdDyn = struct(...
        'accuracy', accuracy, ...
        'cosAngleCalls', cosAngleCalls, ...
        'totalBits', totalBits, ...
        'executionTime', executionTime); 
end

% Exclusion de la plus mauvaise langue à chaque segment
function statsSimpleExclusion = testSimpleExclusion(langAM, testingHV, S)
    arguments
        langAM
        testingHV
        S = 400
    end
    tic

    % Correspondance des langues
    langLabels = {'afr', 'bul', 'ces', 'dan', 'nld', 'deu', 'eng', 'est', 'fin', 'fra', 'ell', 'hun', 'ita', 'lav', 'lit', 'pol', 'por', 'ron', 'slk', 'slv', 'spa', 'swe'};
    langMap = containers.Map;
    langMap ('bg') = 'bul'; langMap ('cs') = 'ces'; langMap ('da') = 'dan'; 
    langMap ('nl') = 'nld'; langMap ('de') = 'deu'; langMap ('en') = 'eng'; 
    langMap ('et') = 'est'; langMap ('fi') = 'fin'; langMap ('fr') = 'fra'; 
    langMap ('el') = 'ell'; langMap ('hu') = 'hun'; langMap ('it') = 'ita'; 
    langMap ('lv') = 'lav'; langMap ('lt') = 'lit'; langMap ('pl') = 'pol'; 
    langMap ('pt') = 'por'; langMap ('ro') = 'ron'; langMap ('sk') = 'slk'; 
    langMap ('sl') = 'slv'; langMap ('es') = 'spa'; langMap ('sv') = 'swe';

    % Dimensions des données
    D = length(testingHV{1, 2}); % Longueur des hypervecteurs
    numSegments = floor(D / S);  % Nombre de segments par hypervecteur
    total = length(testingHV);   % Nombre de vecteurs de test

    % Nombre de bonnes prédictions
    correct = 0;

    % Nombre de calcul d'angle pour les statistiques
    cosAngleCalls = 0;

    % Boucler sur chaque vecteur de test
    for i=1: 1: total
        fileName = testingHV{i, 1};
        textHV = testingHV{i, 2};
        actualLabel = fileName(1:2);

        % Initialiser la liste des langues possibles
        validLangs = langLabels;

        % Boucler pour chaque segmentation S si nécessaire
        for j = 1:numSegments

            % Segmentation du HV de requête
            segmentStart = (j - 1) * S + 1;
            segmentEnd = j * S;
            segmentTextHV = textHV(segmentStart:segmentEnd);

            % Stockage des angles pour identifier le plus mauvais
            angles = zeros(1, length(validLangs));

            % Pour toutes les langues potentiellement correctes
            for k = 1:length(validLangs)

                % Segmentation de la langue en cours
                actualLang = langAM(validLangs{k});
                segmentActualLang = actualLang(segmentStart:segmentEnd);

                % Calcul de l'angle
                angles(k) = dot(segmentActualLang, segmentTextHV) / (norm(segmentActualLang) * norm(segmentTextHV));
                cosAngleCalls = cosAngleCalls + 1;
            end

            % Index de la langue ayant l'angle le plus mauvais
            [~, worstIdx] = min(angles);

            % Exclusion de cette langue de la liste
            validLangs(worstIdx) = [];

            % Arrêt des tests s'il ne reste plus qu'une seule langue en lice
            if length(validLangs) <= 1
                break;
            end
        end

        % Prédiction faite par le programme
        predicLang = char(validLangs);

        % Vérification si la prédiction est correcte
        if predicLang == langMap(actualLabel)
            correct = correct + 1;
        end
    end

    % Calcul de la précision
    accuracy = correct / total;

    % Temps d'exécution pour les statistiques
    executionTime = toc;

    % Calcul des statistiques de consommation
    totalBits = cosAngleCalls * S;
    statsSimpleExclusion = struct(...
        'accuracy', accuracy, ...
        'cosAngleCalls', cosAngleCalls, ...
        'totalBits', totalBits, ...
        'executionTime', executionTime); 
end

% Exclusion cumulative de la plus mauvaise langue à chaque segment
function statsCumulExclusionOne = testCumulExclusionOne(langAM, testingHV, S)
    arguments
        langAM
        testingHV
        S = 400
    end
    tic

    % Correspondance des langues
    langLabels = {'afr', 'bul', 'ces', 'dan', 'nld', 'deu', 'eng', 'est', 'fin', 'fra', 'ell', 'hun', 'ita', 'lav', 'lit', 'pol', 'por', 'ron', 'slk', 'slv', 'spa', 'swe'};
    langMap = containers.Map;
    langMap ('bg') = 'bul'; langMap ('cs') = 'ces'; langMap ('da') = 'dan'; 
    langMap ('nl') = 'nld'; langMap ('de') = 'deu'; langMap ('en') = 'eng'; 
    langMap ('et') = 'est'; langMap ('fi') = 'fin'; langMap ('fr') = 'fra'; 
    langMap ('el') = 'ell'; langMap ('hu') = 'hun'; langMap ('it') = 'ita'; 
    langMap ('lv') = 'lav'; langMap ('lt') = 'lit'; langMap ('pl') = 'pol'; 
    langMap ('pt') = 'por'; langMap ('ro') = 'ron'; langMap ('sk') = 'slk'; 
    langMap ('sl') = 'slv'; langMap ('es') = 'spa'; langMap ('sv') = 'swe';

    % Dimensions des données
    D = length(testingHV{1, 2});   % Longueur des hypervecteurs
    numSegments = floor(D / S);    % Nombre de segments par hypervecteur
    numLangs = length(langLabels); % Nombre de langues
    total = length(testingHV);     % Nombre de vecteurs de test

    % Nombre de bonnes prédictions
    correct = 0;
    
    % Nombre de calcul d'angle pour les statistiques
    cosAngleCalls = 0;

    % Boucler sur chaque vecteur de test
    for i=1: 1: total
        fileName = testingHV{i, 1};
        textHV = testingHV{i, 2};
        actualLabel = fileName(1:2);

        % Initialisation de la liste des langues possibles
        validIdx = 1:numLangs;
        cumulativeAngles = zeros(1, numLangs);

        % Boucler pour chaque segmentation S si nécessaire
        for j = 1:numSegments

            % Segmentation du HV de requête
            segmentStart = (j - 1) * S + 1;
            segmentEnd = j * S;
            segmentTextHV = textHV(segmentStart:segmentEnd);

            % Pour toutes les langues potentiellement correctes
            for k = validIdx

                % Segmentation de la langue en cours
                actualLang = langAM(langLabels{k});
                segmentActualLang = actualLang(segmentStart:segmentEnd);

                % Calcul de l'angle
                angle = dot(segmentActualLang, segmentTextHV) / (norm(segmentActualLang) * norm(segmentTextHV));
                cosAngleCalls = cosAngleCalls + 1;

                % Mise à jour de la somme cumulée moyennée pour la langue en cours
                cumulativeAngles(k) = cumulativeAngles(k) + angle;
            end

            % Exclusion de la langue ayant la moyenne d'angle le plus mauvais
            [~, worstIdx] = min(cumulativeAngles(validIdx));
            validIdx(worstIdx) = [];

            % Arrêt des tests s'il ne reste plus qu'une seule langue en lice
            if length(validIdx) <= 1
                break;
            end
        end


        % Prédiction faite par le programme
        predicLang = langLabels{validIdx(1)};

        % Vérification si la prédiction est correcte
        if predicLang == langMap(actualLabel)
            correct = correct + 1;
        end
    end

    % Calcul de la précision
    accuracy = correct / total;

    % Temps d'exécution pour les statistiques
    executionTime = toc;

    % Calcul des statistiques de consommation
    totalBits = cosAngleCalls * S;
    statsCumulExclusionOne = struct(...
        'accuracy', accuracy, ...
        'cosAngleCalls', cosAngleCalls, ...
        'totalBits', totalBits, ...
        'executionTime', executionTime); 
end

% Exclusion cumulative de la moitié des plus mauvaises langues à chaque segment
function statsCumulExclusionHalf = testCumulExclusionHalf(langAM, testingHV, S)
    arguments
        langAM
        testingHV
        S = 1000
    end
    tic

    % Correspondance des langues
    langLabels = {'afr', 'bul', 'ces', 'dan', 'nld', 'deu', 'eng', 'est', 'fin', 'fra', 'ell', 'hun', 'ita', 'lav', 'lit', 'pol', 'por', 'ron', 'slk', 'slv', 'spa', 'swe'};
    langMap = containers.Map;
    langMap ('bg') = 'bul'; langMap ('cs') = 'ces'; langMap ('da') = 'dan'; 
    langMap ('nl') = 'nld'; langMap ('de') = 'deu'; langMap ('en') = 'eng'; 
    langMap ('et') = 'est'; langMap ('fi') = 'fin'; langMap ('fr') = 'fra'; 
    langMap ('el') = 'ell'; langMap ('hu') = 'hun'; langMap ('it') = 'ita'; 
    langMap ('lv') = 'lav'; langMap ('lt') = 'lit'; langMap ('pl') = 'pol'; 
    langMap ('pt') = 'por'; langMap ('ro') = 'ron'; langMap ('sk') = 'slk'; 
    langMap ('sl') = 'slv'; langMap ('es') = 'spa'; langMap ('sv') = 'swe';

    % Dimensions des données
    D = length(testingHV{1, 2});   % Longueur des hypervecteurs
    numSegments = floor(D / S);    % Nombre de segments par hypervecteur
    numLangs = length(langLabels); % Nombre de langues
    total = length(testingHV);     % Nombre de vecteurs de test

    % Nombre de bonnes prédictions
    correct = 0;

    % Nombre de calcul d'angle pour les statistiques
    cosAngleCalls = 0;

    % Boucler sur chaque vecteur de test
    for i=1: 1: total
        fileName = testingHV{i, 1};
        textHV = testingHV{i, 2};
        actualLabel = fileName(1:2);

        % Initialisation de la liste des langues possibles
        validIdx = 1:numLangs;
        cumulativeAngles = zeros(1, numLangs);

        % Boucler pour chaque segmentation S si nécessaire
        for j = 1:numSegments

            % Segmentation du HV de requête
            segmentStart = (j - 1) * S + 1;
            segmentEnd = j * S;
            segmentTextHV = textHV(segmentStart:segmentEnd);

            % Pour toutes les langues potentiellement correctes
            for k = validIdx

                % Segmentation de la langue en cours
                actualLang = langAM(langLabels{k});
                segmentActualLang = actualLang(segmentStart:segmentEnd);

                % Calcul de l'angle
                angle = dot(segmentActualLang, segmentTextHV) / (norm(segmentActualLang) * norm(segmentTextHV));
                cosAngleCalls = cosAngleCalls + 1;

                % Mise à jour de la somme cumulée moyennée pour la langue en cours
                cumulativeAngles(k) = cumulativeAngles(k) + angle;
            end

            % Nombre de langue à supprimer (moitié arrondie vers le bas)
            numToRemove = floor(length(validIdx) / 2);
            if numToRemove < 1
                numToRemove = 1;
            end

            % Exclusion de la langue ayant la moyenne d'angle le plus mauvais
            [~, sortedIdx] = sort(cumulativeAngles(validIdx));
            idxToRemove = sortedIdx(1:numToRemove);
            validIdx(idxToRemove) = [];
            
            % Arrêt des tests s'il ne reste plus qu'une seule langue en lice
            if length(validIdx) <= 1
                break;
            end
        end

        % Prédiction faite par le programme
        predicLang = langLabels{validIdx(1)};

        % Vérification si la prédiction est correcte
        if predicLang == langMap(actualLabel)
            correct = correct + 1;
        end
    end

    % Calcul de la précision
    accuracy = correct / total;

    % Temps d'exécution pour les statistiques
    executionTime = toc;

    % Calcul des statistiques de consommation
    totalBits = cosAngleCalls * S;
    statsCumulExclusionHalf = struct(...
        'accuracy', accuracy, ...
        'cosAngleCalls', cosAngleCalls, ...
        'totalBits', totalBits, ...
        'executionTime', executionTime);
end

% Exclusion cumulative du tier des plus mauvaises langues à chaque segment
function statsCumulExclusionTier = testCumulExclusionTier(langAM, testingHV, S)
    arguments
        langAM
        testingHV
        S = 1000
    end
    tic

    % Correspondance des langues
    langLabels = {'afr', 'bul', 'ces', 'dan', 'nld', 'deu', 'eng', 'est', 'fin', 'fra', 'ell', 'hun', 'ita', 'lav', 'lit', 'pol', 'por', 'ron', 'slk', 'slv', 'spa', 'swe'};
    langMap = containers.Map;
    langMap ('bg') = 'bul'; langMap ('cs') = 'ces'; langMap ('da') = 'dan'; 
    langMap ('nl') = 'nld'; langMap ('de') = 'deu'; langMap ('en') = 'eng'; 
    langMap ('et') = 'est'; langMap ('fi') = 'fin'; langMap ('fr') = 'fra'; 
    langMap ('el') = 'ell'; langMap ('hu') = 'hun'; langMap ('it') = 'ita'; 
    langMap ('lv') = 'lav'; langMap ('lt') = 'lit'; langMap ('pl') = 'pol'; 
    langMap ('pt') = 'por'; langMap ('ro') = 'ron'; langMap ('sk') = 'slk'; 
    langMap ('sl') = 'slv'; langMap ('es') = 'spa'; langMap ('sv') = 'swe';

    % Dimensions des données
    D = length(testingHV{1, 2});   % Longueur des hypervecteurs
    numSegments = floor(D / S);    % Nombre de segments par hypervecteur
    numLangs = length(langLabels); % Nombre de langues
    total = length(testingHV);     % Nombre de vecteurs de test

    % Nombre de bonnes prédictions
    correct = 0;

    % Nombre de calcul d'angle pour les statistiques
    cosAngleCalls = 0;

    % Boucler sur chaque vecteur de test
    for i=1: 1: total
        fileName = testingHV{i, 1};
        textHV = testingHV{i, 2};
        actualLabel = fileName(1:2);

        % Initialisation de la liste des langues possibles
        validIdx = 1:numLangs;
        cumulativeAngles = zeros(1, numLangs);

        % Boucler pour chaque segmentation S si nécessaire
        for j = 1:numSegments

            % Segmentation du HV de requête
            segmentStart = (j - 1) * S + 1;
            segmentEnd = j * S;
            segmentTextHV = textHV(segmentStart:segmentEnd);

            length(validIdx)

            % Pour toutes les langues potentiellement correctes
            for k = validIdx

                % Segmentation de la langue en cours
                actualLang = langAM(langLabels{k});
                segmentActualLang = actualLang(segmentStart:segmentEnd);

                % Calcul de l'angle
                angle = dot(segmentActualLang, segmentTextHV) / (norm(segmentActualLang) * norm(segmentTextHV));
                cosAngleCalls = cosAngleCalls + 1;

                % Mise à jour de la somme cumulée moyennée pour la langue en cours
                cumulativeAngles(k) = cumulativeAngles(k) + angle;
            end

            % Nombre de langue à supprimer (moitié arrondie vers le bas)
            numToRemove = floor(length(validIdx) / 3);
            if numToRemove < 1
                numToRemove = 1;
            end

            % Exclusion de la langue ayant la moyenne d'angle le plus mauvais
            [~, sortedIdx] = sort(cumulativeAngles(validIdx));
            idxToRemove = sortedIdx(1:numToRemove);
            validIdx(idxToRemove) = [];
            
            % Arrêt des tests s'il ne reste plus qu'une seule langue en lice
            if length(validIdx) <= 1
                break;
            end
        end

        % Prédiction faite par le programme
        predicLang = langLabels{validIdx(1)};

        % Vérification si la prédiction est correcte
        if predicLang == langMap(actualLabel)
            correct = correct + 1;
        end
    end

    % Calcul de la précision
    accuracy = correct / total;

    % Temps d'exécution pour les statistiques
    executionTime = toc;

    % Calcul des statistiques de consommation
    totalBits = cosAngleCalls * S;
    statsCumulExclusionTier = struct(...
        'accuracy', accuracy, ...
        'cosAngleCalls', cosAngleCalls, ...
        'totalBits', totalBits, ...
        'executionTime', executionTime);
end

%% COMPARAISON DES DIFFÉRENTES STRATÉGIES

% Benchmark comparatif
function [basicStats, specificStats] = performanceComparison(langAM, testingHV, basicStats, specificStats)
    arguments
        langAM
        testingHV
        basicStats = zeros(0)    % Établi lors de l'étape 1
        specificStats = zeros(0) % Établi lors de l'étape 4
    end

    % --- ÉTAPE 1 : Initialisation et calcul des statistiques de base ---
    % Étape 1 ignorée si basicStats a déjà été calculé

    % Liste des fonctions utilisées pour le benchmark
    methods = {@testSegmentation, @testThresholdDyn, @testSimpleExclusion, @testCumulExclusionOne, @testCumulExclusionHalf, @testCumulExclusionTier};
    methodNames = ["Segmentation", "Dynamic threshold", "Exclusion", "Cumulative one exclusion", "Cumulative half exclusion", "Cumulative tier exclusion"];
    numMethods = length(methods);

    % Plages de valeurs
    segmentations = [20, 60, 100, 200, 300, 400, 450, 500, 1000, 1500, 2000, 2500, 3000, 3500];
    targetAccuracies = [84, 88, 92, 94, 95, 96, 97, 98];
    numSegmentations = length(segmentations);
    numTargets = length(targetAccuracies);
    
    % Calcul des statistiques de base (si pas de données d'entrées)
    if isempty(basicStats) == 1

        % Structure pour stocker les résultats
        basicStats = struct;
        for i = 1:numMethods
    
            % Initialisation
            basicStats(i).name          = methodNames(i);
            basicStats(i).segmentation  = segmentations;
            basicStats(i).accuracy      = zeros(1, numSegmentations);
            basicStats(i).cosAngleCalls = zeros(1, numSegmentations);
            basicStats(i).totalBits     = zeros(1, numSegmentations);
            basicStats(i).executionTime = zeros(1, numSegmentations);
            
            % Simulations
            for j = 1:numSegmentations
                S = segmentations(j);
                methodStats                     = methods{i}(langAM, testingHV, S);
                basicStats(i).accuracy(j)       = methodStats.accuracy * 100;
                basicStats(i).cosAngleCalls(j)  = methodStats.cosAngleCalls;
                basicStats(i).totalBits(j)      = methodStats.totalBits;
                basicStats(i).executionTime(j)  = methodStats.executionTime;
            end
        end
    end

    fprintf("Étape 1 complétée\n");

    % --- ÉTAPE 2 : Tracé de la précision en fonction de la segmentation ---

    % Graphique : précision en fonction de la segmentation
    figure;
    hold on;
    colors = lines(numMethods);
    for i = 3:6
        plot(basicStats(i).segmentation, basicStats(i).accuracy, '-o', 'Color', colors(i, :), 'LineWidth', 1.5);
    end
    xlabel('Segmentation S (bit)');
    ylabel('Accuracy (%)');
    title('Accuracy as a function of segmentation S');
    legend(methodNames, 'Location', 'southeast');
    grid on;
    hold off;

    fprintf("Étape 2 complétée\n");

    % --- ÉTAPE 3 : Valeur de segmentation pour différente précision ---
    % Étape 3 ignorée si specificStats a déjà été calculé

    % Calcul des statistiques spécifiques (si pas de données d'entrées)
    if isempty(specificStats) == 1

        % Récupération des segmentations par précision
        S_by_accuracy = cell(numMethods, numTargets);
        
        % Boucler sur le nombre de fonctions utilisées pour le benchmark
        for i = 1:numMethods
    
            % Boucler pour le nombre de précision cible
            for t = 1:numTargets
                targetAccuracy = targetAccuracies(t);
                S_opt = NaN;
    
                % Boucler sur le nombre de segmentation
                for j = 1:numSegmentations - 1
    
                    % Précision aux points j et j + 1
                    acc1 = basicStats(i).accuracy(j);
                    acc2 = basicStats(i).accuracy(j + 1);
    
                    % Segmentation aux points j et j + 1
                    seg1 = basicStats(i).segmentation(j);
                    seg2 = basicStats(i).segmentation(j + 1);
    
                    % Vérifie si la précision cible est comprise dans la segmentation actuelle
                    if (targetAccuracy >= min(acc1, acc2)) && (targetAccuracy <= max(acc1, acc2))
                        S_opt = seg1 + (targetAccuracy - acc1) * (seg2 - seg1) / (acc2 - acc1);
                        break;
                    end
                end
                % Stockage de la segmentation par précision
                S_by_accuracy{i, t} = round(S_opt);
            end
        end
    end

    fprintf("Étape 3 complétée\n");

    % --- ÉTAPE 4 : Calcul des statistiques spécifiques ---
    % Étape 4 ignorée si specificStats a déjà été calculé

    % Calcul des statistiques spécifiques (si pas de données d'entrées)
    if isempty(specificStats) == 1

        % Structure pour stocker les résultats
        specificStats = struct;
        for i = 1:numMethods
    
            % Initialisation
            specificStats(i).name           = methodNames(i);
            specificStats(i).segmentation   = zeros(1, numSegmentations);
            specificStats(i).accuracy       = zeros(1, numSegmentations);
            specificStats(i).cosAngleCalls  = zeros(1, numSegmentations);
            specificStats(i).totalBits      = zeros(1, numSegmentations);
            specificStats(i).executionTime  = zeros(1, numSegmentations);
            
            % Simulations
            for t = 1:numTargets
                S = S_by_accuracy{i, t};
                if isnan(S), continue; end % Au cas où la précision n'est pas atteinte par la fonction
                methodStats                         = methods{i}(langAM, testingHV, S);
                specificStats(i).segmentation(t)    = S;
                specificStats(i).accuracy(t)        = methodStats.accuracy * 100;
                specificStats(i).cosAngleCalls(t)   = methodStats.cosAngleCalls;
                specificStats(i).totalBits(t)       = methodStats.totalBits;
                specificStats(i).executionTime(t)   = methodStats.executionTime;
            end
            
            % Filtrage des points invalides (NaN ou zéros)
            validIndices = specificStats(i).accuracy ~= 0;
            specificStats(i).segmentation   = specificStats(i).segmentation(validIndices);
            specificStats(i).accuracy       = specificStats(i).accuracy(validIndices);
            specificStats(i).cosAngleCalls  = specificStats(i).cosAngleCalls(validIndices);
            specificStats(i).totalBits      = specificStats(i).totalBits(validIndices);
            specificStats(i).executionTime  = specificStats(i).executionTime(validIndices);
        end
    end

    fprintf("Étape 4 complétée\n");

    % --- ÉTAPE 5 : Tracés des statistiques spécifiques ---

    % Graphique : cosAngleCalls = f( précision )
    figure;
    hold on;
    for i = 1:numMethods
        plot(specificStats(i).accuracy, specificStats(i).cosAngleCalls, '-o', 'Color', colors(i, :), 'LineWidth', 1.5);
    end
    xlabel('Accuracy (%)');
    ylabel('Number of calls to the cosAngle function');
    title('Number of calls to the cosAngle function as a function of precision');
    legend(methodNames, 'Location', 'best');
    grid on;

    % Graphique : totalBits = f( précision )
    figure;
    hold on;
    for i = 1:numMethods
        plot(specificStats(i).accuracy, specificStats(i).totalBits, '-o', 'Color', colors(i, :), 'LineWidth', 1.5);
    end
    xlabel('Accuracy (%)');
    ylabel('Total number of bits used when calling the cosAngle function');
    title('Total number of bits used when calling the cosAngle function as a function of precision');
    legend(methodNames, 'Location', 'best');
    grid on;

    % Graphique : executionTime = f( précision )
    figure;
    hold on;
    for i = 1:numMethods
        plot(specificStats(i).accuracy, specificStats(i).executionTime, '-o', 'Color', colors(i, :), 'LineWidth', 1.5);
    end
    xlabel('Accuracy (%)');
    ylabel('Execution time (s)');
    title('Execution time as a function of precision');
    legend(methodNames, 'Location', 'best');
    grid on;

    fprintf("Étape 5 complétée\n");
end
