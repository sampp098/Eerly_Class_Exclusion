function message = A3_nbrCharTraining
  assignin('base','genRandomHV',@genRandomHV);
  assignin('base','lookupItemMemeory',@lookupItemMemeory);
  assignin('base','cosAngle',@cosAngle);
  assignin('base','computeSumHV', @computeSumHV);
  assignin('base','binarizeHV', @binarizeHV);
  assignin('base','buildLanguageHV', @buildLanguageHV);
  assignin('base','buildTestingHV', @buildTestingHV);
  assignin('base','test', @test);
  assignin('base','analyzeMaxCharsImpact', @analyzeMaxCharsImpact);
  assignin('base','accuracyBySegmentByLanguage', @accuracyBySegmentByLanguage);
  message='Done importing functions to workspace';
end

% Création de représentations aléatoires des caractères dans la phase d'entraînement
function randomHV = genRandomHV(D)
    if mod(D,2)
        disp ('Dimension is odd!!');
    else
        randomIndex = randperm (D);
        randomHV (randomIndex(1 : D/2)) = 1;
        randomHV (randomIndex(D/2+1 : D)) = -1;
    end
end

% Associe un vecteur hyperdimensionnel unique à chaque caractère du texte
function [itemMemory, randomHV] = lookupItemMemeory(itemMemory, key, D)
    if itemMemory.isKey (key) 
        randomHV = itemMemory (key);
    else
        itemMemory(key) = genRandomHV (D);
        randomHV = itemMemory (key);
    end
end

% Mesure de similarité entre deux hypervecteurs
function cosAngle = cosAngle (u, v)
     cosAngle = dot(u,v)/(norm(u)*norm(v));
end

% Génère un vecteur hyperdimensionnel représentant un texte
function [itemMemory, sumHV] = computeSumHV (buffer, itemMemory, N, D)
    %init
    block = zeros (N,D);
    sumHV = zeros (1,D);
    
    for numItems =1:1:length(buffer)
        %read a key
        key = buffer(numItems);

        %shift read vectors
        block = circshift (block, [1,1]);
        [itemMemory, block(1,:)] = lookupItemMemeory (itemMemory, key, D); 

        if numItems >= N
            nGrams = block(1,:);
            for i = 2:1:N
                nGrams = nGrams .* block(i,:); %element-wise multiplication
            end
            sumHV = sumHV + nGrams;
        end
    end
    
end

% Convertit un vecteur v en valeurs binaires +1 ou 0 selon un seuil nul
function v = binarizeHV (v)
	threshold = 0;
	for i = 1 : 1 : length (v)
		if v (i) > threshold
			v (i) = 1;
		else
			v (i) = 0;
		end
	end
end

%% ENTRAÎNEMENT DU MODÈLE EN FONCTION DE MAXCHAR

% Entraîne le modèle en construisant des vecteurs de langue
function [iM, langAM] = buildLanguageHV (N, D, maxChars)
    arguments
        N
        D
        maxChars = 30000 % Max = 1500000
    end

    iM = containers.Map;
    langAM = containers.Map;
    langLabels = {'afr', 'bul', 'ces', 'dan', 'nld', 'deu', 'eng', 'est', 'fin', 'fra', 'ell', 'hun', 'ita', 'lav', 'lit', 'pol', 'por', 'ron', 'slk', 'slv', 'spa', 'swe'};
    
    for i = 1:1:length(langLabels)
        fileAddress = strcat('/training_texts/', langLabels (i),'.txt');
        fileID = fopen (char(fileAddress), 'r');
        buffer = fscanf (fileID,'%c');
        fclose (fileID);
        %fprintf('Loaded traning language file %s\n',char(fileAddress)); 
        
        % Limite la lecture des fichiers d'apprentissage
        if length(buffer) > maxChars
            buffer = buffer(1:maxChars);
            lastSpace = find(buffer == ' ', 1, 'last');
            buffer = buffer(1:lastSpace);
        end

        [iM, langHV] = computeSumHV (buffer, iM, N, D);
        langAM (char(langLabels (i))) = langHV;
    end        
end

%% ENCODAGE DES HYPERVECTEURS DE TEST

