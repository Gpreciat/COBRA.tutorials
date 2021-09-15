%% Atomically resolve a metabolic reconstruction
%% Author: German Preciat, Analytical BioSciences, Leiden University
%% INTRODUCTION
% Genome-scale metabolic network reconstructions have become a relevant tool 
% in modern biology to study the metabolic pathways of biological systems _in 
% silico_. However, a more detailed representation at the underlying level of 
% atom mappings opens the possibility for a broader range of biological, biomedical 
% and biotechnological applications than with stoichiometry alone.
% 
% In this tutorial, we will see how to generate and process chemoinformatic 
% data using information from the ecoli core model. The tools presented in this 
% tutorial are then used to generate a chemoinformatic database of standardized 
% metabolites via InChI and atom mapped metabolic reactions.
%% MATERIALS
% To atom map reactions it is required to have Java version 8 and Linux. The 
% atom mapping does not run on Windows at present. 
% 
% On _macOS_, please make sure that you run the following commands in the Terminal 
% before continuing with this tutorial:
% 
% |$ /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"|
% 
% |$ brew install coreutils|
% 
% |On _Linux_|, please make sure that Java and ChemAxon directories are included. 
% To do this, run the following commands:
% 
% |$ export PATH=$PATH:/opt/opt/chemaxon/jchemsuite/bin/| (default location 
% of JChem)
% 
% |$ export PATH=$PATH:/usr/java/jre1.8.0_131/bin/| (default installation of 
% Java)
% 
% Also, in order to standardise the chemical reaction format, it is required 
% to have JChem downloaded from ChemAxon with its respective license.
%% Metabolites
% Metabolite structures are represented in a variety of chemoinformatic formats, 
% including 1) Metabolite chemical tables (MDL MOL) that list all of the atoms 
% in a molecule, as well as their coordinates and bonds${\;}^1$; 2) The simplified 
% molecular-input line-entry system (SMILES), which uses a string of ASCII characters 
% to describe the structure of a molecule${\;}^2$; or 3) The International Chemical 
% Identifier (InChI) developed by the IUPAC, provides a standard representation 
% for encoding molecular structures using multiple layers to describe a metabolite 
% structure ${\;}^3$ (see Figure 1). Additionally, different chemical databases 
% assing a particular identifier to represent the metabolite structures as the 
% Virtual Metabolic Human database (*VMH*)${\;}^4$ , the Human Metabolome Database 
% (*HMDB*)${\;}^5$ , *PubChem* database${\;}^6$, the Kyoto Encyclopedia of Genes 
% and Genomes(*KEEG*)${\;}^7$ , and the Chemical Entities of Biological Interest 
% (*ChEBI*)${\;}^8$. 
% 
% 
% 
% Figure 1. L-alaninate molecule represented by a hydrogen-suppressed molecular 
% graph (implicit hydrogens). The main branch of the molecule can be seen in green; 
% the additional branches can be seen in brown, pink and turquoise. The stereochemistry 
% of the molecule is highlighted in blue, the double bond with light green and 
% the charges are highlighted in light brown. The same colours are used to indicate 
% where this information is represented in the different chemoinformatic formats. 
% The InChI is divided into layers, each of which begins with a lowercase letter, 
% except for Layers 1 and 2. Layer 1 indicates if the InChI is standardised, Layer 
% 2 the chemical formula in a neutral state, Layer 3 the connectivity between 
% the atoms (ignoring hydrogen atoms), Layer 4 the connectivity of hydrogen atoms, 
% Layer 5 the charge of the molecule and Layer 6 the stereochemistry. Additional 
% layers can be added, but they cannot be represented with a standard InChI.
% 
% First we clean the workspace and load the model.

clear
load ecoli_core_model.mat
model.mets = regexprep(model.mets, '\-', '\_');
% Add metabolite information
% The |addMetInfoInCBmodel| function will be used to add the identifiers. The 
% chemoinformatic data is obtained from an external file and is added to the ecoli 
% core model. The chemoinformatic information includes SMILES, InChIs, or different 
% database identifiers.

