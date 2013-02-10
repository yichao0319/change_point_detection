
%% ewma_trial
% @input
%   - real_ts: modulation * num_pkts
%        the actual tiemseries
%   - ts: modulation * num_pkts
%        the timeseries for prediction
%   - granularity:
%        the granularity to increase alpha
%
% @output
%   - best_alpha: modulation * 1
%        the selected alpha for each modulation (row)
%   - prediction: modulation * (num_pkts + 1)
%        the preducted timeseries using best_alpha
%
function [best_alpha, prediction] = ewma_trial(real_ts, ts, granularity)
    if size(ts) ~= size(real_ts)
        fprintf('size of ts (%d, %d) ~= size of real_ts (%d, %d)\n', size(ts), size(real_ts));
        error('\n');
    end

    best_err = ones(size(ts, 1), 1) * -1;
    best_alpha = zeros(size(ts, 1), 1);

    for alpha = 0.1:granularity:1
        prediction = ewma(ts, alpha);
        err = mean(abs(prediction(:, 2:end-1) - real_ts(:, 2:end)), 2);
        % fprintf('%f: %.10f, %.10f, %.10f, %.10f\n', alpha, err);

        update_ind = err < best_err | best_err == -1;
        best_err(update_ind) = err(update_ind);
        best_alpha(update_ind) = alpha;
    end

    % fprintf('\nbest err\n');
    % fprintf('%f, %f, %f, %f\n%.10f, %.10f, %.10f, %.10f\n', best_alpha, best_err);

    prediction = ewma(ts, best_alpha);
    % err = mean(abs(prediction(:, 2:end-1) - real_ts(:, 2:end)), 2);
      
    % fprintf('\nreturn err\n');
    % fprintf('%f, %f, %f, %f\n%.10f, %.10f, %.10f, %.10f\n\n', best_alpha, err);
