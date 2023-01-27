# video-dl

Serve with `cd videos; npx http-server` ([systemd example](https://github.com/vogler/smart-home/blob/master/etc/systemd/system/video-dl-http-server.service)), then `open rpi4:8080` (replace `rpi4` with your host).

## news-dl

Run this script as a cronjob to have news to watch for breakfast.

```console
$ crontab -e
# 0 22   *   *   *     ~/video-dl/news-dl.sh
```
