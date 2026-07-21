% Données
k_values = [26, 10, 6]; % Nombre de classe
l_values = [16, 32, 64]; % Taille des tranches
segments = {[64, 128, 256], ...
            [64, 128, 256, 512], ...
            [64, 128, 256, 512, 1024]}; % Taille des segments pour chacun des datasets
N = 3; % Nombre de composants (PEs, findMax, FSMD)

% Consommation d'énergie statique (pJ)
%                 d64          d128         d256         d512
% component = [l16 l32 l64; l16 l32 l64; l16 l32 l64; l16 l32 l64]

E_k26_PEs     = [42.35	42.63	51.52;	76.23	71.05	77.28;	143.99	127.89	128.8];
E_k26_findMax = [14.55	8.73	5.82;	26.19	14.55	8.73;	49.47	26.19	14.55];
E_k26_FSMD    = [1.825	1.095	0.73;	3.285	1.825	1.095;	6.205	3.285	1.825];

E_k10_PEs     = [6.534	6.5772	7.9488;	11.7612	10.962	11.9232;	22.2156	19.7316	19.872;	43.1244	37.2708	35.7696];
E_k10_findMax = [2.502	1.5012	1.0008;	4.5036	2.502	1.5012;	    8.5068	4.5036	2.502;	16.5132	8.5068	4.5036];
E_k10_FSMD    = [0.41715	0.25029	0.16686;	0.75087	0.41715	0.25029;	1.41831	0.75087	0.41715;	2.75319	1.41831	0.75087];

E_k6_PEs      = [2.42	2.436	2.944;	4.356	4.06	4.416;	8.228	7.308	7.36;	15.972	13.804	13.248;	31.46	26.796	25.024];
E_k6_findMax  = [0.615	0.369	0.246;	1.107	0.615	0.369;	2.091	1.107	0.615;	4.059	2.091	1.107;	7.995	4.059	2.091];
E_k6_FSMD     = [0.18925	0.11355	0.0757;	0.34065	0.18925	0.11355;	0.64345	0.34065	0.18925;	1.24905	0.64345	0.34065;	2.46025	1.24905	0.64345];

% Couleurs
color_PEs     = [20  79  183]/255; % bleu
color_findMax = [254 192 0  ]/255; % jaune
color_FSMD    = [33  163 102]/255; % vert

% Figures
% Dimensions en pixels
width_px = 5500;
height_px = 1000;
dpi = 400;

% Conversion en pouces (1 pouce = 2.54 cm)
width_in = width_px / dpi;
height_in = height_px / dpi;

% Création de la figure
fig = figure;
set(fig, 'Units', 'inches');
set(fig, 'Position', [1, 1, width_in, height_in]);
set(fig, 'PaperUnits', 'inches');
set(fig, 'PaperPosition', [0, 0, width_in, height_in]);
hold on;
fontname(gcf, "Times New Roman");

for dset = 1:length(k_values)
    subplot(1,3,dset); hold on;
    
    segs = segments{dset};
    n_seg = length(segs);
    
    % Récupération des données
    E_PEs     = eval(sprintf('E_k%d_PEs', k_values(dset)));
    E_findMax = eval(sprintf('E_k%d_findMax', k_values(dset)));
    E_FSMD    = eval(sprintf('E_k%d_FSMD', k_values(dset)));
    
    % Positions X
    group_spacing = n_seg + 1;   % espace entre groupes de tranches
    X = [];
    labels = {};
    
    for l = 1:length(l_values)
        pos = (l - 1) * group_spacing + (1:n_seg);
        
        % Construire matrice [PEs, findMax, FSMD] pour empilement
        Y = [E_PEs(:,l), E_findMax(:,l), E_FSMD(:,l)];

        % Barres empilées
        b = bar(pos, Y, 0.8, 'stacked');
        b(1).FaceColor = color_PEs;
        b(2).FaceColor = color_findMax;
        b(3).FaceColor = color_FSMD;
        
        % Sauvegarder positions et labels
        X = [X, pos];
        labels = [labels, arrayfun(@(x) x, segs, 'UniformOutput', false)];
        
        % Label de tranche au-dessus du groupe
        mid_pos = mean(pos);
        ymax = max(E_PEs + E_findMax + E_FSMD, [], 'all');
        text(mid_pos, ymax*1.05, ...
             sprintf('l = %d', l_values(l)), ...
             'HorizontalAlignment','center', 'FontWeight','bold', 'FontName', 'Times New Roman');

        % Séparateur vertical esthétique
        xline(l*group_spacing, 'k');  % entre chaque tranche
    end
    
    % Axe X
    xticks(X);
    xticklabels(labels);
    xtickangle(45);
    
    % Titre = nom dataset
    title(sprintf('k = %d', k_values(dset)), 'FontName', 'Times New Roman');
    xlabel('Segmentation size d (bits)', 'FontName', 'Times New Roman');
    ylabel('Energy (pJ)', 'FontName', 'Times New Roman');
    ylim([0, max(E_PEs + E_findMax + E_FSMD, [], 'all') * 1.1]);
    grid on;
end

% Légende globale
legend({'PEs','findMax', 'FSMD'}, 'Position',[0.33 0.95 0.1 0.05], 'Orientation','horizontal', 'FontName', 'Times New Roman');

% Exportation de l'image
exportgraphics(fig, 'energyStatAll.png', 'Resolution', dpi);