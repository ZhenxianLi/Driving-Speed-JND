% run2down1upPEST100.m
% -------------------------------------------------------------------------
% Two-interval, two-alternative forced-choice (2AFC) speed-discrimination
% experiment at a REFERENCE SPEED OF 100 km/h.
%
% On each trial the participant watches two first-person driving clips
% (reference vs. comparison speed) played back-to-back in VLC and reports
% which clip looked faster. The speed difference (Delta v) is adjusted with
% a 2-down/1-up staircase combined with PEST adaptive step sizing
% (Taylor & Creelman, 1967). The whole block is repeated for three interior
% sound conditions: EV, MUTE (silence), and ICEV.
%
% Companion script for the 40 km/h reference speed: run2down1upPEST40.m
% Just-noticeable difference (JND) is computed afterwards with
% src/analysis/calcJND_reversalMeans.m
%
% Author: Zhenxian LI (zhenxian.li@insa-lyon.fr), INSA Lyon, LVA
%
% Reference:
%   Li, Z., Parizet, E., and Colangeli, C., "The Influence of Interior Noise
%   on Just-Noticeable Speed Differences in Conventional and Electric
%   Vehicles," SAE Technical Paper 2026-01-0671, 2026.
%
% Requirements: MATLAB R2016b+ (local functions in scripts), VLC media player.
% -------------------------------------------------------------------------

clear; close all;

% Make sibling functions/classes (listenTestUseVLC, CharMapper) callable
% regardless of the current working directory.
thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

% Participant identifier used only in the saved result file name.
% Replace with the current participant's anonymous ID before each session.
Name = "TestSubject01";

% Sound conditions tested in this block, in presentation order.
% Counter-balance this order across participants (Latin-square rotation).
conditions = {'EV', 'MUTE', 'ICEV'};

for i = 1:numel(conditions)
    whichSound = conditions{i};

    % Initial comparison offset (Delta v) in km/h for the 100 km/h block.
    currentDiff = 32;

    runThisTest(Name, whichSound, currentDiff);

    % ---- Mandatory 1-minute break between blocks --------------------------
    if i < numel(conditions)
        hFig = figure('Name', '1-minute Break', ...
                      'NumberTitle', 'off', ...
                      'MenuBar', 'none', ...
                      'ToolBar', 'none', ...
                      'Resize', 'off', ...
                      'Position', [400 400 600 250], ...
                      'Color', [1 1 1]);

        % Text prompt
        uicontrol(hFig, 'Style', 'text', ...
                         'String', 'Please take a 1-minute break before the next round...', ...
                         'FontSize', 16, ...
                         'FontWeight', 'bold', ...
                         'BackgroundColor', [1 1 1], ...
                         'Position', [50 160 500 50]);

        % Progress-bar area
        ax = axes('Parent', hFig, 'Units', 'pixels', ...
                  'Position', [50 100 500 40], ...
                  'XLim', [0 60], 'YLim', [0 1], ...
                  'Box', 'on', 'XTick', [], 'YTick', [], ...
                  'Color', [0.95 0.95 0.95]);

        bar = patch('XData', [0 0 0 0], 'YData', [0 0 1 1], ...
                    'FaceColor', [0.2 0.6 1], 'EdgeColor', 'none');
        countdownText = title(ax, '', 'FontSize', 14, 'FontWeight', 'bold');

        % Countdown loop
        for t = 0:60
            if ~ishandle(hFig)
                break;  % user closed the window manually
            end
            set(bar, 'XData', [0 t t 0]);
            set(countdownText, 'String', sprintf('%d seconds left', 60 - t));
            drawnow;
            pause(1);
        end

        % If the window is still open, add an "I am back" button
        if ishandle(hFig)
            uicontrol(hFig, 'Style', 'pushbutton', ...
                             'String', 'I am back', ...
                             'FontSize', 14, ...
                             'FontWeight', 'bold', ...
                             'Position', [250 30 100 40], ...
                             'Callback', @(btn,~) close(hFig));  % close on click
            uiwait(hFig);  % wait for the participant to click
        end
    end
end


