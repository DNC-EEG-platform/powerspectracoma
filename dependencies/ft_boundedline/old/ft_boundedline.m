function ft_boundedline(cfg,data,varargin)
% ft_boundedline accepts arguments of structure
% ft_boundedline(cfg,cfg2,data1,data2,data3,...) with at least one data input.
% Input data must be of dimord subj_chan_freq or subj_chan_time to properly work
% (e.g. ft_freqgrandaverage with cfg.keepindividuals = 'yes').
% Inputs recognized: 
% - cfg.cilevel (default .95)
% - cfg.ylim
% Inputs to ft_selectdata from cfg are supported.
% to:
% - fully implement for timelock grandaverages
% - allow tweaking of confidence interval levels
% - allow selection of CI, SE, SD as boundary parameters
addpath(genpath('D:\Matlab functions\boundedline-pkg-master'))

data = {data,varargin{:}};


% apply ft_selectdata
for i = 1:length(data)
    data{i}=ft_selectdata(cfg,data{i});
end

% recognize dimord
if ~isempty(strfind(data{1}.dimord,'freq')) % for freq inputs
    x_val = data{1}.freq;
elseif ~isempty(strfind(data{1}.dimord,'time')) % for time inputs
    x_val = data{1}.time;
else
    error('Specified data do not contain frequency or time dimension')
end

% select method and  additional parameters where appropriate
if isfield(cfg,'boundmethod') && strcmpi(cfg.boundmethod,'ci')
    if ~isfield(cfg,'cilevel')
        cfg.cilevel=.95;
    else
        cfg.cilevel=cfg.cilevel/100;
    end;
    cfg.cilevel = [(1-cfg.cilevel)/2 cfg.cilevel+(1-cfg.cilevel)/2];
end;
    
% avg, ts (get t-values corresponding to 95% overall)
% for grand average of powspctrm data
% src: https://ch.mathworks.com/matlabcentral/answers/159417-how-to-calculate-the-confidence-interval
if strcmpi(cfg.boundmethod,'ci') && strcmp('subj_chan_freq',data{1}.dimord)
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
end;
% plot the figure
boundedline(x_val, [data_avg{:}], cat(3,CI_dat{:}), 'alpha');
% adjust axes
fig_tmp=gca;
fig_tmp.XLim = [x_val(1) x_val(end)];
if isfield(cfg, 'ylim')
    fig_tmp.YLim = [cfg.ylim(1) cfg.ylim(2)];
end;