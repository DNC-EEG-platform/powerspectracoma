%     Predict outcome from power spectra in training and test sets

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

%% Select groups based on day of interest
training_pos = {''}; % String array of subjects in training set (outcome positive), including sub_folders
training_neg = {''}; % String array of subjects in training set (negative positive), including sub_folders
test_pos     = {''}; % String array of subjects in test set (outcome positive), including sub_folders
test_neg     = {''}; % String array of subjects in test set (negative positive), including sub_folders

foi = [8 12]; % frequencies to predict outcome from
adjust_prev='no'; % whether adjustment for prevalence in overall population should be applied
prev=0.5; % prevalence to adjust toward
ci_p_val=0.95; % confidence interval level
true_pos = 'above'; % whether subjects 'above' or 'below' the threshold should be considered to have predicted good outcome
%% load freq spectrum by outcome group for training and test set
base_path = ''; % path where subject folders are located (don't forget backslashes)
file_name = ''; % file containing frequency power information

% TRAINING
% pos outcome
for subj_iter = 1:numel(training_pos)
    file_to_load=[base_path,training_pos{subj_iter},file_name];
    load(file_to_load)
    disp(file_to_load);
    % select frequencies and channels
    cfg = [];
    cfg.frequency = [2 40];
    cfg.channel= {frq.label{~ismember(frq.label,{'EOGH','EOGV','ECG'})}}; % remove ECG/EOG channels from data
    frq=ft_selectdata(cfg,frq);
    freq_all_pos{subj_iter} = frq;
    % normalize power spectra for each subject
    freq_all_norm_pos{subj_iter} = freq_all_pos{subj_iter};
    freq_all_norm_pos{subj_iter}.powspctrm = bsxfun(@rdivide, freq_all_pos{subj_iter}.powspctrm, sum(freq_all_pos{subj_iter}.powspctrm,2));
end
% neg outcome
for subj_iter = 1:numel(training_neg)
    file_to_load=[base_path,training_neg{subj_iter},file_name];
    load(file_to_load)
    disp(file_to_load);
    % select frequencies and channels
    cfg = [];
    cfg.frequency = [2 40];
    cfg.channel = {frq.label{~ismember(frq.label,{'EOGH','EOGV','ECG'})}}; % remove ECG/EOG channels from data
    frq=ft_selectdata(cfg,frq);
    freq_all_neg{subj_iter} = frq;
    % normalize power spectra for each subject
    freq_all_norm_neg{subj_iter} = freq_all_neg{subj_iter};
    freq_all_norm_neg{subj_iter}.powspctrm = bsxfun(@rdivide, freq_all_neg{subj_iter}.powspctrm, sum(freq_all_neg{subj_iter}.powspctrm,2));
end

% TEST
% pos outcome
for subj_iter = 1:numel(test_pos)
    file_to_load=[base_path,test_pos{subj_iter},'\5s_segm_nothresh\freq\',file_name];
    load(file_to_load)
    disp(file_to_load);
    % select frequencies and channels
    cfg = [];
    cfg.frequency = [2 40];
    cfg.channel= {frq.label{~ismember(frq.label,{'EOGH','EOGV','ECG'})}}; % remove ECG/EOG channels from data
    frq=ft_selectdata(cfg,frq);
    freq_all_pos_test{subj_iter} = frq;
    % normalize power spectra for each subject
    freq_all_norm_pos_test{subj_iter} = freq_all_pos_test{subj_iter};
    freq_all_norm_pos_test{subj_iter}.powspctrm = bsxfun(@rdivide, freq_all_pos_test{subj_iter}.powspctrm, sum(freq_all_pos_test{subj_iter}.powspctrm,2));
end
% neg outcome
for subj_iter = 1:numel(test_neg)
    file_to_load=[base_path,test_neg{subj_iter},'\5s_segm_nothresh\freq\',file_name];
    load(file_to_load)
    disp(file_to_load);
    % select frequencies and channels
    cfg = [];
    cfg.frequency = [2 40];
    cfg.channel = {frq.label{~ismember(frq.label,{'EOGH','EOGV','ECG'})}}; % remove ECG/EOG channels from data
    frq=ft_selectdata(cfg,frq);
    freq_all_neg_test{subj_iter} = frq;
    % normalize power spectra for each subject
    freq_all_norm_neg_test{subj_iter} = freq_all_neg_test{subj_iter};
    freq_all_norm_neg_test{subj_iter}.powspctrm = bsxfun(@rdivide, freq_all_neg_test{subj_iter}.powspctrm, sum(freq_all_neg_test{subj_iter}.powspctrm,2));
end
%% grand average the data
cfg=[];
cfg.keepindividual = 'yes';

% training
freq_pos_ga=ft_freqgrandaverage(cfg,freq_all_pos{:});
freq_neg_ga=ft_freqgrandaverage(cfg,freq_all_neg{:});
freq_norm_pos_ga=ft_freqgrandaverage(cfg,freq_all_norm_pos{:});
freq_norm_neg_ga=ft_freqgrandaverage(cfg,freq_all_norm_neg{:});
% test
freq_pos_test_ga=ft_freqgrandaverage(cfg,freq_all_pos_test{:});
freq_neg_test_ga=ft_freqgrandaverage(cfg,freq_all_neg_test{:});
freq_norm_pos_test_ga=ft_freqgrandaverage(cfg,freq_all_norm_pos_test{:});
freq_norm_neg_test_ga=ft_freqgrandaverage(cfg,freq_all_norm_neg_test{:});
%% select frequencies for which to predict outcome (e.g. from extent of cluster)
cfg = [];
cfg.frequency = foi;
cfg.avgoverfreq = 'yes';
cfg.channel = 'EEG';
cfg.avgoverchan = 'yes';
% train
train_frq_pos = ft_selectdata(cfg,freq_norm_pos_ga);
train_frq_neg = ft_selectdata(cfg,freq_norm_neg_ga);
% test
test_frq_pos = ft_selectdata(cfg,freq_norm_pos_test_ga);
test_frq_neg = ft_selectdata(cfg,freq_norm_neg_test_ga);
%% find best ppv
z_val=norminv(ci_p_val);
%
dat_a=train_frq_pos.powspctrm;
dat_b=train_frq_neg.powspctrm;
dat_c=test_frq_pos.powspctrm;
dat_d=test_frq_neg.powspctrm;
title_1  = sprintf('%i-%i Hz',foi(1),foi(2));
%% compute prediction in training set
train_res = predict_comp(dat_a,dat_b,'true_pos',true_pos,'adjust_prev',adjust_prev,'ci_val',ci_p_val);
%% compute prediction in test set
test_res = predict_comp(dat_a,dat_b,'true_pos',true_pos,'adjust_prev',adjust_prev,'ci_val',ci_p_val,'thresh_vals',train_res.thresh_set);
%%
% move to plotting variables
plot_a=dat_a';
plot_b=dat_b';
plot_c=dat_c';
plot_d=dat_d';

% add jitter in plotting
rand_a=rand(size(plot_a));
rand_b=rand(size(plot_b));
rand_c=rand(size(plot_c));
rand_d=rand(size(plot_d));
%% PLOT - adaptive threshold plotting

alpha_deg = 1; % opacity
random_degree=0.2; % magnitude of horizontal scatter jitter

% the color values were (probably) derived from the color scheme of gramm (itself using the ggplot scheme I think) and creating a more
% "red" version plus a lighter red version for differentiation - same for blue colors
colors_scatter={[0 .57 .84],[1 .37 .41],[0 .74 .84],[255/255 102/255 204/255]};% dark blue, dark red,light blue, purple/red;

idx=1;

grps = {'favorable','unfavorable'};
% title_plot = sprintf('%s - %.1f%% pruned',title_1,100-thresh_to_sel);
% prepare aesthetics (e.g. boxes around individual points)
min_box = min([plot_a,plot_b,plot_c,plot_d])-range([plot_a,plot_b,plot_c,plot_d])*0.05;
thresh_low = thresh_set - min_box - range([plot_a,plot_b,plot_c,plot_d])*0.005;
thresh_high = thresh_set + range([plot_a,plot_b,plot_c,plot_d])*0.005;
max_box = max([plot_a,plot_b,plot_c,plot_d])+range([plot_a,plot_b,plot_c,plot_d])*0.05 - thresh_high;
pred_text=max_box+thresh_high-range([plot_a,plot_b,plot_c,plot_d])*(0.05:0.07:0.40);
pred_text_2 = pred_text(end)-range([plot_a,plot_b,plot_c,plot_d])*(0.10:0.07:0.45);
thresh_text = thresh_set + range([plot_a,plot_b,plot_c,plot_d])*0.05;

label_low = min_box+thresh_low/2;
label_high = thresh_high+max_box/2;

fig1=figure;hold on;
% plot survivors/non-survivors by training/test set
scatter(-0.05+1-rand_a*random_degree,plot_a,'Marker','.','MarkerEdgeColor',[0 .57 .84],'MarkerFaceColor',[0 .57 .84],'MarkerEdgeAlpha',alpha_deg)
scatter(0.05+1+rand_c*random_degree,plot_c,'Marker','.','MarkerEdgeColor',[1 .37 .41],'MarkerFaceColor',[1 .37 .41],'MarkerEdgeAlpha',alpha_deg)
scatter(-0.05+2-rand_b*random_degree,plot_b,'Marker','.','MarkerEdgeColor',[0 .57 .84],'MarkerFaceColor',[0 .57 .84],'MarkerEdgeAlpha',alpha_deg)
scatter(0.05+2+rand_d*random_degree,plot_d,'Marker','.','MarkerEdgeColor',[1 .37 .41],'MarkerFaceColor',[1 .37 .41],'MarkerEdgeAlpha',alpha_deg)


ylabel('normalized power')
xlim([-.5 4.5]) % set x axis to create space to fit annotations
plot([0.3 2.7],[thresh_set thresh_set],'LineStyle','--','Color',[169/255 169/255 169/255]) % threshold line
% label columns (x-axis)
fig1.Children.XTick = [1 2];
fig1.Children.XTickLabel = grps;
h=xlabel('Outcome');
h.Position= [1.5 -0.0011 -1];
% rectangles around subjects
rectangle('Position', [0.7 min_box 0.6 thresh_low],'LineStyle','--','LineWidth',1.25)
rectangle('Position', [0.7 thresh_high 0.6 max_box],'LineStyle','--','LineWidth',1.25)
rectangle('Position', [1.7 min_box 0.6 thresh_low],'LineStyle','--','LineWidth',1.25)
rectangle('Position', [1.7 thresh_high 0.6 max_box],'LineStyle','--','LineWidth',1.25)

% gather prediction subject counts
if strcmp(true_pos,'above')
    low_s = [FN_train,FN_test];
    high_s = [TP_train,TP_test];
    high_ns = [FP_train,FP_test];
    low_ns = [TN_train,TN_test];
elseif strcmp(true_pos,'below')
    low_s = [TP_train,TP_test];
    high_s = [FN_train,FN_test];
    high_ns = [TN_train,TN_test];
    low_ns = [FP_train,FP_test];
end
text(-.15,label_high,sprintf('Training/Test \nn = (%s/%s)',num2str(high_s(1)),num2str(high_s(2))),'FontSize',11)
text(.1,label_low,['n = (',num2str(low_s(1)),'/',num2str(low_s(2)),')'],'FontSize',11)
text(2.35,label_low,['n = (',num2str(low_ns(1)),'/',num2str(low_ns(2)),')'],'FontSize',11)
text(2.35,label_high,['n = (',num2str(high_ns(1)),'/',num2str(high_ns(2)),')'],'FontSize',11)

% add prediction values for training set
text(3,pred_text(1),sprintf('{\\bfTraining} ({\\itn}=%i)',numel(plot_a)+numel(plot_b)))
text(3,pred_text(2),sprintf('PPV: %.2f (CI: %.2f-%.2f)',ppv_train,ppv_ci_train{idx}(1),ppv_ci_train{idx}(2)))
text(3,pred_text(3),sprintf('NPV: %.2f (CI: %.2f-%.2f)',npv_train,npv_ci_train{idx}(1),npv_ci_train{idx}(2)))
text(3,pred_text(4),sprintf('Sensitivity: %.2f (CI: %.2f-%.2f)',sens_train(idx),sens_ci_train{idx}(1),sens_ci_train{idx}(2)))
text(3,pred_text(5),sprintf('Specificity: %.2f (CI: %.2f-%.2f)',spec_train(idx),spec_ci_train{idx}(1),spec_ci_train{idx}(2)))
text(3,pred_text(6),sprintf('Accuracy: %.2f (CI: %.2f-%.2f)',acc_train(idx),acc_ci_train{idx}(1),acc_ci_train{idx}(2)))
text(-.3,thresh_text,sprintf('Threshold: %.5f',thresh_set))
% add prediction values for test set
text(3,pred_text_2(1),sprintf('{\\bfTest} ({\\itn}=%i)',numel(plot_c)+numel(plot_d)))
text(3,pred_text_2(2),sprintf('PPV: %.2f (CI: %.2f-%.2f)',ppv_test(idx),ppv_ci_test{idx}(1),ppv_ci_test{idx}(2)))
text(3,pred_text_2(3),sprintf('NPV: %.2f (CI: %.2f-%.2f)',npv_test(idx),npv_ci_test{idx}(1),npv_ci_test{idx}(2)))
text(3,pred_text_2(4),sprintf('Sensitivity: %.2f (CI: %.2f-%.2f)',sens_test(idx),sens_ci_test{idx}(1),sens_ci_test{idx}(2)))
text(3,pred_text_2(5),sprintf('Specificity: %.2f (CI: %.2f-%.2f)',spec_test(idx),spec_ci_test{idx}(1),spec_ci_test{idx}(2)))
text(3,pred_text_2(6),sprintf('Accuracy: %.2f (CI: %.2f-%.2f)',acc_test(idx),acc_ci_test{idx}(1),acc_ci_test{idx}(2)))

% change figure aesthetics
fig1.Color = [1 1 1];
fig1.Position=[834   390   885   588];
fig1.Children.FontSize=12;
% title(title_plot);

% add legend
[leg,icons]=legend({sprintf('Training ({\\itn}=%i)',numel(plot_a(~isnan(plot_a)))+numel(plot_b(~isnan(plot_b)))),
    sprintf('Test ({\\itn}=%i)',numel(plot_c(~isnan(plot_c)))+numel(plot_d(~isnan(plot_d))))},'Location','SouthEast','FontSize',12);
leg.Position=[0.7246    0.1632    0.1254    0.0782];

% enlarge points in figure and legend
set(findall(gca),'LineWidth',2);
set(findobj(gca,'Type','Scatter'),'SizeData',400);
set(findall(gca,'Type','Text'),'FontSize',11);
pause(1)
icons(3).Children.MarkerSize=25;
icons(4).Children.MarkerSize=25;

fig1.Children(2).YTickLabel(fig1.Children(2).YTick < 0)={''}; % remove ticks below zero
fig1.PaperPositionMode = 'auto';