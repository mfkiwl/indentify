% Post-proccesing script for creating the objective functions contour plots
% and hessian metrics heatmaps (Figs. 4-7 in paper)
close all
clear all
clc

% origin_dir = cd;
% cd('D:\Dropbox\Zohar_Dana_shared\Objective Function Analysis\Scripts')

%% Controls for ploting and saving figures
colormap_data_field ='Fval_contour';%'Fval_surface'; %'Fval_contour','grad_mag_contour','scatter3Fval'
normalize_param = 1;
F_pos_version = 2;  % 1- sum(wn)=1, 2- norm2(wn)=1

%% Specify Folders for analysis
dir_name_carray = {};
exp_params_carray = {};
mat_type_carray = {};
%%%%%% Ogden-Moerman
    dir_name_carray{end+1} = 'D:\axysimmetric_objFun\HEX20_meshf_2\attempt8'; exp_params_carray{end+1} = [26e-3,19,26]; mat_type_carray{end+1} = 'OM';
%%%%% MooneyRivlin 
    dir_name_carray{end+1} = 'D:\axysimmetric_objFun\MooneyRivlin\attempt6'; exp_params_carray{end+1} = [57e-3,57e-3,880*(57e-3+57e-3)]; mat_type_carray{end+1} = 'MR';
%%%%% Neo-Hookean
    dir_name_carray{end+1} = 'D:\axysimmetric_objFun\NeoHookeanYoung\attempt2'; exp_params_carray{end+1} = [59e-3,0.3650]; mat_type_carray{end+1} = 'NH';
%%%%%% Ogden 1st order
dir_name_carray{end+1} = 'D:\axysimmetric_objFun\OgdenFirstOrder\coarse_sweep\attempt6'; exp_params_carray{end+1}=[26e-3,19,26]; mat_type_carray{end+1} = 'OG';
%%%%%% 
file_name_carray = fullfile(dir_name_carray,'test.mat');
%% Specify Reference (synthetic experimental data)
specify_ref_test = questdlg('Choose reference data selection method','reference data selection','by exp_params_carry (must be in same structure)','manually', 'by exp_params_carry (must be in same structure)');
%% Set controls (overwritings)
% revaluate objective function
override_obj_fun_val = questdlg('Override previous objective function evaluations?','Override evaluations','yes','no', 'no'); 
% save objective function relvauations
if strcmp(override_obj_fun_val,'yes')
    save_obj_fun_val = questdlg('Save n objfunction evaluations?','Override evaluations','yes','no', 'no');
else
    save_obj_fun_val = 'no';
end
% save figures
save_figures = questdlg('Save generated figures?','Save figures','yes','no', 'no'); 
if strcmp(save_figures,'yes')
    fig_save_path = uigetdir('D:\GitHub\ParamStudy\Objective Function Analysis\Scripts');
        if fig_save_path==0
            warndlg('No folder specified. Figures will not be saved');
            save_figures = 'no';
        end
else
    fig_save_path = [];
end
%% Run over each folder
dir_ind = 1;
waitbar1 = waitbar((dir_ind-1)/numel(file_name_carray),'Loading Data','Name',sprintf('(%d/%d)',dir_ind,numel(file_name_carray)), 'HandleVisibility', 'On');
for dir_ind = 1:numel(file_name_carray)
    waitbar((dir_ind-1)/numel(file_name_carray),waitbar1,'Loading Data','Name',sprintf('(%d/%d)',dir_ind,numel(file_name_carray)), 'HandleVisibility', 'On');
    save_obj_fun_val_temp = save_obj_fun_val;
    % Load Data
    dir_name = dir_name_carray{dir_ind};
    file_name = file_name_carray{dir_ind};
%     cd(dir_name)
    load(file_name);
   
    max_obj_fun_val = 0;
    % arrange Data
    P1_arr = [];
    P2_arr = [];
    for i=1:numel(test)
    %     test{i}.k = test{i}.k_factor/1000*5;
