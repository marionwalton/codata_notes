terms="search_term"
ad_type="ad_type=POLITICAL_AND_ISSUE_ADS"
field_terms="['ad_creation_time','ad_delivery_start_time','ad_delivery_stop_time','ad_creative_bodies','page_id','page_name','currency','spend','demographic_distribution','bylines','impressions','delivery_by_region']"
fields="fields=$field_terms"
access_token="access_token=TOKEN_GOES_HERE"
#['ZA','US']
ad_reached_countries="ad_reached_countries=['ZA']"
south_africa_only=true;
filter_region_python_name="remove_non_sa_regions.py"
to_csv_python_name="JSON_To_CSV.py"
terms_formatted=$(echo $terms | sed "s/ /%20/g")
search_terms="search_terms=$terms_formatted"
limit="limit=50"
expired_token_error="190"
url="https://graph.facebook.com/v16.0/ads_archive"
base_public_url="https://www.facebook.com/ads/library/?id="
error_file_name="error_output.json"
results_file="results/results-$terms.json"
command="curl -G -d \"$ad_reached_countries\" -d \"$search_terms\" -d \"$ad_type\" -d \"$access_token\" -d \"$limit\" -d \"$fields\" $url"
echo $command
first_page=$(eval $command)
error_code=$(echo $first_page | jq -r '.error.code')

echo $first_page | jq > first-page.json 
if [[ $(echo $first_page | jq -r '.error.code') != null ]]
then
    if [ $error_code == $expired_token_error ]
    then
        echo -e "\nYour token has probbaly expired or is invalid. Please generate a new one\n"
    fi
    echo $first_page | jq > $error_file_name
    echo $first_page | jq '.error.message'
    echo "See $error_file_name for more details"

    exit 1
fi

next_page_url=$(echo $first_page | jq -r '.paging.next')
# first_page=$(cat first-page.json)
results=$(echo $first_page | jq '.data')

while [ "$next_page_url" != "null" ]
do
    echo $next_page_url
    next_page_command="curl -G \"$next_page_url\""
    current_page=$(eval $next_page_command)
    echo $current_page > currentpage.json
    current_page_data=$(echo $current_page | jq '.data')
    results=$(echo -e "$current_page_data\n$results" | jq -s 'add')
    next_page_url=$(echo $current_page | jq -r '.paging.next')
done

results=$(echo $results | jq --arg base_url "$base_public_url" 'map(. + {public_url: ($base_url+.id)})')
echo $results > results.json
if $south_africa_only 
then
    echo "Is South Africa only"
    python $filter_region_python_name
    python $to_csv_python_name
  fi

total_ads=$(echo $results | jq '. | length')
mkdir results
echo $results | jq > "$results_file"

echo "Total Ads: $total_ads"
echo "Find the results in $results_file"