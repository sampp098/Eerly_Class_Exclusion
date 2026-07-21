% Données
% Consommation d'énergie pour MNIST, d=512 (pJ)
dyn_baseline = [87.84	87.84	87.84	87.84	87.84	87.84	87.84	87.84	87.84];
stat_baseline = [7.8472	7.8472	7.8472	7.8472	7.8472	7.8472	7.8472	7.8472	7.8472];
dyn_proposed = [90.57224	81.78824	73.00424	64.22024	55.43624	46.65224	37.86824	29.08424	20.30024];
stat_proposed = [8.00479	7.31459	6.62439	5.93419	5.24399	4.55379	3.86359	3.17339	2.48319];
cum_omen = [114.6872	229.3744	344.0616	458.7488	573.436	688.1232	802.8104	802.8104	802.8104];

% Nombre d'itérations totales
iterations = 1:length(dyn_baseline);

% Préparation des données pour bar empilé
Y_baseline = [dyn_baseline; stat_baseline]';
Y_approach = [dyn_proposed; stat_proposed]';

% Figures
% Dimensions en pixels
width_px = 1800;
height_px = 1800;
dpi = 400;

% Conversion en pouces (1 pouce = 2.54 cm)
width_in = width_px / dpi;
height_in = height_px / dpi;

% Création de la figure
fig = figure;
t = tiledlayout(2,1); % 2 lignes, 1 colonne
t.TileSpacing = 'compact';
t.Padding = 'compact';
set(fig, 'Units', 'inches');
set(fig, 'Position', [1, 1, width_in, height_in]);
set(fig, 'PaperUnits', 'inches');
set(fig, 'PaperPosition', [0, 0, width_in, height_in]);
fontname(gcf, "Times New Roman");

% Graphique à barres empilées (en haut)
ax1 = nexttile; hold on;

% Largeur et espacement
barWidth = 0.5;

% Barres baseline (groupe 1)
b1 = bar(iterations-0.125, Y_baseline, barWidth/2, 'stacked', 'FaceColor','flat');
b1(1).FaceColor = [8, 115, 186]/255;
b1(2).FaceColor = [80, 189, 237]/255;

% Barres approche (groupe 2)
b2 = bar(iterations+0.125, Y_approach, barWidth/2, 'stacked', 'FaceColor','flat');
b2(1).FaceColor = [152, 54, 32]/255;
b2(2).FaceColor = [241, 101, 103]/255;

% Axe et labels
xlabel('Iteration');
ylabel({'Energy Consumption', 'per iteration (pJ)'});
xlim([0.5 length(dyn_baseline) + 0.5]);
xticks(1:(length(dyn_baseline)));

% Légende
lgd = legend([b1(2), b1(1), b2(2), b2(1)], ...
       {'Static cons. (Baseline B)','Dynamic cons. (Baseline B)', ...
        'Static cons. (Proposed)','Dynamic cons. (Proposed)'}, ...
       'Location','northoutside'); %,'Orientation','horizontal'

lgd.NumColumns = 2;    % force l’affichage sur 2 colonnes
lgd.FontSize   = 8;    % réduit un peu la taille pour gagner de la place

grid on;

% Courbes cumulées (en bas)
ax2 = nexttile; hold on;

% Totaux par itération
tot_baseline = dyn_baseline + stat_baseline;
tot_proposed = dyn_proposed + stat_proposed;

% Somme cumulée
cum_baseline = cumsum(tot_baseline);
cum_proposed = cumsum(tot_proposed);

% Courbes
plot(iterations, cum_baseline, '-o', 'Color', [8, 115, 186]/255, 'LineWidth', 1.5, ...
    'DisplayName','Baseline B');
plot(iterations, cum_omen, '-^', 'Color', [2, 114, 53]/255, 'LineWidth', 1.5, ...
    'DisplayName','Baseline C');
plot(iterations, cum_proposed, '-s', 'Color', [152, 54, 32]/255, 'LineWidth', 1.5, ...
    'DisplayName','Proposed');

% Axes
xlabel('Iteration');
ylabel({'Cumulative Energy', 'over iterations (pJ)'});
xlim([0.5 length(dyn_baseline) + 0.5]);
xticks(1:(length(dyn_baseline)));
grid on;

% Légende
legend('Location','northwest');

% Exportation de l'image
exportgraphics(fig, 'energyIteration.png', 'Resolution', dpi);