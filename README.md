# Power spectra scripts

related paper: Kustermann, T., Nguissi, N. A. N., Pfeiffer, C., Haenggi, M., Kurmann, R., Zubler, F., ... & De Lucia, M. (2019). Electroencephalography-based power spectra allow coma outcome prediction within 24 hours of cardiac arrest. Resuscitation. https://doi.org/10.1016/j.resuscitation.2019.05.021

Scripts that should allow the user (with some adaption required) to conduct:
- Preprocessing of EEG resting state recording
- Computation of power spectra
- Statistical comparison of two groups' power spectra 
- Prediction of outcome based on power spectra values at specificed frequencies (including training and test set splits)

- Computation of connectivity matrices based on the debiased weighted phase lag index

Dependencies (not provided here):
- FieldTrip (http://www.fieldtriptoolbox.org/download/)
- inputsdlg (https://www.mathworks.com/matlabcentral/fileexchange/25862-inputsdlg-enhanced-input-dialog-box)
- boundedline (https://github.com/kakearney/boundedline-pkg)
- cbrewer (https://www.mathworks.com/matlabcentral/fileexchange/34087-cbrewer-colorbrewer-schemes-for-matlab)
- Remaining ones provided in dependencies folder
