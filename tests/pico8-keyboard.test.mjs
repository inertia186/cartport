import assert from 'node:assert/strict';
import test from 'node:test';
import { installPico8KeyboardNavigation } from '../src/pico8Keyboard.js';

// Exercise the adapter's event contract without booting or replacing the VM.
// Browser focus traversal and the native runtime still need a browser pass.
function fixture() {
  const attributes = new Map();
  const counts = { launches: 0, focused: 0, exits: 0, styles: 0 };
  const launcher = {
    setAttribute: (key, value) => attributes.set(key, value),
    removeAttribute: (key) => attributes.delete(key),
    click: () => counts.launches++
  };
  const win = new EventTarget();
  win.focus = () => counts.focused++;
  const doc = {
    getElementById: (id) => id === 'p8_start_button' ? launcher : null,
    createElement: () => ({ remove: () => counts.styles-- }),
    head: { append: () => counts.styles++ }
  };
  const frame = { contentDocument: doc, contentWindow: win };
  const install = () => installPico8KeyboardNavigation(frame, 'Example', () => counts.exits++);
  function press(key, overrides = {}) {
    const event = new Event('keydown', { cancelable: true });
    Object.defineProperties(event, Object.fromEntries(
      Object.entries({ key, target: launcher, repeat: false, ...overrides })
        .map(([name, value]) => [name, { value }])
    ));
    win.dispatchEvent(event);
    return event;
  }
  return { attributes, counts, launcher, win, frame, install, press };
}

test('launcher is named, focusable, and activates through Enter or Space', () => {
  for (const key of ['Enter', ' ']) {
    const f = fixture();
    f.install();
    assert.equal(f.attributes.get('role'), 'button');
    assert.equal(f.attributes.get('tabindex'), '0');
    assert.equal(f.attributes.get('aria-label'), 'Play Example');
    assert.equal(f.press(key).defaultPrevented, true);
    assert.equal(f.counts.launches, 1);
    assert.equal(f.counts.focused, 1);
    f.press(key, { repeat: true });
    assert.equal(f.counts.launches, 1, 'holding the key must not restart the cart');
  }
});

test('Tab and Shift+Tab return to the shelf before the runtime consumes them', () => {
  const f = fixture();
  f.install();
  let runtimeCalls = 0;
  f.win.addEventListener('keydown', () => runtimeCalls++);
  for (const shiftKey of [false, true]) {
    assert.equal(f.press('Tab', { shiftKey, target: {} }).defaultPrevented, true);
  }
  assert.equal(f.counts.exits, 2);
  assert.equal(runtimeCalls, 0);
  assert.equal(f.counts.launches, 0);
});

test('gameplay input, browser shortcuts, and Enter away from the launcher pass through', () => {
  const f = fixture();
  f.install();
  let runtimeCalls = 0;
  f.win.addEventListener('keydown', () => runtimeCalls++);
  for (const key of ['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'z', 'x', 'Escape', 'Enter', ' ']) {
    assert.equal(f.press(key, { target: {} }).defaultPrevented, false);
  }
  for (const modifier of ['ctrlKey', 'altKey', 'metaKey']) {
    assert.equal(f.press('Tab', { [modifier]: true }).defaultPrevented, false);
  }
  assert.equal(runtimeCalls, 12);
  assert.equal(f.counts.exits, 0);
  assert.equal(f.counts.launches, 0);
});

test('reload/unmount cleanup removes handlers and reinsertion does not duplicate them', () => {
  const f = fixture();
  const cleanup = f.install();
  cleanup();
  assert.equal(f.attributes.size, 0);
  assert.equal(f.counts.styles, 0);
  assert.equal(f.press('Tab').defaultPrevented, false);
  assert.equal(f.counts.exits, 0);
  f.install();
  f.press('Tab');
  assert.equal(f.counts.exits, 1);
  assert.equal(f.counts.styles, 1);
});

test('an unloaded or unexpected export is left alone', () => {
  const f = fixture();
  f.frame.contentDocument = null;
  assert.doesNotThrow(() => f.install()());
  f.frame.contentDocument = { getElementById: () => null };
  assert.doesNotThrow(() => f.install()());
  assert.equal(f.counts.styles, 0);
});
