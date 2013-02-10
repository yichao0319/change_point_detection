%% cusum
function [S, S_diff] = cusum(ts, plot_name)

    if nargin == 1
        plot_name = 'no_plot';
    end

    %% ----------------------------------
    % variables
    figure_dir = './FIGURE/';


    %% ----------------------------------
    %% figure for debuging
    if length(findstr(plot_name, 'no_plot')) == 0
        f1 = figure;
        plot(ts);
        print(f1, '-dpsc', [figure_dir plot_name '_ts.ps']);
    end


    %% ----------------------------------
    % CUSUM: 
    %   http://www.variation.com/cpa/tech/changepoint.html
    avg = mean(ts, 2);
    ts_var = [0, ts - avg];
    S = cumsum(ts_var);
    S_diff = max(S) - min(S);


    %% ----------------------------------
    %% figure for debuging
    if length(findstr(plot_name, 'no_plot')) == 0
        f2 = figure;
        plot(S);
        print(f2, '-dpsc', [figure_dir plot_name '_S.ps']);
    end


end
