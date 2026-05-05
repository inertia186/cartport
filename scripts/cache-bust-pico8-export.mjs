#!/usr/bin/env node
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';

const exportDir = process.argv[2];
if (!exportDir) {
  console.error('Usage: node scripts/cache-bust-pico8-export.mjs public/carts/<slug>');
  process.exit(1);
}

const indexPath = path.join(exportDir, 'index.html');
const jsName = path.basename(exportDir) === 'pixels-progress'
  ? 'pixels-progress.js'
  : null;

const html = await readFile(indexPath, 'utf8');
const match = html.match(/e\.src = "([^"]+\.js)(?:\?v=[^"]*)?";/);
const cartJs = jsName ?? match?.[1];

if (!cartJs) {
  console.error(`Could not find PICO-8 cart script reference in ${indexPath}`);
  process.exit(1);
}

const jsPath = path.join(exportDir, cartJs);
const js = await readFile(jsPath);
const hash = createHash('sha256').update(js).digest('hex').slice(0, 12);
const busted = html.replace(/e\.src = "([^"]+\.js)(?:\?v=[^"]*)?";/, `e.src = "$1?v=${hash}";`);

if (busted === html) {
  console.error(`No cache-bust replacement made in ${indexPath}`);
  process.exit(1);
}

await writeFile(indexPath, busted);
console.log(`Cache-busted ${cartJs} with v=${hash}`);