% =========================================================================
function runThisTest(Name, whichSound, currentDiff)
% Run one 2-down/1-up + PEST staircase block for a single sound condition.

    % ========== 1. Paths and basic parameters ==========
    thisDir  = fileparts(mfilename('fullpath'));   % src/experiment
    repoRoot = fileparts(fileparts(thisDir));      % repository root

    currentTimeStr = datestr(now, 'yyyy_mm_dd__HH_MM_SS');
    disp("Experiment start time: " + currentTimeStr + '_' + whichSound);

    % Folder where raw staircase results are saved (created if missing).
    saveFolder = fullfile(repoRoot, 'results');
    if ~exist(saveFolder, 'dir')
        mkdir(saveFolder);
    end

    % Hidden-name mapping used to blind the experimenter to the speed encoded
    % in the file name. Set doHideName = 0 below to play plainly-named files
    % (the default, so the shipped sample stimuli run out-of-the-box).
    doHideName = 0;
    mappingFilename = fullfile(thisDir, 'charMapping.mat');
    mapper = [];
    if doHideName == 1
        if ~exist(mappingFilename, 'file')
            error('Mapping file "%s" not found. It is required when doHideName = 1.', mappingFilename);
        end
        loadedData = load(mappingFilename);
        mapper = loadedData.obj;
    end

    % Folder holding the merged audio+video stimuli for this condition, e.g.
    % <repo>/video/mergeEV/ . When doHideName = 1, blinded copies are expected
    % in the <...>/hidename subfolder.
    foldername   = "merge" + whichSound;
    sourceFolder = fullfile(repoRoot, 'video', foldername);
    destFolder   = fullfile(sourceFolder, 'hidename');

    % ========== 2. Staircase initialisation ==========
    speed_ref              = 100;  % fixed reference speed (km/h)
    initialDiff            = abs(currentDiff);
    stepSize               = floor(currentDiff / 2);
    maxTrials              = 50;
    maxReversals           = 12;
    maxReversalsInMiniStep = 6;
    stepSizeWanted         = 3;    % start counting "mini-step" reversals once step <= this
    downCriterion          = 2;    % 2-down
    upCriterion            = 1;    % 1-up

    nReversals             = 0;
    nReversalsInMiniStep   = 0;
    prevDirection          = 'none';
    consecutiveCorrect     = 0;
    consecutiveIncorrect   = 0;
    trialIndex             = 0;

    % ---------- PEST-related state ----------
    minStepSize = 2;   % rule 1: after a reversal step is halved, but not below this
    maxStepSize = 16;  % rule 5: maximum step size
    consecutiveSameDirSteps = 0;   % count of consecutive same-direction steps
    skipDoubleNextTime      = false; % rule 4 flag: skip one doubling after a doubling-then-reversal

    % Per-trial record
    resultsArray = struct('trialIndex', {}, 'speed_ref', {}, 'speed_compare', {}, ...
        'playOrder', {}, 'choice', {}, 'choiceIsEV', {}, ...
        'diffBeforeStep', {}, 'diffAfterStep', {}, ...
        'directionThisStep', {}, 'reversalFlag', {});

    audioTrack1 = 0;
    audioTrack2 = 0;

    % ========== 3. Trial loop ==========
    while trialIndex < maxTrials && nReversals < maxReversals && nReversalsInMiniStep < maxReversalsInMiniStep
        trialIndex = trialIndex + 1;
        speed_compare = speed_ref + currentDiff;

        if speed_compare <= 0
            warning('speed_compare <= 0 is not physically meaningful; stopping.');
            break;
        end

        % Resolve the two stimulus files (optionally blinded).
        if doHideName == 1
            video1_hidename = destFolder + "/" + mapper.mapString(char("merge" + whichSound + speed_compare + "_MIX")) + ".mkv";
            video2_hidename = destFolder + "/" + mapper.mapString(char("merge" + whichSound + speed_ref    + "_MIX")) + ".mkv";
            if ~exist(video1_hidename, 'file')
                warning('Blinded file "%s" not found.', video1_hidename);
            end
            if ~exist(video2_hidename, 'file')
                warning('Blinded file "%s" not found.', video2_hidename);
            end
        else
            video1_hidename = sourceFolder + "/merge" + whichSound + speed_compare + "_MIX.mkv";
            video2_hidename = sourceFolder + "/merge" + whichSound + speed_ref     + "_MIX.mkv";
        end

        % Randomly decide which clip is played first (counter-balancing).
        if rand() > 0.5
            video1_name     = sourceFolder + "/merge" + whichSound + speed_compare + "_MIX.mkv";
            video2_name     = sourceFolder + "/merge" + whichSound + speed_ref     + "_MIX.mkv";
            realOrderString = video1_name + video2_name;
            SpeedVideo1 = speed_compare;
            SpeedVideo2 = speed_ref;
        else
            video1_name     = sourceFolder + "/merge" + whichSound + speed_ref     + "_MIX.mkv";
            video2_name     = sourceFolder + "/merge" + whichSound + speed_compare + "_MIX.mkv";
            realOrderString = video1_name + video2_name;
            SpeedVideo2 = speed_compare;
            SpeedVideo1 = speed_ref;

            % Swap blinded names too, keeping the playback order consistent.
            tmp             = video1_hidename;
            video1_hidename = video2_hidename;
            video2_hidename = tmp;
        end

        fprintf("Trial %d: SpeedVideo1=%d, SpeedVideo2=%d\n", trialIndex, SpeedVideo1, SpeedVideo2);
        fprintf("   Play order: %s\n", realOrderString);

        % Play both clips and collect the participant's choice.
        trialResult = listenTestUseVLC(video1_hidename, video2_hidename, ...
            audioTrack1, audioTrack2, ...
            video1_name, video2_name);
        userChoice = trialResult.Choice;

        % ------ Score the response ------
        if userChoice == 1
            choiceIsRight = (SpeedVideo1 > SpeedVideo2);
        elseif userChoice == 2
            choiceIsRight = (SpeedVideo2 > SpeedVideo1);
        else
            % Cancel is treated as incorrect.
            choiceIsRight = false;
        end

        diffBefore = currentDiff;

        % ------ Update Delta v and step size (2-down/1-up + PEST) ------
        [currentDiff, stepSize, directionThisStep, reversalFlag, ...
            consecutiveCorrect, consecutiveIncorrect, prevDirection, nReversals, nReversalsInMiniStep, stepSizeWanted, ...
            consecutiveSameDirSteps, skipDoubleNextTime] = ...
            updateDiff_NdownMup(choiceIsRight, currentDiff, stepSize, ...
            downCriterion, upCriterion, ...
            consecutiveCorrect, consecutiveIncorrect, ...
            prevDirection, nReversals, nReversalsInMiniStep, stepSizeWanted, ...
            minStepSize, maxStepSize, ...
            consecutiveSameDirSteps, skipDoubleNextTime, initialDiff);

        % Record this trial.
        resultsArray(trialIndex).trialIndex        = trialIndex;
        resultsArray(trialIndex).speed_compare     = speed_compare;
        resultsArray(trialIndex).speed_ref         = speed_ref;
        resultsArray(trialIndex).playOrder         = realOrderString;
        resultsArray(trialIndex).choice            = userChoice;
        resultsArray(trialIndex).choiceIsEV        = choiceIsRight;
        resultsArray(trialIndex).diffBeforeStep    = diffBefore;
        resultsArray(trialIndex).diffAfterStep     = currentDiff;
        resultsArray(trialIndex).directionThisStep = directionThisStep;
        resultsArray(trialIndex).reversalFlag      = reversalFlag;

        fprintf("Trial %d done.\n\n", trialIndex);
    end

    % ========== 4. Save results ==========
    modeStr = sprintf('%ddown%dup', downCriterion, upCriterion);
    resultPath = fullfile(saveFolder, ...
        "StaircaseResult_" + currentTimeStr + "_" + Name + "_" + modeStr + whichSound + ".mat");
    disp("Saving results: " + resultPath);
    save(resultPath, 'resultsArray');

    % ========== 5. Summary ==========
    disp('Staircase result:');
    disp(resultsArray);
    disp("Block finished: " + Name + "  " + whichSound);
