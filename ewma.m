%% ewma: function description
function prediction = ewma(timeseries, alpha)
    prediction = zeros(size(timeseries, 1), size(timeseries, 2) + 1);

    for ti = 1:size(timeseries, 2)
        if ti == 1
            prediction(:, 2) = timeseries(:, 1);
        else
            prediction(:, ti+1) = alpha .* timeseries(:, ti) + (1-alpha) .* prediction(:, ti);
        end
    end
end
