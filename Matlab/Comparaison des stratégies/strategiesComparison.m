function message = strategiesComparison
  assignin('base','tb_PE',@tb_PE);
  assignin('base','tb_PU',@tb_PU);
  assignin('base','log2c',@log2c);
  assignin('base','next_power_of_two',@next_power_of_two);
  assignin('base','XOR_slice',@XOR_slice);
  assignin('base','PSUM',@PSUM);
  assignin('base','ACC',@ACC);
  assignin('base','HD_PE',@HD_PE);
  assignin('base','findMax',@findMax);
  assignin('base','PU',@PU);
  assignin('base','testPUsimu',@testPUsimu);
  assignin('base','testBaselineA',@testBaselineA);
  assignin('base','compare_similarity_tests',@compare_similarity_tests);
  assignin('base','plot_similarity_results_multi',@plot_similarity_results_multi);
  assignin('base','plot_similarity_results',@plot_similarity_results);
  assignin('base','omen_inference',@omen_inference);
  message='Done importing functions to workspace';
end

%% TESTBENCH

% Testbench du HD_PE
function tb_PE()
    VECTOR_WIDTH = 128;
    SLICE_WIDTH = 32;
    NBR_ACC = 4;
    
    % Exemple : deux tranches aléatoires
    BHV = randi([0 1], 1, VECTOR_WIDTH);
    QHV = randi([0 1], 1, VECTOR_WIDTH);
    HamDist = zeros(4, 1);
    
    % Initialisation
    PE_active_input = 1;
    acc_reg = 0;

    % Reset
    [~, acc_reg] = HD_PE(PE_active_input, BHV(1:SLICE_WIDTH), QHV(1:SLICE_WIDTH), SLICE_WIDTH, acc_reg);

    % Activation
    for i = 1 : NBR_ACC
        [HamDist(i), acc_reg] = HD_PE(PE_active_input, BHV((i - 1) * SLICE_WIDTH + 1 : i * SLICE_WIDTH), QHV((i - 1) * SLICE_WIDTH + 1 : i * SLICE_WIDTH), SLICE_WIDTH, acc_reg);
    end

    % Affichage des résultats
    for i = 1 : NBR_ACC
        fprintf ('Distance de Hamming acc%d : %d\n', i, HamDist(i));
    end
end

% Testbench du PU class_vectors, query_vectors, query_labels
function stats = tb_PU(class_vectors, query_vectors, query_labels, d)

    % Paramètres génériques
    NBR_CLASS = size(class_vectors, 1);
    SLICE_WIDTH = 32;

    VECTOR_WIDTH = size(class_vectors, 2);
    NBR_SEG = VECTOR_WIDTH / d;
    assert(NBR_CLASS <= NBR_SEG - 1, 'Erreur : Taille des segments insufisants');

    % Variables de simulation
    correct = 0;
    total = size(query_vectors, 1); % Nombre de requêtes
    
    % Statistiques de simulation
    stats = struct(...
        'width', ['d=', num2str(d), ', l=', num2str(SLICE_WIDTH)], ...
        'samplesData', ['nbrQuery=', num2str(total), ', nbrClass=', num2str(NBR_CLASS)], ...
        'accuracy', -1, ...
        'PECalls', 0, ...
        'findMaxCalls', 0);

    % Information sur la progression
    progress_interval = 10; % (en %)
    next_progress = progress_interval;
    tic;

    % Préparation des hypervecteurs de base
    BHV = class_vectors;

    % Lancement de la simulation
    for QHV_idx = 1 : total

        % Préparation de l'hypervecteur requête
        QHV = query_vectors(QHV_idx, :);

        % Traitement de l'hypervecteur requête
        [PU_predicted_class_idx_output, stats] = PU(BHV, QHV, NBR_CLASS, SLICE_WIDTH, d, stats);

        % Vérification de la prédiction
		actualLabel = query_labels(QHV_idx);
        if PU_predicted_class_idx_output - 1 == actualLabel
            correct = correct + 1;
            %fprintf('idx=%5d,\tPrédit=%2d,\tOK\n', QHV_idx, PU_predicted_class_idx_output - 1);
        else
            %fprintf('idx=%5d,\tPrédit=%2d,\tCorrect=%2d\n', QHV_idx, PU_predicted_class_idx_output - 1, actualLabel);
        end

        % Affichage de la progression
        progress_percent = (QHV_idx / total) * 100;
        if progress_percent >= next_progress
            elapsed_time = toc;
            estimated_remaining = elapsed_time * (100 / next_progress - 1);
            fprintf('[%3.0f%% QHVs processed] - Time remaining : %.1fs (Elapsed time : %.1fs)\n', ...
                    next_progress, estimated_remaining, elapsed_time);
            next_progress = next_progress + progress_interval;
        end

    end

    % Calcul de la précision
    stats.accuracy = correct / total;

    toc
