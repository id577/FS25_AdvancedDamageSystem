ADS_Utils = {}

function ADS_Utils.getChancePerFrameFromMeanTime(dt, meanTimeInMinutes)
    if meanTimeInMinutes <= 0 then
        return 1.0
    end
    local meanTimeInMs = meanTimeInMinutes * 60 * 1000
    return dt / meanTimeInMs
end

function ADS_Utils.calculateQuadraticMultiplier(level, threshold, lessIsWorse, customMax)
    if (lessIsWorse and level >= threshold) or (not lessIsWorse and level <= threshold) then
        return 0.0
    end
    if lessIsWorse then
        local normalizedValue = (threshold - level) / threshold
        return normalizedValue * normalizedValue
    else
        local normalizedValue = (level - threshold) / ((customMax or 1) - threshold)
        return normalizedValue * normalizedValue
    end
end
