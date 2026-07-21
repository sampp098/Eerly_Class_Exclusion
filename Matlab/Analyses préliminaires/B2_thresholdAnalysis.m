function message = B2_thresholdAnalysis
  assignin('base','angleBySegmentByLanguage', @angleBySegmentByLanguage);
  assignin('base','angleBySegmentByLanguageAdvanced', @angleBySegmentByLanguageAdvanced);
  assignin('base','testThresholdDyn', @testThresholdDyn);
  assignin('base','optimizeThresholdFactor', @optimizeThresholdFactor);
  message='Done importing functions to workspace';
end

%% ÉTUDE DU SEUIL

% Moyenne des angles segmentés en fonction de chaque langue (analyse simple)
function angles = angleBySegmentByLanguage(langAM, testingHV, S)
    arguments
        langAM
        testingHV
        S = 1000
    end

    % Correspondance des langues
    langLabels = {'afr', 'bul', 'ces', 'dan', 'nld', 'deu', 'eng', 'est', 'fin', 'fra', 'ell', 'hun', 'ita', 'lav', 'lit', 'pol', 'por', 'ron', 'slk', 'slv', 'spa', 'swe'};
    langMap = containers.Map;
	langMap ('af') = 'afr';	langMap ('bg') = 'bul';	langMap ('cs') = 'ces';
	langMap ('da') = 'dan';	langMap ('nl') = 'nld';	langMap ('de') = 'deu';
	langMap ('en') = 'eng';	langMap ('et') = 'est';	langMap ('fi') = 'fin';
	langMap ('fr') = 'fra';	langMap ('el') = 'ell';	langMap ('hu') = 'hun';
	langMap ('it') = 'ita';	langMap ('lv') = 'lav';	langMap ('lt') = 'lit';
	langMap ('pl') = 'pol';	langMap ('pt') = 'por';	langMap ('ro') = 'ron';
	langMap ('sk') = 'slk';	langMap ('sl') = 'slv';	langMap ('es') = 'spa';
	langMap ('sv') = 'swe';

    % Dimensions des données
    D = length(testingHV{1, 2});   % Longueur des hypervecteurs
    numSegments = floor(D / S);    % Nombre de segments par hypervecteur
    numLangs = length(langLabels); % Nombre de langues
    numTests = length(testingHV);  % Nombre de vecteurs de test

    % Initialisation des tableaux pour stocker les angles (langue, segment, test), et nombre de vecteurs par langue
    angles = zeros(numLangs, numSegments, numTests);
    langVectorsSize = zeros(1 + numLangs, 1);

    % Boucler pour chaque langue
    for l = 1:numLangs
        analysisLang = langLabels{l};
        fprintf('Analyse de la langue : %s (%d/%d)\n', analysisLang, l, numLangs);
        
        % Filtrage des vecteurs de test de la langue analysée
        langVectors = {};
        for i = 1:size(testingHV, 1)
            fileName = testingHV{i, 1};
            actualLabel = fileName(1:2);
            
            % Vérifier si la langue correspond
            if analysisLang == langMap(actualLabel)
                langVectors{end + 1, 1} = testingHV{i, 1};
                langVectors{end, 2} = testingHV{i, 2};
            end
        end
        
        % Mise à jour du nombre de vecteur pour langue l en cours
        langVectorsSize(l + 1) = length(langVectors);

        % Boucler pour chaque segmentation S par langue
        for j = 1:numSegments
            
            % Boucler pour chaque vecteur de test de la langue cible
            for i=1: 1: langVectorsSize(l + 1)
                textHV = langVectors{i, 2};

                % Segmentation du HV de requête
                segmentStart = (j - 1) * S + 1;
                segmentEnd = j * S;
                segmentTextHV = textHV(segmentStart:segmentEnd);

                % Prédiction de la langue avec segmentation S
                for k = 1:1:numLangs
                    i_Idx = i + sum(langVectorsSize(1:l));

                    % Segmentation de la langue en cours
                    actualLang = langAM(langLabels{k});
                    segmentActualLang = actualLang(segmentStart:segmentEnd);

                    % Calcul de l'angle
                    angles(k, j, i_Idx) = dot(segmentActualLang, segmentTextHV) / (norm(segmentActualLang) * norm(segmentTextHV));
                end
            end
        end
    end

    % Graphique : moyenne des angles entre requête HV et base HV en fonction du langage
    figure;
    hold on;
    title('Average angle between HV query and base HV as a function of language');
    xlabel('Languages');
    ylabel('Average angle');
    grid on;

    % Autant de courbe que de segmentation
    for j = 1:numSegments

        % Initialisation des moyennes in-class et out-class
        inClassMean = zeros(1, numLangs);  % In-class : vecteurs de test correspondant à la langue sélectionnée
        outClassMean = zeros(1, numLangs); % Out-class : vecteurs de test ne correspondant pas à la langue sélectionnée

        % Calcul des moyennes pour chaque langue
        for l = 1:numLangs

            % Extraction des angles par langue par segment
            startIdx = sum(langVectorsSize(1:l)) + 1;
            endIdx = sum(langVectorsSize(1:l+1));
            inClassAngles = angles(l, j, startIdx:endIdx);
            outClassAngles = angles(l, j, [1:startIdx-1, endIdx+1:end]);

            % Moyennes des angles
            inClassMean(l) = mean(inClassAngles);
            outClassMean(l) = mean(outClassAngles);
        end

        % Affichage des courbes in-class et out-class par segment
        plot(1:numLangs, inClassMean, '-o');
        plot(1:numLangs, outClassMean, '--x');

    end
    % Noms des langues sur l'axe X
    xticks(1:numLangs);
    xticklabels(langLabels);

    % Ajout d'une légende
    ylim([-1, 1]);
    legend(sprintf('In-class'), sprintf('Out-class'));
    legend('show');
    hold off;
