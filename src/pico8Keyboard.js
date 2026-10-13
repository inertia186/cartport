// Adapt the native export's mouse-only launcher and Tab blocker at the portal
// boundary. Keep the generated cartridge/runtime files unchanged.
export function installPico8KeyboardNavigation(frame, gameTitle, returnToShelf) {
  const doc = frame.contentDocument;
  const frameWindow = frame.contentWindow;
  const launcher = doc?.getElementById('p8_start_button');
  if (!launcher || !frameWindow) return () => {};

  launcher.setAttribute('role', 'button');
  launcher.setAttribute('tabindex', '0');
  launcher.setAttribute('aria-label', `Play ${gameTitle}`);

  const focusStyle = doc.createElement('style');
  focusStyle.textContent = '#p8_start_button:focus-visible { outline: 3px solid #fff1e8; outline-offset: -4px; }';
  doc.head.append(focusStyle);

  const onKeyDown = (event) => {
    if (event.altKey || event.ctrlKey || event.metaKey) return;

    if (event.key === 'Tab') {
      // Capture before the export consumes Tab. Both directions offer a way
      // back to the selected cartridge, without reloading or pausing the game.
      event.preventDefault();
      event.stopImmediatePropagation();
      returnToShelf();
    } else if (event.target === launcher && (event.key === 'Enter' || event.key === ' ')) {
      event.preventDefault();
      event.stopImmediatePropagation();
      if (!event.repeat) {
        launcher.click();
        frameWindow.focus();
      }
    }
  };

  frameWindow.addEventListener('keydown', onKeyDown, { capture: true });
  return () => {
    frameWindow.removeEventListener('keydown', onKeyDown, { capture: true });
    focusStyle.remove();
    launcher.removeAttribute('role');
    launcher.removeAttribute('tabindex');
    launcher.removeAttribute('aria-label');
  };
}
