// https://stackoverflow.com/questions/37614649/how-can-i-download-and-save-a-file-using-the-fetch-api-node-js
import { createWriteStream, mkdirSync } from 'fs';
import { Readable } from 'stream';
import { finished } from 'stream/promises';
import { join, basename } from 'path';

export const download = async (url, dir = '.', path = join(dir, basename(url))) => {
  mkdirSync(dir, { recursive: true });
  return await finished(Readable.fromWeb((await fetch(url)).body).pipe(createWriteStream(path)));
};
