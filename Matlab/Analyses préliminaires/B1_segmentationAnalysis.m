function message = B1_segmentationAnalysis
  assignin('base','testSegmentation', @testSegmentation);
  assignin('base','testSegmentationSize', @testSegmentationSize);
  assignin('base','testSegmentationSizeByLanguage', @testSegmentationSizeByLanguage);
  assignin('base','testSegmentPosition', @testSegmentOrigin);
  assignin('base','cosAngle', @cosAngle);
  assignin('base','testSegmentPosition', @testSegmentOrigin);
  assignin('base','testSegmentRandomPosition', @testSegmentRandomOrigin);
  assignin('base','testSegmentPositionByLanguage', @testSegmentPositionByLanguage);
  message='Done importing functions to workspace';
end

%% ANALYSE DE LA SEGMENTATION

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

% Analyse de la segmentation sur la précision et temps d'exécution
function testSegmentationSize(langAM, testingHV, R)
    % Taille des HV
    D = length(testingHV{1, 2}); 

    % Génération de R valeurs de S de manière logarithmique
    S_values = round(logspace(1, log10(D), R));
    
    % Initialisation des tableaux pour stocker la précision et le temps
    accuracy_values = zeros(1, R);
    time_values = zeros(1, R);
    
    % Boucler pour chaque segmentation S
    for i = 1:R
        S = S_values(i);
        fprintf('Test %d/%d : S = %d\n', i, R, S);
        
        % Mesure de la précision et du temps d'exécution
        statsWithSegmentation = testSegmentation(langAM, testingHV, S);
        fprintf('Accuracy is %f.\n\n', statsWithSegmentation.accuracy);
        
        % Stockage des résultats
        accuracy_values(i) = statsWithSegmentation.accuracy * 100;
        time_values(i) = statsWithSegmentation.executionTime;
    end
    
    % Conversion en pourcentage
    S_percent = (S_values / D) * 100;
    time_values = time_values * 100 / time_values(end);

    % Graphique : précision en fonction de S
    figure;
    plot(S_percent, accuracy_values, '-o', 'LineWidth', 2);
    xlabel('Value of S (%)');
    ylabel('Accuracy (%)');
    title('Impact of segmentation on accuracy');
    grid on;
    
    % Graphique : temps d'exécution en fonction de S
    figure;
    plot(S_percent, time_values, '-o', 'LineWidth', 2);
    xlabel('Value of S (%)');
    ylabel('Execution time (%)');
    title('Impact of segmentation on execution time');
    grid on;
end

% Analyse de la segmentation sur la précision en fonction de la langue
function testSegmentationSizeByLanguage(langAM, testingHV, R)

    % Taille des HV
    D = length(testingHV{1, 2});
    
    % Génération de R valeurs de S de manière logarithmique
    S_values = round(logspace(1, log10(D), R));
    S_percent = (S_values / D) * 100;
    
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
    numLangs = length(langLabels);
    
    % Initialisation des tableaux pour stocker la précision par langue
    accuracy_per_lang = zeros(numLangs, R);
    S_90_percent = zeros(1, numLangs);

    % Boucler pour chaque langue
    for l = 1:numLangs
        analysisLang = langLabels{l};
        fprintf('Analyse de la langue : %s (%d/%d)\n', analysisLang, l, numLangs);
        
        % Filtrer les vecteurs de test de la langue analysée
        langVectors = {};
        for i = 1:size(testingHV, 1)
            % Extraire le code langue
            fileName = testingHV{i, 1};
            actualLabel = fileName(1:2);

             % Vérifier si la langue correspond
            if analysisLang == langMap(actualLabel)
                langVectors{end + 1, 1} = testingHV{i, 1};
                langVectors{end, 2} = testingHV{i, 2};
            end
        end

        % Boucler pour chaque segmentation S par langue
        for j = 1:R
            S = S_values(j);
            correct = 0;
            total = length(langVectors);
            
            % Boucler pour chaque vecteur de test de la langue cible
            for i=1: 1: total
                textHV = langVectors{i, 2};
                
                % Segmentation du HV de requête
                segmentTextHV = textHV(1:S);

                % Prédiction de la langue avec segmentation S
		        maxAngle = -1;
                for k = 1:1:length(langLabels)

                    % Segmentation de la langue en cours
                    actualLang = langAM(char(langLabels (k)));
                    segmentActualLang = actualLang(1:S);
        
                    % Calcul de l'angle
                    angle = dot(segmentActualLang, segmentTextHV) / (norm(segmentActualLang) * norm(segmentTextHV));

			        if (angle > maxAngle)
				        maxAngle = angle;
				        predicLang = char (langLabels (k));
			        end
                end

                % Vérification si la prédiction est correcte
		        if predicLang == analysisLang
			        correct = correct + 1;
		        end
            end

            % Calcul de la précision par langue par segmentation S
            accuracy_per_lang(l, j) = correct / total;   
        end
        
        % Valeur minimale de S pour avoir 90 % de la précision finale
        maxAccuracy = max(accuracy_per_lang(l, :));
        targetAccuracy = 0.9 * maxAccuracy;

        % Première valeur de S atteignant cette précision
        idx = find(accuracy_per_lang(l, :) >= targetAccuracy, 1, 'first');
        if ~isempty(idx)
            S_90_percent(l) = S_percent(idx);
        end
    end
    
    % Graphique : précision en fonction de S pour chaque langue
    figure;
    hold on;
    for i = 1:numLangs
        plot(S_percent, accuracy_per_lang(i, :) * 100, 'LineWidth', 2, 'DisplayName', langLabels{i});
    end
    hold off;
    xlabel('Value of S (%)');
    ylabel('Accuracy (%)');
    title('Accuracy as a function of segmentation for each language');
    legend('Location', 'southeast');
    grid on;
    
    % Graphique : S minimal pour atteindre 90 % de la précision finale de chaque langue
    figure;
    bar(categorical(langLabels), S_90_percent);
    xlabel('Language');
    ylabel('Value of S (%)');
    title('Segmentation required to achieve 90% of final accuracy');
    grid on;