end

%% PACKAGE

% Fonction log2c (pour calculer la taille en bit d'un nombre)
function res = log2c(n)
    res = 0;
    val = n;
    while val > 0
        res = res + 1;
        val = floor(val / 2);
    end
end

% Fonction (pour calculer la plus petite puissance de 2 supérieure ou égale d'un nombre)
function res = next_power_of_two(n)
    res = 1;
    while res < n
        res = res * 2;
    end
end

%% COMPOSANTS

% Composant XOR_slice
function XOR_slice_output = XOR_slice(XOR_slice_input_1, XOR_slice_input_2, SLICE_WIDTH)

    % Vérification de la taille des vecteurs d'entrée
    assert(length(XOR_slice_input_1) == SLICE_WIDTH, 'Erreur : Taille incorrecte (XOR_slice/XOR_slice_input_1)');
    assert(length(XOR_slice_input_2) == SLICE_WIDTH, 'Erreur : Taille incorrecte (XOR_slice/XOR_slice_input_2)');
   
    % XOR des vecteurs d'entrées
    XOR_slice_output = xor(XOR_slice_input_1, XOR_slice_input_2);
end

% Composant PSUM
function PSUM_sum_output = PSUM(PSUM_slice_input, SLICE_WIDTH)
    
    % Vérification de la taille du vecteur d'entrée
    assert(length(PSUM_slice_input) == SLICE_WIDTH, 'Erreur : Taille incorrecte (PSUM/PSUM_slice_input)');
   
    % Stockage des données entre les étages
    data_between_stages = cell(log2c(SLICE_WIDTH), 1);

    % Premier étage (entrée)
    data_between_stages{1} = PSUM_slice_input;

    % Entre les étages
    for s = 2 : log2c(SLICE_WIDTH)
        for i = 1 : SLICE_WIDTH / (2 ^ (s - 1))
            data_between_stages{s}(i) = data_between_stages{s - 1}(2 * i - 1) + data_between_stages{s - 1}(2 * i);

        end
    end

    % Dernier étage (sortie)
    PSUM_sum_output = data_between_stages{log2c(SLICE_WIDTH)}(1);
end

% Composant ACC
function [ACC_HamDist_output, acc_reg] = ACC(ACC_sum_input, acc_reg)

    acc_reg = acc_reg + ACC_sum_input;
    ACC_HamDist_output = acc_reg;
end

% Composant HD_PE
function [PE_HamDist_output, acc_reg, stats] = HD_PE(...
    PE_slice_input_BHV, PE_slice_input_QHV, ...
    SLICE_WIDTH, acc_reg, ...
    stats)

    % Liaisons entre les composants
    slice_xor = XOR_slice(PE_slice_input_BHV, PE_slice_input_QHV, SLICE_WIDTH);
    sum = PSUM(slice_xor, SLICE_WIDTH);
    [PE_HamDist_output, acc_reg] = ACC(sum, acc_reg);

    % Incrémentation du nombre d'appel au PE
    stats.PECalls = stats.PECalls + 1;
end

% Composant findMax
function [findmax_maxIdx_output, stats] = findMax(findmax_active_input, findmax_data_input, NBR_CLASS_NEXT_POW2, stats)
       
    % Stockage des données entre les étages
    data_between_stages = cell(log2c(NBR_CLASS_NEXT_POW2), 1);
    idx_between_stages = cell(log2c(NBR_CLASS_NEXT_POW2), 1);
    active_between_stages = cell(log2c(NBR_CLASS_NEXT_POW2), 1);

    % Premier étage (entrée)
    data_between_stages{1} = findmax_data_input;
    idx_between_stages{1} = 1:NBR_CLASS_NEXT_POW2;
    active_between_stages{1} = findmax_active_input;

    % Entre les étages
    for s = 2 : log2c(NBR_CLASS_NEXT_POW2)
        for i = 1 : NBR_CLASS_NEXT_POW2 / (2 ^ (s - 1))

            % Sélecteur et comparaison
            if active_between_stages{s - 1}(2 * i) && ~active_between_stages{s - 1}(2 * i - 1)
                sel = 1;

            elseif ~active_between_stages{s - 1}(2 * i)
                sel = 0;

            elseif data_between_stages{s - 1}(2 * i) > data_between_stages{s - 1}(2 * i - 1)
                sel = 1;
            
            else
                sel = 0;

            end

            % Attribution pour le prochain étage
            if sel
                data_between_stages{s}(i) = data_between_stages{s - 1}(2 * i);
                idx_between_stages{s}(i) = idx_between_stages{s - 1}(2 * i);

            else
                data_between_stages{s}(i) = data_between_stages{s - 1}(2 * i - 1);
                idx_between_stages{s}(i) = idx_between_stages{s - 1}(2 * i - 1);
            end

            active_between_stages{s}(i) = active_between_stages{s - 1}(2 * i - 1) || active_between_stages{s - 1}(2 * i);
       end
    end

    % Dernier étage (sortie)
    findmax_maxIdx_output = idx_between_stages{s}(1);

    % Incrémentation du nombre d'appel au findMax
    stats.findMaxCalls = stats.findMaxCalls + 1;
end

% Composant PU
function [PU_predicted_class_idx_output, stats] = PU(BHV, QHV, ...
    NBR_CLASS, SLICE_WIDTH, SEGMENT_WIDTH, ...
    stats)

    % Constantes
    NBR_CLASS_NEXT_POW2 = next_power_of_two(NBR_CLASS);
    NBR_ACC = SEGMENT_WIDTH / SLICE_WIDTH;

    % États de la machine d'état
    IDLE = 0; ACCUMULATION = 1; DESACTIVATE = 2;

    % Initialisation du PU
    state = IDLE;
    ready = 0;


    while ~ready
        switch state

            %IDLE
            case IDLE
                % Initialisation
                slice_idx = 1;
                segment_idx = 1;
                active_classes = zeros(1, NBR_CLASS_NEXT_POW2);
                active_classes(1:NBR_CLASS) = 1;
                state = ACCUMULATION;

                % Liaisons entre les composants
                acc_array = zeros(1, NBR_CLASS_NEXT_POW2);
                findmax_data = zeros(1, NBR_CLASS_NEXT_POW2);

            % ACCUMULATION
            case ACCUMULATION
                if slice_idx == NBR_ACC + 1
                    state = DESACTIVATE;

                else
                    % En partant du LSB (conformément au VHDL), pour D=10000
                    addr_slice = (NBR_ACC * (segment_idx - 1) + slice_idx);
                    segmentStart = 10001 - (addr_slice * SLICE_WIDTH);
                    segmentEnd = 10001 - ((addr_slice - 1) * SLICE_WIDTH + 1);

                    for i = find(active_classes)
                        [findmax_data(i), acc_array(i), stats] = HD_PE(BHV(i, segmentStart:segmentEnd), QHV(segmentStart:segmentEnd), SLICE_WIDTH, acc_array(i), stats);
                        
                    end
                    slice_idx = slice_idx + 1;

                end

            % DESACTIVATE
            case DESACTIVATE
                [findmax_maxIdx, stats] = findMax(active_classes, findmax_data, NBR_CLASS_NEXT_POW2, stats);
                active_classes(findmax_maxIdx) = 0;

                if segment_idx == NBR_CLASS - 1
                    PU_predicted_class_idx_output = find(active_classes);
                    state = IDLE;
                    ready = 1;

                else
                    slice_idx = 1;
                    segment_idx = segment_idx + 1;
                    state = ACCUMULATION;
    
                end

            otherwise
                state = IDLE;
        end
    end
end

%% TESTS POUR SIMULATION

% Test de l'approche Proposed (équivalent à PU, et optimisé en temps d'exécution pour simulation)
function statsSimu = testPUsimu(class_vectors, query_vectors, query_labels, d)
    arguments
        class_vectors
        query_vectors
        query_labels
        d = 256
    end

    % Dimensions des données
    nbrClass = size(class_vectors, 1); % Nombre de classes
    D = size(class_vectors, 2);        % Dimension des hypervecteurs
    total = size(query_vectors, 1);    % Nombre de requêtes
    numSegments = floor(D / d);        % Nombre de segments par hypervecteur

    % Statistiques de simulation
    statsSimu = struct(...
        'width', ['d=', num2str(d)], ...
        'samplesData', ['nbrQuery=', num2str(total), ', nbrClass=', num2str(nbrClass)], ...
        'accuracySimu', -1, ...
        'moy_HDCalls', 0, ...
        'simuTime', -1);

    % Nombre de bonnes prédictions
    correct = 0;

    % Information sur la progression
%     progress_interval = 10; % (en %)
%     next_progress = progress_interval;
    tic;

    % Boucler sur chaque vecteur de test
    for i=1: 1: total
        currentQuery = query_vectors(i, :);
		actualLabel = query_labels(i);

        % Initialisation de la liste des langues possibles
        validIdx = 1:nbrClass;
        cumulativeHamDist = zeros(1, nbrClass);

        % Boucler pour chaque segmentation S si nécessaire
        for j = 1:numSegments

            % Segmentation du HV de requête
            segmentStart = D + 1 - j * d;
            segmentEnd = D + 1 - ((j - 1) * d + 1);
            segmentTextHV = currentQuery(segmentStart:segmentEnd);

            % Pour toutes les langues potentiellement correctes
            for k = validIdx

                % Segmentation de la langue en cours
                currentClass = class_vectors(k, :);
                segmentActualLang = currentClass(segmentStart:segmentEnd);

                % Calcul de la distance de Hamming
                xor_slice = xor(segmentActualLang, segmentTextHV);
                hamDist = length(find(xor_slice));

                % Incrémentation du nombre d'appel au PE
                statsSimu.moy_HDCalls = statsSimu.moy_HDCalls + 1;

                % Mise à jour de la somme cumulée moyennée pour la langue en cours
                cumulativeHamDist(k) = cumulativeHamDist(k) + hamDist;
            end

            % Exclusion de la langue ayant la moyenne d'angle le plus mauvais
            [~, worstIdx] = max(cumulativeHamDist(validIdx));
            validIdx(worstIdx) = [];

            % Arrêt des tests s'il ne reste plus qu'une seule langue en lice
            if length(validIdx) <= 1
                break;
            end
        end

        % Prédiction faite par le programme
        prediction = validIdx(1) - 1;

        % Vérification si la prédiction est correcte
        if prediction == actualLabel
            correct = correct + 1;
        end

        % Affichage de la progression
%         progress_percent = (i / total) * 100;
%         if progress_percent >= next_progress
%             elapsed_time = toc;
%             estimated_remaining = elapsed_time * (100 / next_progress - 1);
%             fprintf('[%3.0f%% QHVs processed] - Time remaining : %.1fs (Elapsed time : %.1fs)\n', ...
%                     next_progress, estimated_remaining, elapsed_time);
%             next_progress = next_progress + progress_interval;
%         end
    end

    % Calcul de la précision
    statsSimu.accuracySimu = correct / total;

    % Temps d'exécution
    statsSimu.simuTime = toc;

    % Moyenne du nombre d'appel au PE
    statsSimu.moy_HDCalls = statsSimu.moy_HDCalls / total;
end

% Test de l'approche Baseline A (optimisé en temps d'exécution pour simulation)
function statsRef = testBaselineA(class_vectors, query_vectors, query_labels, D)
    arguments
        class_vectors
        query_vectors
        query_labels
        D = size(class_vectors, 2)
    end

    % Dimensions des données
    nbrClass = size(class_vectors, 1);  % Nombre de classes
    total = size(query_vectors, 1);     % Nombre de requêtes

    % Statistiques de simulation
    statsRef = struct(...
        'samplesData', ['nbrQuery=', num2str(total), ', nbrClass=', num2str(nbrClass)], ...
        'accuracyRef', -1, ...
        'hammingDistanceCalls', 0, ...
        'simuTime', -1);

    % Nombre de bonne prédiction
    correct = 0;

    % Information sur la progression
