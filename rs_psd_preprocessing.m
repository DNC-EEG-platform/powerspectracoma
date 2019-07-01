%     Preprocessing script that will segment data and filter data, allowing for 
%     artifact rejection and independent component analysis
%
%     Copyright (C) 2019, Thomas Kustermann and Marzia De Lucia
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <https://www.gnu.org/licenses/>.

%% Script to preprocess EEG data
% Dependencies:
% - FieldTrip (http://www.fieldtriptoolbox.org/download/)
% - inputsdlg (https://www.mathworks.com/matlabcentral/fileexchange/25862-inputsdlg-enhanced-input-dialog-box)
%% segment and preprocess data
base_path = ''; % path where subject folders are located (don't forget backslahes)
sub_fold  = ''; % sub-folder that will be created within the subject folder (don't forget backslahes)
subjects  = {''}; % array of subject folder names incl sub-folders for raw EEG file
raw_file  = ''; % file that contains the continuous data in FieldTrip format 
               % (see http://www.fieldtriptoolbox.org/reading_data/ and exemplary dataset on repository)
for subj_iter = 1:numel(subjects)
    disp(['Loading data from: ',base_path,subjects{subj_iter},raw_file]);
    data = load([base_path,subjects{subj_iter},raw_file]);
    
    % segment data into epochs
    % remove the line noise using a BS filter and demean data
    cfg = [];
    cfg.demean = 'yes';    
    cfg.bsfilter = 'yes';
    cfg.bsfreq = [45 55; 95 105; 145 155];
    cfg.bsfilttype = 'firws';
    data=ft_preprocessing(cfg,data);
    
    % segment data into epochs
    cfg                = [];
    cfg.length         = 5;
    data               = ft_redefinetrial(cfg, data);
    data.trialinfo     = data.sampleinfo;
    
    % downsample data to 500Hz to save computational space and time
    cfg = [];
    cfg.resamplefs = 500;
    data=ft_resampledata(cfg,data);
    
    mkdir([base_path,subjects{subj_iter},sub_fold])
    out_full = [base_path,subjects{subj_iter},sub_fold,'data_segm.mat'];
    disp(['Saving data to: ',out_full]);
    save(out_full,'data');
    %% perform artifact rejection routine
    data_orig = data;
%     % remove the early amplifier artifacts in first trials by default
%     (only needed for g.tec system used by authors)
%     cfg=[];
%     cfg.trials=~(data.trialinfo(:,2)<21*1200);
%     data=ft_selectdata(cfg,data);    
    % prepare a layout used for subsequent artifact rejection
    cfg = [];
    cfg.channel         = data.label;
    cfg.layout          = 'standard_1020.elc';%
    cfg.feedback        = 'no';
    lay                 = ft_prepare_layout(cfg);    
    % set config for artifact rejection using my_artefactremoval2 function 
    cfg                 = [];
    cfg.eog             = [find(strcmpi(data.label,'EOGH')), ...
        find(strcmpi(data.label,'EOGV'))];
    cfg.ecg             =  find(strcmpi(data.label,'ECG'));
    cfg.eeg             = [1:min(cfg.eog)-1];
    cfg.layout          = lay;
    % add cfg settings for databrowser
    cfg2                = [];
    cfg2.ylim           = [-25 25];
    cfg2.ecgscale       = .05;
    % add data for thres and vis_rej
    cfg2.vis_rej='trlchan';
    data = my_artefactremoval2(cfg,data,cfg2);
    
    % save data
    disp(['Saving to: ', [base_path,subjects{subj_iter},sub_fold,'data_art.mat']])
    save([base_path,subjects{subj_iter},sub_fold,'data_art.mat'],'data','lay');
    %% perform ICA
    cfg = [];
    cfg.channel = {'EEG'};
    data=ft_selectdata(cfg,data);
    % downsample if higher than 400 Hz to save time (unmixing matrix is later applied to non-downsampled data)
    if data.fsample > 400
        cfg = [];
        cfg.resamplefs = 250;
        data_fs=ft_resampledata(cfg,data);
    else
        data_fs = data;
    end
    % apply 1hz hp and 40hz lp filter before ICA (e.g.
    % https://sccn.ucsd.edu/wiki/Makoto%27s_preprocessing_pipeline#High-pass_filter_the_data_at_1-Hz_.28for_ICA.2C_ASR.2C_and_CleanLine.29.2808.2F17.2F2018_updated.29 
    % also we dont compute power spectra above 40 Hz in the first place)
    cfg = [];
    cfg.hpfilter = 'yes';
    cfg.hpfreq = 1;
    cfg.lpfilter = 'yes';
    cfg.lpfreq = 40;
    data_fs=ft_preprocessing(cfg,data_fs);
    % perform ICA
    cfg               = [];
    comp              = ft_componentanalysis(cfg,data_fs);
    %save
    disp(['Saving data to: ',base_path,subjects{subj_iter},sub_fold,'data_comp.mat']);
    save([base_path,subjects{subj_iter},sub_fold,'data_comp.mat'],'comp','lay');
    keep subj_iter subjects base_path sub_fold
    disp(sprintf('\n\n%i/%i DATASETS PROCESSED\n\n',subj_iter,numel(subjects)))
end
%% remove components and check for further trial/chan distortions post ICA
% using data_segm here because the sampleinfo constructed from artifact rejection assumes a start at sample 1
% (not true for above since 4 first trials are removed)

file_name{1} = 'data_comp.mat'; % file output from ica
file_name{2} = 'data_art.mat'; % file output from artifact rejection
file_name{3} = 'raw_data.mat'; % raw data read at first step
file_name{4} = 'data_segm.mat'; % read segmented data
for subj_iter = 1:numel(subjects)
    % load downsampled components
    display(['Loading data from: ',base_path,subjects{subj_iter},sub_fold,file_name{1}]);
    load([base_path,subjects{subj_iter},sub_fold,file_name{1}])
    % load artifact rejected orig data
    display(['Loading data from: ',base_path,subjects{subj_iter},sub_fold,file_name{2}]);
    load([base_path,subjects{subj_iter},sub_fold,file_name{2}])
    % if fsample field missing in "data" reconstruct from data.time
    if ~isfield(data,'fsample')
        data.fsample=round(numel(data.time{1})/(data.time{1}(end)-data.time{1}(1)));
        save([base_path,subjects{subj_iter},file_name{2}],'data','lay');
    end
    data_art = data;
    % %     % add trialinfo field also as sampleinfo as in newer preprocessing samepleinfo does not match trialinfo anymore due to being removed from
    % %     % data structure
    % %     data.sampleinfo=ceil(data.trialinfo*(data.fsample/1200)); % 1200 = original sampling
    % Visually check the components
    'SELECT ICA COMPONENTS TO REMOVE'
    if mod(comp.fsample,1)~=0
        comp.fsample=round(comp.fsample);
    end
    cfg               = [];
    cfg.viewmode      = 'component';
    cfg.continuous    = 'yes';
    cfg.blocksize     = 5;
    cfg.channels      = [1:10];
    cfg.layout        = lay;
    cfg.compscale     = 'local';
    ft_databrowser(cfg,comp);
    fig1=gcf;
    fig1.Position = [796 49 1097 948]; % matches a 1080p screen
    % %     % compare with ecg signal to identify heart related components (works only if ECG is contained in data)
    % %     display(['Loading data from: ',base_path,subjects{subj_iter},sub_fold,file_name{3}]);
    % %     load([base_path,subjects{subj_iter},sub_fold,file_name{3}])
    % %     addpath 'D:\Lausanne_analyses\scripts\resting_data\artifact_rejection\ICA'
    % %     ica_ecg_identify(comp,data,data_all)
    %
    display(subjects{subj_iter})
    % gui to select components for rejection (requires inputsdlg)
        Prompt(1,:) = {'Enter all components to be rejected (space-separated - e.g. 1 4 7 12)', 'comp',[]};
    name='Component Rejection';
    formats(1,1).type = 'edit';
    formats(1,1).format = 'text';
    formats(1,1).limits = [0 1];
    DefAns = struct([]);
    DefAns(1).comp = 'None';
    [answer,canceled] = inputsdlg(Prompt,name,formats,DefAns);
    comp_rej = unique(str2num(answer.comp));
    close all
    % unmix original data to continue with non-downsampled and non-filtered data
    cfg = [];
    cfg.unmixing = comp.unmixing;
    cfg.topolabel = comp.topolabel;
    data_ic = ft_componentanalysis(cfg,data);
    % reject selected components
    cfg = [];
    cfg.component = comp_rej;
    data=ft_rejectcomponent(cfg,data_ic);
    %% append the ecg/eog channels back to data
    cfg=[];
    cfg.channel = {'ECG','EOGH','EOGV'};
    data_extra=ft_selectdata(cfg,data_art);
    data=ft_appenddata([],data,data_extra);
    data.fsample=data_extra.fsample;
    % save data
    disp(['Saving data to: ',[base_path,subjects{subj_iter},sub_fold,'data_ica.mat']]);
    mkdir([base_path,subjects{subj_iter},sub_fold])
    save([base_path,subjects{subj_iter},sub_fold,'data_ica.mat'],'data','lay');
    %%  visually rejection of artifacts as ICA rejections can induce aberrations in previously existing trl-chan structure
    % load data which are then used for the excel sheet
    display(['Loading data from: ',base_path,subjects{subj_iter},sub_fold,file_name{4}]);
    tmp_load=load([base_path,subjects{subj_iter},sub_fold,file_name{4}]);
    data_orig=tmp_load.data;
    % again use the "my_artefactremoval2" function to reject trials/channels
    cfg                 = [];
    cfg.eog             = [find(strcmpi(data.label,'EOGH')), ...
        find(strcmpi(data.label,'EOGV'))];
    cfg.ecg             =  find(strcmpi(data.label,'ECG'));
    cfg.eeg             = [1:min(cfg.eog)-1];
    cfg.layout          = lay;
    % add cfg for databrowser
    cfg2                = [];
    cfg2.ylim           = [-25 25];
    cfg2.ecgscale       = .05;
    % add data for thres and vis_rej
    cfg2.vis_rej='chan';
    data = my_artefactremoval2(cfg,data,cfg2);
    %%
    mkdir([base_path,subjects{subj_iter},sub_fold])
    disp(['Saving to: ',base_path,subjects{subj_iter},sub_fold,'data_rej2.mat'])
    save([base_path,subjects{subj_iter},sub_fold,'data_rej2.mat'],'data','lay');
    %% Interpolate bad and missing channels
    elecs=p_layout('ladybird');
    %load 'PATH\LAYOUTFILE.mat'
 
    % add these to layout for scarabeo layouts
    if ismember('O9',lay.label)
        lay.label=[lay.label;'F9';'F10'];
        lay.pos  =[lay.pos;[-0.4500    0.2997];[0.4500    0.2944]];
        lay.width=[lay.width;0.0416;0.0416];
        lay.height=[lay.height;0.0375;0.037];
    end
    % remove scarabeo channels
    cfg = [];
    cfg.channel = data.label(~ismember(data.label,{'AFz','O9','O10'}));
    data=ft_selectdata(cfg,data);
    % interpolate channels
    cfg=[];
    cfg.method         = 'template';%, 'triangulation' or 'template'
    cfg.template       = 'gtec62_neighbours.mat';%name of the template file, e.g. CTF275_neighb.mat
    cfg.layout         = lay;%filename of the layout, see FT_PREPARE_LAYOUT
    neighbours         = ft_prepare_neighbours(cfg);
    
    chans=load('gtec_gamma_62+3chans.mat','channames');
    cfg = [];
    cfg.layout         = lay;
    cfg.missingchannel = chans(~ismember(chans,data.label));
    cfg.neighbours     = neighbours;
    data               = ft_channelrepair(cfg, data);
    % re-ref channels
    cfg = [];
    cfg.reref = 'yes';
    cfg.refchannel = {data.label{~ismember(data.label,{'EOGH','EOGV','ECG'})}};
    data=ft_preprocessing(cfg,data);
    % save
    out_full = [base_path,subjects{subj_iter},sub_fold];
    mkdir(out_full)
    disp(['Saving data to: ',out_full,'data_interp.mat']);
    save([out_full,'data_interp.mat'],'data','lay');
    keep subj_iter subjects base_path file_name keep elecs time_subj time_per_subj
end
%%