module SocialStudioExtractor

export SocialStudioClient
export authorize_client!, refresh_client!
export get_workspaces, get_topics, get_posts, get_media_types
export filter_workspaces_data, filter_topics_data

export group_posts_by_sentiment, group_posts_by_source, group_posts_by_date

using DataStructures
using Dates
using HTTP
using JSON3
using TimeZones

include("data_extraction.jl")
include("data_processing.jl")

end