%     progress_interval = 10; % (en %)
%     next_progress = progress_interval;
    tic;
    
    % Boucler pour chaque vecteur de test
    for i = 1:1:total
        currentQuery = query_vectors(i, 1:D);
		actualLabel = query_labels(i);
        
        % Prédiction de la langue sans segmentation
        minAngle = inf;
        for k = 1:1:nbrClass
            currentClass = class_vectors(k, 1:D);

            % Calcul de l'angle
            xor_slice = xor(currentClass, currentQuery);
            hamDist = length(find(xor_slice));
            statsRef.hammingDistanceCalls = statsRef.hammingDistanceCalls + 1;
            
            if (hamDist < minAngle)
	            minAngle = hamDist;
	            prediction = k - 1;
            end

        end

        % Vérification si la prédiction est correcte
        if prediction == actualLabel
            correct = correct + 1;
        end

        % Affichage de la progression
%         progress_percent = (i / total) * 100;
%         if progress_percent >= next_progress
%             elapsed_time = toc;
%             estimated_remaining = elapsed_time * (100 / next_progress - 1);
%             fprintf('[%3.0f%% QHVs processed] - Time remaining : %.1fs (Elapsed time : %.1fs)\n', ...
%                     next_progress, estimated_remaining, elapsed_time);
%             next_progress = next_progress + progress_interval;
%         end
    end

    % Calcul de la précision
    statsRef.accuracyRef = correct / total;

    % Temps d'exécution
    statsRef.simuTime = toc;
