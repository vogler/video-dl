#!/usr/bin/env node

import { firefox } from 'playwright';
import 'dotenv/config' // loads environment variables from .env
import { datetime, prompt, downloadProgress } from './util.js';

// console.log(process.argv); // ['.../node', '.../youtv-dl', ...]
const auth = process.argv.includes('auth');
const show = auth || process.env.SHOW == '1'; // can also set PWDEBUG=1 to show UI and debug

const cfg = {
  videoDir: process.env.VIDEODIR || 'data/videos',
  headless: !show,
  width: Number(process.env.WIDTH) || 1280, // width of the opened browser
  height: Number(process.env.HEIGHT) || 1280, // height of the opened browser
  email: process.env.EMAIL,
  password: process.env.PASSWORD,
}

console.log(datetime(), 'started checking youtv.de');

// https://playwright.dev/docs/auth#multi-factor-authentication
const context = await firefox.launchPersistentContext('data/browser', {
  headless: cfg.headless,
  viewport: { width: cfg.width, height: cfg.height },
  // locale: "en-US", // ignore OS locale to be sure to have english text for locators -> done via /en in URL
});

const page = context.pages().length ? context.pages()[0] : await context.newPage(); // should always exist
// console.debug('userAgent:', await page.evaluate(() => navigator.userAgent));

try {
  await page.goto('https://www.youtv.de/videorekorder', { waitUntil: 'domcontentloaded' });

  page.waitForURL('**/login').then(async () => {
    console.error('Not logged in.');
    if (cfg.headless)
      console.info('Run `npx . auth` to show the browser to login.');
    else
      console.info('You can now login in the opened browser.');
    console.info('Press ESC to skip the prompts if you want to login in the browser.');
    const email = cfg.email || await prompt({message: 'Enter email'});
    const password = email && (cfg.password || await prompt({type: 'password', message: 'Enter password'}));
    if (email && password) {
      await page.fill('#session_email', email);
      await page.fill('#session_password', password);
      await page.click('input[value="Anmelden"]');
    } else {
      console.error('Waiting for you to login.');
    }
  }).catch(_ => { });
  await page.waitForSelector('.recordings'); // blocks if not logged in
  console.log('Logged in.');

  // need to wait for request to recs.json to populate table; before there is .broadcast-message (same as if empty) which is then replaced by .broadcasts-table if not empty
  // await Promise.any([page.waitForSelector('.broadcast-message'), page.waitForSelector('.broadcasts-table')]); // .broadcast-message always resolves since it's there initially
  // const recs = page.waitForResponse('https://www.youtv.de/api/v2/recs.json'); // had this before the initial goto and await here, but only worked without context.close() at the end...
  await page.waitForLoadState('networkidle'); // easiest solution
  const rows = page.locator('tbody tr');
  console.log('Recordings:', await rows.count());
  for (const r of await rows.all()) {
    const [title, subtitle] = (await r.locator('.broadcasts-table-cell-title').innerText()).split('\n');
    const [time, duration] = (await r.locator('.broadcasts-table-cell-date').innerText()).split('\n');
    console.log(`- ${time}  (${duration})  ${title} - ${subtitle}`);
    await r.locator('.action-play').click();
    // console.log(' ', page.url());
    await page.waitForSelector('video');
    const videoUrl = await page.locator('video source').first().getAttribute('src');
    console.log(' ', 'Downloading', videoUrl, 'to', cfg.videoDir);
    const resp = await downloadProgress(videoUrl, cfg.videoDir);
    if (resp == 'exists')
      console.log(' ', 'File already exists!');
    else
      console.log(' ', 'Downloaded', resp);
    await page.waitForLoadState(); // needed if file exists
    await page.goBack(); // without the wait above got Error: NS_BINDING_ABORTED; same for goto()
  }
  // await page.pause();
} catch (error) {
  console.error(error); // .toString()?
}
await context.close();
