
%% hw_trial: function description
function [best_alpha, best_beta, prediction] = hw_trial(real_ts, ts, granularity)
    if size(ts) ~= size(real_ts)
        fprintf('size of ts (%d, %d) ~= size of real_ts (%d, %d)\n', size(ts), size(real_ts));
        error('\n');
    end

    best_err = ones(size(ts, 1), 1) * -1;
    best_alpha = zeros(size(ts, 1), 1);
    best_beta = zeros(size(ts, 1), 1);

    for alpha = 0.1:granularity:1
        for beta = 0:granularity:1
            prediction = hw(ts, alpha, beta);
            err = mean(abs(prediction(:, 2:end-1) - real_ts(:, 2:end)), 2);
            % fprintf('%f: %.10f, %.10f, %.10f, %.10f\n', alpha, err);

            update_ind = err < best_err | best_err == -1;
            best_err(update_ind) = err(update_ind);
            best_alpha(update_ind) = alpha;
            best_beta(update_ind) = beta;
        end
    end

    % fprintf('\nbest err\n');
    % fprintf('%f, %f, %f, %f\n%.10f, %.10f, %.10f, %.10f\n', best_alpha, best_err);

    prediction = hw(ts, best_alpha, best_beta);
    % err = mean(abs(prediction(:, 2:end-1) - real_ts(:, 2:end)), 2);
      
    % fprintf('\nreturn err\n');
    % fprintf('%f, %f, %f, %f\n%.10f, %.10f, %.10f, %.10f\n\n', best_alpha, err);
