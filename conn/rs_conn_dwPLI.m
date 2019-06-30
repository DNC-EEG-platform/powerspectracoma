%     Compute the debiased weighted phase lag index from preprocessed files

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
%% compute freq spectrum
base_path   = ''; % folder where subjects reside in
subjects    = {''}; % subjects incl. relevant sub-path
in_file     = ''; % file from preprocessing to be used in connectivity
output_frq  = ''; % computed frequency file
output_conn = ''; % computed connectivity file
sub_frq     = ''; % sub path of frequency file
sub_conn    = ''; % sub path of connectivity file
for subj_iter = 1:numel(subjects)    
        load_file = [base_path,subjects{subj_iter},in_file];
        display(['Loading data from: ',[base_path,subjects{subj_iter},in_file]]);
        load(load_file)
        % make sure all trials contain same time axis 
        time_per_trial=round(data.time{1}(end)-data.time{1}(1));
        samples_per_trial=time_per_trial*data.fsample;
        time_equal = time_per_trial/samples_per_trial:time_per_trial/samples_per_trial:time_per_trial;
        data.time=cellfun(@(x) time_equal,data.time,'UniformOutput',false);
        %
        cfg            = [];
        cfg.pad        = 15;
        cfg.output     = 'fourier';
        cfg.method     = 'mtmfft';
        cfg.foi        = 1:1:40;
        cfg.tapsmofrq  = 1;
        cfg.keeptrials = 'yes';
        frq    = ft_freqanalysis(cfg, data);
        % save
        outputfile_frq=[base_path,subjects{subj_iter},sub_frq,output_frq];
        mkdir([base_path,subjects{subj_iter},sub_frq]);
        display(['Saving data to: ',outputfile_frq]);
        save(outputfile_frq,'frq','lay');
        %% compute debiased weighted phase lag index
        cfg=[];
        cfg.channel = {frq.label{~ismember(frq.label,{'EOGH','EOGV'})}};
        cfg.method='wpli_debiased';
        dwpli=ft_connectivityanalysis(cfg,frq);
        % save
        outputfile_conn=[base_path,subjects{subj_iter},sub_conn,output_conn];
        mkdir([base_path,subjects{subj_iter},sub_conn]);
        display(['Saving data to: ',outputfile_conn]);
        save(outputfile_conn,'dwpli','lay');
        %
        keep subj_iter subjects base_path file_name  time_subj time_per_subj subj_miss_iter output_name in_file output_frq output_conn sub_frq sub_conn
end;