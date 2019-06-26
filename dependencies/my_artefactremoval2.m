function [data] = my_artefactremoval2(cfg,data,cfg2)
%
%   MY_ARTEFACTREMOVAL allows removal of EEG artefacts specific for blinks, 
%   muscle movement, bad channels, ICA, and visual inspection by
%   user-interaction. 
%   Inputs is a data structure with segmented EEG and EOG data
%
%   example configuration file:
%   cfg                = [];
%   cfg.eeg_chans      = [1:63];
%   cfg.eog_chans      = [64 65];
%   cfg.layout         = lay;
%
%   cfg2 allows specification of options within this function (implemented
%   options for ft_componentanalysis and ft_databrowser) - additionally
%   used for thresholding and style of artifact rejection, see below
%   
%   cfg2.vis_rej:
%       - trl     (trials only)
%       - chan    (channels only)
%       - trlchan (trials and channels)
%
%   cfg2.threshold: Apply a treshold of uV below which trials or channels
%   are to be removed:
%       - yes / no (threshold apply) - without further options set will use
%       gui to determine threshold
%   Options:
%   cfg2.thresholdval: set value for which trials are to be rejected
%   (using channel unit)
%   cfg2.threshold_mintrial: set number of minimum trials
%   cfg2.thresholdtrials: yes/no - whether trials should be thresholded
%   cfg2.thresholdchannel: yes/no - whether channel should be thresholded
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

    
'RUNNING MY_ARTEFACTREMOVAL FUNCTION'

%make general configuration structure
cfgx = cfg;

lay = cfgx.layout;

% test whether defaults should be used
if ~isfield(cfg2,'viewmode')
    cfg2.viewmode='vertical';
end
if ~isfield(cfg2,'channel')
    cfg2.channel = {data.label{numel(data.label)-34:end}};
end
if ~isfield(cfg2,'layout')
    cfg2.layout = 'standard_1020.elc';
end
% general purpose of my_artefactremoval2
if ~isfield(cfg2,'threshold')
    cfg2.threshold = 'no';
end
if ~isfield(cfg2,'vis_rej')
    cfg2.vis_rej = 'trlchan';
end

if strcmpi(cfg2.vis_rej,'trl') || strcmpi(cfg2.vis_rej,'trlchan')
    % get to plotting the data
    ft_databrowser(cfg2,data);
    fig1=gcf;
    fig1.Position=[882 54 1028 940];
    % run artefact rejection on EEG data only
    cfg                     = [];
    cfg.method              = 'summary';%'channel';
    cfg.keepchannel         = 'yes';
    cfg.metric              = 'absmax';%'var';
    cfg.layout              = lay;     % this allows for plotting
    cfg.channel             = cfgx.eeg;   % only EEG channels
    data                    = ft_rejectvisual(cfg,data);
    close
end;
% split data into EEG and rest/extra data if other channels exist
% or if specified
if (~isempty(cfgx.eeg) && (length(cfgx.eeg) ~= length(data.label))) && (strcmpi(cfg2.vis_rej,'trlchan') || strcmpi(cfg2.vis_rej,'chan'))
    cfg                     = [];
    cfg.channel             = cfgx.eeg;
    data_eeg                = ft_preprocessing(cfg, data);
    
    ind = ones(size(data.label));
    ind(cfgx.eeg)=0;
    ind = find(ind==1);
    cfg                     = [];
    cfg.channel             = ind;
    data_extra              = ft_preprocessing(cfg, data);
    clear ind
else
    data_eeg = data;
end
data_db=data;
clear data;
% remove trials and channels
if strcmpi(cfg2.vis_rej,'chan') || strcmpi(cfg2.vis_rej,'trlchan')
    cfg2.viewmode  ='vertical';
    cfg2.channel   = {data_db.label{33:end}};
    cfg2.layout    = 'standard_1020.elc';
    ft_databrowser(cfg2,data_db);
    fig1=gcf;
    fig1.Position  =[882 54 1028 940];
    % run artefact rejection on EEG data only
    cfg                     = [];
    cfg.method              = 'summary';%'channel';
    cfg.keepchannel         = 'no';
    if strcmpi(cfg2.vis_rej,'chan')
        cfg.keeptrial = 'yes';
    end
    cfg.metric              = 'absmax';%'var';
    cfg.layout              = lay;     % this allows for plotting
    cfg.channel             = 'all';   % only EEG channels
    data_eeg                = ft_rejectvisual(cfg,data_eeg);
    close
