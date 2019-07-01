function ft_boundedline(cfg,cfg2,data,varargin)
%     ft_boundedline plots boundaries of data or individual underlying data
%     ft_boundedline(cfg,cfg2,data1,data2,data3,...) with at least one data input.
%     Input data must be frequency or time-lock data FT data.
%     Function accepts rpt over trials or subjects.
%     (e.g. ft_freqgrandaverage with cfg.keepindividuals = 'yes')
% 
%     Inputs recognized from cfg:
%     - cfg.viewmode ('bounded' or 'indiv' - indiv only works for one data input)
%     - cfg.alpha (default .2 sets transparency for individuals in plot)
%     - cfg.cilevel (default .95)
%     - cfg.ylim
%     - cfg.linecolor (RGB triplets in m [lines] x n [R G B] matrix, defaults to cbrewer)
% 
%     Inputs to ft_selectdata from cfg2 are supported. Leave empty (cfg2=[]) if unused.
%
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


% gather all data in one variable
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
    error('Specified data do not contain frequency or time dimension data')
end

% select defaults and additional parameters where appropriate
cfg.boundmethod = ft_getopt(cfg, 'boundmethod', 'ci');
if strcmp(cfg.boundmethod,'ci')
    cfg.cilevel = ft_getopt(cfg, 'cilevel', .95);
end
% choose viewmode
cfg.viewmode = ft_getopt(cfg,'viewmode','bounded');
if numel(data) >= 2 && strcmpi(cfg.viewmode,'indiv')
    cfg.viewmode = 'bounded';
    warning('More than one data input not supported for "indiv", outputting as "bounded"')
end
% make upper and lower boundaries
cfg.cilevel = [(1-cfg.cilevel)/2 cfg.cilevel+(1-cfg.cilevel)/2];
% set colors
cfg.linecolor = ft_getopt(cfg,'linecolor',cbrewer('qual','Set1',numel(varargin)+1,'pchip'));
cfg.linecolor = cfg.linecolor(1:numel(varargin)+1,:);
% set alpha
cfg.alpha = repmat(ft_getopt(cfg,'alpha',0.2),numel(data),1);


% avg, ts (get t-values corresponding to 95% overall)
% for grand average of powspctrm data
% src: https://ch.mathworks.com/matlabcentral/answers/159417-how-to-calculate-the-confidence-interval

if strcmp('subj_chan_freq',data{1}.dimord) || strcmp('rpt_chan_freq',data{1}.dimord)
    for i = 1:numel(data)
        dat{i} = data{i}.powspctrm;
    end
elseif strcmp('subj_chan_time',data{1}.dimord)
    for i = 1:numel(data)
        dat{i} = data{i}.individual;
    end
elseif strcmp('rpt_chan_time',data{1}.dimord)
    for i = 1:numel(data)
        dat{i} = data{i}.trial;
    end
% use chans as rpt
elseif strcmp('chan_time',data{1}.dimord) || strcmp('chan_freq',data{1}.dimord)
    for i = 1:numel(data)
        dat{i} = reshape(data{i}.avg,size(data{i}.avg,1),1,size(data{i}.avg,2));
    end
end

if strcmp(cfg.viewmode,'bounded')
    % compute the data
    for i = 1:numel(dat)
        data_avg{i}=squeeze(mean(mean(dat{i},1),2));
        ts{i} = tinv(cfg.cilevel,size(dat{i},1)-1);
        CI_dat{i}=repmat([std(squeeze(mean(dat{i},2)))/sqrt(size(dat{i},1)).*ts{i}(1)]',1,2);
    end
    % plot the figure
    boundedline(x_val, [data_avg{:}], cat(3,CI_dat{:}), 'alpha','cmap',cfg.linecolor);

elseif strcmp(cfg.viewmode,'indiv')
    for dat_iter = 1:numel(dat)
        dat_plt = squeeze(mean(dat{dat_iter},2));
        fig=plot(x_val,dat_plt,'Color',[0 0 0]);
        set(findall(fig),'Color',[cfg.linecolor, cfg.alpha])
        hold on
        plot(x_val,mean(dat_plt,1),'Color',[cfg.linecolor],'LineWidth',3);
    end
end
    
% adjust axes
fig_tmp=gca;
fig_tmp.XLim = [x_val(1) x_val(end)];
if isfield(cfg, 'ylim')
    fig_tmp.YLim = [cfg.ylim(1) cfg.ylim(2)];
end