function result = listenTestUseVLC(video1, video2, audioTrack1, audioTrack2, video1_realname, video2_realname)
% listenTestUseVLC  Play two clips in VLC and collect a 2AFC speed judgement.
%
% Plays two video clips back-to-back in fullscreen using the VLC media player,
% then asks the participant which clip showed the faster car speed.
%
% Input:
%   video1, video2           - paths of the two clips to play (in order)
%   audioTrack1, audioTrack2  - (optional) VLC audio-track index, default 0
%   video1_realname, video2_realname - true (un-blinded) paths, stored in the
%                              result for later analysis
%
% Output:
%   result - struct with fields:
%       Video1hidename, Video2hidename - the paths actually played
%       Video1realname, Video2realname - the true paths
%       AudioTrack1, AudioTrack2       - audio-track indices used
%       Choice                          - 1 (first clip faster),
%                                         2 (second clip faster),
%                                         or 'Cancel'
%
% The VLC executable is located automatically for macOS, Windows and Linux
% (see getVlcPath below). Edit that function if VLC is installed elsewhere.

    % Default audio tracks
    if nargin < 3, audioTrack1 = 0; end
    if nargin < 4, audioTrack2 = 0; end

    % Check that the clips exist
    if ~exist(video1, 'file')
        error('Video file %s does not exist. Please check the filename and path.', video1);
    end
    if ~exist(video2, 'file')
        error('Video file %s does not exist. Please check the filename and path.', video2);
    end

    % Locate the VLC executable for the current operating system
    vlcPath = getVlcPath();

    % Play the first clip
    playVideo_VLC(vlcPath, video1, 'Video 1', audioTrack1);

    % Short gap between the two clips
    pause(0.1);

    % Play the second clip
    playVideo_VLC(vlcPath, video2, 'Video 2', audioTrack2);

    % Ask the participant which clip looked faster
    choice = questdlg('Which video shows faster car speeds?', ...
        'Speed Judgment', ...
        'Video 1', 'Video 2', 'Cancel');

    % Assemble the result
    result = struct();
    result.Video1hidename = video1;
    result.Video2hidename = video2;
    result.Video1realname = video1_realname;
    result.Video2realname = video2_realname;
    result.AudioTrack1 = audioTrack1;
    result.AudioTrack2 = audioTrack2;
    result.Choice = choice;

    switch choice
        case 'Video 1'
            disp('Participant chose: Video 1 is faster.');
            result.Choice = 1;
        case 'Video 2'
            disp('Participant chose: Video 2 is faster.');
            result.Choice = 2;
        otherwise
            disp('Participant cancelled the choice.');
            result.Choice = 'Cancel';
    end
end


% =========================================================================
function playVideo_VLC(vlcPath, videoFile, windowName, audioTrack)
% Play a single clip fullscreen via the VLC command line.
%
% VLC options used:
%   --start-time=<s>           start a few seconds in (random, see below)
%   --play-and-exit            quit VLC when playback finishes
%   --fullscreen               fullscreen playback
%   --audio-track=<n>          select an audio track
%   --run-time=<s>             play for a fixed number of seconds
%   --no-video-title-show      hide the title overlay
%   --no-osd                   disable on-screen display
%   --mouse-hide-timeout=1000  hide the cursor after 1 s

    % Random start (1-5 s in) so participants cannot memorise scene cues.
    startTime = randi([1, 5]);
    % Playback duration (6-8 s), matching the ~7 s clip used in the study.
    duration = randi([6, 8]);

    cmd = sprintf(['"%s" --start-time=%d --play-and-exit --fullscreen ' ...
                   '--audio-track=%d --run-time=%d --no-video-title-show ' ...
                   '--no-osd --mouse-hide-timeout=1000 "%s"'], ...
                   vlcPath, startTime, audioTrack, duration, videoFile);

    status = system(cmd);
    if status ~= 0
        warning('Unable to play video %s (VLC returned a non-zero status).', videoFile);
    end
end


% =========================================================================
function vlcPath = getVlcPath()
% Return the VLC executable path for the current OS, or error if not found.
% Add your own install location to the candidate list if necessary.

    if ismac
        candidates = {'/Applications/VLC.app/Contents/MacOS/VLC'};
    elseif ispc
        candidates = {'C:\Program Files\VideoLAN\VLC\vlc.exe', ...
                      'C:\Program Files (x86)\VideoLAN\VLC\vlc.exe'};
    else  % Linux / other Unix
        candidates = {'/usr/bin/vlc', '/usr/local/bin/vlc', 'vlc'};
    end

    vlcPath = '';
    for k = 1:numel(candidates)
        if strcmp(candidates{k}, 'vlc') || exist(candidates{k}, 'file')
            vlcPath = candidates{k};
            return;
        end
    end

    error(['VLC media player not found. Install VLC from https://www.videolan.org ' ...
           'or edit getVlcPath() in listenTestUseVLC.m to point to your VLC executable.']);
end
