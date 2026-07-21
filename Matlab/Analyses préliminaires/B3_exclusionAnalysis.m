function message = B3_exclusionAnalysis
  assignin('base','testSimpleExclusion', @testSimpleExclusion);
  assignin('base','testCumulExclusionOne', @testCumulExclusionOne);
  assignin('base','testCumulExclusionHalf', @testCumulExclusionHalf);
  assignin('base','testCumulExclusionTier', @testCumulExclusionTier);
  message='Done importing functions to workspace';
end

%% ANALYSE DE L'EXCLUSION DE LA PLUS MAUVAISE LANGUE À CHAQUE SEGMENT

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
