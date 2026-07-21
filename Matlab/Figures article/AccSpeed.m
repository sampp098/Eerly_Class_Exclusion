% Données
% Taille des segmentations pour chacun des datasets
d_ISOLET = [64, 128, 256];
d_MNIST  = [64, 128, 256, 512];
d_UCIHAR = [64, 128, 256, 512, 1024];

% Speedup (×)
speedup_ISOLET = [4.1, 2.6, 1.4];
speedup_MNIST  = [11.3, 6.9, 3.8, 2.1];
speedup_UCIHAR = [19.7, 12.1, 6.9, 3.7, 1.9];

% Proposed accuracy (%)
accuracy_ISOLET = [68.6, 76.2, 81.6];
accuracy_MNIST  = [68.8, 77.1, 80.9, 83.9];
accuracy_UCIHAR = [58.9, 65.1, 77.8, 80.3, 82.9];

% Baseline A accuracy (%)
baselineA_ISOLET = 85.2;
baselineA_MNIST  = 85.8;
baselineA_UCIHAR = 83.5;

% Couleurs
green_light = [0.6 0.9 0.6]; % barres
dark        = [0.0 0.0 0.0]; % triangles
red         = [1.0 0.2 0.2]; % lignes baseline

% Concaténation des valeurs de d et création de l'axe x
d_all = [d_ISOLET, d_MNIST, d_UCIHAR];
x = 1:length(d_all);

% Indices par groupe
idx_ISOLET = 1:length(d_ISOLET);
idx_MNIST  = length(d_ISOLET)+(1:length(d_MNIST));
idx_UCIHAR = length(d_ISOLET)+length(d_MNIST)+(1:length(d_UCIHAR));

% Figure
% Dimensions en pixels
width_px = 3600;
height_px = 1600;
dpi = 600;

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

% Speedup (axe gauche)
yyaxis left
ax = gca;
ax.YColor = 'k';
b1 = bar(x(idx_ISOLET), speedup_ISOLET, 0.6, 'FaceColor', green_light, 'DisplayName', 'Speedup');
bar(x(idx_MNIST),  speedup_MNIST,  0.6, 'FaceColor', green_light, 'HandleVisibility', 'off');
bar(x(idx_UCIHAR), speedup_UCIHAR, 0.6, 'FaceColor', green_light, 'HandleVisibility', 'off');
ylabel('Speedup');
ylim([0 24]);

% Accuracy (axe droit)
yyaxis right
ax = gca;
ax.YColor = 'k';
s1 = scatter(x(idx_ISOLET), accuracy_ISOLET, 60, '^', 'MarkerEdgeColor', dark, ...
             'MarkerFaceColor', dark, 'DisplayName', 'Proposed accuracy');
scatter(x(idx_MNIST),  accuracy_MNIST,  60, '^', 'MarkerEdgeColor', dark, ...
        'MarkerFaceColor', dark, 'HandleVisibility', 'off');
scatter(x(idx_UCIHAR), accuracy_UCIHAR, 60, '^', 'MarkerEdgeColor', dark, ...
        'MarkerFaceColor', dark, 'HandleVisibility', 'off');
ylabel('Accuracy (%)');
ylim([55 94]);

% Baseline (en rouge)
p1 = plot([x(idx_ISOLET(1)) - 0.5, x(idx_ISOLET(end)) + 0.5], [baselineA_ISOLET baselineA_ISOLET], ...
          '--', 'Color', red, 'LineWidth', 1.5, 'DisplayName', 'Baseline accuracy');
plot([x(idx_MNIST(1)) - 0.5, x(idx_MNIST(end)) + 0.5], [baselineA_MNIST baselineA_MNIST], ...
     '--', 'Color', red, 'LineWidth', 1.5, 'HandleVisibility', 'off');
plot([x(idx_UCIHAR(1)) - 0.5, x(idx_UCIHAR(end)) + 0.5], [baselineA_UCIHAR baselineA_UCIHAR], ...
     '--', 'Color', red, 'LineWidth', 1.5, 'HandleVisibility', 'off');

% Valeur de d en bas
xticks(x);
xticklabels(repmat({''}, 1, length(x))); % Supprimer temporairement
for i = 1:length(d_all)
    text(x(i), 55, num2str(d_all(i)), 'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'top', 'FontSize', 11, 'FontName', 'Times New Roman');
end
xlim([0.5, 12.5]);

% Nom des datasets en haut
group_centers = [mean(x(idx_ISOLET)), mean(x(idx_MNIST)), mean(x(idx_UCIHAR))];
dataset_labels = {'ISOLET', 'MNIST', 'UCIHAR'};
for i = 1:3
    text(group_centers(i), 92, dataset_labels{i}, ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
         'FontWeight', 'bold', 'FontSize', 15, 'FontName', 'Times New Roman');
end

% Séparateurs verticaux esthétiques
xline(x(idx_ISOLET(end)) + 0.5, ':k', 'LineWidth', 1.5); % après ISOLET
xline(x(idx_MNIST(end))  + 0.5, ':k', 'LineWidth', 1.5); % après MNIST

% Légende
legend([b1, s1, p1], {'Speedup', 'Proposed accuracy', 'Baseline A accuracy'}, ...
       'Location', 'north', 'Orientation', 'horizontal');

% Esthétique finale
grid on;
text(6, 53.1, 'Segmentation size d', 'HorizontalAlignment', 'center', ...
     'VerticalAlignment', 'top', 'FontSize', 11, 'FontName', 'Times New Roman');
hold off;

% Exportation de l'image
exportgraphics(fig, 'accuracyVSspeedup.png', 'Resolution', dpi);