end

%% COMPARAISON DES APPROCHES

% Comparaison des tests de similarité (Baseline A vs Proposed)
function results = compare_similarity_tests()

    % Emplacement des fichiers vecteurs
    files_path = 'datasets/';

    % Chargement des fichiers
    %files = dir(fullfile(files_path, '*.mat')); % pour comparer avec les autres encodages
    files = dir(fullfile(files_path, '*_OnlineHD_binary.mat'));
    results = struct();
    
    % Information sur la progression
    progress_interval = 10; % (en %)
    next_progress = progress_interval;
    tic;

    for i = 1:length(files)
    
        % Chargement des données
        file = files(i).name;
        data = load(fullfile(files_path, file));
    
        % Extraction des champs
        tokens = regexp(file, '^(.*?)_(.*?)_(.*?)\.mat$', 'tokens');
        if isempty(tokens)
            warning(['Format de nom de fichier non reconnu : ', file]);
            continue;
        end
        tokens = tokens{1};
        dataset = lower(tokens{1});
        model = tokens{2};

        % Configurations des données
        dim = size(data.class_vectors, 2);
        nbr_classes = size(data.class_vectors, 1);
        nbr_queries = size(data.query_vectors, 1);
    
        % Test de similarité de la baseline A
        statsRef = testBaselineA(data.class_vectors, data.query_vectors, data.query_labels);
        acc_baseline = statsRef.accuracyRef;
        ham_baseline = statsRef.hammingDistanceCalls;
        tim_baseline = statsRef.simuTime;

        % Taille de la segmentation selon le modèle
        d_max = dim / nbr_classes;
        d_list = [next_power_of_two(d_max)/32, next_power_of_two(d_max)/16, next_power_of_two(d_max)/8, next_power_of_two(d_max)/4, next_power_of_two(d_max)/2];

        % Tests de similarité de l'algorithme proposé pour différents d
        acc_proposed = zeros(length(d_list), 1);
        ham_proposed = zeros(length(d_list), 1);
        tim_proposed = zeros(length(d_list), 1);
        for k = 1:length(d_list)
            statsSimu = testPUsimu(data.class_vectors, data.query_vectors, data.query_labels, d_list(k));
            acc_proposed(k) = statsSimu.accuracySimu;
            ham_proposed(k) = statsSimu.hammingDistanceCalls;
            tim_proposed(k) = statsSimu.simuTime;
        end

        % Enregistrement des données
        if ~isfield(results, dataset)
            results.(dataset) = struct();
        end

        results.(dataset).(model).dim = dim;
        results.(dataset).(model).nbr_classes = nbr_classes;
        results.(dataset).(model).nbr_queries = nbr_queries;
        results.(dataset).(model).baseline.accuracy = acc_baseline;
        results.(dataset).(model).baseline.hamCalls = ham_baseline;
        results.(dataset).(model).baseline.timeSimu = tim_baseline;
        results.(dataset).(model).proposed.accuracy = acc_proposed;
        results.(dataset).(model).proposed.d_list = d_list;
        results.(dataset).(model).proposed.hamCalls = ham_proposed;
        results.(dataset).(model).proposed.timeSimu = tim_proposed;

        % Affichage de la progression
        progress_percent = (i / length(files)) * 100;
        if progress_percent >= next_progress
            elapsed_time = toc;
            fprintf('[%3.0f%%] Elapsed time : %.1fs\n', ...
                    next_progress, elapsed_time);
            next_progress = next_progress + progress_interval;
        end
    end