end

%% ÉTUDE DE L'ORIGINE DES SEGMENTS (depuis MSB, MID, LSB, RDM)

% Mesure de similarité entre deux hypervecteurs
function cosAngle = cosAngle (u, v, S, mode, seg)
    arguments % Valeurs par défaut
        u
        v
        S = length(u)
        mode = 'MSB'
        seg = 1
    end

    if length(u) ~= length(v) % Vérifie si les vecteurs d'entrée sont de mêmes tailles
        error('La taille des vecteurs à tester doit être de même dimension')
    elseif S > length(u) % Vérifie que S ne soit pas plus grande que les HV d'entrées
        S = length(u);
        fprintf('La segmentation S dépasse la longueur des HV, S forcée à %d bits', length(u));
    end

    switch mode
        case 'MSB' % Depuis le début (MSB)
            cosAngle = dot(u(1:S), v(1:S)) / (norm(u(1:S)) * norm(v(1:S)));

        case 'MID' % Depuis le milieu (MID)
            midPoint = floor(length(u) / 2);
            startIdx = max(1, midPoint - floor(S / 2));
            endIdx = min(length(u), startIdx + S - 1);
            cosAngle = dot(u(startIdx:endIdx), v(startIdx:endIdx)) / (norm(u(startIdx:endIdx)) * norm(v(startIdx:endIdx)));

        case 'LSB' % Depuis la fin (LSB)
            cosAngle = dot(u(end - S + 1:end), v(end - S + 1:end)) / (norm(u(end - S + 1:end)) * norm(v(end - S + 1:end)));

        case 'RDM' % Aléatoire (RDM)
            randomIdx = randperm(length(u), S);
            cosAngle = dot(u(randomIdx), v(randomIdx)) / (norm(u(randomIdx)) * norm(v(randomIdx)));
 
        case 'SEG' % Par segmentation
            segmentStart = (seg - 1) * S + 1;
            segmentEnd = seg * S;
            cosAngle = dot(u(segmentStart:segmentEnd), v(segmentStart:segmentEnd)) / (norm(u(segmentStart:segmentEnd)) * norm(v(segmentStart:segmentEnd)));

         otherwise
            error('Mode non reconnu : %s', mode);
    end
end

