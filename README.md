# Power spectra scripts

related paper: Kustermann, T., Nguissi, N. A. N., Pfeiffer, C., Haenggi, M., Kurmann, R., Zubler, F., ... & De Lucia, M. (2019). Electroencephalography-based power spectra allow coma outcome prediction within 24 hours of cardiac arrest. Resuscitation. https://doi.org/10.1016/j.resuscitation.2019.05.021

Scripts that should allow the user (with some adaptions required) to conduct:
- Preprocessing of EEG resting state recording (rs_psd_preprocessing.m)
- Computation of power spectra (rs_psd_compute_freq_spectra.m)
- Statistical comparison of two groups' power spectra (rs_psd_stat_comp.m)
- Prediction of outcome based on power spectra values at specificed frequencies (including training and test set splits) (rs_psd_prediction.m)

- Computation of connectivity matrices based on the debiased weighted phase lag index (conn/rs_conn_dwPLI.m & conn/rs_conn_dwPLI_trl_time_varying.m)

Dependencies (not provided here):
- FieldTrip (http://www.fieldtriptoolbox.org/download/)
- inputsdlg (https://www.mathworks.com/matlabcentral/fileexchange/25862-inputsdlg-enhanced-input-dialog-box)
- boundedline (https://github.com/kakearney/boundedline-pkg)
- cbrewer (https://www.mathworks.com/matlabcentral/fileexchange/34087-cbrewer-colorbrewer-schemes-for-matlab)
- Remaining ones provided in dependencies folder
