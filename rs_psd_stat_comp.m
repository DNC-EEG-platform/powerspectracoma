% Compute statistical contrast of two groups (e.g. survivors and
% non-survivors of coma)
%  - requires input of subjects from rs_psd_subjects_for_study.m

%%
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

%% Select groups based on day of interest

grp_pos = {''}; % String array of subjects in training set (outcome positive), including sub_folders
grp_neg = {''}; % String array of subjects in training set (negative positive), including sub_folders
%% load freq spectrum by outcome group for training and test set
base_path = ''; % path where subject folders are located (don't forget backslashes)
file_name = ''; % file containing frequency power information

% TRAINING
% pos outcome
for subj_iter = 1:numel(grp_pos)
    file_to_load=[base_path,grp_pos{subj_iter},file_name];
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
for subj_iter = 1:numel(grp_neg)
    file_to_load=[base_path,grp_neg{subj_iter},file_name];
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
%% grand average the data
cfg=[];
cfg.keepindividual = 'yes';
freq_pos_ga=ft_freqgrandaverage(cfg,freq_all_pos{:});
freq_neg_ga=ft_freqgrandaverage(cfg,freq_all_neg{:});
freq_norm_pos_ga=ft_freqgrandaverage(cfg,freq_all_norm_pos{:});
freq_norm_neg_ga=ft_freqgrandaverage(cfg,freq_all_norm_neg{:});
%% concatenate across groups to plot individuals' spectra
freq_all = {freq_all_pos{:},freq_all_neg{:}};
freq_all_norm = {freq_all_norm_pos{:},freq_all_norm_neg{:}};
subjects = {grp_pos{:},grp_neg{:}};
%% Plot all individiual subjects - spectrum only - normalized
fig1=figure;
plot_iter = 1;
ft_hastoolbox('brewermap', 1)
for i = 1:numel(freq_all_norm)
    subplot(5,ceil(numel(freq_all_norm)/5),plot_iter)
    plot_iter = plot_iter+1;
    cfg=[];
    cfg.xlim = [5 15];
    cfg.ylim = [0 0.05];
    cfg.layout='standard_1020.elc';
    cfg.channel = {frq.label{~ismember(frq.label,{'EOGH','EOGV','ECG'})}};
    ft_singleplotER(cfg,freq_all_norm{i})
    title(subjects{i}(1:4));
    if i ~= 1
        set(gca,'ytick',[])
    end
end
mtit('Normalized spectra')
fig1.Color=[1 1 1];
set(gcf, 'units','normalized','outerposition',[0 0 1 1]);

%%%%%%%%%%% GROUP LEVEL STATISTICAL COMPARISON OF POWER %%%%%%%%%%%
%% prepare neighbourhood structure 
cfg=[];
cfg.method         = 'template'; % 'triangulation' or 'template'
cfg.template       = ''; % name of the template file (e.g. gtec62_neighbours.mat)
cfg.layout         = lay; % filename of the layout, see FT_PREPARE_LAYOUT
nghbrs             = ft_prepare_neighbours(cfg);
%% compute statistic for a comparison of outcome groups
dat_a_stat = freq_all_norm_pos;
dat_b_stat = freq_all_norm_neg;

foi = [2 40]; % frequencies to use in statistical comparison
cfg = [];
cfg.channel          = {'EEG'};
cfg.frequency        = foi;
cfg.method           = 'montecarlo';
cfg.statistic        = 'ft_statfun_indepsamplesT';
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.minnbchan        = 2;
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.alpha            = 0.025;
cfg.numrandomization = 5000;
cfg.neighbours       = nghbrs;
cfg.design           = [ones(1,length(dat_a_stat)),ones(1,length(dat_b_stat))*2];
cfg.ivar             = 1;
stat                 = ft_freqstatistics(cfg, dat_a_stat{:}, dat_b_stat{:});
%% get grand average w/o retaining individuals
dat_a = ft_freqgrandaverage([],dat_a_stat{:});
dat_b = ft_freqgrandaverage([],dat_b_stat{:});
% keep individuals for boundedline plot
cfg = [];
cfg.keepindividual = 'yes';
dat_a_indiv_ga = ft_freqgrandaverage(cfg,dat_a_stat{:});
dat_b_indiv_ga = ft_freqgrandaverage(cfg,dat_b_stat{:});
% select the foi
cfg= [];
cfg.frequency = foi;
dat_a=ft_selectdata(cfg,dat_a);
dat_b=ft_selectdata(cfg,dat_b);
dat_a.mask=stat.mask;
dat_b.mask=stat.mask;
%% plot possible differences
% execute one of the combinations desired for plotting
clear idx_cluster idx_cluster_2

% get time frame of cluster

% % all statistically significant clusters
% idx_cluster(1)=min(stat.freq(any(stat.mask)));
% idx_cluster(2)=max(stat.freq(any(stat.mask)));

% % if no cluster exist, alternatively use n.s. ones to plot their extent
% positive cluster
% idx_cluster(1)=min(stat.freq(any(stat.posclusterslabelmat==1)));
% idx_cluster(2)=max(stat.freq(any(stat.posclusterslabelmat==1)));
% negative cluster
% idx_cluster(1)=min(stat.freq(any(stat.negclusterslabelmat==1)));
% idx_cluster(2)=max(stat.freq(any(stat.negclusterslabelmat==1)));


% multiple clusters (one pos and one neg here, e.g. for day 1 comp of surv and non-survs)
% idx_cluster(1)=min(stat.freq(any(stat.posclusterslabelmat==1)));
% idx_cluster(2)=max(stat.freq(any(stat.posclusterslabelmat==1)));
% idx_cluster_2(1)=min(stat.freq(any(stat.negclusterslabelmat==1)));
% idx_cluster_2(2)=max(stat.freq(any(stat.negclusterslabelmat==1)));
%% Plot spectra for paper
fig1=figure;
% set the cluster extent via grey bars at bottom of plot
fill([idx_cluster(1) idx_cluster(1) idx_cluster(2) idx_cluster(2)],[0 0.003 0.003 0],[166/255 166/255 166/255],'FaceAlpha',.5,'LineStyle','None');
if exist('idx_cluster_2','var')
    hold on;fill([idx_cluster_2(1) idx_cluster_2(1) idx_cluster_2(2) idx_cluster_2(2)],[0 0.003 0.003 0],[166/255 166/255 166/255],'FaceAlpha',.5,'LineStyle','None');
end
% plot the group-wise power with confidence intervals
cfg = [];
cfg.channel = {stat.label{any(stat.mask,2)}}; % plot significant channels
cfg.layout = lay;
cfg.ylim = [0 0.05];
cfg.boundmethod='ci';
cfg.cilevel = .95;
cfg2.frequency=[2 40];
ft_boundedline_nightly(cfg,[],dat_a_indiv_ga,dat_b_indiv_ga)
% change appearance
allines=findall(fig1,'Type','line');
set(allines,'LineWidth',2)
allaxes=findall(fig1,'Type','axes');
set(allaxes,'LineWidth',2)
hold on;
fig_tmp=gca;
hold on
% add legend
[leg,icon]=legend({'favorable outcome','unfavorable outcome'},'FontSize',12);
pause(1)
xlabel('Frequency (Hz)')
ylabel('Normalized power')
% change color of lines
col1=[0/255 188/255 213/255];
col2=[255/255 94/255 105/255];
fig1.Children(2).Children(2).Color = col1;
fig1.Children(2).Children(4).FaceColor = col1;
fig1.Children(2).Children(1).Color = col2;
fig1.Children(2).Children(3).FaceColor = col2;
fig1.Position = [680 708 480 270];
fig1.Color=[1 1 1];
fig1.PaperPositionMode='auto';
% change aesthetics of legend
    % change color of legend markers
pause(1)
icon(3).FaceColor=col1;
icon(4).FaceColor=col2;
set(gca, 'box', 'off')
% change font sizes
allaxes=findall(fig1,'Type','axes');
set(allaxes,'FontSize',12)
allaxes=findall(fig1,'Type','legend');
set(allaxes,'FontSize',12)
fig1.Position=[834   390   885   388];
%% plot topographies for survivors, non-survivors and t-map of differences between the two in cluster
% % % elecs=p_layout('ladybird'); 
fig1=figure;
cfg = [];
cfg.xlim = idx_cluster;
cfg.zlim= [0.006 0.012]; % color limits
cfg.marker='off';
cfg.comment='no';
% channels marked
cfg.highlight = 'on';
cfg.highlightchannel = {stat.label{any(stat.mask,2)}};
cfg.highlightsymbol='.';
cfg.highlightsize = 6;
cfg.layout=lay;
% plot first group topograph
subplot(1,3,1);
ft_topoplotER(cfg,dat_a)
colormap(flipud(brewermap(64,'RdBu')))
% plot second group topograph
subplot(1,3,2);
ft_topoplotER(cfg,dat_b)
% plot t-statistic of difference in pos vs. neg outcome
subplot(1,3,3);
cfg.parameter='stat';
cfg.zlim=[0 3]; % color lim of stat maps
ft_topoplotER(cfg,stat)
% % % % oPos1=fig1.Children(1).Position;
fig1.Color=[1 1 1];
fig1.PaperPositionMode='auto';
%% plot legends so they can be used/manipulated outside of MATLAB
fig1=figure;
% colorbar for normalized power
subplot(1,2,1)
colormap(flipud(brewermap(64,'RdBu')))
cb=colorbar('southoutside');
% modify colorbar
cb.Label.String = 'normalized power';
cb.Label.FontSize = 12;
cb.Ticks = [0.0050    0.0060    0.0070    0.0080];
cb.Ticks = [0.016    0.02    0.024];
caxis([0.016 0.024])
cb.Ticks = [0.006    0.008  0.010  0.012];
caxis([0.006 0.012])

% colorbar for statistical values (t-statistic)
subplot(1,2,2)
colormap(flipud(brewermap(64,'RdBu')))
cb=colorbar('southoutside');
% modify colorbar
cb.Label.String = 't-value';
cb.Label.FontSize = 12;
cb.Ticks = [0 1 2 3];
caxis([0 3])
% figure position
fig1.Position = [462 558 778 420];
fig1.Color = [1 1 1];
% set linewidth and fontsize of legend
allaxes=findall(fig1,'Type','colorbar');
set(allaxes,'LineWidth',1.5)
set(allaxes,'FontSize',12)
%% combined plot of spectra, topographies and multiplot
%%% multiplot
fig1=figure;
subplot(2,4,[3 4 7 8]);
stat.posmask = stat.posclusterslabelmat==1;
stat.negmask = stat.negclusterslabelmat==1;
cfg = [];
cfg.parameter = 'stat';
cfg.maskparameter = 'mask';
cfg.maskparameter = 'posmask';
cfg.layout = lay;
ft_multiplotER(cfg,stat)
fig1.Position=[119 351 1569 627];
%%% spectrum
cfg = [];
% cfg.parameter = 'powspctrm';
% elecs=p_layout('ladybird'); = {stat.label{any(stat.mask,2)}}; % plot significant channels
elecs=p_layout('ladybird'); 
cfg.channel = {stat.label{any(stat.posclusterslabelmat==1,2)}}; % plot significant channels
% cfg.maskparameter ='mask';
cfg.layout = lay;
subplot(2,4,[1 2]);
cfg.ylim = [0 0.05];
cfg.frequency=[1 40];
cfg.boundmethod='ci';
cfg.cilevel = .95;
ft_boundedline(cfg,[],dat_a_indiv_ga,dat_b_indiv_ga)
alllines=findall(fig1,'Type','line');
set(alllines,'LineWidth',1.5)
allaxes=findall(fig1,'Type','axes');
set(allaxes,'LineWidth',1.5)
hold on;
fig_tmp=gca;
hold on
% % plot the cluster extent on spectral lines either (in order of code): 
% % a) fill a rectangle with grey around frequencies
% % b) dashed line rectangle
% % c) add black bar at top of plot
% % d) shade area between curves (multiple lines)
fill([idx_cluster(1) idx_cluster(1) idx_cluster(2) idx_cluster(2)],[fig_tmp.YLim(1) fig_tmp.YLim(2) fig_tmp.YLim(2) fig_tmp.YLim(1)],[166/255 166/255 166/255],'FaceAlpha',.6,'LineStyle','None')
% rectangle('Position',[idx_cluster(1) fig_tmp.YLim(1) idx_cluster(2)-idx_cluster(1) fig_tmp.YLim(2)-fig_tmp.YLim(1)],'LineStyle','--')
% line([idx_cluster(1) idx_cluster(2)],[fig_tmp.YLim(2) fig_tmp.YLim(2)],'LineWidth',5,'Color',[0 0 0])
% % get indices and shade area between curves
% min_freq_idx=find(freq_norm_pos_ga.freq==idx_cluster(1));
% max_freq_idx=find(freq_norm_pos_ga.freq==idx_cluster(2));
% x2 = [freq_norm_pos_ga.freq(min_freq_idx:max_freq_idx), fliplr(freq_norm_pos_ga.freq(min_freq_idx:max_freq_idx))];
% inBetween = [squeeze(mean(mean(freq_norm_pos_ga.powspctrm(:,:,min_freq_idx:max_freq_idx),2),1))', fliplr(squeeze(mean(mean(freq_norm_neg_ga.powspctrm(:,:,min_freq_idx:max_freq_idx),2),1))')];
% fill(x2, inBetween, [166/255 166/255 166/255],'FaceAlpha',.6,'LineStyle','None');

