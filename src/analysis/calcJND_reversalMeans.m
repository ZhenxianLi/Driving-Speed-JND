% calcJND_reversalMeans.m
% -------------------------------------------------------------------------
% Compute the just-noticeable difference (JND) in speed from adaptive
% staircase result files, and plot each staircase.
%
% Method (matches the paper's Data Analysis section):
%   1) Take the last 6 reversals of the staircase (or all of them if fewer
%      than 6 occurred) and read the stimulus level (Delta v) preceding each.
%   2) Trim the single most-extreme reversal: compute each reversal's absolute
%      deviation from the sample median; if the largest deviation exceeds twice
%      the mean of those deviations, discard that reversal.
%   3) The JND is the arithmetic mean of the remaining reversals (J_pruned).
%
% The script reads every *.mat file in folderPath. Each file holds a struct
% array 'resultsArray' with (at least) the fields .diffBeforeStep and
% .reversalFlag, as written by the experiment scripts in src/experiment/.
%
% By default it analyses the anonymised demo data in data/sample_staircase/.
% Point folderPath at your own results/ folder to analyse real sessions.
%
% Reference:
%   Z. LI, "The Influence of Interior Noise on Just-Noticeable Speed
%   Differences in Conventional and Electric Vehicles", SAE Technical Paper
%   2026-01-0671.
% -------------------------------------------------------------------------

clear; close all;

% ---------- Parameters ----------
thisDir    = fileparts(mfilename('fullpath'));   % src/analysis
repoRoot   = fileparts(fileparts(thisDir));      % repository root

% Folder of staircase .mat files to analyse.
%   - demo data:  fullfile(repoRoot,'data','sample_staircase')
%   - your runs:  fullfile(repoRoot,'results')
folderPath    = fullfile(repoRoot, 'data', 'sample_staircase');

method        = 'lastN';   % 'lastN' (use last N reversals) or 'last6'
methodParam   = 6;         % N when method = 'lastN'
maxPlotPerFig = 48;        % tiles per overview figure

% ---------- Scan files ----------
matFiles = dir(fullfile(folderPath, '*.mat'));
nFiles   = numel(matFiles);
fprintf('Found %d .mat file(s) in %s\n', nFiles, folderPath);

plotCount = 0; skipCount = 0; figIdx = 0;
summary = {};   % rows of {subject, mode, J_raw, J_pruned}

