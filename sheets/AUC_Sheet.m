%% Script to calculate AUC of CCG envelope
% Needs to load CCG_Sheet.mat file first
% Then it saves AUC_Sheet.csv

t = t{1,2};
AUC = cell(size(CCG,1),size(CCG,2));
AUC(:,1) = CCG(:,1);
t2 = t(1,251:2251);

for i = 2:size(CCG,2)
    for j = 1:size(CCG,1)
        X = abs(hilbert(CCG{j,i}));
        X = X(1,251:2251);
        AUC{j,i} = trapz(t2, X);
        disp(['Saving AUC ' num2str(j) ' and ' num2str(i)]);
    end
end

T = cell2table(AUC, 'VariableNames', column_names);
 
cd('D:\Doctorado\Analisis\Sheets');
writetable(T, 'AUC_Sheet.csv');

disp('Ready!');