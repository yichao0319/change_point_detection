%% batch_detect_change_point
function batch_detect_change_point


    %% ----------------------
    % variables
    figure_dir = '/v/filer4b/v27q002/ut-wireless/yichao/mobile_streaming/change_point_detection/FIGURE/';
    output_dir = '/v/filer4b/v27q002/ut-wireless/yichao/mobile_streaming/change_point_detection/PRED_ERR/';
    input_dir = '/v/filer4b/v27q002/ut-wireless/yichao/mobile_streaming/traffic_prediction/PARSEDDATA/';
    input_files = { ...
        % 'example', ...
        'tcpdump.campus.walking.tcp.dat.throughput.1.txt', ...
        'tcpdump.driving.highway.midnight.tcp.dat.throughput.1.txt', ...
        'tcpdump.driving.midnight1.tcp.dat.throughput.1.txt', ...
        'tcpdump.driving.midnight2.tcp.dat.throughput.1.txt', ...
        'tcpdump.driving.midnight3.tcp.dat.throughput.1.txt', ...
        'tcpdump.driving_walking.midnight.tcp.20130204.tr1.dat.throughput.1.txt', ...
        'tcpdump.driving_walking.midnight.tcp.20130204.tr2.dat.throughput.1.txt', ...
        'tcpdump.home.shuttle.tcp.dat.throughput.1.txt', ...
        'tcpdump.home.static.tcp.dat.throughput.1.txt', ...
        'tcpdump.home.walking2.tcp.dat.throughput.1.txt', ...
        'tcpdump.home.walking.tcp.dat.throughput.1.txt', ...
        'tcpdump.office.static.midnight.tcp.dat.throughput.1.txt', ...
        'tcpdump.office.static.tcp.dat.throughput.1.txt', ...
        'tcpdump.shuttle.morning.tcp.20130206.tr1.dat.throughput.1.txt', ...
        'tcpdump.shuttle.morning.tcp.20130206.tr2.dat.throughput.1.txt', ...
        'kw_seoul_st_udp_cbr_5500kbps_iperf_dn_20x120sec_sv_20071005.pcap.throughput.1.txt', ...
        'kw_seoul_st_udp_cbr_4000~6500kbps_iperf_dn_12x5x120sec_cl_20071012.pcap.throughput.1.txt', ...
    };
    rank_methods = [0, 1];
    % rank_methods = [0];
    filter_methods = [0, 1];
    % filter_methods = [1];
    num_bootstrap = 1000;   % number of iterations for Bootstrap Analysis
    conf_threshold = 0.99;  % the threshold for Signiﬁcance Testing
    stable_threshold = 0.1;    % dynamic decide # of samples for prediction
    
    %% for prediction statistics
    %% 1. fixed number of samples
    pred_samples_nums = [3:20];  % number of samples for prediction
    avg_errs = zeros(length(input_files), length(pred_samples_nums), length(rank_methods), length(filter_methods));
    std_errs = zeros(length(input_files), length(pred_samples_nums), length(rank_methods), length(filter_methods));
    var_errs = zeros(length(input_files), length(pred_samples_nums), length(rank_methods), length(filter_methods));
    time_ratio_for_prediction_all = zeros(length(input_files), length(pred_samples_nums), length(rank_methods), length(filter_methods));
    %% 2. dynamic number of samples
    dyn_avg_errs = zeros(length(input_files), length(rank_methods), length(filter_methods));
    dyn_std_errs = zeros(length(input_files), length(rank_methods), length(filter_methods));
    dyn_var_errs = zeros(length(input_files), length(rank_methods), length(filter_methods));
    dyn_time_ratio_for_prediction_all = zeros(length(input_files), length(rank_methods), length(filter_methods));


    %% ----------------------
    % Initialization
    rand('twister',76599);  % seed
    set(0,'RecursionLimit',2000);


    %% ----------------------
    % main starts here
    for f_i = 1:length(input_files)
        input_file = input_files(f_i);
        this_filename = [input_dir char(input_file)];
        fprintf('%s\n', this_filename);

        ts = read_ts(this_filename);
        ts_len = size(ts, 2);
        fprintf('  len = %d\n', ts_len);



        for rank_i = 1:length(rank_methods)
            is_rank_based = rank_methods(rank_i);
            fprintf('  is_rank_based: %d\n', is_rank_based);
            

            for filter_i = 1:length(filter_methods)
                is_filtered = filter_methods(filter_i);
                fprintf('    is_filtered: %d\n', is_filtered);


                %% ----------------------
                % detect change points with given parameters
                this_ts = ts;
                cps = detect_change_points(this_ts, num_bootstrap, conf_threshold, is_rank_based, is_filtered, 'no_plot');


                %% ----------------------
                % print change points
                fprintf('      > cps = ');
                fprintf('%d, ', cps);
                fprintf('\n');


                %% ----------------------
                % variables for each trace
                cnt_segs = 0;   % number of segments
                segments = [];  % the length of all segments
                time_ratio_for_prediction = zeros(1, length(pred_samples_nums));


                for sample_i = 1:length(pred_samples_nums)
                    pred_samples_num = pred_samples_nums(sample_i);
                    fprintf('      samples number for prediction: %d\n', pred_samples_num);
                

                    %% ----------------------
                    % Go over the change points. 
                    % Lots of things happen here:
                    % - Calculate prediction error of avg/var/stdev
                    % - Collect segment length information for later analysis
                    % - Plot figure

                    f1 = figure;
                    %  plot raw timeseries
                    plot(1:length(ts), ts, '-b', 'LineWidth', 2);
                    hold on;
                    %  plot change points
                    plot(cps, ts(1, cps), 'ro', 'MarkerSize', 5, 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r');
                    hold on;
                    %  actual and predicted avg of the segment
                    predict_avg_err = 0;
                    predict_var_err = 0;
                    predict_std_err = 0;
                    
                    seg_start = 1;
                    for cp_i = 1:length(cps)
                        seg_end = cps(cp_i)-1;
                        
                        %% ----------------------
                        %  segment length
                        if sample_i == 1
                            segments = [segments, seg_end - seg_start + 1];
                            cnt_segs = cnt_segs + 1;
                        end


                        %% ----------------------
                        %  actual and predicted avg of the segment
                        actual_avg = mean(this_ts(1, seg_start:seg_end));
                        actual_std = std(this_ts(1, seg_start:seg_end));
                        actual_var = var(this_ts(1, seg_start:seg_end));
                        plot(seg_start:seg_end, ones(1, seg_end-seg_start+1) * actual_avg, '-g', 'LineWidth', 2);
                        hold on;


                        %% ----------------------
                        %  fixed number of samples
                        if seg_end - seg_start + 1 > pred_samples_num
                            %  the segment is long enough
                            pred_avg = mean(this_ts(1, seg_start:seg_start+pred_samples_num-1));
                            pred_std = std(this_ts(1, seg_start:seg_start+pred_samples_num-1));
                            pred_var = var(this_ts(1, seg_start:seg_start+pred_samples_num-1));

                            time_ratio_for_prediction(1, sample_i) = time_ratio_for_prediction(1, sample_i) + pred_samples_num / (seg_end - seg_start + 1);
                        else
                            %  the segment is short
                            pred_avg = actual_avg;
                            pred_std = actual_std;
                            pred_var = actual_var;

                            time_ratio_for_prediction(1, sample_i) = time_ratio_for_prediction(1, sample_i) + 1;
                        end
                        plot(seg_start:seg_end, ones(1, seg_end-seg_start+1) * pred_avg, '-y', 'LineWidth', 2);
                        hold on;
                        
                        predict_avg_err = predict_avg_err + abs(actual_avg - pred_avg) * (seg_end - seg_start + 1);
                        predict_std_err = predict_std_err + abs(actual_std - pred_std) * (seg_end - seg_start + 1);
                        predict_var_err = predict_var_err + abs(actual_var - pred_var) * (seg_end - seg_start + 1);


                        %% ----------------------
                        %  dynamic number of samples
                        if sample_i == 1
                            curr_avg = -1000000;
                            curr_std = -1000000;
                            curr_var = -1000000;
                            for sub_seg_i = seg_start:seg_end
                                pred_avg = mean(this_ts(1, seg_start:sub_seg_i));
                                pred_std = std(this_ts(1, seg_start:sub_seg_i));
                                pred_var = var(this_ts(1, seg_start:sub_seg_i));

                                if (abs(pred_avg - curr_avg) < curr_avg * stable_threshold) & (abs(pred_std - curr_std) < curr_std * stable_threshold)

                                    break;
                                end

                                curr_avg = pred_avg;
                                curr_std = pred_std;
                                curr_var = pred_var;                            
                            end

                            dyn_time_ratio_for_prediction_all(f_i, rank_i, filter_i) = dyn_time_ratio_for_prediction_all(f_i, rank_i, filter_i) + (sub_seg_i-seg_start+1) / (seg_end-seg_start+1);
                            dyn_avg_errs(f_i, rank_i, filter_i) = dyn_avg_errs(f_i, rank_i, filter_i) + abs(actual_avg - pred_avg) * (seg_end - seg_start + 1);
                            dyn_std_errs(f_i, rank_i, filter_i) = dyn_std_errs(f_i, rank_i, filter_i) + abs(actual_std - pred_std) * (seg_end - seg_start + 1);
                            dyn_var_errs(f_i, rank_i, filter_i) = dyn_var_errs(f_i, rank_i, filter_i) + abs(actual_var - pred_var) * (seg_end - seg_start + 1);
                            plot(seg_start:seg_end, ones(1, seg_end-seg_start+1) * pred_avg, '-m', 'LineWidth', 2);
                            hold on;
                        end


                        seg_start = cps(cp_i);
                    end

                    seg_end = ts_len;
                    %% ----------------------
                    %  segment length
                    if sample_i == 1
                        segments = [segments, seg_end - seg_start + 1];
                        cnt_segs = cnt_segs + 1;
                    end

                    
                    %% ----------------------
                    %  actual and predicted avg of the segment
                    actual_avg = mean(this_ts(1, seg_start:seg_end));
                    actual_std = std(this_ts(1, seg_start:seg_end));
                    actual_var = var(this_ts(1, seg_start:seg_end));
                    plot(seg_start:seg_end, ones(1, seg_end-seg_start+1) * actual_avg, '-g', 'LineWidth', 2);
                    hold on;


                    %% ----------------------
                    %  fixed number of samples
                    if seg_end - seg_start + 1 > pred_samples_num
                        %  the segment is long enough
                        pred_avg = mean(this_ts(1, seg_start:seg_start+pred_samples_num-1));
                        pred_std = std(this_ts(1, seg_start:seg_start+pred_samples_num-1));
                        pred_var = var(this_ts(1, seg_start:seg_start+pred_samples_num-1));

                        time_ratio_for_prediction(1, sample_i) = (time_ratio_for_prediction(1, sample_i) + pred_samples_num / (seg_end - seg_start + 1) ) / cnt_segs;

                    else
                        %  the segment is short
                        pred_avg = actual_avg;
                        pred_std = actual_std;
                        pred_var = actual_var;

                        time_ratio_for_prediction(1, sample_i) = (time_ratio_for_prediction(1, sample_i) + 1) / cnt_segs;

                    end
                    plot(seg_start:seg_end, ones(1, seg_end-seg_start+1) * pred_avg, '-y', 'LineWidth', 2);
                    
                    predict_avg_err = predict_avg_err + abs(actual_avg - pred_avg) * (seg_end - seg_start + 1);
                    predict_std_err = predict_std_err + abs(actual_std - pred_std) * (seg_end - seg_start + 1);
                    predict_var_err = predict_var_err + abs(actual_var - pred_var) * (seg_end - seg_start + 1);


                    %% ----------------------
                    %  dynamic number of samples
                    if sample_i == 1
                        curr_avg = -1000000;
                        curr_std = -1000000;
                        curr_var = -1000000;
                        for sub_seg_i = seg_start:seg_end
                            pred_avg = mean(this_ts(1, seg_start:sub_seg_i));
                            pred_std = std(this_ts(1, seg_start:sub_seg_i));
                            pred_var = var(this_ts(1, seg_start:sub_seg_i));

                            if (abs(pred_avg - curr_avg) < curr_avg * stable_threshold) & (abs(pred_std - curr_std) < curr_std * stable_threshold)

                                break;
                            end

                            curr_avg = pred_avg;
                            curr_std = pred_std;
                            curr_var = pred_var;                            
                        end
                        
                        dyn_time_ratio_for_prediction_all(f_i, rank_i, filter_i) = (dyn_time_ratio_for_prediction_all(f_i, rank_i, filter_i) + (sub_seg_i-seg_start+1) / (seg_end-seg_start+1)) / cnt_segs;;
                        dyn_avg_errs(f_i, rank_i, filter_i) = (dyn_avg_errs(f_i, rank_i, filter_i) + abs(actual_avg - pred_avg) * (seg_end - seg_start + 1)) / ts_len / mean(ts);
                        dyn_std_errs(f_i, rank_i, filter_i) = (dyn_std_errs(f_i, rank_i, filter_i) + abs(actual_std - pred_std) * (seg_end - seg_start + 1)) / ts_len / std(ts);
                        dyn_var_errs(f_i, rank_i, filter_i) = (dyn_var_errs(f_i, rank_i, filter_i) + abs(actual_var - pred_var) * (seg_end - seg_start + 1)) / ts_len / var(ts);
                        plot(seg_start:seg_end, ones(1, seg_end-seg_start+1) * pred_avg, '-m', 'LineWidth', 2);
                        print(f1, '-dpsc', [figure_dir char(input_file) '_rank' int2str(is_rank_based) '_filter' int2str(is_filtered) '_sample' int2str(pred_samples_num)  '.ps']);                    
                    end

                    %% end for all segments in this trace
                    %% ----------------------


                    avg_errs(f_i, sample_i, rank_i, filter_i) = predict_avg_err / ts_len / mean(ts);
                    std_errs(f_i, sample_i, rank_i, filter_i) = predict_std_err / ts_len / std(ts);
                    var_errs(f_i, sample_i, rank_i, filter_i) = predict_var_err / ts_len / var(ts);
                    fprintf('        pred avg err = %f / %f = %f (%f)\n', predict_avg_err, ts_len, predict_avg_err / ts_len, avg_errs(f_i, sample_i, rank_i, filter_i));
                    fprintf('        pred std err = %f / %f = %f (%f)\n', predict_std_err, ts_len, predict_std_err / ts_len, std_errs(f_i, sample_i, rank_i, filter_i));
                    fprintf('        pred var err = %f / %f = %f (%f)\n', predict_var_err, ts_len, predict_var_err / ts_len, var_errs(f_i, sample_i, rank_i, filter_i));

                    time_ratio_for_prediction_all(f_i, sample_i, rank_i, filter_i) = time_ratio_for_prediction(1, sample_i);


                    if sample_i == 1
                        fprintf('        dyn pred avg err = %f\n', dyn_avg_errs(f_i, rank_i, filter_i));
                        fprintf('        dyn pred std err = %f\n', dyn_std_errs(f_i, rank_i, filter_i));
                        fprintf('        dyn pred var err = %f\n', dyn_var_errs(f_i, rank_i, filter_i));
                    end


                end % end for number of samples for prediction


                %% ------------------------
                % analysis for this trace:
                % 1. mean/std/var predicton error
                tmp_avg_errs = squeeze(avg_errs(f_i, :, rank_i, filter_i));
                f1_1 = figure;
                plot(1:length(tmp_avg_errs), tmp_avg_errs, '-b*', 'LineWidth', 2, 'MarkerSize', 5);
                xlabel('# of samples used for prediction');
                ylabel('prediction error of mean');
                print(f1_1, '-dpsc', [figure_dir char(input_file) '_rank' int2str(is_rank_based) '_filter' int2str(is_filtered) '.avg_err.ps']);

                tmp_std_errs = squeeze(std_errs(f_i, :, rank_i, filter_i));
                f1_2 = figure;
                plot(1:length(tmp_std_errs), tmp_std_errs, '-b*', 'LineWidth', 2, 'MarkerSize', 5);
                xlabel('# of samples used for prediction');
                ylabel('prediction error of stdev');
                print(f1_2, '-dpsc', [figure_dir char(input_file) '_rank' int2str(is_rank_based) '_filter' int2str(is_filtered) '.std_err.ps']);

                tmp_var_errs = squeeze(var_errs(f_i, :, rank_i, filter_i));
                f1_3 = figure;
                plot(1:length(tmp_var_errs), tmp_var_errs, '-b*', 'LineWidth', 2, 'MarkerSize', 5);
                xlabel('# of samples used for prediction');
                ylabel('prediction error of var');
                print(f1_3, '-dpsc', [figure_dir char(input_file) '_rank' int2str(is_rank_based) '_filter' int2str(is_filtered) '.var_err.ps']);


                %% ------------------------
                % 2. time ratio used for prediction
                f2 = figure;
                plot(pred_samples_nums, time_ratio_for_prediction, '-b*', 'LineWidth', 2);
                xlabel('# of samples used for prediction');
                ylabel('ratio of # of samples for prediction to segment length')
                print(f2, '-dpsc', [figure_dir char(input_file) '_rank' int2str(is_rank_based) '_filter' int2str(is_filtered) '.sample_ratio_for_prediction.ps']);


                %% ------------------------
                % 3. predict segment length
                f3 = figure;
                plot(1:cnt_segs, segments, '-b*', 'LineWidth', 2);
                hold on;
                %    method 1: prev
                pred_segments_1 = [0 segments(1, 1:end-1)];
                seg_len_pred_errs_1 = abs(segments - pred_segments_1) ./ segments;
                plot(1:cnt_segs, seg_len_pred_errs_1, '-r.', 'LineWidth', 1);
                %    method 2: EWMA
                [best_alpha, prediction] = ewma_trial(segments, segments, 0.1);
                pred_segments_2 = prediction(1, 1:end-1);
                seg_len_pred_errs_2 = abs(segments - pred_segments_2) ./ segments;
                plot(1:cnt_segs, seg_len_pred_errs_2, '-g.', 'LineWidth', 1);
                %    method 3: HW
                [best_alpha, best_beta, prediction] = hw_trial(segments, segments, 0.1);
                pred_segments_3 = prediction(1, 1:end-1);
                seg_len_pred_errs_3 = abs(segments - pred_segments_3) ./ segments;
                plot(1:cnt_segs, seg_len_pred_errs_3, '-y.', 'LineWidth', 1);

                xlabel('segments');
                ylabel('length of segments (s)');
                print(f3, '-dpsc', [figure_dir char(input_file) '_rank' int2str(is_rank_based) '_filter' int2str(is_filtered) '.segment_len.ps']);
                fprintf('      segment len pred err (prev) = %f\n', mean(seg_len_pred_errs_1));
                fprintf('      segment len pred err (ewma) = %f\n', mean(seg_len_pred_errs_2));
                fprintf('      segment len pred err (hw  ) = %f\n', mean(seg_len_pred_errs_3));
                

            end % end for is_filtered
        end % end for is_rank_based


        % dlmwrite([output_dir char(input_file) '.pred_err.txt'], avg_errs, 'delimiter', '\t');
    end % end for all files



    %% ------------------------
    % fixed number of samples for prediction
    avg_errs
    dlmwrite([output_dir 'pred_avg_err.txt'], avg_errs, 'delimiter', '\t');
    tmp_avg_errs = squeeze(avg_errs(:, :, 1, 1));
    f1 = figure;
    bar(pred_samples_nums, tmp_avg_errs', 'group');
    xlabel('# of samples used for prediction');
    ylabel('prediction error of mean');
    print(f1, '-dpsc', [figure_dir 'pred_avg_err.ps']);


    std_errs
    dlmwrite([output_dir 'pred_std_err.txt'], std_errs, 'delimiter', '\t');
    tmp_std_errs = squeeze(std_errs(:, :, 1, 1));
    f2 = figure;
    bar(pred_samples_nums, tmp_std_errs', 'group');
    xlabel('# of samples used for prediction');
    ylabel('prediction error of stdev');
    print(f2, '-dpsc', [figure_dir 'pred_std_err.ps']);


    var_errs
    dlmwrite([output_dir 'pred_var_err.txt'], var_errs, 'delimiter', '\t');
    tmp_var_errs = squeeze(var_errs(:, :, 1, 1));
    f3 = figure;
    bar(pred_samples_nums, tmp_var_errs', 'group');
    xlabel('# of samples used for prediction');
    ylabel('prediction error of var.');
    print(f3, '-dpsc', [figure_dir 'pred_var_err.ps']);


    time_ratio_for_prediction_all
    dlmwrite([output_dir 'pred_time_ratio.txt'], time_ratio_for_prediction_all, 'delimiter', '\t');
    tmp_time_ratio_for_prediction_all = squeeze(time_ratio_for_prediction_all(:, :, 1, 1));
    f4 = figure;
    bar(pred_samples_nums, tmp_time_ratio_for_prediction_all', 'group');
    xlabel('# of samples used for prediction');
    ylabel('ratio of # of samples for prediction to segment length');
    print(f4, '-dpsc', [figure_dir 'num_samples_for_pred.ps']);


    %% ------------------------
    % dynamic number of samples for prediction
    dyn_avg_errs
    dlmwrite([output_dir 'dyn_pred_avg_err.txt'], dyn_avg_errs, 'delimiter', '\t');
    tmp_avg_errs = squeeze(avg_errs(:, 1, 1));
    f1 = figure;
    bar(tmp_avg_errs', 'group');
    xlabel('files');
    ylabel('prediction error of mean');
    print(f1, '-dpsc', [figure_dir 'dyn_pred_avg_err.ps']);


    dyn_std_errs
    dlmwrite([output_dir 'dyn_pred_std_err.txt'], dyn_std_errs, 'delimiter', '\t');
    tmp_std_errs = squeeze(dyn_std_errs(:, 1, 1));
    f2 = figure;
    bar(tmp_std_errs', 'group');
    xlabel('files');
    ylabel('prediction error of stdev');
    print(f2, '-dpsc', [figure_dir 'dyn_pred_std_err.ps']);


    dyn_var_errs
    dlmwrite([output_dir 'dyn_pred_var_err.txt'], dyn_var_errs, 'delimiter', '\t');
    tmp_var_errs = squeeze(dyn_var_errs(:, 1, 1));
    f3 = figure;
    bar(tmp_var_errs', 'group');
    xlabel('files');
    ylabel('prediction error of var.');
    print(f3, '-dpsc', [figure_dir 'dyn_pred_var_err.ps']);


    dyn_time_ratio_for_prediction_all
    dlmwrite([output_dir 'dyn_pred_time_ratio.txt'], dyn_time_ratio_for_prediction_all, 'delimiter', '\t');
    tmp_time_ratio_for_prediction_all = squeeze(dyn_time_ratio_for_prediction_all(:, 1, 1));
    f4 = figure;
    bar(tmp_time_ratio_for_prediction_all', 'group');
    xlabel('files');
    ylabel('ratio of # of samples for prediction to segment length');
    print(f4, '-dpsc', [figure_dir 'dyn_num_samples_for_pred.ps']);


end




%% read_ts: function description
function [ts] = read_ts(filename)
    if length(findstr(filename, 'example')) > 0
        %% ----------------------
        % example timeseries for debugging
        % from http://www.variation.com/cpa/tech/changepoint.html
        ts = [10.7, 13.0, 11.4, 11.5, 12.5, 14.1, 14.8, 14.1, 12.6, 16.0, 11.7, 10.6, 10.0, 11.4, 7.9, 9.5, 8.0, 11.8, 10.5, 11.2, 9.2, 10.1, 10.4, 10.5];
    else
        data = load(filename);
        ts = data(:, 3)';
    end
end

