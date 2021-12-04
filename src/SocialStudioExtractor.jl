module SocialStudioExtractor

export SocialStudioClient
export authorize_client!, refresh_client!
export get_workspaces, get_topics, get_posts
export filter_workspaces_data, filter_topics_data

export group_posts_by_sentiment, group_posts_by_source


include("data_extraction.jl")
include("data_processing.jl")


end
