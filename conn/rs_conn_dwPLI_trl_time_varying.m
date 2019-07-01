%     Compute the debiased weighted phase lag index for bshorter blocks
%     of trials from preprocessed files

%     Preprocessing script that will segent data, filter the, allow for 
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
%% Dependencies
% - FieldTrip (http://www.fieldtriptoolbox.org/download/)
%%
base_path   = ''; % folder where subjects reside in
subjects    = {''}; % subjects incl. relevant sub-path
in_file     = ''; % file from preprocessing to be used in connectivity
output_conn = ''; % computed connectivity file
sub_conn    = ''; % sub path of connectivity file

for subj_iter = 1:numel(subjects)
    load_file = [base_path,subjects{subj_iter},in_file];
    disp(['Loading data from: ',load_file]);
    load(load_file)
    % make sure all trials contain same time axis
    time_per_trial=round(data.time{1}(end)-data.time{1}(1));
    samples_per_trial=time_per_trial*data.fsample;
    time_equal = time_per_trial/samples_per_trial:time_per_trial/samples_per_trial:time_per_trial;
    data.time=cellfun(@(x) time_equal,data.time,'UniformOutput',false);
    % iterator to select 5 epochs for one block of connectivity estimation
    trl_iter=1;
    dwpli={};
    for packs = 1:5:floor(size(data.trialinfo,1)/5)*5
        % select chunck of 5 trials
        cfg=[];
        inc_trl = zeros(size(data.trialinfo,1),1);
        inc_trl(packs:packs+4)=1;
        cfg.trials=logical(inc_trl);
        data_tmp=ft_selectdata(cfg,data);
        warning(sprintf('Using trials %i to %i of %i for analysis',find(inc_trl,1),find(inc_trl,1,'last'),size(data.trialinfo,1)))
        % perform frequency analysis on the chunks
        cfg            = [];
        cfg.pad        = 15;
        cfg.output     = 'fourier';
        cfg.method     = 'mtmfft';
        cfg.foi        = 1:1:40;
        cfg.tapsmofrq  = 1;
        cfg.keeptrials = 'yes';
        frq    = ft_freqanalysis(cfg, data_tmp);
        %
        cfg=[];
        cfg.channel = {frq.label{~ismember(frq.label,{'EOGH','EOGV'})}};
        cfg.method='wpli_debiased';
        dwpli{trl_iter}=ft_connectivityanalysis(cfg,frq);
        trl_iter=trl_iter+1;
    end
    % save results of connectivity estimation
    outputfile=[base_path,subjects{subj_iter},sub_conn,output_conn];
    mkdir([base_path,subjects{subj_iter},sub_conn])
    disp(['Saving data to: ',outputfile]);
    save(outputfile,'dwpli','lay');
end