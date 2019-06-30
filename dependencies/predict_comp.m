function [data] = predict_comp(dat_a,dat_b,varargin)
%     Function that will predict outcome based on the numeric vectors
%     entered for dat_a and dat_b
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


% set defaults in case no arguments passed to func
default_adj         = 'no';
default_prev        = 0.5;
default_ci          = 0.95;
default_true_pos    = 'above';
default_thresh_vals = sort(unique([dat_a;dat_b]));

p = inputParser;
addParameter(p,'adjust_prev',default_adj,@ischar);
addParameter(p,'true_pos',default_true_pos,@ischar);
addParameter(p,'prev',default_prev,@isnumeric);
addParameter(p,'ci_val',default_ci,@isnumeric);
addParameter(p,'thresh_vals',default_thresh_vals);

parse(p,varargin{:});

adjust_prev = p.adjust_prev;
true_pos    = p.true_pos;
prev        = p.prev;
ci_p_val    = p.ci_val;
thresh_pred = p.thresh_vals;
%% compute prediction
% ppv, npv, sensitivity, specificity, accuracy including confidence
% intervals
TN=[];FN=[];FP=[];TP=[];
ppv=[];npv=[];sens=[];spec=[];acc=[];
ppv_ci=[];npv_ci=[];sens_ci=[];spec_ci=[];acc_ci=[];

% compute prediction at each threshold value
for thresh_iter=1:numel(thresh_pred)
    if strcmpi(true_pos,'below')
        TN(thresh_iter)=length(find(dat_b' > thresh_pred(thresh_iter)));
        FN(thresh_iter)=length(find(dat_a' > thresh_pred(thresh_iter)));
        FP(thresh_iter)=length(find(dat_b' <= thresh_pred(thresh_iter)));
        TP(thresh_iter)=length(find(dat_a' <= thresh_pred(thresh_iter)));
    elseif strcmpi(true_pos,'above')
        TN(thresh_iter)=length(find(dat_b' < thresh_pred(thresh_iter)));
        FN(thresh_iter)=length(find(dat_a' < thresh_pred(thresh_iter)));
        FP(thresh_iter)=length(find(dat_b' >= thresh_pred(thresh_iter)));
        TP(thresh_iter)=length(find(dat_a' >= thresh_pred(thresh_iter)));
    end
    
    %
    TP_iter=TP(thresh_iter);
    FP_iter=FP(thresh_iter);
    TN_iter=TN(thresh_iter);
    FN_iter=FN(thresh_iter);
    
    % accuracy
    [acc(thresh_iter),acc_ci{thresh_iter}]=...
        binofit((TP_iter+TN_iter),(TP_iter+FP_iter+FN_iter+TN_iter),1-ci_p_val);
    
    % sensitivity
    [sens(thresh_iter),sens_ci{thresh_iter}]=...
        binofit(TP_iter,TP_iter+FN_iter,1-ci_p_val);
    
    % specificity
    [spec(thresh_iter),spec_ci{thresh_iter}]=...
        binofit(TN_iter,TN_iter+FP_iter,1-ci_p_val);
    
    % bifurcation for whether an adjustment for prevalence in population should be made for PPV and NPV
    if strcmp(adjust_prev,'no')
        % positive predictive value (PPV)
        [ppv(thresh_iter),ppv_ci{thresh_iter}]=...
            binofit(TP_iter,TP_iter+FP_iter,1-ci_p_val);
        % negative predictive value (NPV)
        [npv(thresh_iter),npv_ci{thresh_iter}]=...
            binofit(TN_iter,TN_iter+FN_iter);
    elseif strcmp(adjust_prev,'yes') % adjust for actual prevalence numbers
        % positive predictive value (PPV)
        ppv(thresh_iter)=(sens(thresh_iter)*prev)/...
            (sens(thresh_iter)*prev+(1-spec(thresh_iter))*(1-prev));
        ppv_tmp = ppv(thresh_iter);
        ppv_se=sqrt((ppv_tmp*(1-ppv_tmp))/(TP_iter+FP_iter));
        ppv_ci{thresh_iter}=[ppv_tmp-z_val*ppv_se, ppv_tmp+z_val*ppv_se];
        % negative predictive value (NPV)
        npv(thresh_iter)=(spec(thresh_iter)*(1-prev))/...
            (spec(thresh_iter)*(1-prev)+(1-sens(thresh_iter))*prev);
        npv_tmp=npv(thresh_iter);
        npv_se=sqrt((npv_tmp*(1-npv_tmp))/(TN_iter+FN_iter));
        npv_ci{thresh_iter}=[npv_tmp-z_val*npv_se, npv_tmp+z_val*npv_se];
    end
end
%% identify highest ppv across pruning levels and thresholds

% find best threshold per pruning level with min 10 predictions in PPV
pred_vals=[TP;FP;TN;FN;...
    ppv;npv;sens;spec;acc;thresh_pred']';
% find maximal ppv with min 10 correct TP
tmp_1=pred_vals;
tmp_1(TP<10,:)=0;
[~,idx]=max(tmp_1(:,5)); % finds max POSITIVE PREDICTIVE VALUE
max_ppv=tmp_1(idx,:);
max_ppv_ci.acc    = acc_ci{idx};
max_ppv_ci.sens   = sens_ci{idx};
max_ppv_ci.spec   = spec_ci{idx};
max_ppv_ci.ppv    = ppv_ci{idx};
max_ppv_ci.npv    = npv_ci{idx};
thresh_set = max_ppv(10); % value to use for prediction in test set
% gather in one variable
data.max_ppv    = max_ppv;
data.thresh_set = thresh_set;
data.max_ppv_ci = max_ppv_ci;
