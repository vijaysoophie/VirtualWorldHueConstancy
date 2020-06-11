function saveRecipesConditionsTogether(parser)
%saveRecipesConditionsTogether(parser)
%
% Usage: 
%     saveRecipesConditionsTogether(parser)
%
% Description:
%   This function saves the recipe conditions specified in the fieldNames
%   variable below and saves it to the Cases/Cases.txt file in the
%   VirtualWorldColorConstancy folder. 
%   If /Cases/Cases.txt does not exits this creates the corresponding file
%   and directory and saves the recipe data. Otherwise it appends the
%   information to the existing file.
%
% Input:
%   parser = struct with the recipe information
%
% Written by VS 02/02/2017


projectName = 'VirtualWorldHueConstancy';
if ~exist(fullfile(getpref(projectName, 'baseFolder'),'Cases'))
    mkdir(fullfile(getpref(projectName, 'baseFolder'),'Cases'))
end
filename = fullfile(getpref(projectName, 'baseFolder'),'Cases','Cases.txt');

fieldNames = {
    'outputName'
    'baseSceneSet'
    'objectShapeSet'
    'lightShapeSet'
    'illuminantSpectraRandom'
    'otherObjectReflectanceRandom'    
    'lightPositionRandom'
    'lightScaleRandom'
    'targetPositionRandom'
    'targetScaleRandom'
    'hueLevels'
    'reflectanceNumbers'};

if ~exist(filename)
    fid = fopen(filename,'wt');
    for numFields = 1 : numel(fieldNames)
        switch fieldNames{numFields}
            case {'illuminantSpectraRandom'}
                fprintf(fid, '%20s\t', 'Illuminant Spectra');
            case {'otherObjectReflectanceRandom'}
                fprintf(fid, '%20s\t', 'Background Spectra');
            case {'lightPositionRandom'}
                fprintf(fid, '%20s\t', 'Light Position');
            case {'lightScaleRandom'}
                fprintf(fid, '%20s\t', 'Light Scale');
            case {'targetPositionRandom'}
                fprintf(fid, '%20s\t', 'Target Position');
            case {'targetScaleRandom'}
                fprintf(fid, '%20s\t', 'Target Scale');
            otherwise
                fprintf(fid, '%20s\t', fieldNames{numFields});
        end                
    end
    fprintf(fid, '%20s\t', 'Date & Time');
    fprintf(fid, '\n');    
else
    fid = fopen(filename,'at');
end

for numFields = 1 : numel(fieldNames)
    subFields = parser.Results.(fieldNames{numFields});
    switch fieldNames{numFields}
        case {'outputName'}
            fprintf(fid, '%20s\t', subFields);
        case {'baseSceneSet'}
            if (numel(subFields) == 1)
                fprintf(fid, '%20s\t', subFields{:});
            else
                fprintf(fid, '%20s\t', [num2str(numel(subFields)),' Scenes']);
            end
        case {'objectShapeSet'}
            if (numel(subFields) == 1)
                fprintf(fid, '%20s\t', subFields{:});
            else
                fprintf(fid, '%20s\t', [num2str(numel(subFields)),' Objects']);
            end
        case {'lightShapeSet'}
            if (numel(subFields) == 1)
                fprintf(fid, '%20s\t', subFields{:});
            else
                fprintf(fid, '%20s\t', [num2str(numel(subFields)),' Light']);
            end
        case {'hueLevels', 'reflectanceNumbers'}
            subFields = num2str(subFields);
            fprintf(fid, '%20s', subFields);
            fprintf(fid, '\t');
        case {'illuminantSpectraRandom', 'otherObjectReflectanceRandom'}
            if (subFields==0)
                fprintf(fid, '%20s\t', 'Fixed');
            else
                fprintf(fid, '%20s\t', 'Random');
            end
        case {'lightPositionRandom', ...
                'lightScaleRandom', 'targetPositionRandom', 'targetScaleRandom'}
            if (subFields==0)
                fprintf(fid, '%20s\t', 'Fixed');
            else
                fprintf(fid, '%20s\t', 'Random');
            end
    end
end
fprintf(fid, '%20s\t', datestr(datetime));
fprintf(fid, '\n');
fclose(fid);