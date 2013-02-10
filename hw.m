%% hw: function description
function prediction = hw(timeseries, alpha, beta)
    prediction = zeros(size(timeseries, 1), size(timeseries, 2) + 1);
    a = zeros(size(timeseries, 1), 1);
    b = zeros(size(timeseries, 1), 1);

    for ti = 1:size(timeseries, 2)
        a_new = alpha .* timeseries(:, ti) + (1 - alpha) .* (a + b);
        b_new = beta .* (a_new - a) + (1 - beta) .* b;
        prediction(:, ti+1) = a_new + b_new;

        a = a_new;
        b = b_new;
    end
end
