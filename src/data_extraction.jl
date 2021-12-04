using HTTP
using JSON3
using Dates
using TimeZones


const API_URL = "https://api.socialstudio.radian6.com/"

mutable struct SocialStudioClient
    api_key::String
    api_secret::String
    token::String
    refresh_token::String
end

"""
Initialize a Social Studio Client.

# Examples

ss = SocialStudioClient(api\\_key, api\\_secret)

If you already have an access token, you can use it directly.

ss = SocialStudioClient(api\\_key, api\\_secret, token, refresh\\_token)
"""
SocialStudioClient(api_key::String, api_secret::String) = SocialStudioClient(api_key, api_secret, "", "")

function make_url(endpoint::String)
    return API_URL * lstrip(endpoint, '/')
end

function make_headers(ss::SocialStudioClient, kwargs...)
    return Dict("access_token" => ss.token, "Accept" => "application/json", kwargs...)
end

function authorize_client!(ss::SocialStudioClient, username::String, password::String)
    url = make_url("oauth/token")
    params = Dict(
        "grant_type" => "password",
        "client_id" => ss.api_key,
        "client_secret" => ss.api_secret,
        "username" => username,
        "password" => password
    )
    headers = Dict("Content-Type" => "application/x-www-form-urlencoded")
    resp = HTTP.post(url, headers, query = params)
    json_resp = JSON3.read(resp.body)
    ss.token = json_resp["access_token"]
    ss.refresh_token = json_resp["refresh_token"]

    nothing
end

function refresh_client!(ss::SocialStudioClient)
    url = make_url("oauth/token")
    params = Dict(
        "grant_type" => "refresh_token",
        "refresh_token" => ss.refresh_token,
        "client_id" => ss.api_key,
        "client_secret" => ss.api_secret
    )
    headers = Dict("Content-Type" => "application/x-www-form-urlencoded")
    resp = HTTP.post(url, headers, query = params)
    json_resp = JSON3.read(resp.body)

    ss.token = json_resp["access_token"]
    ss.refresh_token = json_resp["refresh_token"]

    nothing
end

function get_workspaces(ss::SocialStudioClient)
    url = make_url("v1/workspaces")
    headers = make_headers(ss)
    resp = HTTP.get(url, headers)
    json_resp = JSON3.read(resp.body)

    return json_resp["response"]
end

function filter_workspaces_data(workspaces_list::AbstractArray, workspace_name::String)
    workspaces = [workspace for workspace in workspaces_list if contains(workspace["name"], workspace_name)]
    return workspaces
end

function get_topics(ss::SocialStudioClient, workspace_group_id::String, kwargs...)
    url = make_url("v3/topics")
    params = Dict("workspaceGroupId" => workspace_group_id, kwargs...)

    headers = make_headers(ss)
    resp = HTTP.get(url, headers, query = params)
    json_resp = JSON3.read(resp.body)

    topics_list = json_resp["data"]

    return topics_list
end

function filter_topics_data(topics_list::AbstractArray, topic_title::String)
    topics = [
        topic for topic in topics_list if contains(topic["title"], topic_title)
    ]
    return topics
end

function recursive_posts_request(ss::SocialStudioClient, params::Dict)
    url = make_url("v3/posts")
    headers = make_headers(ss)
    resp = HTTP.get(url, headers, query = params)
    json_resp = JSON3.read(resp.body)

    posts_list = json_resp["data"]
    meta = json_resp["meta"]
    total_records = meta["totalCount"]

    while length(posts_list) < total_records
        print("Fetching more results... $(length(posts_list)) / $total_records")
        last_idx = posts_list[end]["id"]
        params["beforeId"] = last_idx
        resp = HTTP.get(url, headers, query = params)
        json_resp = JSON3.read(resp.body)
        new_posts = json_resp["data"]
        posts_list = [posts_list; new_posts]
    end

    return deduplicate_posts_list(posts_list), meta
end

function parse_date(date::String, tz::String; end_date = false)
    year, month, day = [parse(Int, i) for i in split(date, "-")]
    timezone = TimeZone(tz)

    if end_date
        datetime = ZonedDateTime(DateTime(year, month, day, 23, 59, 59), timezone)
    else
        datetime = ZonedDateTime(DateTime(year, month, day), timezone)
    end

    datetime_utc = DateTime(datetime, UTC)
    timestamp = datetime2unix(datetime_utc)

    # API expects unixtime in miliseconds
    return Int(timestamp * 1000)
end

function deduplicate_posts_list(posts_list::AbstractArray)
    deduplicated = Dict(post["id"] => post for post in posts_list)

    return collect(values(deduplicated))
end

function get_posts(ss::SocialStudioClient; topics_id_list::Array, start_date::String, end_date::String, tz::String, kwargs...)
    url = make_url("v3/posts")

    start_date = parse_date(start_date, tz)
    end_date = parse_date(end_date, tz; end_date = true)

    params = Dict(
        "topics" => join(topics_id_list, ","),
        "limit" => 1000,
        "startDate" => start_date,
        "endDate" => end_date,
        kwargs...
    )

    return recursive_posts_request(ss, params)

end
