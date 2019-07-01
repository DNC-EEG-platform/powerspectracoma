function ft_boundedline(cfg,cfg2,data,varargin)
% ft_boundedline accepts arguments of structure
% ft_boundedline(cfg,cfg2,data1,data2,data3,...) with at least one data input.
% Input data must be frequency or time-lock data FT data.
% Function accepts rpt over trials or subjects.
% (e.g. ft_freqgrandaverage with cfg.keepindividuals = 'yes')
%
% Inputs recognized from cfg: 
% - cfg.cilevel (default .95)
% - cfg.ylim
% - cfg.linecol (RGB triplets in m [lines] x n [R G B] matrix, defaults to cbrewer)
% Inputs to ft_selectdata from cfg2 are supported. Leave empty (cfg2=[]) if unused.
%
%
% to-do:
% - allow selection of CI, SE, SD as boundary parameters
addpath(genpath('D:\Matlab functions\boundedline-pkg-master'))

% gather all data in one variable
% for i = 1:length(varargin)
%     data={data,varargin{i}};
% end;
data = {data,varargin{:}};


% apply ft_selectdata
for i = 1:length(data)
    data{i}=ft_selectdata(cfg2,data{i});
end

% recognize dimord
if ~isempty(strfind(data{1}.dimord,'freq')) % for freq inputs
    x_val = data{1}.freq;
elseif ~isempty(strfind(data{1}.dimord,'time')) % for time inputs
    x_val = data{1}.time;
else
    error('Specified data do not contain frequency or time dimension')
end

% select defaults and additional parameters where appropriate
cfg.boundmethod = ft_getopt(cfg, 'boundmethod', 'ci');
if strcmp(cfg.boundmethod,'ci')
    cfg.cilevel = ft_getopt(cfg, 'cilevel', .95);
end
% make upper and lower boundaries
cfg.cilevel = [(1-cfg.cilevel)/2 cfg.cilevel+(1-cfg.cilevel)/2];
% set colors
cfg.linecolor = ft_getopt(cfg,'linecolor',cbrewer('qual','Set3',numel(varargin)+1,'pchip'));
cfg.linecolor = cfg.linecolor(1:numel(varargin)+1,:);


% avg, ts (get t-values corresponding to 95% overall)
% for grand average of powspctrm data
% src: https://ch.mathworks.com/matlabcentral/answers/159417-how-to-calculate-the-confidence-interval

if strcmp('subj_chan_freq',data{1}.dimord) || strcmp('rpt_chan_freq',data{1}.dimord)
    for i = 1:numel(data)
        data_avg{i}=squeeze(mean(mean(data{i}.powspctrm,1),2));
        ts{i} = tinv(cfg.cilevel,size(data{i}.powspctrm,1)-1);
        CI_dat{i}=repmat([std(squeeze(mean(data{i}.powspctrm,2)))/sqrt(size(data{i}.powspctrm,1)).*ts{i}(1)]',1,2);
    end
elseif strcmp('subj_chan_time',data{1}.dimord)
    for i = 1:numel(data)
        data_avg{i}=squeeze(mean(mean(data{i}.avg,1),2));
        ts{i} = tinv([0.025 0.975],size(data{i}.avg,1)-1);
        CI_dat{i}=repmat([std(squeeze(mean(data{i}.avg,2)))/sqrt(size(data{i}.avg,1)).*ts{i}(1)]',1,2);
    end
elseif strcmp('rpt_chan_time',data{1}.dimord)
    for i = 1:numel(data)
        data_avg{i}=squeeze(mean(mean(data{i}.trial,1),2));
        ts{i} = tinv([0.025 0.975],size(data{i}.trial,1)-1);
        CI_dat{i}=repmat([std(squeeze(mean(data{i}.avg,2)))/sqrt(size(data{i}.avg,1)).*ts{i}(1)]',1,2);
    end
end
% plot the figure
boundedline(x_val, [data_avg{:}], cat(3,CI_dat{:}), 'alpha');
% adjust axes
fig_tmp=gca;
fig_tmp.XLim = [x_val(1) x_val(end)];
if isfield(cfg, 'ylim')
    fig_tmp.YLim = [cfg.ylim(1) cfg.ylim(2)];
end;