%         test{i}.k = test{i}.k_factor*test{i}.p1;
%         test{i}.D1 = (test{i}.p1+test{i}.p2)/2;
%         test{i}.D2 = (-test{i}.p1+test{i}.p2)/2;
        P1_arr = unique([P1_arr, test{i}.p1]);
        P2_arr = unique([P2_arr, test{i}.p2]);
    end
%     global force_exp indentation_depth_exp pos_exp disp_exp 
    % specify reference test
    switch specify_ref_test
        case 'by exp_params_carry (must be in same structure)' % find by exp_params_carry
            exp_params = exp_params_carray{dir_ind};
            ref_ind = [];
            % find reference test id.
            for i=1:numel(test)
                if test{i}.runFlag==0
                    continue;
                end
                if norm([test{i}.p1,test{i}.p2]-exp_params(1:2))<1e-10
                    ref_ind = i;
                    break;
                end
            end
            if isempty(ref_ind)
                error('Reference test index not found!')
            end
            ref_test = test{ref_ind};
        case 'manually' % manually select the job representing the synthetic test results (specify subfolder of job). 
                        %  meshes must be identicle but material models and parameters may vary.
            temp_ref_test = [];
            [ref_file,ref_path] = uigetfile(fullfile(dir_name,'*.mat'));
            temp_ref_test = load(fullfile(ref_path,ref_file));
            temp_ref_test_arr = temp_ref_test.test;
            if ~(isfield(temp_ref_test_arr,'indenter_RB_out')&&isfield(temp_ref_test_arr,'pos_out'))
                temp_ref_test_arr = loadDataFiles(temp_ref_test_arr);
            end
            ref_test = temp_ref_test_arr;
    end 
    objectiveStruct.force_exp = ref_test.indenter_RB_out.Fz.data;
    objectiveStruct.indentation_depth_exp = ref_test.indenter_RB_out.z.data;
    [~,objectiveStruct.pos_exp, objectiveStruct.disp_exp] = getNPosMat(ref_test);
    
    
    
    % Add random noise to "experimental" data
    S_pos = rand(size(objectiveStruct.pos_exp));
    S_force = rand(size(objectiveStruct.force_exp));
    de = 0; % de (%)
    M_pos = de*((2*S_pos-1)/100)+1; % =100+-de%     
    M_force = de*((2*S_force-1)/100)+1; % =100+-de% 
    objectiveStruct.pos_exp = objectiveStruct.pos_exp.*M_pos;
    objectiveStruct.force_exp = objectiveStruct.force_exp.*M_force;
    
    
    
    global variable_tracking_struct
%     global objectiveStruct
    variable_tracking_struct.isfirst_flg = 1;
    objectiveStruct.formulation = 6;
    objectiveStruct.indenterRadius = 15;
    eta_arr = [0,0.25,0.5,0.75,1];
    %Calculate objective function value for each test
    for i=1:numel(test)     % run over tests
        if test{i}.runFlag==0
            continue;
        end
        if isfield(test{i},'obj_fun_val')
            if strcmp(override_obj_fun_val,'yes') %re-evaluate objFun
                warning('Evaluating test #%d/%d in %s.',i,numel(test),dir_name); 
                test{i}.obj_fun_val = objFun(test{i},objectiveStruct);
            end
        else
            warning('Obective function field not found. Evaluating test #%d/%d in %s.',i,numel(test),dir_name); 
            test{i}.obj_fun_val = objFun(test{i}); %evaluate objFun
            save_obj_fun_val_temp = 'yes';
        end
    end
    switch save_obj_fun_val_temp
        case 'yes'
            warning('Saving test data in %s.',dir_name); 
            save(fullfile(dir_name,'test.mat'),'test','-v7.3');
    end
    waitbar((dir_ind-1)/numel(file_name_carray),waitbar1,'Plotting Data','Name',sprintf('(%d/%d)',dir_ind,numel(file_name_carray)));
    %% Post Processing
    mat_type = mat_type_carray{dir_ind};
    figH = MakePlots(test,mat_type,eta_arr,dir_name,normalize_param,colormap_data_field,F_pos_version,save_figures,fig_save_path);
end
close(waitbar1);
% Open location of saved plots
if strcmp(save_figures, 'yes')
    winopen(fig_save_path)
end