%%% add legend and labels
legend({'Survivors','Non-survivors'})
xlabel('Frequency (Hz)')
ylabel('Normalized power')
% change line colors
col1=[0/255 188/255 213/255];
col2=[255/255 94/255 105/255];
fig1.Children(3).Children(2).Color = col1;
fig1.Children(3).Children(4).FaceColor = col1;
fig1.Children(3).Children(3).Color = col2;
fig1.Children(3).Children(5).FaceColor = col2;

%%% plot topography
cfg = [];
cfg.xlim = idx_cluster;
cfg.marker='off';
cfg.comment='no';
cfg.parameter = 'stat';
cfg.layout=lay;
plcfg.zlim=[0 3.2];
subplot(2,4,[5 6]);
ft_topoplotER(cfg,stat)
colormap(flipud(brewermap(64,'RdBu')))
title(sprintf('freq: %.2f - %.2f Hz',idx_cluster(1),idx_cluster(2)))
fig1.Color=[1 1 1];
fig1.PaperPositionMode='auto';
cb=colorbar;
cb.Label.String = 't-value';
cb.Label.FontSize = 12;
text(5,-.45,'t-values','FontSize',12)
% export_fig('D:\\Google Drive\\Arbeit\\Lausanne\\resting_state\\Paper_Spectra\\Figures\\Spectra\\d1_stat_normalized-overlap.png','-painters','-r300')
%%

