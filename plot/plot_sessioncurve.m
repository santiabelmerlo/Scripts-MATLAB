%%
% data 1 = PL.TR1.delta.CS1
% data 2 = PL.TR1.delta.CS2

% delta,theta,beta,slowgamma,fastgamma

cs1_color = [0 128 0]/255; % Seteo el color para el CS+ apetitivo
cs2_color = [96 96 96]/255; % Seteo el color para el CS-
behaviour_color = [10 10 10]/255; % Seteo el color para comportamiento
fz_color = [255 165 0]/255; % Seteo el color para el freezing

markersize = 4;
ylim1 = -1; ylim2 = 1;

subplot(2,3,1);

% CS-
data = PL.TR1.delta.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(1,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(1, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
mean_dataprev = mean_data;
data = PL.TR5.delta.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(2,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(2, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([1 2],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;
data = PL.EXT1A.delta.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(3,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(3, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([2 3],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;
data = PL.EXT1B.delta.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(4,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(4, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([3 4],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;
data = PL.EXT2.delta.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(5,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(5, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([4 5],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;

% CS+
data = PL.TR1.delta.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(1,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(1, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
mean_dataprev = mean_data;
data = PL.TR5.delta.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(2,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(2, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([1 2],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;
data = PL.EXT1A.delta.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(3,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(3, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([2 3],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;
data = PL.EXT1B.delta.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(4,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(4, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([3 4],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;
data = PL.EXT2.delta.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(5,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(5, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([4 5],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;

line([0 6],[0 0],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
ylim([ylim1 ylim2]);
xlim([0.5 5.5]);
set(gcf, 'Color', 'white');
ylabel('Power (Z-score)'); xlabel('Session');
title('PL delta');
set(gca,'xtick',[1:5],'xticklabel',{'TR1'; 'TR5'; 'EXT1A'; 'EXT1B'; 'EXT2'})
set(gca,'FontSize',10);

subplot(2,3,2);

% CS-
data = PL.TR1.theta.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(1,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(1, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
mean_dataprev = mean_data;
data = PL.TR5.theta.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(2,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(2, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([1 2],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;
data = PL.EXT1A.theta.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(3,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(3, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([2 3],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;
data = PL.EXT1B.theta.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(4,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(4, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([3 4],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;
data = PL.EXT2.theta.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(5,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(5, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([4 5],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;

% CS+
data = PL.TR1.theta.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(1,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(1, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
mean_dataprev = mean_data;
data = PL.TR5.theta.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(2,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(2, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([1 2],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;
data = PL.EXT1A.theta.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(3,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(3, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([2 3],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;
data = PL.EXT1B.theta.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(4,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(4, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([3 4],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;
data = PL.EXT2.theta.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(5,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(5, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([4 5],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;

line([0 6],[0 0],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
ylim([ylim1 ylim2]);
xlim([0.5 5.5]);
set(gcf, 'Color', 'white');
ylabel('Power (Z-score)'); xlabel('Session');
title('PL theta');
set(gca,'xtick',[1:5],'xticklabel',{'TR1'; 'TR5'; 'EXT1A'; 'EXT1B'; 'EXT2'})
set(gca,'FontSize',10);

subplot(2,3,3);

% CS-
data = PL.TR1.beta.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(1,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(1, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
mean_dataprev = mean_data;
data = PL.TR5.beta.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(2,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(2, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([1 2],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;
data = PL.EXT1A.beta.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(3,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(3, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([2 3],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;
data = PL.EXT1B.beta.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(4,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(4, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([3 4],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;
data = PL.EXT2.beta.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(5,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(5, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([4 5],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;

% CS+
data = PL.TR1.beta.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(1,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(1, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
mean_dataprev = mean_data;
data = PL.TR5.beta.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(2,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(2, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([1 2],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;
data = PL.EXT1A.beta.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(3,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(3, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([2 3],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;
data = PL.EXT1B.beta.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(4,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(4, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([3 4],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;
data = PL.EXT2.beta.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(5,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(5, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([4 5],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;

line([0 6],[0 0],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
ylim([ylim1 ylim2]);
xlim([0.5 5.5]);
set(gcf, 'Color', 'white');
ylabel('Power (Z-score)'); xlabel('Session');
title('PL beta');
set(gca,'xtick',[1:5],'xticklabel',{'TR1'; 'TR5'; 'EXT1A'; 'EXT1B'; 'EXT2'})
set(gca,'FontSize',10);

subplot(2,3,4);

% CS-
data = PL.TR1.slowgamma.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(1,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(1, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
mean_dataprev = mean_data;
data = PL.TR5.slowgamma.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(2,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(2, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([1 2],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;
data = PL.EXT1A.slowgamma.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(3,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(3, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([2 3],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;
data = PL.EXT1B.slowgamma.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(4,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(4, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([3 4],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;
data = PL.EXT2.slowgamma.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(5,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(5, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([4 5],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;

% CS+
data = PL.TR1.slowgamma.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(1,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(1, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
mean_dataprev = mean_data;
data = PL.TR5.slowgamma.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(2,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(2, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([1 2],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;
data = PL.EXT1A.slowgamma.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(3,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(3, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([2 3],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;
data = PL.EXT1B.slowgamma.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(4,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(4, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([3 4],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;
data = PL.EXT2.slowgamma.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(5,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(5, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([4 5],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;

line([0 6],[0 0],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
ylim([ylim1 ylim2]);
xlim([0.5 5.5]);
set(gcf, 'Color', 'white');
ylabel('Power (Z-score)'); xlabel('Session');
title('PL slowgamma');
set(gca,'xtick',[1:5],'xticklabel',{'TR1'; 'TR5'; 'EXT1A'; 'EXT1B'; 'EXT2'})
set(gca,'FontSize',10);

subplot(2,3,5);

% CS-
data = PL.TR1.fastgamma.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(1,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(1, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
mean_dataprev = mean_data;
data = PL.TR5.fastgamma.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(2,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(2, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([1 2],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;
data = PL.EXT1A.fastgamma.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(3,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(3, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([2 3],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;
data = PL.EXT1B.fastgamma.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(4,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(4, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([3 4],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;
data = PL.EXT2.fastgamma.CS2;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(5,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs2_color, 'MarkerFaceColor', cs2_color);
hold on
errorbar(5, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([4 5],[mean_dataprev mean_data],'Color', cs2_color);
mean_dataprev = mean_data;

% CS+
data = PL.TR1.fastgamma.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(1,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(1, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
mean_dataprev = mean_data;
data = PL.TR5.fastgamma.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(2,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(2, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([1 2],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;
data = PL.EXT1A.fastgamma.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(3,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(3, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([2 3],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;
data = PL.EXT1B.fastgamma.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(4,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(4, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([3 4],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;
data = PL.EXT2.fastgamma.CS1;
mean_data = mean(data); sem_data = std(data)/sqrt(length(data));
plot(5,mean_data,'MarkerSize',markersize,'Marker','o','LineStyle','none','Color', cs1_color, 'MarkerFaceColor', cs1_color);
hold on
errorbar(5, mean_data, sem_data, 'k.', 'LineWidth', 1); % 'k.' specifies black dots as error bars
line([4 5],[mean_dataprev mean_data],'Color', cs1_color);
mean_dataprev = mean_data;

line([0 6],[0 0],'Color',behaviour_color,'LineWidth',0.5,'LineStyle','--');
ylim([ylim1 ylim2]);
xlim([0.5 5.5]);
set(gcf, 'Color', 'white');
ylabel('Power (Z-score)'); xlabel('Session');
title('PL fastgamma');
set(gca,'xtick',[1:5],'xticklabel',{'TR1'; 'TR5'; 'EXT1A'; 'EXT1B'; 'EXT2'})
set(gca,'FontSize',10);

Width = 12; Height = 5;
set(gcf, 'Units', 'Inches', 'Position', [0, 0, Width, Height], 'PaperUnits', 'Inches', 'PaperSize', [Width, Height])
