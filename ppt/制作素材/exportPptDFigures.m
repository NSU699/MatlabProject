function exportPptDFigures()
% exportPptDFigures  从已保存结果生成墨灰松石汇报的图表副本
% 输入：results 下的 CSV/MAT，原始文件只读；不重新求解数值问题。
% 输出：figures/ppt-D/*.png，对应重制PPT第5、6、8、9、10、11页。
% 作者：庄肃涵；排版整理日期与运行日期：2026-09-12。

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
dst = fullfile(root,'figures','ppt-D');
if ~exist(dst,'dir'), mkdir(dst); end
data = fullfile(root,'results');
teal = [59 157 154]/255; gold = [155 125 64]/255; navy = [53 78 104]/255;
fd = readtable(fullfile(data,'poisson_convergence.csv'));
rk = readtable(fullfile(data,'ode_convergence.csv'));
rr = readtable(fullfile(data,'poisson_richardson_summary.csv'));
ss = readtable(fullfile(data,'poisson_shooting_analysis_summary.csv'));
mm = readtable(fullfile(data,'ode_method_comparison.csv'),'TextType','string');

% 第5页：解析值均取自已保存节点文件。
coarse = readtable(fullfile(data,'poisson_n008_points.csv'));
dense = readtable(fullfile(data,'poisson_n256_points.csv'));
[fig,ax] = panel();
plot(ax,dense.x,dense.uExact,'-','Color',navy,'LineWidth',3.5);
plot(ax,coarse.x,coarse.uNum,'o','Color',teal,'MarkerFaceColor','w','MarkerSize',13,'LineWidth',3);
xlabel(ax,'x'); ylabel(ax,'u(x)'); xlim(ax,[-1 1]); xticks(ax,[-1 0 1]); yticks(ax,[-.4 -.2 0]);
legend(ax,{'Exact','FD, N=8'},'Location','north','Orientation','horizontal','FontSize',36,'Box','off');
savePanel(fig,dst,'fd-solution');
[fig,ax] = panel(); orderPlot(ax,fd.h,fd.maxError,2,teal);
savePanel(fig,dst,'fd-convergence');

% 第6页：共同粗网格上的最大误差，无拟合或数据筛选改动。
[fig,ax] = panel();
loglog(ax,rr.h,rr.coarseMaxError,'o-','Color',navy,'LineWidth',3.5,'MarkerSize',11);
loglog(ax,rr.h,rr.richardsonMaxError,'s-','Color',teal,'LineWidth',3.5,'MarkerSize',11);
xlabel(ax,'h'); ylabel(ax,'E_{max}');
set(ax,'XScale','log','YScale','log'); xticks(ax,[.01 .1]); yticks(ax,10.^(-10:4:-2));
legend(ax,{'FD','Richardson'},'Location','southeast','FontSize',36,'Box','off');
savePanel(fig,dst,'richardson');

% 第8页：只用已保存的解析节点值和RK4节点值。
old = load(fullfile(data,'ode_experiment.mat'));
[fig,ax] = panel();
last = old.out{end}; first = old.out{1};
plot(ax,last.t,last.yExact,'-','Color',navy,'LineWidth',3.5);
plot(ax,first.t,first.yNum(:,1),'o','Color',teal,'MarkerFaceColor','w','MarkerSize',13,'LineWidth',3);
xlabel(ax,'t'); ylabel(ax,'y(t)'); xlim(ax,[0 3]); xticks(ax,[0 1 2 3]); yticks(ax,[1 4 7]);
legend(ax,{'Exact','RK4, N=6'},'Location','northwest','FontSize',36,'Box','off');
savePanel(fig,dst,'rk-solution');
[fig,ax] = panel(); orderPlot(ax,rk.h,rk.maxError,4,teal);
savePanel(fig,dst,'rk-convergence');

% 第9页：三方法的函数调用次数与误差，完整保留七组结果。
[fig,ax] = panel();
keys = ["Euler","RK2","RK4"]; colors = [gold;navy;teal]; symbols = {'o-','s--','^-.'};
for k=1:3
    selected = mm.methodKey==keys(k);
    loglog(ax,mm.functionEvaluations(selected),mm.maxError(selected),symbols{k}, ...
        'Color',colors(k,:),'LineWidth',3.5,'MarkerSize',10);
end
set(ax,'XScale','log','YScale','log'); xlabel(ax,'W'); ylabel(ax,'E_{max}');
xticks(ax,[10 100 1000]); yticks(ax,10.^(-10:5:0));
legend(ax,cellstr(keys),'Location','southwest','FontSize',36,'Box','off');
savePanel(fig,dst,'work-precision');

% 第10页：从已保存的打靶解和斜率还原零斜率解，不重新求解。
raw = load(fullfile(data,'poisson_shooting_raw.mat'));
sol = raw.rawSolutions{3};
z = sol.uShooting - sol.shootingMeta.initialSlope*(sol.x+1);
[fig,ax] = panel();
plot(ax,sol.x,z,'--','Color',gold,'LineWidth',3.5);
plot(ax,sol.x,sol.uShooting,'-','Color',teal,'LineWidth',3.5);
yline(ax,0,':','Color','#89949E','LineWidth',1.5,'HandleVisibility','off');
xlabel(ax,'x'); ylabel(ax,'u, z'); xlim(ax,[-1 1]); xticks(ax,[-1 0 1]); yticks(ax,[-.5 0 .5 1 1.5]);
legend(ax,{'z(x)','u(x)'},'Location','northwest','FontSize',36,'Box','off');
savePanel(fig,dst,'shooting-process');

% 第11页：三方解对比与误差收敛；方法间差值在正文另行解释。
coarse = readtable(fullfile(data,'poisson_shooting_n008_raw.csv'));
[fig,ax] = panel();
plot(ax,dense.x,dense.uExact,'-','Color',navy,'LineWidth',3.5);
plot(ax,coarse.x,coarse.uFiniteDifference,'o','Color',gold,'MarkerSize',13,'LineWidth',3);
plot(ax,coarse.x,coarse.uShooting,'x','Color',teal,'MarkerSize',14,'LineWidth',3);
xlabel(ax,'x'); ylabel(ax,'u(x)'); xlim(ax,[-1 1]); xticks(ax,[-1 0 1]); yticks(ax,[-.4 -.2 0]);
legend(ax,{'Exact','FD','Shooting'},'Location','north','Orientation','horizontal','FontSize',36,'Box','off');
savePanel(fig,dst,'shooting-compare');
[fig,ax] = panel();
loglog(ax,ss.h,ss.maxFiniteDifferenceExact,'o--','Color',navy,'LineWidth',3.5,'MarkerSize',11);
loglog(ax,ss.h,ss.maxShootingExact,'s-','Color',teal,'LineWidth',3.5,'MarkerSize',11);
set(ax,'XScale','log','YScale','log'); xlabel(ax,'h'); ylabel(ax,'E_{max}');
xticks(ax,[.01 .1]); yticks(ax,10.^(-12:4:-4));
legend(ax,{'FD','Shooting'},'Location','southeast','FontSize',36,'Box','off');
savePanel(fig,dst,'shooting-convergence');
fprintf('PPT_D_FIGURES_OK: 9 PNGs from saved data, no solver rerun.\n');
end

function [fig,ax] = panel()
fig=figure('Visible','off','Color','w','Position',[100 100 1000 650]);
ax=axes(fig,'Position',[.21 .27 .75 .66]); hold(ax,'on');
set(ax,'Color','w','XColor','k','YColor','k','FontName','Times New Roman', ...
    'FontSize',44,'LineWidth',1.6,'Box','off','GridAlpha',.12);
grid(ax,'on');
end

function orderPlot(ax,h,err,p,color)
loglog(ax,h,err,'o-','Color',color,'LineWidth',3.5,'MarkerSize',12);
ref = err(1)/3*(h/h(1)).^p;
loglog(ax,h,ref,'--','Color','#89949E','LineWidth',2);
set(ax,'XScale','log','YScale','log'); xlabel(ax,'h'); ylabel(ax,'E_{max}');
xticks(ax,[.01 .1]);
if p==2, yticks(ax,10.^(-6:2:-2)); else, yticks(ax,10.^(-10:3:-1)); end
legend(ax,{'E_{max}',sprintf('O(h^{%d})',p)},'Location','southeast','FontSize',38,'Box','off');
end

function savePanel(fig,dst,name)
set(findall(fig,'Type','legend'),'TextColor','k','Color','w','FontSize',44);
set(findall(fig,'Type','axes'),'XMinorGrid','off','YMinorGrid','off');
set(findall(fig,'Type','text'),'Color','k');
exportgraphics(fig,fullfile(dst,[name '.png']),'Resolution',200,'BackgroundColor','white');
close(fig);
end
