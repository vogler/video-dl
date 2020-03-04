# run this script as a cronjob to have news to watch for breakfast
# $ crontab -e
# 0 22   *   *   *     ~/news/news-dl.sh

# serve with: cd videos; npx http-server
# open rpi4.local:8080

mkdir -p videos
cd "$(dirname "$0")/videos"

youtube-dl https://www.sat1.de/news/video/abendnachrichten-$(date '+%d-%m-%Y')-clip
youtube-dl https://www.sat1.de/news/video/abendnachrichten-$(date '+%d-%m-%Y')-ganze-folge # sometimes the URL is different, only Tuesdays?

youtube-dl https://www.tagesschau.de/sendung/tagesschau/index.html

# The following does not work because there is only an image instead of a video element until the teaser is clicked on:
# youtube-dl https://boerse.ard.de/multimedia/audios-und-videos/boerse-vor-acht/index.html
# Since the url has some number suffix which we can't guess, we have to extract the latest url from the index page first (use cheerio-cli from submodule where piping is fixed):
# youtube-dl $(curl -s https://boerse.ard.de/multimedia/audios-und-videos/boerse-vor-acht/index.html | ../cheerio-cli/bin/cheerio '.teaser a' -a href | head -n1)
# This works but youtube-dl only downloads the lowest resolution...
# DIY:
latest=$(curl -s https://boerse.ard.de/multimedia/audios-und-videos/boerse-vor-acht/index.html | grep -o 'https.*boerse-vor-acht/hr_.*\.html' | head -n1)
wget -nc $(curl -s $latest | grep -o "https://.*1280x720-50p-5000kbit\.mp4")


# delete files with an access time older than 7 days
find . -type f -atime +7 -exec rm -f {} \;