end


% =========================================================================
function [newDiff, newStepSize, directionThisStep, reversalFlag, ...
    consecutiveCorrect, consecutiveIncorrect, prevDirection, ...
    nReversals, nReversalsInMiniStep, stepSizeWanted, ...
    consecutiveSameDirSteps, skipDoubleNextTime] = ...
    updateDiff_NdownMup(isCorrect, oldDiff, oldStepSize, ...
    downCriterion, upCriterion, ...
    consecutiveCorrect, consecutiveIncorrect, ...
    prevDirection, nReversals, nReversalsInMiniStep, ...
    stepSizeWanted, minStepSize, maxStepSize, ...
    consecutiveSameDirSteps, skipDoubleNextTime, ...
    initialDiff)
% Update the speed difference and step size using an "N-down / M-up" rule
% combined with PEST step-size logic.
%
% PEST rules:
%   1) On every reversal, halve the step size (but not below minStepSize).
%   2) If the direction is the same as last step, keep the step size, unless
%      rule 3 applies.
%   3) From the 3rd consecutive same-direction step on, double the step size
%      (until a reversal), subject to the rule-4 exception.
%   4) If a doubling is immediately followed by a reversal, skip one doubling
%      the next time a same-direction run reaches its 3rd step.
%   5) The step size must never exceed maxStepSize.

    % --- defaults: no change ---
    newDiff           = oldDiff;
    newStepSize       = oldStepSize;
    directionThisStep = 'none';
    reversalFlag      = false;

    % Same-direction count before this update (restored on a boundary hit).
    oldConsecutiveSameDir = consecutiveSameDirSteps;

    % ========== (1) update correct/incorrect counters ==========
    if isCorrect
        consecutiveCorrect = consecutiveCorrect + 1;
    else
        consecutiveIncorrect = consecutiveIncorrect + 1;
        consecutiveCorrect   = 0;   % clear and restart counter
    end

    % ========== (2) decide whether this step is up or down ==========
    stepMade = false;
    if consecutiveCorrect >= downCriterion
        directionThisStep = 'down';
        consecutiveCorrect = 0;
        stepMade = true;
    elseif consecutiveIncorrect >= upCriterion
        directionThisStep = 'up';
        consecutiveIncorrect = 0;
        stepMade = true;
    end

    % ========== (3) if a step was made, check for a reversal & adjust step ==========
    if stepMade
        % -- reversal = direction opposite to the previous step --
        if ~strcmp(prevDirection, 'none') && ~strcmp(directionThisStep, prevDirection)
            reversalFlag = true;
            nReversals = nReversals + 1;
            fprintf('   *** Reversal! Count=%d ***\n', nReversals);

            % Count reversals that occur once the step size is small enough.
            if abs(oldStepSize) <= abs(stepSizeWanted)
                nReversalsInMiniStep = nReversalsInMiniStep + 1;
            end

            % Rule 1: halve step on reversal, not below minStepSize.
            newStepSize = floor(oldStepSize * 0.5);
            if newStepSize < minStepSize
                newStepSize = minStepSize;
            end

            % Rule 4: if the previous (large) step was a doubled one, set the
            % skip flag so the next same-direction 3rd step is not doubled.
            if abs(oldStepSize) >= 2 * abs(newStepSize)
                skipDoubleNextTime = true;
            end

            % Restart the same-direction counter.
            consecutiveSameDirSteps = 1;

        else
            % Not a reversal (same direction as last step, or previous = none).
            reversalFlag = false;

            if strcmp(directionThisStep, prevDirection)
                consecutiveSameDirSteps = consecutiveSameDirSteps + 1;
            else
                consecutiveSameDirSteps = 1;
            end

            % Rule 2: same direction -> keep step size by default.
            newStepSize = oldStepSize;

            % Rule 3: from the 3rd consecutive same-direction step, double the
            % step (may be skipped once by rule 4).
            if consecutiveSameDirSteps >= 2
                if ~skipDoubleNextTime
                    newStepSize = min(maxStepSize, oldStepSize * 2);
                else
                    skipDoubleNextTime = false;  % consume the skip
                end
            end
        end

        % Apply the step to Delta v.
        if strcmp(directionThisStep, 'down')
            newDiff = oldDiff - newStepSize;
        elseif strcmp(directionThisStep, 'up')
            newDiff = oldDiff + newStepSize;
        end

        % Record this direction.
        prevDirection = directionThisStep;

        % Clamp step size to [1, maxStepSize].
        if abs(newStepSize) > abs(maxStepSize)
            newStepSize = maxStepSize;
        end
        if abs(newStepSize) < 1
            newStepSize = 1;
        end

        % --- (4) boundary check: clamp Delta v to [0, initialDiff] ---
        boundaryHit = false;
        if abs(newDiff) > abs(initialDiff)
            newDiff = sign(newDiff) * abs(initialDiff);
            boundaryHit = true;
        elseif newDiff < 0
            newDiff = 0;
            boundaryHit = true;
        end

        if boundaryHit
            % Do not advance the same-direction count or change the step size.
            consecutiveSameDirSteps = oldConsecutiveSameDir;
            newStepSize = oldStepSize;
            directionThisStep = 'none';
        end

    else
        % No up/down criterion met: do not step, keep prevDirection.
        directionThisStep = 'none';
    end
end