end

% Moyenne des angles segmentés en fonction de chaque langue (analyse avancée)
function [angles, langVectorsSize] = angleBySegmentByLanguageAdvanced(langAM, testingHV, S)
    arguments
        langAM
        testingHV
        S = 1000
    end

    % Correspondance des langues
    langLabels = {'afr', 'bul', 'ces', 'dan', 'nld', 'deu', 'eng', 'est', 'fin', 'fra', 'ell', 'hun', 'ita', 'lav', 'lit', 'pol', 'por', 'ron', 'slk', 'slv', 'spa', 'swe'};
    langMap = containers.Map;
	langMap ('af') = 'afr';	langMap ('bg') = 'bul';	langMap ('cs') = 'ces';
	langMap ('da') = 'dan';	langMap ('nl') = 'nld';	langMap ('de') = 'deu';
	langMap ('en') = 'eng';	langMap ('et') = 'est';	langMap ('fi') = 'fin';
	langMap ('fr') = 'fra';	langMap ('el') = 'ell';	langMap ('hu') = 'hun';
	langMap ('it') = 'ita';	langMap ('lv') = 'lav';	langMap ('lt') = 'lit';
	langMap ('pl') = 'pol';	langMap ('pt') = 'por';	langMap ('ro') = 'ron';
	langMap ('sk') = 'slk';	langMap ('sl') = 'slv';	langMap ('es') = 'spa';
	langMap ('sv') = 'swe';

    % Dimensions des données
    D = length(testingHV{1, 2});   % Longueur des hypervecteurs
    numSegments = floor(D / S);    % Nombre de segments par hypervecteur
    numLangs = length(langLabels); % Nombre de langues
    numTests = length(testingHV);  % Nombre de vecteurs de test

    % Initialisation des tableaux pour stocker les angles et la taille des vecteurs par langue
    angles = zeros(numLangs, numSegments, numTests);
    langVectorsSize = zeros(1 + numLangs, 1);

    % Boucler pour chaque langue
    for l = 1:numLangs
        analysisLang = langLabels{l};
        fprintf('Analyse de la langue : %s (%d/%d)\n', analysisLang, l, numLangs);

        % Filtrage des vecteurs de test de la langue analysée
        langVectors = {};
        for i = 1:numTests
            fileName = testingHV{i, 1};
            actualLabel = fileName(1:2);

            % Vérifier si la langue correspond
            if analysisLang == langMap(actualLabel)
                langVectors{end + 1, 1} = testingHV{i, 1};
                langVectors{end, 2} = testingHV{i, 2};
            end
        end

        % Mise à jour du nombre de vecteur pour langue l en cours
        langVectorsSize(l + 1) = length(langVectors);

        % Boucler pour chaque segmentation S par langue
        for j = 1:numSegments

            % Boucler pour chaque vecteur de test de la langue cible
            for i=1: 1: langVectorsSize(l + 1)
                textHV = langVectors{i, 2};

                % Segmentation du HV de requête
                segmentStart = (j - 1) * S + 1;
                segmentEnd = j * S;
                segmentTextHV = textHV(segmentStart:segmentEnd);

                % Prédiction de la langue avec segmentation S
                for k = 1:1:numLangs
                    i_Idx = i + sum(langVectorsSize(1:l));

                    % Segmentation de la langue en cours
                    actualLang = langAM(langLabels{k});
                    segmentActualLang = actualLang(segmentStart:segmentEnd);

                    % Calcul de l'angle
                    angles(k, j, i_Idx) = dot(segmentActualLang, segmentTextHV) / (norm(segmentActualLang) * norm(segmentTextHV));
                end
            end
        end
    end
    
    % Affichage plein écran des figures
    screenSize = get(0, 'ScreenSize');

    % Graphique : moyenne et violons des angles entre requête HV et base HV en fonction du langage
    for l = 1:numLangs
        figure;
        hold on;
        sgtitle(sprintf('Angles for language : %s', langLabels{l}));
        xlabel('Segment');
        ylabel('CosAngle');
        set(gcf, 'Position', [1, 1, screenSize(3), screenSize(4)]);
        grid on;

        % Boucler pour chaque segment
        for j = 1:numSegments

            % Indices des in-class
            startIdx = sum(langVectorsSize(1:l)) + 1;
            endIdx = sum(langVectorsSize(1:l+1));
            inClassAngles = squeeze(angles(l, j, startIdx:endIdx))';
            outClassAngles = squeeze(angles(l, j, [1:startIdx-1, endIdx+1:end]))';

            % Préparation des données pour violinplot
            data = [inClassAngles(:); outClassAngles(:)];
            labels = [repmat("in-class", numel(inClassAngles), 1); repmat("out-class", numel(outClassAngles), 1)];

            % Décalage horizontal artificiel pour chaque segment
            subplot(1, numSegments, j); % Une sous-figure par segment
            violinplot(data, labels);

            % Affichage des moyennes
            hold on;
            yline(mean(inClassAngles), '--g', 'LineWidth', 1.5);
            yline(mean(outClassAngles), '--r', 'LineWidth', 1.5);
            title(sprintf('Segment %d', j));
            hold off;
        end

        % Sauvegarde des figures
        saveFileNameFig = ['figures/angles ' langLabels{l} '.fig'];
        saveFileNameJpg = ['figures/angles ' langLabels{l} '.jpg'];
        saveas(gcf, saveFileNameFig);
        saveas(gcf, saveFileNameJpg);
    end
