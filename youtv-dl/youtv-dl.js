#!/usr/bin/env node

import { firefox } from 'playwright';

// console.log(process.argv); // ['.../node', '.../youtv-dl', ...]
const auth = process.argv.includes('auth');
const show = auth || process.env.SHOW == '1'; // can also set PWDEBUG=1 to show UI and debug

const cfg = {
  headless: !show,
  width: Number(process.env.WIDTH) || 1280, // width of the opened browser
  height: Number(process.env.HEIGHT) || 1280, // height of the opened browser
}

console.log(new Date(), 'started checking youtv.de');

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

  page.waitForURL('**/login').then(() => {
    if (cfg.headless) {
      console.error('Run `npx . auth` to login in the browser.');
      process.exit(1);
    }
    console.log('Please use the opened browser to login.');
  }).catch(_ => { });
  await page.waitForSelector('.recordings');
  console.log('Logged in.');
  console.log('Recordings:', await page.locator('.broadcasts-table-title').count());
  for (const l of await page.locator('.broadcasts-table-title').all()) {
    console.log('-', await l.innerText());
  }
  // await page.pause();
  // process.exit(1);
} catch (error) {
  console.error(error); // .toString()?
} finally {

}
await context.close();
