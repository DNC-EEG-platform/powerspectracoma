%     Compute the frequency spectra from preprocessed files

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

%% Script to preprocess EEG data
% Dependencies:
% - FieldTrip (http://www.fieldtriptoolbox.org/download/)

%% compute freq spectrum
clear
base_path = ''; % path where subject folders are located (don't forget backslashes)
file_name = '/FOLDER/data_interp.mat'; % path to move to within patient folder
sub_fold = '/freq/';
out_file = 'data_freq_mtm.mat';
subjects = {''}; % contains the subject strings including the path to top-level files
for subj_iter = 1:numel(subjects)        
    display(['Loading data from: ',base_path,subjects{subj_iter},file_name]);
    load([base_path,subjects{subj_iter},file_name])
    % compute frequency spectra
    cfg                         = [];
    cfg.method                  = 'mtmfft';
    cfg.taper                   = 'dpss';
    cfg.tapsmofrq               = 1; % smoothing
    cfg.foi                     = 1:0.2:40;
%     cfg.keeptrials              = 'yes';
    frq                         = ft_freqanalysis(cfg,data);
    %
    mkdir([base_path,subjects{subj_iter},sub_fold]);
    % Save results
    out_full = [base_path,subjects{subj_iter},sub_fold,out_file];
    display(['Saving data to: ',out_full]);
%     save(out_file,'frq','lay');
    %
    keep subj_iter subjects base_path file_name keep elecs
end