end

%% ANALYSE DU SEUIL DYNAMIQUE

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

% Optimisation des paramètres du seuil initial et du facteur de testWithThresholdDyn()
function optimizeThresholdFactor(langAM, testingHV, numSamples, SRange, thresholdRange, factorRange)
    arguments
        langAM
        testingHV
        numSamples = 5               % Nombre d'échantillons à tester pour chaque paramètre
        SRange = [200, 2000]         % Taille de la segmentation
        thresholdRange = [0.05, 0.3] % Plage des seuils à tester
        factorRange = [1.1, 2.5]     % Plage des facteurs à tester
    end
    
    % Génération des valeurs pour S, threshold et factor
    SValues = round(linspace(SRange(1), SRange(2), numSamples)); 
    thresholdValues = linspace(thresholdRange(1), thresholdRange(2), numSamples);
    factorValues = linspace(factorRange(1), factorRange(2), numSamples);

    % Stocker les résultats
    results = [];

    % Boucler sur chaque combinaison (S, threshold, factor)
    for sIdx = 1:numSamples
        for tIdx = 1:numSamples
            for fIdx = 1:numSamples

                % Paramètres testés
                currentS = SValues(sIdx);
                currentThreshold = thresholdValues(tIdx);
                currentFactor = factorValues(fIdx);
                fprintf("Test: S = %d, T = %.3f, F = %.2f\n", currentS, currentThreshold, currentFactor);

                % Mesure du temps d'exécution et de la précision
                tic;
                accuracy = testThresholdDyn(langAM, testingHV, currentS, currentThreshold, currentFactor);
                executionTime  = toc;

                % Stockage des résultats dans une structure pour faciliter le traitement
                results = [results; struct(...
                    'S', currentS, ...
                    'Threshold', currentThreshold, ...
                    'Factor', currentFactor, ...
                    'Accuracy', accuracy, ...
                    'Time', executionTime)];

            end
        end
    end

    % Convertir les résultats en matrice pour tracer le graphique 3D
    executionTimes = [results.Time];
    accuracies = [results.Accuracy];
    segmentSizes = [results.S];

    % Graphique : nuage de points 3D de la précision et du temps d'exécution
    figure;
    scatter3(executionTimes, segmentSizes, accuracies, 70, 'filled');
    xlabel('Execution Time (s)');
    ylabel('Segmentation size (bits)');
    zlabel('Accuracy (%)');
    title('Segmentation, Threshold and Factor optimisation');
    grid on;

    % Affichage des valeurs threshold et factor associées aux mesures
    for i = 1:length(results)
            text(executionTimes(i), segmentSizes(i), accuracies(i), ...
            sprintf('\\leftarrow t=%.2f, f=%.2f', results(i).Threshold, results(i).Factor), ...
            'FontSize', 8, 'HorizontalAlignment', 'left');
    end
end