end;
% reject the same trials also in data_extra (e.g. EOG, ECG)
cfg=[];
cfg.trials = ismember(data_extra.trialinfo(:,1),data_eeg.trialinfo(:,1));
data_extra=ft_selectdata(cfg,data_extra);
% concatenate if needed
if exist('data_extra','var')
    cfg                     = [];
    data                    = ft_appenddata(cfg,data_eeg,data_extra);
    data.fsample            = data_eeg.fsample;
else
    data=data_eeg;
end;
% ask via GUI for threshold parameters if requested and not all parameters set in cfg2
if strcmpi(cfg2.threshold,'yes') && (~isfield(cfg2,'thresholdval') || ~isfield(cfg2,'thresholdmin')...
        || ~isfield(cfg2,'thresholdtrials') || ~isfield(cfg2,'thresholdchannel'))
    addpath 'D:\Matlab functions\inputsdlg'
    clear Prompt
    name='Threshold-based rejection';
    Prompt(1,:) = {'Enter desired threshold', 'threshold',[]};
    DefAns = struct([]);
    formats(1,1).type = 'edit';
    formats(1,1).format = 'text';
    formats(1,1).limits = [0 1];
    DefAns(1).threshold = 'NaN';
    Prompt(2,:) = {'Do you want to remove all TRIALS above specified threshold', 'trials',[]};
    formats(2,1).type = 'list';
    formats(2,1).format = 'text';
    formats(2,1).style = 'radiobutton';
    formats(2,1).items = {'Yes','No'};
    DefAns.trials = 'No';
    Prompt(3,:) = {'Do you want to remove all CHANNELS above specified threshold', 'channels',[]};
    formats(3,1).type = 'list';
    formats(3,1).format = 'text';
    formats(3,1).style = 'radiobutton';
    formats(3,1).items = {'Yes','No'};
    DefAns.channels = 'No';
    Prompt(4,:) = {'Enter minimum number of trials to remain after applying threshold', 'min_trial',[]};
    formats(4,1).type = 'edit';
    formats(4,1).format = 'text';
    formats(4,1).limits = [0 1];
    DefAns.min_trial = '50';
    [answer,~] = inputsdlg(Prompt,name,formats,DefAns);
    answer.threshold = str2num(answer.threshold);
    answer.min_trial = str2num(answer.min_trial);
    % when all parameters for automatic threshold based rejection were set
elseif strcmpi(cfg2.threshold,'yes') && isfield(cfg2,'thresholdval') && isfield(cfg2,'thresholdmin') ...
        && isfield(cfg2,'thresholdtrials') && isfield(cfg2,'thresholdchannel')
    answer.threshold=cfg2.thresholdval;
    answer.min_trial=cfg2.thresholdmin;
    answer.trials=cfg2.thresholdtrials;
    answer.channels=cfg2.thresholdchannel;
end;
if strcmpi(cfg2.threshold,'yes')
    if strcmpi(answer.trials,'yes')
        below_thresh_trial =  cellfun(@(x) max(max(abs(x(~ismember(data.label,{'EOGH','EOGV','ECG'}),:))))<answer.threshold,data.trial,'UniformOutput',false);
        if sum([below_thresh_trial{:}]) > answer.min_trial
            cfg = [];
            cfg.trials = [below_thresh_trial{:}]';
            % add info to log by selecting trials ABOVE threshold
            data.cfg.trials_sinfo = data.sampleinfo(~[below_thresh_trial{:}]',1);
            data = ft_selectdata(cfg,data);
            warning('ON','MyWarn:TrialNo')
            warning('MyWarn:TrialNo','Number of remaining trials: %s of %s based on threshold of %s.',num2str(numel(data.trial)),num2str(numel(below_thresh_trial)),num2str(answer.threshold))
        else
            warning('ON','MyWarn:LowTrial')
            warn_thresh = sprintf('Not applying threshold - resulting trial no < %s',num2str(answer.min_trial));
            warning('MyWarn:LowTrial',warn_thresh)
        end
    end
    % reject channels acc to threshold
    if strcmpi(answer.channels,'yes')
        chan_cat=horzcat(data.trial{:});
        below_thresh_channel=max(abs(chan_cat),[],2) < answer.threshold;
        cfg = [];
        cfg.channel = {data.label{below_thresh_channel},'EOGH','EOGV','ECG'};
        data = ft_selectdata(cfg,data);
    end
end;
clear data_eeg data_extra;
end