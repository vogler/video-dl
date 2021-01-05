#!/bin/bash 

# run this script as a cronjob to have news to watch for breakfast
# $ crontab -e
# 0 22   *   *   *     ~/news/news-dl.sh

# serve with: cd videos; npx http-server
# open rpi4:8080

videos="$(dirname "$0")/videos"
mkdir -p $videos
cd $videos
function ytdl { # abort before youtube-dl if http status code is not 200; not needed, but faster than letting youtube-dl try first
  curl -o /dev/null --silent --head --write-out '%{http_code}\n' $1 | grep -q 200 && youtube-dl $1
}

ytdl https://www.sat1.de/news/video/abendnachrichten-$(date '+%d-%m-%Y')-clip # e.g. 01-01-2020
ytdl https://www.sat1.de/news/video/abendnachrichten-$(date '+%d-%m-%Y')-clip2 # happend on 12-06-2020
ytdl https://www.sat1.de/news/video/abendnachrichten-$(date '+%d-%m-%Y')-ganze-folge # sometimes the URL is different, only Tuesdays?
ytdl https://www.sat1.de/news/video/abendnachrichten-$(date '+%d-%B-%Y')-clip # on 09.04.2020 they changed to full month name: 09-april-2020-clip
ytdl https://www.sat1.de/news/video/abendnachrichten-$(date '+%-d-%-m-%Y')-clip # e.g. 1-1-2020; on 18.04.2020 they changed to non-leading zero for month: 18-4-2020-clip
ytdl https://www.sat1.de/news/video/abendnachrichten-$(date '+%-d-%-m-%Y')-ganze-folge # 19-4-2020-ganze-folge

ytdl https://www.tagesschau.de/sendung/tagesschau/index.html

# changed on 05.01.21 since 'boerse.ard.de zieht zu tagesschau.de (15.12.20)'
# old URL was https://www.daserste.de/information/wirtschaft-boerse/boerse-im-ersten/videosextern/index.html
# can't find any 'Börse vor Acht' on tagesschau.de, but there's
# https://www.daserste.de/information/wirtschaft-boerse/boerse-im-ersten/videosextern/index.html
# Since this is an overview and videos have a number suffix which we can't guess, we have to extract the latest URL from the index page first.
# old:
  # use cheerio-cli from submodule where piping is fixed:
  # youtube-dl $(curl -s https://boerse.ard.de/multimedia/audios-und-videos/boerse-vor-acht/index.html | ../cheerio-cli/bin/cheerio '.teaser a' -a href | head -n1)
  # This works but youtube-dl only downloads the lowest resolution...
  # DIY:
  # latest=$(curl -s https://boerse.ard.de/multimedia/audios-und-videos/boerse-vor-acht/index.html | grep -o 'https.*boerse-vor-acht/hr_.*\.html' | head -n1)
  # wget -nc $(curl -s $latest | grep -o "https://.*1280x720-50p-5000kbit\.mp4")
# new:
youtube-dl "https://daserste.de$(curl -s https://www.daserste.de/information/wirtschaft-boerse/boerse-im-ersten/videosextern/index.html | grep -o '/.*boerse-vor-acht-video-.*\.html' | head -n1)"

# delete files with an access time older than 7 days
find . -type f -atime +7 -exec rm -f {} \;
