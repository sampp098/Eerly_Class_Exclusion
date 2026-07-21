function message = A2_errByLang
  assignin('base','test_by_language', @test_by_language);
  message='Done importing functions to workspace';
end

% Test de précision pour chaque langue
function global_accuracy = test_by_language(langAM, testingHV)
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

    errorsPerLang = containers.Map(langLabels, num2cell(zeros(1, length(langLabels))));
    totalPerLang = containers.Map(langLabels, num2cell(zeros(1, length(langLabels))));
    
    for i=1: 1: length(testingHV)
        fileName = testingHV{i, 1};
        textHV = testingHV{i, 2};
		actualLabel = fileName(1:2);

        actualLang = langMap(actualLabel);
        totalPerLang(actualLang) = totalPerLang(actualLang) + 1;

		maxAngle = -1;
		for l = 1:1:length(langLabels)
            angle = dot(langAM(langLabels{l}), textHV) / (norm(langAM(langLabels{l}))*norm(textHV));
			if (angle > maxAngle)
				maxAngle = angle;
				predicLang = char (langLabels (l));
			end
		end
		if predicLang == actualLang
			correct = correct + 1;
        else
            errorsPerLang(actualLang) = errorsPerLang(actualLang) + 1;
		end
		total = total + 1;
    end
    
    global_accuracy = correct / total;
    
    % Calcule des erreurs par langue
    errorRates = zeros(1, length(langLabels));
    for i = 1:length(langLabels)
        if totalPerLang(langLabels{i}) > 0
            errorRates(i) = (errorsPerLang(langLabels{i}) / totalPerLang(langLabels{i})) * 100;
        end
    end
    
    % Graphique des erreurs par langue
    figure;
    bar(categorical(langLabels), errorRates);
    xlabel('Language');
    ylabel('Error rate (%)');
    title('Error rate by language');
    grid on;
end