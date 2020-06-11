function MakeMultispectralStruct(varargin)
%%MakeMultispectralStruct Make the struct with cropped multispctral images
%
% Usage:
%   MakeMultispectralStruct('folderName','FixedTargetShapeFixedIlluminantFixedBkGnd')
%
% Description:
%   This function makes a struct with fields multispectralImages,
%   lightnessLevels, reflectanceNumbers, uniquehueLevels, hueLevelIndex,
%   cropSize, wavelengths, fullImageHeight, fullImageWidth, baseFolderName,
%   and pathToFullMultispectralimage. The struct is saved as a .mat
%   file in the parent directory provided in the input field 'outputname', which
%   itself goes underneath
%
% Input:
%    None.
%
% Output:
%    None.
%
% Optional key/value pairs:
%    'folderName' : (string) Name of folder inside of the base dir from where the images will be selected (default 'ExampleOutput').
%    'hueLevels' : (numerical vector) hue levels of images to be selected for struct (defalult [0.2 0.6])
%    'reflectanceNumbers' : (scalar) reflectnace numbers to be used for struct (default [1 2])
%    'cropImageHalfSize : (integer) Size of cropped image (default 25)
%    'targetShape': Name of target object targetShape (default '\w+')
%    'baseSceneSet': Name of baseScene (default '\w+')

% Oct 16 2017, VS wrote this

%% Get inputs and defaults.
parser = inputParser();
parser.addParameter('folderName','ExampleOutput',@ischar);
parser.addParameter('hueLevels', [0.2 0.6], @isnumeric);
parser.addParameter('reflectanceNumbers', [1 2], @isnumeric);
parser.addParameter('cropImageHalfSizeX', 25, @isnumeric);
parser.addParameter('cropImageHalfSizeY', 25, @isnumeric);
parser.addParameter('targetShape', '\w+', @ischar);
parser.addParameter('baseScene', '\w+', @ischar);
parser.parse(varargin{:});

hueLevels = parser.Results.hueLevels;
reflectanceNumbers = parser.Results.reflectanceNumbers;
cropImageHalfSizeX = parser.Results.cropImageHalfSizeX;
cropImageHalfSizeY = parser.Results.cropImageHalfSizeY;
targetShape = parser.Results.targetShape;
baseScene = parser.Results.baseScene;

%% Overall Setup.
smallNumber = 10^(-4);
% location of packed-up recipes
projectName = 'VirtualWorldHueConstancy';
recipeFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.folderName, 'Originals');
if ~exist(recipeFolder, 'dir')
    disp(['Recipe folder not found: ' recipeFolder]);
end

% % location of reflectance folder
% pathToTargetReflectanceFolder = fullfile(getpref(projectName, 'baseFolder'),...
%     parser.Results.outputName,'Data','Reflectances','TargetObjects');

% edit some batch renderer options
hints.workingFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.folderName,'Working');

%% Assemble recipies by combinations of target hues reflectances.
nReflectances = length(reflectanceNumbers);
nhueLevels = length(hueLevels);
nScenes = nhueLevels * nReflectances;
sceneRecord = struct( ...
    'targethueLevel', [], ...
    'reflectanceNumber', []);

% pre-fill hue and reflectance conditions per scene
% so that we can unroll the nested loops below
for ll = 1:nhueLevels
    targethueLevel = hueLevels(ll);
    for rr = 1:nReflectances
        reflectanceNumber = reflectanceNumbers(rr);
        
        sceneIndex = rr + (ll-1)*nReflectances;
        sceneRecord(sceneIndex).targethueLevel = targethueLevel;
        sceneRecord(sceneIndex).reflectanceNumber = reflectanceNumber;
    end
end

% Outputs for AMA
multispectralStruct = struct(...
    'multispectralImage',zeros(31,(2*cropImageHalfSizeX+1)*(2*cropImageHalfSizeY+1),nScenes),...
    'hueLevels', zeros(1,nScenes),...
    'reflectanceNumber', zeros(1,nScenes),...
    'uniquehueLevels', [],...
    'hueLevelIndex', zeros(1,nScenes),...
    'cropImageSizeX',2*cropImageHalfSizeX+1,...
    'cropImageSizeY',2*cropImageHalfSizeY+1,...
    'S',[400 10 31]);

recipeName = FormatRecipeName(targethueLevel(1), reflectanceNumber(1), ...
    targetShape, baseScene);
recipePattern = fullfile(recipeName,'ConeResponse.mat');
if (strcmp(targetShape,'\w+') || strcmp(baseScene, '\w+'))
    pathToRecipe = rtbFindFiles('root', hints.workingFolder, 'filter', recipePattern);
    tempRecipe = parloadConeResponse(pathToRecipe{1});
else
    pathToRecipe = fullfile(hints.workingFolder, recipePattern);
    tempRecipe = parloadConeResponse(pathToRecipe);
end

multispectralStruct.fullImageHeight = tempRecipe.input.hints.imageHeight;
multispectralStruct.fullImageWidth = tempRecipe.input.hints.imageWidth;

parfor ii = 1:nScenes
    workingRecord = sceneRecord(ii);
    targethueLevel = workingRecord.targethueLevel;
    tempReflectanceNumber = workingRecord.reflectanceNumber;
    
    try
%         get the recipe
        recipeName = FormatRecipeName(targethueLevel, tempReflectanceNumber, ...
            targetShape, baseScene);
        recipePattern = fullfile(recipeName,'ConeResponse.mat');
        if (strcmp(targetShape,'\w+') || strcmp(baseScene, '\w+'))
            pathToRecipe = rtbFindFiles('root', hints.workingFolder, 'filter', recipePattern);
            recipe = parloadConeResponse(pathToRecipe{1});
        else
            pathToRecipe = fullfile(hints.workingFolder, recipePattern);
            recipe = parloadConeResponse(pathToRecipe);
        end        
        
        hueLevels(ii) = recipe.input.sceneRecord.targethueLevel;
        reflectanceNumber(ii) = recipe.input.sceneRecord.reflectanceNumber;
        multispectralImage(:,:,ii) = ImageToCalFormat(recipe.processing.croppedImage);
        pathToFullImage{ii} = recipe.rendering.radianceDataFiles{end};
    catch err
        SaveToyVirutalWorldError(analysedFolder, err, recipe, varargin);
    end
    
end
multispectralStruct.hueLevels = round(hueLevels*10000)/10000;
multispectralStruct.uniquehueLevels = unique(multispectralStruct.hueLevels);
for ii = 1:length(multispectralStruct.uniquehueLevels)
    multispectralStruct.hueLevelIndex(abs(multispectralStruct.hueLevels-multispectralStruct.uniquehueLevels(ii)) < smallNumber) = ii;
end
multispectralStruct.reflectanceNumber = reflectanceNumber;
multispectralStruct.multispectralImage = multispectralImage;
multispectralStruct.baseFolderName = fullfile(getpref(projectName, 'baseFolder'),parser.Results.folderName);
multispectralStruct.pathToFullMultispectralImage = pathToFullImage;

save(fullfile(getpref(projectName, 'baseFolder'),...
    parser.Results.folderName,'multispectralStruct.mat'),...
    'multispectralStruct','-v7.3');
