classdef CharMapper
    % CharMapper  Reversible character substitution used to blind file names.
    %
    % Builds a one-to-one forward and reverse mapping over a fixed character
    % set (letters, digits and underscore) so that a stimulus file name such
    % as "mergeEV100_MIX" can be scrambled into an opaque string. This hides
    % the encoded speed from the experimenter during testing. Seed the
    % constructor to make the mapping reproducible.

    properties
        ForwardMap   % original char -> mapped char
        ReverseMap   % mapped char   -> original char
        Characters   % original character set
        MappedChars  % shuffled character set
    end

    methods
        function obj = CharMapper(seed)
            % Constructor. Optional 'seed' makes the random mapping reproducible.

            if nargin < 1
                seed = [];
            end

            % Character set: uppercase letters, a single lowercase letter,
            % digits and underscore (matches the original study's mapping).
            uppercase  = 'A':'Z';
            lowercase  = 'a'; % :'z';
            digits     = '0':'9';
            underscore = '_';
            obj.Characters = [uppercase, lowercase, digits, underscore];

            % Seed the random number generator (optional).
            if ~isempty(seed)
                rng(seed);
            else
                rng('shuffle');
            end

            % Random permutation used as the mapping.
            numChars = length(obj.Characters);
            shuffledIndices = randperm(numChars);
            obj.MappedChars = obj.Characters(shuffledIndices);

            % Build forward and reverse maps.
            obj.ForwardMap = containers.Map(cellstr(obj.Characters'),  cellstr(obj.MappedChars'));
            obj.ReverseMap = containers.Map(cellstr(obj.MappedChars'), cellstr(obj.Characters'));
        end

        function newStr = mapString(obj, originalStr)
            % Map an original string to its scrambled form.
            % Characters outside the mapped set are left unchanged.
            newStr = originalStr;
            for k = 1:length(originalStr)
                char = originalStr(k);
                if isKey(obj.ForwardMap, char)
                    newStr(k) = obj.ForwardMap(char);
                else
                    newStr(k) = char;
                end
            end
        end

        function originalStr = reverseMapString(obj, mappedStr)
            % Map a scrambled string back to its original form.
            originalStr = mappedStr;
            for k = 1:length(mappedStr)
                char = mappedStr(k);
                if isKey(obj.ReverseMap, char)
                    originalStr(k) = obj.ReverseMap(char);
                else
                    originalStr(k) = char;
                end
            end
        end

        function displayMapping(obj)
            % Print the full mapping table (for debugging only).
            fprintf('Original -> Mapped\n');
            for k = 1:length(obj.Characters)
                orig   = obj.Characters(k);
                mapped = obj.MappedChars(k);
                fprintf('    %s    ->    %s\n', orig, mapped);
            end
        end

        function saveMapping(obj, filename)
            % Save this mapping object to a .mat file.
            save(filename, 'obj');
        end
    end
end