% Analyse localisée de la pertinence de l'information dans un HV
function testSegmentOrigin(langAM, testingHV, R)
    % Taille des HV
    D = length(testingHV{1, 2});
    
    % Génération de R valeurs de S de manière logarithmique
    S_values = round(logspace(1, log10(D), R));
    S_percent = (S_values / D) * 100;

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
    
    % Initialisation des tableaux pour stocker la précision
    accuracy_MSB = zeros(1, R);   % Depuis le début (MSB)
    accuracy_MID = zeros(1, R);   % Depuis le milieu (MIB)
    accuracy_LSB = zeros(1, R);   % Depuis la fin (LSB)
    
    % Boucler pour chaque segmentation S
    for j = 1:R
        S = S_values(j);
        fprintf('Test %d/%d : S = %d\n', j, R, S);

        % Calcule de la précision pour chaque approche
        correct = zeros(1, 3); % [1]=MSB, [2]=MID, [3]=LSB
        total = length(testingHV);
        
        % Boucler pour chaque vecteur de test
        for i=1: 1: total
            fileName = testingHV{i, 1};
            textHV = testingHV{i, 2};
		    actualLabel = fileName(1:2);

            % Prédiction de la langue avec segmentation S
	        maxAngle = [-1,-1,-1];
            predicLang = {'000','000','000'};
            for k = 1:1:length(langLabels)
                % Calcul de l'angle pour les différentes positions de S
		        angle(1) = cosAngle(langAM (char(langLabels (k))), textHV, S, 'MSB');
		        angle(2) = cosAngle(langAM (char(langLabels (k))), textHV, S, 'MID');
		        angle(3) = cosAngle(langAM (char(langLabels (k))), textHV, S, 'LSB');
                for l = 1:3
                    if (angle(l) > maxAngle(l))
			            maxAngle(l) = angle(l);
			            predicLang{l} = char (langLabels (k));
                    end
                end
            end
            
            % Vérification si la prédiction est correcte
            for l = 1:3
                if predicLang{l} == langMap(actualLabel)
		            correct(l) = correct(l) + 1;
                end
            end
        end

        % Calcul de la précision par localisation par segmentation S
        accuracy_MSB(j) = correct(1) / total;
        accuracy_MID(j) = correct(2) / total;
        accuracy_LSB(j) = correct(3) / total;
    end
    
    % Graphique : comparaison de la précision selon l'emplacement de S
    figure;
    hold on;
    plot(S_percent, accuracy_MSB * 100, '-o', 'LineWidth', 2, 'DisplayName', 'From MSB');
    plot(S_percent, accuracy_MID * 100, '-x', 'LineWidth', 2, 'DisplayName', 'From MID');
    plot(S_percent, accuracy_LSB * 100, '-s', 'LineWidth', 2, 'DisplayName', 'From LSB');
    hold off;
    xlabel('Value of S (%)');
    ylabel('Accuracy (%)');
    title('Comparison of accuracy depending on the position of S');
    legend('Location', 'southeast');
    grid on;
end

% Analyse aléatoire de la pertinence de l'information dans un HV
function testSegmentRandomOrigin(langAM, testingHV, R)
    % Taille des HV
    D = length(testingHV{1, 2});

    % Nombre d'essais pour la segmentation aléatoire
    nRDM = 5;

    % Génération de R valeurs de S de manière logarithmique
    S_values = round(logspace(1, log10(D), R));
    S_percent = (S_values / D) * 100;

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
    
    % Initialisation des tableaux pour stocker la précision
    accuracy_MSB = zeros(1, R);    % Sert de référence
    accuracy_RDM = zeros(nRDM, R); % Stocke les N essais aléatoires
    
    % Boucler pour chaque segmentation S
    for j = 1:R
        S = S_values(j);
        fprintf('Test %d/%d : S = %d\n', j, R, S);

        % Calcule de la précision pour chaque approche
        correct = zeros(1, 1 + nRDM); % [1]=MSB, [2:nRDM]=RDM
        total = length(testingHV);
        
        % Boucler pour chaque vecteur de test
        for i=1: 1: total
            fileName = testingHV{i, 1};
            textHV = testingHV{i, 2};
		    actualLabel = fileName(1:2);

            % Prédiction de la langue avec segmentation S
	        maxAngle = -1 * ones(1, 1 + nRDM);
            predicLang = repmat({'000'}, 1, 1 + nRDM);
	        angle = zeros(1, 1 + nRDM);
            for k = 1:1:length(langLabels)
                % Calcul de l'angle pour les différentes positions de S
		        angle(1) = cosAngle(langAM (char(langLabels (k))), textHV, S, 'MSB');
                for t = 1:nRDM
                     angle(1 + t) = cosAngle(langAM (char(langLabels (k))), textHV, S, 'RDM');
                end
                
                for l = 1:(1 + nRDM)
                    if (angle(l) > maxAngle(l))
			            maxAngle(l) = angle(l);
			            predicLang{l} = char (langLabels (k));
                    end
                end
            end
            
            % Vérification si la prédiction est correcte
            for l = 1:(1 + nRDM)
                if predicLang{l} == langMap(actualLabel)
		            correct(l) = correct(l) + 1;
                end
            end
        end

        % Calcul de la précision par segmentation S
        accuracy_MSB(j) = correct(1) / total;
        for i = 1:nRDM
            accuracy_RDM(i,j) = correct(1 + i) / total;
        end
    end

    % Calcul de la moyenne des nRDM mesures aléatoires
    mean_accuracy_RDM = mean(accuracy_RDM, 1);
    
    % Graphique : comparaison de la précision selon une segmenation aléatoire
    figure;
    hold on;
    plot(S_percent, accuracy_MSB * 100, '-o', 'LineWidth', 2, 'Color', 'b', 'DisplayName', 'From MSB (Reference)');
    for i = 1:nRDM
        plot(S_percent, accuracy_RDM(i, :) * 100, '--', 'LineWidth', 1, 'Color', [0.7, 0.7, 0.7]);
    end
    plot(S_percent, mean_accuracy_RDM * 100, '-s', 'LineWidth', 2, 'Color', 'r', 'DisplayName', 'Random average');
    hold off;
    xlabel('Value of S (%)');
    ylabel('Accuracy (%)');
    title('Comparison of accuracy according to random segmentation');
    legend('Location', 'southeast');
    grid on;