end

%% AFFICHAGE DES RÉSULTATS DE COMPARAISON

% Affichage des résultats de comparaison (pour plusieurs modèles d'encodage : LDC, LeHDC, OnlineHD)
function plot_similarity_results_multi(results)

    datasets = fieldnames(results);
    models = fieldnames(results.(datasets{1}));
    nbr_list = results.(datasets{1}).(models{1}).accuracy_proposed.d_list(:)';
    
    datasets = fieldnames(results);
    num_datasets = length(datasets);

    figure('Name', 'Comparison of Accuracy', 'Color', 'w', 'Position', [100, 100, 300*num_datasets, 400]);
    tiledlayout(1, num_datasets, 'Padding', 'compact', 'TileSpacing', 'compact');
    
    % Couleurs
    orange_map = autumn(length(nbr_list));  % nuances pour d
    blue = [0.2, 0.4, 0.8];                 % baseline

    for i = 1:num_datasets
        dataset = datasets{i};
        models = fieldnames(results.(dataset));
        num_models = length(models);
        
        % Initialisation des matrices de précision
        acc_mat = zeros(num_models, 1 + length(nbr_list));  % [baseline | d1 | d2 | ...]
        xtick_labels = cell(1, num_models);

        for j = 1:num_models
            model = models{j};
            r = results.(dataset).(model);
            d_list = results.(dataset).(model).proposed.d_list(:)';

            % Baseline
            acc_mat(j, 1) = r.baseline.accuracy;

            % Tests personnalisés (alignés avec d_values)
            acc_mat(j, 2:end) = r.proposed.accuracy(:)';

            % Label
            xtick_labels{j} = sprintf('Model %d (D=%d)', j, r.dim);
        end

        nexttile
        b = bar(acc_mat * 100, 'grouped');
        hold on;

        % Appliquer les couleurs
        b(1).FaceColor = blue;  % baseline
        for k = 1:length(nbr_list)
            b(k+1).FaceColor = orange_map(k, :);
        end

        ylim([0 100]);
        ylabel('Accuracy (%)');
        title(upper(dataset));
        xticks(1:num_models);
        xticklabels(xtick_labels);
        xtickangle(25);
        grid on;

        % Légende dynamique
        legend_entries = [{'Baseline'}, arrayfun(@(d) sprintf('d = %d', d), d_list, 'UniformOutput', false)];
        legend(legend_entries, 'Location', 'southoutside', 'Orientation', 'horizontal');
    end
    
    sgtitle('Comparison of Accuracy by Model and Dataset', 'FontWeight', 'bold');
end

% Affichage des résultats de comparaison (pour un seul modèle d'encodage : LDC, LeHDC, OnlineHD)
function plot_similarity_results(results)

    datasets = fieldnames(results);
    num_datasets = length(datasets);
    
    % Vérifie s’il y a un seul modèle
    models = fieldnames(results.(datasets{1}));
    if length(models) ~= 1
        plot_similarity_results_multi(results); % Mode multi-modèle
        return;
    end

    d_list = results.(datasets{1}).(models{1}).proposed.d_list(:)';

    model = models{1};  % unique modèle
    acc_mat = zeros(num_datasets, 1 + length(d_list));  % [baseline | d1 | d2 | ...]

    xtick_labels = cell(1, num_datasets);
    dims = zeros(1, num_datasets);

    for i = 1:num_datasets
        dataset = datasets{i};
        r = results.(dataset).(model);
        acc_mat(i, 1) = r.baseline.accuracy;
        acc_mat(i, 2:end) = r.proposed.accuracy(:)';
        dims(i) = r.dim;
        xtick_labels{i} = sprintf('%s', upper(dataset));
    end

    % Couleurs
    orange_map = autumn(length(d_list));  % nuances pour d
    blue = [0.2, 0.4, 0.8];               % baseline

    % Figure
    figure('Name', ['Accuracy Comparison'], 'Color', 'w', 'Position', [100 100 700 450]);
    b = bar(acc_mat * 100, 'grouped');
    hold on;

    % Couleurs
    b(1).FaceColor = blue;
    for k = 1:length(d_list)
        b(k+1).FaceColor = orange_map(k, :);
    end

    % Affichage
    ylim([0 100]);
    ylabel('Accuracy (%)');
    title(['Accuracy Comparison'], 'FontWeight', 'bold');
    xticks(1:num_datasets);
    xticklabels(xtick_labels);
    xtickangle(15);
    grid on;

    % Légende
    legend_entries = [{'Baseline'}, arrayfun(@(d) sprintf('d = %d', d), d_list, 'UniformOutput', false)];
    legend(legend_entries, 'Location', 'southoutside', 'Orientation', 'horizontal');
end

%% STRATÉGIE PAR SEUIL STATISTIQUE OMEN

function statsOMEN = omen_inference(class_vectors, query_vectors, query_labels)
    [k, D] = size(class_vectors); % k : nombre de classe / D : dimension des hypervecteurs
    D = 4608; % dimension des hypervecteurs pour pouvoir être comparée à notre approche
    num_query = size(query_vectors, 1); % nombre de requête
    %term_points = [1024, 2048, 4096, 9192]; % points de terminaison (conformes à l'article)
    term_points = (1:9) * 512; % points de terminaison (pour comparaison avec notre approche)
    alpha = 0.05; % limite supérieure de la baisse de précision autorisée

    correct = 0;

    % Statistiques de simulation
    statsOMEN = struct(...
        'samplesData', ['nbrQuery=', num2str(num_query), ', nbrClass=', num2str(k)], ...
        'accuracySimu', -1, ...
        'moy_PECalls', 0, ...
        'ecrt_PECalls', -1, ...
        'simuTime', -1);
    tab_ecrt = zeros(num_query, 1);

    tic;

    for q = 1:num_query
        vq = query_vectors(q, :);
        dist = zeros(1, k);  % distance cumulée
        D_mat = zeros(k, D); % distance par dimension

        % Nombre d'itérations (pour les stats)
        iteration = 0;

        for n = 1:D
            vq_n = vq(n);

            for i = 1:k % pour toutes les classes
                vc_n = class_vectors(i, n);
                d_in = (vq_n ~= vc_n); % cas BSC {0,1}
                D_mat(i, n) = d_in;
                dist(i) = dist(i) + d_in;
            end

            % Terminaison lorsqu'un point de terminaison est atteint
            if ismember(n, term_points)
    
                % Mise à jour du nombre d'itérations (pour les stats)
                iteration = iteration + 1;

                [~, cand] = min(dist); % findMin
                pvals = zeros(1, k-1);
                idx = 1;

                % Test de Wald
                for j = 1:k
                    if j == cand
                        continue;
                    end
                    % Comparer D[cand,1:n] vs D[j,1:n]
                    x = D_mat(cand, 1:n);
                    y = D_mat(j, 1:n);
                    % Test de Mann-Whitney U
                    pvals(idx) = ranksum(x, y);
                    idx = idx + 1;
                end

                % Correction de Holm-Bonferri
                pvals_sorted = sort(pvals);
                h = false(1, length(pvals));
                for m = 1:length(pvals_sorted)
                    if pvals_sorted(m) < alpha / (length(pvals_sorted) - m + 1)
                        h(m) = true;
                    else
                        break;
                    end
                end

                if all(h)
                    break; % Terminaison précoce
                end
            end
        end

        % Classification finale
        [~, pred] = min(dist);
        if pred - 1 == query_labels(q)
            correct = correct + 1;
        end

        % Incrémentation du nombre d'appel au PE (pour les stats)
        statsOMEN.moy_PECalls = statsOMEN.moy_PECalls + iteration;

        % Stockage du nombre d'itération pour traiter la requête (pour les stats)
        tab_ecrt(q) = iteration;
    end

    % Calcul de précision (pour les stats)
    statsOMEN.accuracySimu = correct / num_query;

    % Temps d'exécution (pour les stats)
    statsOMEN.simuTime = toc;

    % Moyenne du nombre d'appel au PE (pour les stats)
    statsOMEN.moy_PECalls = statsOMEN.moy_PECalls / num_query;

    % Écart type du nombre d'appel au PE (pour les stats)
    statsOMEN.ecrt_PECalls = sqrt(sum((tab_ecrt(:) - statsOMEN.moy_PECalls).^2) / num_query);
    
end