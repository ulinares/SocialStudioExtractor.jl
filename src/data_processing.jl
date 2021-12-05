# Data formatting and processing

function group_posts_by_sentiment(posts_arr::AbstractArray)
    sentiment_mapping = Dict(10 => "positive", -10 => "negative", 0 => "neutral")
    sentiment_dict = Dict(sentiment => [] for sentiment in ["positive", "negative", "neutral"])

    for post in posts_arr
        sentiment = post["sentiment"]

        if length(sentiment) == 0
            continue
        end

        sentiment = sentiment_mapping[sentiment[1]["value"]]
        push!(sentiment_dict[sentiment], post)
    end

    return sentiment_dict
end


function group_posts_by_source(posts_arr::AbstractArray)
    source_types = unique([post["media_type"] for post in posts_arr])
    sources_dict = Dict(st => [] for st in source_types)

    for post in posts_arr
        source_type = post["media_type"]
        push!(sources_dict[source_type], post)
    end

    return sources_dict
end


function group_posts_by_date(posts_arr::AbstractArray, current_tz::String)
    date_dict = DefaultDict{String,AbstractArray}(Vector)
    date_format = DateFormat("Y-m-dTH:M:S\\Z")

    for post in posts_arr
        date_str = post["publishedDate"]
        date = ZonedDateTime(DateTime(date_str, date_format), tz"UTC")
        date = astimezone(date, TimeZone(current_tz))
        year_month_day = join(yearmonthday(date), "-")
        push!(date_dict[year_month_day], post)
    end

    return date_dict
end
