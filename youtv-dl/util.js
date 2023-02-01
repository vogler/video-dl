// https://stackoverflow.com/questions/37614649/how-can-i-download-and-save-a-file-using-the-fetch-api-node-js
import { createWriteStream, existsSync, mkdirSync } from 'fs';
import { Readable } from 'stream';
import { finished } from 'stream/promises';
import { join, basename } from 'path';

export const download = async (url, dir = '.', path = join(dir, basename(url))) => {
  if (existsSync(path)) return 'exists'; // TODO resume download if needed?
  mkdirSync(dir, { recursive: true });
  await finished(Readable.fromWeb((await fetch(url)).body).pipe(createWriteStream(path)));
  return path;
};
