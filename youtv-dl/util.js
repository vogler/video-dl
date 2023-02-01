// https://stackoverflow.com/questions/37614649/how-can-i-download-and-save-a-file-using-the-fetch-api-node-js
import { join, basename } from 'path';
import { createWriteStream, existsSync, mkdirSync } from 'fs';
import { Readable } from 'stream';
import { finished } from 'stream/promises';

export const download = async (url, dir = '.', path = join(dir, basename(url))) => {
  if (existsSync(path)) return 'exists'; // TODO resume download if needed?
  mkdirSync(dir, { recursive: true });
  await finished(Readable.fromWeb((await fetch(url)).body).pipe(createWriteStream(path)));
  return path;
};


import progressStream from 'progress-stream';
import cliProgress from 'cli-progress';

export const downloadProgress = async (url, dir = '.', path = join(dir, basename(url))) => {
  if (existsSync(path)) return 'exists'; // TODO resume download if needed?
  mkdirSync(dir, { recursive: true });
  const resp = await fetch(url);
  const length = parseInt(resp.headers.get('Content-Length'));
  const s = l => Math.round(l/1024/1024);
  const ss = l => (l/1024/1024).toFixed(2);
  // console.log(`Will download ${s(length)} MB`);
  const bar = new cliProgress.Bar({
    format: '  [{bar}] {percentage}% | {value}MB/{total}MB | {duration_formatted} | {peta}s | {speed}MB/s', // included {eta} jumps around more than progress' {peta}
    hideCursor: true,
    // barCompleteChar: '#',
    barIncompleteChar: '-',
  }, cliProgress.Presets.rect);
  bar.start(s(length), 0, { speed: '0', peta: '0' });
  const str = progressStream({ length, time: 250 }, p => {
    // console.log(p);
    bar.update(s(p.transferred), { speed: ss(p.speed), peta: p.eta });
  });

  await finished(Readable.fromWeb(resp.body).pipe(str).pipe(createWriteStream(path)));
  bar.stop();
  return path;
};

// downloadProgress('https://rec.cdn.youtv.de/s/32597052823/2023-02-01_20-15_Tv-Total_pro-7_hq.mp4');
