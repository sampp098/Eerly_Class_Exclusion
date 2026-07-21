function message = A1_buildingModele
  assignin('base','genRandomHV',@genRandomHV);
  assignin('base','lookupItemMemeory',@lookupItemMemeory);
  assignin('base','cosAngle',@cosAngle);
  assignin('base','computeSumHV', @computeSumHV);
  assignin('base','binarizeHV', @binarizeHV);
  assignin('base','buildLanguageHV', @buildLanguageHV);
  assignin('base','buildListTextHV', @buildTestingHV);
  assignin('base','test', @test);
  message='Done importing functions to workspace';
end

% 1ère étape : Entraînement du modèle
%   [iM, langAM] = buildLanguageHV (N, D)
% 
% 2ème étape : Encodage des hypervecteurs de test
%   testingHV = buildListTextHV (iM, N, D)
%
% 3ème étape : Test de similarité
%   accuracy = test(langAM, testingHV)


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

%% ENTRAÎNEMENT DU MODÈLE

% Entraîne le modèle en construisant des vecteurs de langue
function [iM, langAM] = buildLanguageHV (N, D) 
    iM = containers.Map;
    langAM = containers.Map;
    langLabels = {'afr', 'bul', 'ces', 'dan', 'nld', 'deu', 'eng', 'est', 'fin', 'fra', 'ell', 'hun', 'ita', 'lav', 'lit', 'pol', 'por', 'ron', 'slk', 'slv', 'spa', 'swe'};
    
    for i = 1:1:length(langLabels)
        fileAddress = strcat('/training_texts/', langLabels (i),'.txt');
        fileID = fopen (char(fileAddress), 'r');
        buffer = fscanf (fileID,'%c');
        fclose (fileID);
        fprintf('Loaded traning language file %s\n',char(fileAddress)); 
        
        [iM, langHV] = computeSumHV (buffer, iM, N, D);
        langHVBin = binarizeHV (langHV);
        langAM (char(langLabels (i))) = langHVBin;
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