for iFile = 1:nFiles
    fileName = matFiles(iFile).name;
    fullPath = fullfile(matFiles(iFile).folder, fileName);

    S = load(fullPath, 'resultsArray');
    if ~isfield(S, 'resultsArray') || isempty(S.resultsArray)
        skipCount = skipCount + 1; continue;
    end
    A = S.resultsArray;

    % Start a new overview figure every maxPlotPerFig tiles.
    if mod(plotCount, maxPlotPerFig) == 0
        figIdx = figIdx + 1;
        figure('Name', sprintf('Staircase Set %d', figIdx), 'NumberTitle', 'off', ...
               'Position', [100 50 1400 900]);
        t = tiledlayout('flow', 'TileSpacing', 'compact', 'Padding', 'compact');
    end

    % Compute raw/pruned JND and the selected/dropped indices.
    [J_raw, J_pruned, selIdx, droppedIdx] = calcJND_withOutlier2(A, method, methodParam);

    % Parse "subject | mode" from the file name for the title.
    tokens = regexp(fileName, '_(.*?)_(\d+down\d+up.*?)\.mat$', 'tokens', 'once');
    if isempty(tokens), subj = '?'; mode = '?'; else, subj = tokens{1}; mode = tokens{2}; end
    summary(end+1, :) = {subj, mode, J_raw, J_pruned}; %#ok<SAGROW>

    % ---- Plot this staircase ----
    ax = nexttile(t); hold(ax, 'on'); grid(ax, 'on');
    trials = 1:numel(A);
    diffs  = [A.diffBeforeStep];
    revs   = find([A.reversalFlag]);

    plot(ax, trials, diffs, '-o', 'MarkerSize', 3, 'Color', [.6 .6 .6]);     % all trials
    plot(ax, revs, diffs(revs), 'rx', 'MarkerSize', 6, 'LineWidth', 1.2);     % all reversals
    plot(ax, selIdx, diffs(selIdx), 'ms', 'MarkerFaceColor', 'm');            % last-N reversals
    if ~isempty(droppedIdx)
        plot(ax, droppedIdx, diffs(droppedIdx), 'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 8); % trimmed outlier
    end
    if ~isnan(J_raw)
        yline(ax, J_raw, 'b--', 'LineWidth', 1, 'DisplayName', 'JND raw');
    end
    if ~isnan(J_pruned)
        yline(ax, J_pruned, 'r-', 'LineWidth', 1.5, 'DisplayName', 'JND pruned');
    end

    title(ax, sprintf('%s | %s', subj, mode), 'Interpreter', 'none', 'FontSize', 7);
    xlabel(ax, 'Trial'); ylabel(ax, '\Deltav'); set(ax, 'FontSize', 7);

    plotCount = plotCount + 1;
end

fprintf('Plotted: %d staircase(s), skipped: %d\n', plotCount, skipCount);

% ---------- Print a JND summary table ----------
if ~isempty(summary)
    fprintf('\n%-24s %-22s %10s %10s\n', 'Subject', 'Mode', 'JND_raw', 'JND_pruned');
    fprintf('%s\n', repmat('-', 1, 70));
    for r = 1:size(summary, 1)
        fprintf('%-24s %-22s %10.2f %10.2f\n', summary{r,1}, summary{r,2}, summary{r,3}, summary{r,4});
    end
end


%% ========================================================================
% Detailed single-staircase plot (the paper's Figure 3 style).
% Set targetPattern to part of a file name to pick a specific staircase;
% leave it empty to use the first file in the folder.
% =========================================================================
targetPattern = '';

hit = [];
for iFile = 1:nFiles
    if isempty(targetPattern) || contains(matFiles(iFile).name, targetPattern, 'IgnoreCase', true)
        hit = iFile; break;
    end
end

if isempty(hit)
    warning('No file matching "%s" was found for the detailed plot.', targetPattern);
else
    fileName = matFiles(hit).name;
    fullPath = fullfile(matFiles(hit).folder, fileName);
    fprintf('\nDetailed plot of: %s\n', fileName);

    L = load(fullPath, 'resultsArray');
    A = L.resultsArray;

    [J_raw, J_pruned, selIdx, droppedIdx] = calcJND_withOutlier2(A, method, methodParam);

    figure('Name', ['Single Staircase: ' fileName], 'NumberTitle', 'off', ...
           'Position', [100 100 700 440]);

    trials = 1:numel(A);
    diffs  = [A.diffBeforeStep];
    revs   = find([A.reversalFlag]);

    hold on; grid on; box on;
    plot(trials, diffs, '-o', 'MarkerSize', 4, 'Color', [0.55 0.55 0.55], ...
        'DisplayName', 'Staircase stimulus levels');
    plot(revs, diffs(revs), 'x', 'MarkerSize', 7, 'Color', [0.80 0.25 0.25], ...
        'LineWidth', 1.3, 'DisplayName', 'Unselected reversal points');
    plot(selIdx, diffs(selIdx), 'ms', 'Color', [0.17 0.52 0.33], ...
        'MarkerFaceColor', [0.17 0.52 0.33], 'DisplayName', 'Selected reversal points (last 6)');
    if ~isempty(droppedIdx)
        plot(droppedIdx, diffs(droppedIdx), 'ko', 'MarkerFaceColor', 'y', ...
            'MarkerSize', 6, 'DisplayName', 'Trimmed outlier reversal');
    end
    if ~isnan(J_raw)
        yline(J_raw, '--', 'Color', [0.27 0.39 0.85], 'LineWidth', 1.2, ...
            'DisplayName', 'Average before outlier trimming');
    end
    if ~isnan(J_pruned)
        yline(J_pruned, '-', 'Color', [0.85 0.33 0.31], 'LineWidth', 1.5, ...
            'DisplayName', 'Average after outlier trimming');
    end

    title('Example of a Complete Staircase Run', 'FontSize', 12, 'Interpreter', 'none');
    xlabel('Trial Number', 'FontSize', 12);
    ylabel('Speed Difference \Deltav (km/h)', 'FontSize', 12);
    legend('Location', 'best');
end


%% ========================================================================
function [J_raw, J_pruned, selIdx, droppedIdx] = calcJND_withOutlier2(R, method, param)
% Compute the JND from a single staircase's reversals.
%
% Outputs:
%   J_raw      - mean of the last N reversals (no trimming)
%   J_pruned   - mean after trimming the single most-extreme reversal
%   selIdx     - trial indices of the last N reversals
%   droppedIdx - trial index of the trimmed reversal ([] if none)
%
% Outlier rule (robust, suited to small samples): compute each value's
% absolute deviation from the median; if the largest deviation exceeds twice
% the mean of those deviations, that value is treated as a lapse and removed.

    J_raw = NaN; J_pruned = NaN; droppedIdx = [];
    revIdx = find([R.reversalFlag]);
    if numel(revIdx) == 0, selIdx = []; return; end

    % Select the last N reversals.
    switch lower(method)
        case 'last6'
            N = 6;
        case 'lastn'
            N = param;
        otherwise
            error('Unknown method "%s".', method);
    end
    selIdx = revIdx(max(1, end - N + 1):end);

    % Stimulus level (Delta v) preceding each selected reversal.
    vals  = [R(selIdx).diffBeforeStep];
    J_raw = mean(vals);

    % Median-deviation outlier test.
    medv    = median(vals);
    absDev  = abs(vals - medv);
    meanDev = mean(absDev);

    [maxDev, xi] = max(absDev);
    if maxDev > 2 * meanDev
        droppedIdx = selIdx(xi);
        vals(xi)   = [];
        selIdx(xi) = [];
    end

    if ~isempty(vals)
        J_pruned = mean(vals);
    end
end
