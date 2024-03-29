#!/bin/bash 

# run this script as a cronjob to have news to watch for breakfast
# $ crontab -e
# 55 20,23   *   *   *     ~/news/news-dl.sh 2>&1 | tee -a /tmp/news-dl.log

# serve with: cd videos; npx http-server
# open rpi4:8080

# set -v
trap 'echo "ERROR: $BASH_SOURCE:$LINENO $BASH_COMMAND" >&2' ERR

date -R # print datetime for log
videos="$(dirname "$0")/videos"
mkdir -p $videos
cd $videos
function ytdl { # abort before youtube-dl if http status code is not 200; not needed, but faster than letting youtube-dl try first
  echo $1
  curl -o /dev/null --silent --head --write-out '%{http_code}\n' $1 | grep -q 200 && yt-dlp $1 # switched to yt-dlp since youtube-dl started to time out on sat1 videos
}

# opt=--date="1 days ago"

if [ ${SAT1:-0} -eq "1" ]; then 
  ytdl https://www.sat1.de/news/video/abendnachrichten-$(date $opt '+%d-%m-%Y')-clip # e.g. 01-01-2020
  ytdl https://www.sat1.de/news/video/abendnachrichten-$(date $opt '+%d-%m-%Y')-clip2 # happend on 12-06-2020
  ytdl https://www.sat1.de/news/video/abendnachrichten-$(date $opt '+%d-%m-%Y')-ganze-folge # sometimes the URL is different, only Tuesdays?
  ytdl https://www.sat1.de/news/video/abendnachrichten-vom-$(date $opt '+%d-%m-%Y')-ganze-folge # vom-19-04-2022
  ytdl https://www.sat1.de/news/video/abendnachrichten-$(date $opt '+%d-%B-%Y')-clip # on 09.04.2020 they changed to full month name: 09-april-2020-clip
  ytdl https://www.sat1.de/news/video/abendnachrichten-$(date $opt '+%-d-%-m-%Y')-clip # e.g. 1-1-2020; on 18.04.2020 they changed to non-leading zero for month: 18-4-2020-clip
  ytdl https://www.sat1.de/news/video/abendnachrichten-$(date $opt '+%-d-%-m-%Y')-ganze-folge # 19-4-2020-ganze-folge
fi

# ytdl https://www.tagesschau.de/sendung/tagesschau/index.html # stopped working on 26.01.2021 since ytdl can't extract download link
# hq download link example: https://download.media.tagesschau.de/video/2021/0128/TV-20210128-2021-5000.webxl.h264.mp4 but the part with 5000 changes for each episode. So we need to grep for the link. The part after the date is the time it was created/uploaded which so far was in 20:20-21:02.
# could use `curl -L -O -C -` (as an alternative to wget) which shows nice download statistics but no URL, filename, time
# `wget`'s progress bar spams log and `wget -nv` is a little too non-verbose, so we ignore the progress dots with `grep -v`
wget --timeout=5 -c $(curl -s https://www.tagesschau.de/multimedia/sendung/tagesschau_20_uhr | grep -oP 'https[^;]+-2[01]\d\d-[^;]+webxl\.h264\.mp4' | head -n1) |& grep -v '\.\{10\}'

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
# somehow youtube-dl was much faster here than yt-dlp...
# currently fails with ERROR: [ARDBetaMediathek] ... Unable to download JSON metadata: HTTP Error 404; see https://github.com/yt-dlp/yt-dlp/issues/7666
yt-dlp "https://www.ardmediathek.de$(curl -s https://www.ardmediathek.de/sendung/wirtschaft-vor-acht/Y3JpZDovL2Rhc2Vyc3RlLmRlL3dpcnRzY2hhZnQgdm9yIGFjaHQ | grep -P -o '/video/wirtschaft-vor-acht/.*?(?=")' | head -n1)"

# delete files older than 7 days. TODO only delete if not accessed
# `mount` says / is mounted with noatime - so access times are not updated
# https://unix.stackexchange.com/questions/8840/last-time-file-opened
find . -type f -atime +7 -exec rm -f {} \; # -atime/-mtime were problematic since ytdl sets atime/mtime to Last-modified header (unless --no-mtime) and sat1 has it set to constant 2000-11-19 9:52. However, -ctime (stat: Change) is fine since it changes when metadata change which happens on download.
echo
