
function [cps] = detect_change_points(ts, num_bootstrap, conf_threshold, is_rank_based, is_filtered, plot_name)

    %% ----------------------
    % raw or rank-based timeseries
    if is_rank_based == 1
        ts = cal_rank(ts);
    end


    %% ----------------------
    % apply lowpass filter or not
    if is_filtered == 1
        ts = lowpass_filter_2(ts);
    end


    %% ----------------------
    % CUSUM
    [S, S_diff] = cusum(ts, plot_name);


    %% ----------------------
    % Bootstrap Analysis
    cnt_larger = 0;
    for b_i = 1:num_bootstrap
        % permutation
        ts_perm = ts(1, randperm(length(ts)));
        [this_S, this_S_diff] = cusum(ts_perm, [plot_name '_perm_' int2str(b_i)]);
        if S_diff > this_S_diff
            cnt_larger = cnt_larger + 1;
        end
    end


    %% ----------------------
    % Signiﬁcance Testing
    confidence = cnt_larger / num_bootstrap;
    if confidence <= conf_threshold 
        %% ----------------------
        % no change point
        cps = [];
        return;

    else
        %% ----------------------
        % Change has been detected.
        % Next, estimate when the change occurred 
        % method 1: |S_m| = max |S_i|, m+1 is the change point
        [C, cp] = max(abs(S));
        cp = cp(1) - 1 + 1; % bc S starts from 0

        if cp >= length(ts)
            cps = [];
            return;
        end

    end


    %% ----------------------
    % Recursive detection:
    % break timeseries into two segments, 
    % one each side of the change-point, 
    % and the analysis repeated for each segment.
    ts_seg1 = ts(1, 1:cp);
    ts_seg2 = ts(1, cp+1:end);
    if length(ts_seg1) > 1
        % only run when the segment is long enough
        cps_seg1 = detect_change_points(ts_seg1, num_bootstrap, conf_threshold, 0, 0, [plot_name '_seg1']);
        cps = [cps_seg1, cp];
    else
        cps = [cp];
    end

    if length(ts_seg2) > 1
        % only run when the segment is long enough
        cps_seg2 = detect_change_points(ts_seg2, num_bootstrap, conf_threshold, 0, 0, [plot_name '_seg2']) + cp;
        cps = [cps, cps_seg2];
    end
end



%% cal_rank
function [rank_ts] = cal_rank(ts)
    sorted_ts = sort(ts);
    ts_len = length(ts);

    rank_ts = zeros(1, ts_len);
    for ts_i = 1:ts_len
        rank_ts(1, ts_i) = mean(find(sorted_ts == ts(1, ts_i)), 2);
    end
end


%% lowpass_filter
function [filtered_ts] = lowpass_filter(ts)
    a = 1/3;
    filtered_ts = filter(a, [1 a-1], ts);


    %% -------------------
    % DEBUG
    % f1 = figure;
    % plot(1:length(ts), ts, '-b.', 1:length(ts), filtered_ts, '-.r.');
    % print(f1, '-dpsc', ['filtered_ts.ps']);
end


function [filtered_ts] = lowpass_filter_2(ts)
    filtered_ts = zeros(1, length(ts));
    win = 3;

    for ts_i = 1:length(ts)
        if ts_i < win
            filtered_ts(1, ts_i) = median(ts(1:ts_i));
        else
            filtered_ts(1, ts_i) = median(ts(ts_i-win+1:ts_i));
        end
    end


    %% -------------------
    % DEBUG
    % f1 = figure;
    % plot(1:length(ts), ts, '-b.', 1:length(ts), filtered_ts, '-.r.');
    % print(f1, '-dpsc', ['filtered_ts.ps']);
end
