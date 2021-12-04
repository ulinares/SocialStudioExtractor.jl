function group_posts_by_sentiment(posts_arr::AbstractArray)
    sentiment_mapping = Dict(10 => "positive", -10 => "negative", 0 => "neutral")
    sentiment_dict = Dict(sentiment => [] for sentiment in ["positive", "negative", "neutral"])

    for post in posts_arr

        if length(post["sentiment"]) == 0
            continue
        end

        sentiment = sentiment_mapping[sentiment[0]["value"]]
        push!(sentiment_dict[sentiment], post)
    end

    return sentiment_dict
end


function group_posts_by_source(posts_arr::AbstractArray)
    source_types = unique([post["media_type"] for post in posts_arr])
    sources_dict = Dict(st => [] for st in source_types)

    for post in posts_arr
        source_type = post["media_type"]
        push!(sources_dict[media_type], post)
    end

    return sources_dict
end