% Création des textHV de test
function testingHV = buildTestingHV (iM, N, D)
	fileList = dir ('/testing_texts/*.txt');
    testingHV = cell(length(fileList),2);
    for i=1: 1: length(fileList)
		fileAddress = strcat('/testing_texts/', fileList(i).name);
		fileID = fopen (char(fileAddress), 'r');
		buffer = fscanf (fileID, '%c');
		fclose (fileID);
		%fprintf ('Loaded testing text file %s\n', char(fileAddress)); 
        
		[iMn, textHV] = computeSumHV (buffer, iM, N, D);
		textHVBin = binarizeHV (textHV);
        if iM ~= iMn
			fprintf ('\n>>>>>   NEW UNSEEN ITEM IN TEST FILE   <<<<\n');
			exit;
        end

        testingHV{i, 1} = fileList(i).name;
        testingHV{i, 2} = textHVBin;
    end
end

%% TEST DE PRÉCISION

% Test de précision classique (baseline A)
function accuracy = test (langAM, testingHV)
	total = 0;
	correct = 0;
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

    for i=1: 1: length(testingHV)
        fileName = testingHV{i, 1};
        textHV = testingHV{i, 2};
		actualLabel = fileName(1:2);
		maxAngle = -1;
		for l = 1:1:length(langLabels)
			angle = cosAngle(langAM (char(langLabels (l))), textHV);
			if (angle > maxAngle)
				maxAngle = angle;
				predicLang = char (langLabels (l));
			end
		end
		if predicLang == langMap(actualLabel)
			correct = correct + 1;
        else
            %fprintf ('%s --> %s\n', langMap(actualLabel), predicLang);
		end
		total = total + 1;
    end
    accuracy = correct / total;
end

%% ANALYSE DE L'IMPACT DE MAXCHAR

% Analyse de la précision et du temps d'exécution en fonction du nombre de caractères d'entraînement d'entrée
function analyzeMaxCharsImpact(N, D, X)
    arguments
        N = 4
        D = 10000
        X = 15
    end

    % Génération de X valeurs de maxChars de manière logarithmique
    maxCharsList = round(logspace(log10(1e2), log10(1e5), X));
    
    % Initialisation des tableaux pour stocker la précision et les temps
    accuracies = zeros(1, X);
    times_step = zeros(3, X);
    
    % Boucler pour chaque valeur de maxChars
    for i = 1:X
        maxChars = maxCharsList(i);
        fprintf('Nombre de caractère d entraînement utilisé = %d (%d/%d)\n', maxChars, i, X);
        
        % Etape 1 : Phase d'entraînement
        tic; % Début chrono
        [iM, langAM] = buildLanguageHV(N, D, maxChars);
        times_step(1,i) = toc; % Fin chrono
        fprintf('  1/3 : Entraînement fini\n');
        
        % Etape 2 : Création des hypervecteurs de test
        tic; % Début chrono
        testingHV = buildTestingHV (iM, N, D);
        times_step(2,i) = toc; % Fin chrono
        fprintf('  2/3 : Création des hypervecteurs de test fini\n');

        % Etape 3 : Test de similarité
        tic; % Début chrono
        accuracy = test(langAM, testingHV);
        times_step(3,i) = toc; % Fin chrono
        accuracies(i) = accuracy * 100;
        fprintf('  3/3 : Test de similarité fini\n');
    end
    
    % Pourcentage des temps d'exécution
    max_times_step = zeros(1,3);
    for i = 1:3
        max_times_step(i) = max(times_step(i, :));
        times_step(i, :) = times_step(i, :) * 100 / max_times_step(i);
    end

    % Graphique : précision en fonction de maxChars
    figure;
    plot(maxCharsList, accuracies, '-o', 'LineWidth', 2);
    text(1e4, 1, ['Maximum accuracy = ', num2str(max(accuracies), '%.2f'), '%'], 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'FontSize', 12, 'Color', 'r');
    xlabel('Number of training characters used');
    ylabel('Accuracy (%)');
    title('Accuracy as a function of the number of training characters');
    ylim([0, 100]);
    grid on;
    
    % Graphique : temps d'exécution en fonction de maxChars
    figure;
    for i = 1:3
        subplot(1,3,i);
        plot(maxCharsList, times_step(i,:), '-s', 'LineWidth', 2);
        text(1e5, 1, ['Maximum time = ', num2str(max_times_step(i), '%.2f'), 's'], 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'FontSize', 12, 'Color', 'r');
        xlabel('Number of training characters used');
        ylabel('Execution time (%)');
        title(['Time execution of step ' num2str(i)]);
        ylim([0, 100]);
        grid on;
    end
end