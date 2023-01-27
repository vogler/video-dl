#!/bin/bash

# ids of recordings as json, e.g. [5353866,5353907]
ids=$(curl 'https://www.youtv.de/videorekorder' -s \
 -H 'cookie: tvguide_current_group_uid=hauptsender; G_ENABLED_IDPS=google; recording_view=recordings; normal_cookies_accepted=1; AWSALB=...; _bstv_session=...' \
 --compressed | ggrep -oP 'data-recordings=.*?\K\[.*?\]')

echo $ids
ids=$(echo $ids | sed 's/[][]//g' | sed 's/,/\n/')
for id in $ids; do
  # echo "https://www.youtv.de/tv-sendungen/$id/streamen";
  curl "https://www.youtv.de/tv-sendungen/$id/streamen" -s \
 -H 'cookie: tvguide_current_group_uid=hauptsender; G_ENABLED_IDPS=google; recording_view=recordings; normal_cookies_accepted=1; AWSALB=...; _bstv_session=...' \
 --compressed | ggrep -oP '".*?_hq\.mp4"' | sed 's/"//g' | xargs -L 1 wget --no-check-certificate
done

# TODO get cookies from Chrome automatically
# https://gist.github.com/kamikat/7a9c3c5a495e41aed26b
# sqlite3 -separator '  ' ~/Library/Application\ Support/Google/Chrome/Default/Cookies "select name,encrypted_value from cookies where host_key='www.youtv.de'"

# yt-dlp PR for --cookies-from-browser: https://github.com/yt-dlp/yt-dlp/pull/488/files#diff-c042473d560a04c6fd504c3cb3ae2c9a56a27e42458132a265a3ffda0d60a5c7R64
# use of load_cookies: yt-dlp/yt-dlp.py

# keyring password:
# security find-generic-password -w -a Chrome