dataFile = which('chemoinformaticDatabaseTutorial.mlx');
inputData = regexprep(dataFile, 'chemoinformaticDatabaseTutorial.mlx', 'metaboliteIds.xlsx');
replace = false;
[model, hasEffect] = addMetInfoInCBmodel(model, inputData, replace);
clearvars -except model
% Download metabolites from model identifiers
% The function |obtainMetStructures| is used to obtain MDL MOL files from different 
% databases, including HMDB${\;}^5$, PubChem${\;}^6$, KEEG${\;}^7$ and ChEBI${\;}^8$. 
% Alternatively, the function can be used to convert the InChI strings or SMILES 
% in the model to MDL MOL files. All that is required to run the function is a 
% COBRA model with identifiers.
% 
% The optional variables are:
% 
% The variable |mets| contains a list of metabolites to be download (Default: 
% All). To obtain the metabolite structure of glucose, we use the VMH id.

mets = {'glc_D'};
%% 
% |outputDir|: Path to the directory that will contain the MOL files (default: 
% current directory).

outputDir = [pwd filesep];
%% 
% |sources|, is an array indicating the source of preference (default: all the 
% sources with ID)
%% 
% # InChI (requires openBabel)
% # Smiles (requires openBabel)
% # KEGG (https://www.genome.jp/)
% # HMDB (https://hmdb.ca/)
% # PubChem (https://pubchem.ncbi.nlm.nih.gov/)
% # CHEBI (https://www.ebi.ac.uk/)

sources = {'inchi'; 'smiles'; 'kegg'; 'hmdb'; 'pubchem'; 'chebi'};
%% 
% Run the function

molCollectionReport = obtainMetStructures(model, mets, outputDir, sources);
% Convert metabolites
% Open Babel is a chemical toolbox designed to speak the different chemical 
% data languages. It is possible to convert between chemical formats such as MDL 
% MOL files to InChI. This function |openBabelConverter| converts chemoformatic 
% formats using OpenBabel. It requires having OpenBabel installed. 
% 
% The function requires the original chemoinformatic structure (|origFormat|) 
% and the output format (|outputFormat|). The formats supported are smiles, mol, 
% inchi, inchikey, rxn and rinchi. Furthermore, if the optional variable |saveFileDir| 
% is set, the new format will be saved with the name specified in the variable.
% 
% All of the downloaded metabolite structures are converted to an InChI as follows.

for i = 1:length(sources)
    metaboliteDir = [outputDir 'metabolites' filesep sources{i} filesep];
    inchis{i, 1} = openBabelConverter([metaboliteDir 'glc_D.mol'], 'inchi');
end
% InChI comparison
% With the function |compareInchis|, each InChI string is given a score based 
% on its similarity to the chemical formula and charge of the metabolite in the 
% model. Factors such as stereochemistry, if it is a standard inchi, and its similarity 
% to the other inchis are also considered. The InChI with the highest score is 
% the identifier considered as more consistent with the model.

comparisonTable = compareInchis(model, inchis, 'glc_D');
display(comparisonTable)
%% Reactions
% A set of atom mappings represents the mechanism of each chemical reaction 
% in a metabolic network, each of which relates an atom in a substrate metabolite 
% to an atom of the same element in a product metabolite (Figure 1). To atom map 
% reactions in a metabolic network reconstruction, one requires chemical structures 
% in a data file format (SMILES, MDL MOL, InChIs), reaction stoichiometries, and 
% an atom mapping algorithm.
% 
% A set of atom mappings represents the mechanism of each chemical reaction 
% in a metabolic network, each of which relates an atom in a substrate metabolite 
% to an atom of the same element in a product metabolite (Figure 1). To atom map 
% reactions in a metabolic network reconstruction, one requires chemical structures 
% in a data file format (SMILES, MDL MOL and InChIs), reaction stoichiometries, 
% and an atom mapping algorithm.
% 
% 
% 
% Figure 1. Set of atom mappings for reaction L-Cysteine L-Homocysteine-Lyase 
% (VMH ID: r0193).
% 
% Metabolite structures and reaction stoichiometries from the genome-scale reconstruction 
% are used to generate reaction chemical tables containing information about the 
% chemical reactions (MDL RXN). The metabolic reactions are atom mapped using 
% the Reaction Decoder Tool (RDT) algorithm${\;}^{11}$ , which was chosen after 
% comparing the performance of published atom mapping algorithms${\;}^{12}$.
% Atom map metabolic reactions
% Atom mappings for the internal reactions of a metabolic network reconstruction 
% are performed by the function |obtainAtomMappingsRDT|. The main inputs are a 
% COBRA model structure and a directory containing the molecular structures in 
% MDL MOL format. 
% 
% For this section, the atom mappings are generated based on the molecular structures 
% contained in <https://github.com/opencobra/ctf https://github.com/opencobra/ctf 
% >and the ecoli core model. 

