import { readFile, writeFile, rename } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
const appearance = process.argv[2];
if (!['light', 'dark'].includes(appearance)) {
  console.error('Usage: bun select-appearance.mjs light|dark');
  process.exit(1);
}
const destination = fileURLToPath(new URL('./app-store-screenshots.json', import.meta.url));
const source = new URL(`../projects/${appearance}.json`, import.meta.url);
const contents = await readFile(source, 'utf8');
JSON.parse(contents);
await writeFile(`${destination}.tmp`, contents);
await rename(`${destination}.tmp`, destination);
console.log(`Selected ${appearance}. Refresh the editor to load this preset. This replaces the current editor composition; your exported PNGs are preserved.`);
