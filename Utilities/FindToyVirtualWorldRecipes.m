function archiveFiles = FindToyVirtualWorldRecipes(recipeFolder, hueLevels, reflectanceNumbers)
% Find recipes by parameter values, in the given recipeFolder.
%
% archiveFiles = FindToyVirtualWorldRecipes(recipeFolder, hueLevels, reflectanceNumbers)
% searches the given recipeFolder for Toy Virtual World recipes.  If
% hueLevels and reflectanceNumbers are provided, searches for recipes
% based on their names, using these parameter values.  Otherwise, looks for
% all recipe archives in the given recipeFolder.

parser = inputParser();
parser.addRequired('recipeFolder', @ischar);
parser.addRequired('hueLevels', @isnumeric);
parser.addRequired('reflectanceNumbers', @isnumeric);
parser.parse(recipeFolder, hueLevels, reflectanceNumbers);
recipeFolder = parser.Results.recipeFolder;
hueLevels = parser.Results.hueLevels;
reflectanceNumbers = parser.Results.reflectanceNumbers;

%% Locate packed-up recipes.
if isempty(hueLevels) || isempty(reflectanceNumbers)
    % find all recipes available
    archiveFiles = rtbFindFiles('root', recipeFolder, 'filter', '\.zip$');
    
else
    % look for recipes by name
    nhueLevels = size(hueLevels,2);
    nReflectances = numel(reflectanceNumbers);
    nScenes = nhueLevels * nReflectances;
    archiveFiles = cell(1, nScenes);
    isFound = false(1, nScenes);
    
    for ll = 1:nhueLevels
        targethueLevel = hueLevels(1,ll);
        for rr = 1:nReflectances
            reflectanceNumber = reflectanceNumbers(rr);
            
            recipeName = FormatRecipeName(targethueLevel, reflectanceNumber, '\w+', '\w+');
            recipePattern = [recipeName '\.zip$'];
            archiveMatches = rtbFindFiles('root', recipeFolder, 'filter', recipePattern);
            
            if isempty(archiveMatches)
                continue;
            else
                sceneIndex = rr + (ll-1)*nReflectances;
                archiveFiles(sceneIndex) = archiveMatches(1);
                isFound(sceneIndex) = true;
            end
        end
    end
    archiveFiles = archiveFiles(isFound);
end
