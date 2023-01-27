# video-dl

Serve with `cd videos; npx http-server`, then `open rpi4:8080`.

## news-dl

Run this script as a cronjob to have news to watch for breakfast.

```console
$ crontab -e
# 0 22   *   *   *     ~/video-dl/news-dl.sh
```