end

%% ÉTUDE DE LA POSITION DES SEGMENTS

% Analyse de la position des segments par langue
function testSegmentPositionByLanguage(langAM, testingHV, S)
    arguments
        langAM
        testingHV
        S = 1000
    end

    % Taille des HV
    D = length(testingHV{1, 2});
    
    % Nombre de segments par hypervecteur
    numSegments = floor(D / S);
    
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
    numLangs = length(langLabels);

    % Initialisation des tableaux pour stocker la précision par langue
    accuracy_per_lang = zeros(numLangs, numSegments);

    % Boucler pour chaque langue
    for l = 1:numLangs
        analysisLang = langLabels{l};
        fprintf('Analyse de la langue : %s (%d/%d)\n', analysisLang, l, numLangs);
        
        % Filtrer les vecteurs de test de la langue analysée
        langVectors = {};
        for i = 1:size(testingHV, 1)
            % Extraire le code langue
            fileName = testingHV{i, 1};
            actualLabel = fileName(1:2);

             % Vérifier si la langue correspond
            if analysisLang == langMap(actualLabel)
                langVectors{end + 1, 1} = testingHV{i, 1};
                langVectors{end, 2} = testingHV{i, 2};
            end
        end

        % Nombre de vecteurs par langue
        total = length(langVectors);

        % Boucler pour chaque segmentation S par langue
        for j = 1:numSegments
            correct = 0;
            
            % Boucler pour chaque vecteur de test de la langue cible
            for i=1: 1: total
                textHV = langVectors{i, 2};
                
                % Prédiction de la langue avec segmentation S
	            maxAngle = -1;
                for k = 1:1:length(langLabels)
		            angle = cosAngle(langAM (char(langLabels (k))), textHV, S, 'SEG', j);

		            if (angle > maxAngle)
			            maxAngle = angle;
			            predicLang = char (langLabels (k));
		            end
                end
    
                % Vérification si la prédiction est correcte
	            if predicLang == analysisLang
		            correct = correct + 1;
	            end
            end
    
            % Calcul de la précision par langue par segmentation S
            if total == 0   % Évite une division par 0 pour la précision par langue
                accuracy_per_lang(l, j) = 1;
            else
                accuracy_per_lang(l, j) = correct / total;
            end 
        end
    end

    % Calcul de la précision moyenne par segment
    global_accuracy = mean(accuracy_per_lang(:,:));
    fprintf('Précision globale = %f\n', mean(global_accuracy));

    % Graphique : précision en fonction des segments par langue
    figure;
    hold on;
    for i = 1:numLangs
        plot(1:numSegments, accuracy_per_lang(i, :) * 100, '.-', 'MarkerSize', 20, 'LineWidth', 1, 'DisplayName', langLabels{i});
    end
    plot(1:numSegments, global_accuracy * 100, '-o', 'LineWidth', 2, 'Color', 'k', 'DisplayName', 'Global accuracy');
    hold off;
    xlabel('Segment number');
    ylabel('Accuracy (%)');
    title(sprintf('Accuracy by segment by language (S = %d bits)', S));
    legend('show');
    ylim([0, 100]);
    grid on;
end