load ecoli_core_model.mat
model.mets = regexprep(model.mets, '\-', '\_');
molFileDir = ['~' filesep 'work' filesep 'code' filesep 'ctf' filesep 'mets' filesep 'molFiles'];
%% 
% The function |obtainAtomMappingsRDT| generates 4 different directories containing: 
%% 
% * the atom mapped reactions in MDL RXN format (directory _atomMapped_), 
% * the images of the atom mapped reactions (directory _images_), 
% * additional data for the atom mapped reactions (SMILES,  and product and 
% reactant indexes) (directory _txtData_), and 
% * the unmapped MDL RXN files (directory _rxnFiles_). 
%% 
% The input variable |outputDir| indicates the directory where the folders will 
% be generated (by default the function assigns the current directory).

outputDir = [pwd filesep 'output'];
%% 
% The input variable |rxnsToAM| indicates the reactions that will be atom mapped. 
% By default the function atom map all the internal reactions with all of its 
% metabolites present in the metabolite database (|molFileDir|).

rxnsToAM = {'ENO', 'FBP'};
%% 
% The variable |hMapping|, indicates if the hydrogen atoms will be also atom 
% mapped (Default: |true|).

hMapping = true;
%% 
% Finally, the variable |onlyUnmapped| indicates if only the reaction files 
% will be generated without atom mappings (Default: |false|).

onlyUnmapped = false;
%% 
% Now, let's obtain the atom map using |obtainAtomMappingsRDT|: 

atomMappingReport = obtainAtomMappingsRDT(model, molFileDir, outputDir, rxnsToAM, hMapping, onlyUnmapped)
%% 
% The output, |atomMappingReport,| contains a report of the reactions written 
% which include:
%% 
% * |rxnFilesWritten|: The MDL RXN written.
% * |balanced|: The atomically balanced reactions.
% * |unbalanced|: The atomically unbalanced reactions.
% * mapped: The atom mapped reactions.
% * |notMapped:| The unmapped reactions.
% * |inconsistentBool|: A Boolean vector indicating the inconsistent reactions.
% * |rinchi|: The reaction InChI for the MDL RXN files written.
% * |rsmi|: The reaction SMILES for the MDL RXN files written.
%% 
% *TIMING*
% 
% The time to compute atom mappings for metabolic reactions depends on the size 
% of the genome-scale model and the size of the molecules in the reactions. The 
% above example may take ~40 min|.|
%% Chemoinformatic database
% The function |generateChemicalDatabase| generates a chemoinformatic database 
% of standardised metabolite structures and atom-mapped reactions on a genome-scale 
% metabolic reconstruction using the tools described in this tutorial. In order 
% to identify the metabolite structure that most closely resembles the metabolite 
% in the genome-scale reconstruction, identifiers from different sources are compared 
% based on their InChI (See Table 1).  Finally, the obtained atom mapped reactions 
% are used to identify the number of broken and formed bonds, as well as the enthalpy 
% change of the reactions in the genome-scale reconstruction.
% 
% 
% 
% Figure 2. |generateChemicalDatabase| workflow
% 
% 
% 
% Table 1. InChI scoring criteria.
% 
% 
% 
% 
% 
% The goal of the comparison is to obtain a larger number of atomically balanced 
% metabolic reactions. The Reaction Decoder Tool algorithm${\;}^8$ (*RDT*) is 
% used to obtain the atom mappings of each metabolic reaction. The atom mapping 
% data is used to calculate the number of bonds formed or broken in a metabolic 
% reaction, as well as the enthalpy change. The information gathered is incorporated 
% into the COBRA model.
% 
% We will obtain chemoinformatic database of the Ecoli core model in this tutorial. 
% 
% Load the ecoli core model.

clear
load ecoli_core_model.mat
model.mets = regexprep(model.mets, '\-', '\_');
%% 
% The |addMetInfoInCBmodel| function will be used to add the identifiers. The 
% chemoinformatic data is obtained from an external file and is added to the ecoli 
% core model. The chimoinformatic information includes, SMILES, InChIs, or different 
% database identifiers.

dataFile = which('chemoinformaticDatabaseTutorial.mlx');
inputData = regexprep(dataFile, 'chemoinformaticDatabaseTutorial.mlx', 'metaboliteIds.xlsx');
replace = false;
[model, hasEffect] = addMetInfoInCBmodel(model, inputData, replace);
%% 
% The user-defined parameters in the function |generateChemicalDatabase| will 
% activate various processes. Each parameter is contained in the struct array 
% |options| and described in detail below:
%% 
% * *outputDir*: The path to the directory containing the chemoinformatic database 
% (default: current directory)
% * *printlevel*: Verbose level 
% * *standardisationApproach*: String containing the type of standardisation 
% for the molecules (default: 'explicitH' if openBabel${\;}^6$ is installed, otherwise 
% default: 'basic'):
%% 
% # explicitH: Chemical graphs; 
% # implicitH: Hydrogen suppressed chemical graph; 
% # basic: Update the header.  
%% 
% * *keepMolComparison*: Logical value, indicate if  all metabolite structures 
% per source will be saved or not.
% * *onlyUnmapped*: Logic value to select create only unmapped MDL RXN files 
% (default: FALSE, requires Java to run the RDT${\;}^{11}$). 
% * *adjustToModelpH*: Logic value used to determine whether a molecule's pH 
% must be adjusted in accordance with the COBRA model. (default: TRUE, requires 
% MarvinSuite${\;}^{10}$). 
% * *addDirsToCompare*: Cell(s) with the path to directory to an existing database 
% (default: empty).
% * *dirNames*: Cell(s) with the name of the directory(ies) (default: empty).
% * *debug*: Logical value used to determine whether or not the results of different 
% points in the function will be saved for debugging (default: empty).

options.outputDir = pwd;
options.printlevel = 1;
options.debug = true;
options.standardisationApproach = 'explicitH';
options.adjustToModelpH = true;
options.keepMolComparison = true;
options.dirsToCompare = {['~' filesep 'work' filesep 'code' filesep 'ctf' filesep 'mets' filesep 'molFiles']};
options.onlyUnmapped = false;
options.dirNames = {'VMH'};
%% 
% Use the function generateChemicalDatabase

info = generateChemicalDatabase(model, options);
%% Bibliography
%% 
% # Dalby et al., "Description of several chemical structure file formats used 
% by computer programs developed at molecular design limited", *(2002).*
% # Anderson et al., "Smiles: A line notation and computerized interpreter for 
% chemical structures", _Environmental research Brief_ *(1987)*.
% # Helle et al., "Inchi, the iupac international chemical identifier", _Journal 
% of Cheminformatics_ *(2015)*.
% # Noronha et al., "The Virtual Metabolic Human database: integrating human 
% and gut microbiome metabolism with nutrition and disease", _Nucleic acids research_ 
% *(2018).*
% # Wishart et al., "HMDB 4.0 — The Human Metabolome Database for 2018_"._ _Nucleic 
% acids research_ *(2018).*
% # Sunghwan et al. “PubChem in 2021: new data content and improved web interfaces.” 
% _Nucleic acids research_ *(2021).*
% # Kanehisa, and Goto. "KEGG: Kyoto Encyclopedia of Genes and Genomes". _Nucleic 
% acids research_ *(2000).*
% # Hastings et al,. "ChEBI in 2016: Improved services and an expanding collection 
% of metabolites". _Nucleic acids research_ *(2016).*
% # O'Boyle et al,. "Open Babel: An open chemical toolbox." _Journal of Cheminformatics_ 
% *(2011).*
% # "Marvin was used for drawing, displaying and characterizing chemical structures, 
% substructures and reactions, ChemAxon (<http://www.chemaxon.com/ http://www.chemaxon.com>)"
% # Rahman et al,. "Reaction Decoder Tool (RDT): Extracting Features from Chemical 
% Reactions", Bioinformatics *(2016).*
% # Preciat et al., "Comparative evaluation of atom mapping algorithms for balanced 
% metabolic reactions: application to Recon3d", _Journal of Cheminformatics_ *(2017)*.