import { useEffect, useMemo, useRef, useState } from 'react';
import { installPico8KeyboardNavigation } from './pico8Keyboard';

const PLAYTEST_WIDTH = 256;
const PLAYTEST_HEIGHT = 160;
const GROUND_Y = 144;
const PIXEL_SCALE = 4;
const PLAYER_BASE_SIZE = 1;
const PLAYER_RENDER_SIZE = PLAYER_BASE_SIZE * PIXEL_SCALE;
const MOVE_ACCEL = 0.45;
const MAX_RUN_SPEED = 2.35;
const GROUND_FRICTION = 0.72;
const AIR_FRICTION = 0.985;
const GRAVITY = 0.18;
const JUMP_VELOCITY = -3.9;
const COYOTE_FRAMES = 6;
const JUMP_BUFFER_FRAMES = 6;

const PLAYTEST_PLATFORMS = [
  { x: 0, y: GROUND_Y, width: PLAYTEST_WIDTH, height: PLAYTEST_HEIGHT - GROUND_Y },
  { x: 18, y: 122, width: 42, height: 6 },
  { x: 72, y: 106, width: 34, height: 6 },
  { x: 120, y: 90, width: 26, height: 6 },
  { x: 164, y: 110, width: 22, height: 6 },
  { x: 196, y: 132, width: 30, height: 6 }
];

const PLAYER_KIND = {
  movementPlaytest: 'movement-playtest',
  localExport: 'local-export',
  placeholder: 'placeholder',
  embeddedVm: 'embedded-vm',
  waveformMatch: 'waveform-match'
};

const withBase = (path) => `${import.meta.env.BASE_URL}${path.replace(/^\//, '')}`;
const withCacheBust = (path) => `${withBase(path)}?v=${__CARTPORT_BUILD_ID__}`;

const games = [
  {
    id: 'pixels-progress',
    title: "Pixel's Progress",
    author: 'Cartport Prototype',
    genre: 'Platformer',
    description:
      "A platformer built around an almost absurd constraint: the player character is a single pixel. Level 1 uses a full-screen, no-scroll layout reminiscent of Kid Icarus: start at the bottom left, climb to the top, cut right, descend through the middle, then rise again to the goal in the top right — an N-shaped route across the whole screen.",
    sourceUrl: 'https://github.com/inertia186/cartport/blob/main/game-specs/pixels-progress/README.md',
    cartridgeImage: 'carts/pixels-progress.p8.png',
    cartridgeDownload: {
      href: 'carts/pixels-progress.p8.png',
      filename: 'pixels-progress.p8.png',
      label: '⬇'
    },
    cartridgeBlurb:
      'A tiny PICO-8 platformer where every bad touch makes the player bigger, stranger, and harder to route through the room.',
    status: 'in development',
    player: {
      kind: PLAYER_KIND.localExport,
      surface: 'iframe',
      runtime: 'pico8-html-export',
      src: 'carts/pixels-progress/index.html'
    },
    note: 'Generated export path: /carts/pixels-progress/index.html'
  },
  {
    id: 'oscillarium',
    title: 'Oscillarium',
    author: 'Cartport Prototype',
    genre: 'Wave Puzzle',
    description:
      'A tiny signal-museum puzzle about reconstructing a final waveform from two component waves. The docent would like to welcome you to the Oscill-ARIUM.',
    sourceUrl: 'https://github.com/inertia186/cartport/blob/main/game-specs/oscillarium/README.md',
    cartridgeImage: 'carts/oscillarium.p8.png',
    cartridgeDownload: {
      href: 'carts/oscillarium.p8.png',
      filename: 'oscillarium.p8.png',
      label: '⬇'
    },
    cartridgeBlurb:
      'Mode One prototype: inspect the target waveform, pick two component waves, and submit the pair that recreates the signal.',
    status: 'playtest',
    player: {
      kind: PLAYER_KIND.localExport,
      surface: 'iframe',
      runtime: 'pico8-html-export',
      src: 'carts/oscillarium/index.html'
    },
    note: 'Generated export path: /carts/oscillarium/index.html'
  },
  {
    id: 'oubliette',
    title: 'Oubliette',
    author: 'Cartport Prototype',
    genre: 'Dungeon Crawler',
    description:
      'A turn-by-turn first-person dungeon crawler for PICO-8. Explore generated labyrinth floors, fight monsters, collect supplies, level up, and descend deeper into the oubliette.',
    sourceUrl: 'https://github.com/inertia186/cartport/blob/main/game-specs/oubliette/README.md',
    cartridgeImage: 'carts/oubliette.p8.png',
    cartridgeDownload: {
      href: 'carts/oubliette.p8.png',
      filename: 'oubliette.p8.png',
      label: '⬇'
    },
    cartridgeBlurb:
      'Slot 03: a compact PICO-8 dungeon crawl with authored pixel masonry, monsters, icon inventory, leveling, and locked oubliette grates.',
    status: 'playtest',
    player: {
      kind: PLAYER_KIND.localExport,
      surface: 'iframe',
      runtime: 'pico8-html-export',
      src: 'carts/oubliette/index.html'
    },
    note: 'Generated export path: /carts/oubliette/index.html'
  },
  {
    id: 'aggreculture',
    title: 'Aggreculture',
    author: 'Cartport Prototype',
    genre: 'Action Farming',
    description:
      'Choose a world seed, generate a connected 3×3 top-down overworld, then reclaim its wilderness into persistent farmland with Zelda-like directional tools. Reusing a seed recreates its routes, biomes, obstacles, caches, growth rules, and blight pressure.',
    sourceUrl: 'https://github.com/inertia186/cartport/blob/main/game-specs/aggreculture/README.md',
    cartridgeImage: 'carts/aggreculture.p8.png',
    cartridgeDownload: {
      href: 'carts/aggreculture.p8.png',
      filename: 'aggreculture.p8.png',
      label: '⬇'
    },
    cartridgeBlurb:
      'Set a world seed, reclaim nine wilderness screens, and tap or hold Z to manage the Hoe/Farm action assigned to X.',
    status: 'in development',
    player: {
      kind: PLAYER_KIND.localExport,
      surface: 'iframe',
      runtime: 'pico8-html-export',
      src: 'carts/aggreculture/index.html'
    },
    note: 'Generated export path: /carts/aggreculture/index.html'
  }
];


const OSCILLARIUM_CANDIDATES = [
  { id: 'low-sine', label: 'LOW SINE', color: '#29adff', freq: 1, amp: 24, phase: 0 },
  { id: 'high-sine', label: 'HIGH SINE', color: '#ff77a8', freq: 3, amp: 12, phase: 0 },
  { id: 'phase-sine', label: 'PHASED', color: '#ffd166', freq: 2, amp: 15, phase: Math.PI / 2 },
  { id: 'wide-sine', label: 'WIDE', color: '#86efac', freq: 1, amp: 16, phase: Math.PI },
  { id: 'tiny-sine', label: 'TINY 4X', color: '#c084fc', freq: 4, amp: 8, phase: Math.PI / 4 }
];

const OSCILLARIUM_PUZZLES = [
  {
    id: 'exhibit-01',
    title: 'Exhibit 01: Constructive Wiggle',
    answer: ['low-sine', 'high-sine'],
    guide: 'Welcome to the Oscill-ARIUM. Please reconstruct the suspicious wiggle.'
  },
  {
    id: 'exhibit-02',
    title: 'Exhibit 02: Phase Misbehavior',
    answer: ['phase-sine', 'tiny-sine'],
    guide: 'Observe how the signal refuses to stand politely in the middle.'
  },
  {
    id: 'exhibit-03',
    title: 'Exhibit 03: Counterwave Etiquette',
    answer: ['wide-sine', 'high-sine'],
    guide: 'Two waves enter. One confusing wiggle leaves.'
  }
];

function sampleWave(wave, t) {
  return Math.sin(t * Math.PI * 2 * wave.freq + wave.phase) * wave.amp;
}

function combinedPath(waves, width = 320, height = 96) {
  const points = [];
  const mid = height / 2;
  const count = 96;

  for (let i = 0; i < count; i += 1) {
    const t = i / (count - 1);
    const y = mid - waves.reduce((sum, wave) => sum + sampleWave(wave, t), 0) / Math.max(1, waves.length) * 1.55;
    points.push(`${(t * width).toFixed(2)},${Math.max(6, Math.min(height - 6, y)).toFixed(2)}`);
  }

  return `M ${points.join(' L ')}`;
}

function getWaveById(id) {
  return OSCILLARIUM_CANDIDATES.find((wave) => wave.id === id);
}

function OscillariumModeOne() {
  const [puzzleIndex, setPuzzleIndex] = useState(0);
  const [selectedIds, setSelectedIds] = useState([]);
  const [message, setMessage] = useState('Pick two components, then submit the exhibit report.');
  const [resultState, setResultState] = useState(null);
  const puzzle = OSCILLARIUM_PUZZLES[puzzleIndex];
  const targetWaves = puzzle.answer.map(getWaveById);
  const selectedWaves = selectedIds.map(getWaveById);
  const solved = selectedIds.length === 2 && puzzle.answer.every((id) => selectedIds.includes(id));

  const evaluateSelection = (ids) => {
    if (ids.length < 2) {
      setResultState(null);
      setMessage('The docent squints at your selected interference pattern.');
      return ids;
    }

    const isCorrect = puzzle.answer.every((answerId) => ids.includes(answerId));
    if (isCorrect) {
      setResultState('correct');
      setMessage('Correct. The exhibit hums like it meant to do that.');
      return ids;
    }

    setResultState('incorrect');
    setMessage('Wrong pair. The display resets with a small, educational noise-crime.');
    return [];
  };

  const toggleWave = (id) => {
    setSelectedIds((current) => {
      let next;
      if (current.includes(id)) {
        next = current.filter((item) => item !== id);
      } else if (current.length >= 2) {
        next = [current[1], id];
      } else {
        next = [...current, id];
      }
      return evaluateSelection(next);
    });
  };

  const submit = () => {
    setSelectedIds((current) => evaluateSelection(current));
  };

  const nextPuzzle = () => {
    setPuzzleIndex((current) => (current + 1) % OSCILLARIUM_PUZZLES.length);
    setSelectedIds([]);
    setResultState(null);
    setMessage('Welcome to the Oscill-ARIUM. New exhibit, same questionable docent.');
  };

  return (
    <div className="oscillarium-shell">
      <div className={`oscillarium-display${resultState ? ` ${resultState}` : ''}`}>
        <div className="oscillarium-header">
          <span>{puzzle.title}</span>
          <strong>Target waveform</strong>
        </div>
        <WaveScope path={combinedPath(targetWaves)} stroke="#f4f1ff" />
        <p className="docent-line">“{puzzle.guide}”</p>
      </div>

      <div className="oscillarium-candidates" aria-label="Component wave candidates">
        {OSCILLARIUM_CANDIDATES.map((wave) => {
          const active = selectedIds.includes(wave.id);
          return (
            <button
              key={wave.id}
              type="button"
              className={`wave-card${active ? ' active' : ''}`}
              onClick={() => toggleWave(wave.id)}
            >
              <span>{wave.label}</span>
              <WaveScope path={combinedPath([wave], 180, 54)} stroke={wave.color} compact />
            </button>
          );
        })}
      </div>

      <div className={`oscillarium-display preview${resultState ? ` ${resultState}` : ''}`}>
        <div className="oscillarium-header">
          <span>Selected sum</span>
          <strong>{selectedIds.length}/2 waves</strong>
        </div>
        {resultState ? (
          <div className={`result-banner ${resultState}`}>
            {resultState === 'correct' ? 'Correct combination' : 'Incorrect combination'}
          </div>
        ) : (
          <WaveScope
            path={combinedPath(selectedWaves.length ? selectedWaves : [], 320, 84)}
            stroke={selectedWaves.length ? '#ffd166' : '#55516b'}
          />
        )}
        <p className="docent-line">{message}</p>
        <div className="oscillarium-actions">
          <button type="button" onClick={submit}>Submit pair</button>
          <button type="button" onClick={nextPuzzle} disabled={!solved}>Next exhibit</button>
        </div>
      </div>
    </div>
  );
}

function WaveScope({ path, stroke, compact = false }) {
  return (
    <svg className={`wave-scope${compact ? ' compact' : ''}`} viewBox="0 0 320 96" role="img" aria-label="Waveform display">
      <line x1="0" y1="48" x2="320" y2="48" />
      <path d={path} stroke={stroke} />
    </svg>
  );
}

function MovementPlaytest() {
  const frameRef = useRef(null);
  const keysRef = useRef({ left: false, right: false, jump: false });
  const jumpBufferRef = useRef(0);
  const [player, setPlayer] = useState(() => ({
    x: 24,
    y: GROUND_Y - PLAYER_RENDER_SIZE,
    vx: 0,
    vy: 0,
    facing: 1,
    grounded: true,
    coyoteFrames: COYOTE_FRAMES,
    jumps: 0
  }));

  useEffect(() => {
    const onKeyDown = (event) => {
      if (event.repeat) {
        return;
      }

      if (event.key === 'ArrowLeft' || event.key.toLowerCase() === 'a') {
        keysRef.current.left = true;
      }

      if (event.key === 'ArrowRight' || event.key.toLowerCase() === 'd') {
        keysRef.current.right = true;
      }

      if (
        event.key === 'ArrowUp' ||
        event.key === ' ' ||
        event.key.toLowerCase() === 'w' ||
        event.key.toLowerCase() === 'z'
      ) {
        keysRef.current.jump = true;
        jumpBufferRef.current = JUMP_BUFFER_FRAMES;
        event.preventDefault();
      }
    };

    const onKeyUp = (event) => {
      if (event.key === 'ArrowLeft' || event.key.toLowerCase() === 'a') {
        keysRef.current.left = false;
      }

      if (event.key === 'ArrowRight' || event.key.toLowerCase() === 'd') {
        keysRef.current.right = false;
      }

      if (
        event.key === 'ArrowUp' ||
        event.key === ' ' ||
        event.key.toLowerCase() === 'w' ||
        event.key.toLowerCase() === 'z'
      ) {
        keysRef.current.jump = false;
        event.preventDefault();
      }
    };

    window.addEventListener('keydown', onKeyDown);
    window.addEventListener('keyup', onKeyUp);

    return () => {
      window.removeEventListener('keydown', onKeyDown);
      window.removeEventListener('keyup', onKeyUp);
    };
  }, []);

  useEffect(() => {
    let mounted = true;

    const tick = () => {
      setPlayer((current) => {
        const keys = keysRef.current;
        let vx = current.vx;
        let vy = current.vy;
        let x = current.x;
        let y = current.y;
        let grounded = false;
        let coyoteFrames = Math.max(0, current.coyoteFrames - 1);
        const horizontalInput = (keys.right ? 1 : 0) - (keys.left ? 1 : 0);

        if (horizontalInput !== 0) {
          vx += horizontalInput * MOVE_ACCEL;
          vx = Math.max(-MAX_RUN_SPEED, Math.min(MAX_RUN_SPEED, vx));
        } else {
          vx *= current.grounded ? GROUND_FRICTION : AIR_FRICTION;
          if (Math.abs(vx) < 0.02) {
            vx = 0;
          }
        }

        if (jumpBufferRef.current > 0 && (current.grounded || current.coyoteFrames > 0)) {
          vy = JUMP_VELOCITY;
          grounded = false;
          coyoteFrames = 0;
          jumpBufferRef.current = 0;
        } else if (jumpBufferRef.current > 0) {
          jumpBufferRef.current -= 1;
        }

        vy += GRAVITY;
        x += vx;
        y += vy;

        if (x < 0) {
          x = 0;
          vx = 0;
        }

        if (x + PLAYER_RENDER_SIZE > PLAYTEST_WIDTH) {
          x = PLAYTEST_WIDTH - PLAYER_RENDER_SIZE;
          vx = 0;
        }

        for (const platform of PLAYTEST_PLATFORMS) {
          const wasAbove = current.y + PLAYER_RENDER_SIZE <= platform.y;
          const nowAtOrBelow = y + PLAYER_RENDER_SIZE >= platform.y;
          const insideX = x + PLAYER_RENDER_SIZE > platform.x && x < platform.x + platform.width;

          if (vy >= 0 && wasAbove && nowAtOrBelow && insideX) {
            y = platform.y - PLAYER_RENDER_SIZE;
            vy = 0;
            grounded = true;
            coyoteFrames = COYOTE_FRAMES;
          }
        }

        if (y > PLAYTEST_HEIGHT + 24) {
          return {
            x: 24,
            y: GROUND_Y - PLAYER_RENDER_SIZE,
            vx: 0,
            vy: 0,
            facing: 1,
            grounded: true,
            coyoteFrames: COYOTE_FRAMES,
            jumps: 0
          };
        }

        return {
          x,
          y,
          vx,
          vy,
          facing: horizontalInput !== 0 ? horizontalInput : current.facing,
          grounded,
          coyoteFrames,
          jumps: current.jumps + (grounded ? 0 : 1)
        };
      });

      if (mounted) {
        frameRef.current = window.requestAnimationFrame(tick);
      }
    };

    frameRef.current = window.requestAnimationFrame(tick);

    return () => {
      mounted = false;
      window.cancelAnimationFrame(frameRef.current);
    };
  }, []);

  return (
    <div className="playtest-shell">
      <div className="playtest-screen" role="img" aria-label="Pixel's Progress movement playtest">
        <div className="playtest-skyline" />
        {PLAYTEST_PLATFORMS.map((platform, index) => (
          <div
            key={`${platform.x}-${platform.y}-${index}`}
            className="playtest-platform"
            style={{
              left: `${(platform.x / PLAYTEST_WIDTH) * 100}%`,
              top: `${(platform.y / PLAYTEST_HEIGHT) * 100}%`,
              width: `${(platform.width / PLAYTEST_WIDTH) * 100}%`,
              height: `${(platform.height / PLAYTEST_HEIGHT) * 100}%`
            }}
          />
        ))}

        <div
          className={`playtest-player${player.grounded ? ' grounded' : ''}`}
          style={{
            left: `${(player.x / PLAYTEST_WIDTH) * 100}%`,
            top: `${(player.y / PLAYTEST_HEIGHT) * 100}%`,
            width: `${(PLAYER_RENDER_SIZE / PLAYTEST_WIDTH) * 100}%`,
            height: `${(PLAYER_RENDER_SIZE / PLAYTEST_HEIGHT) * 100}%`
          }}
        />

        <div className="playtest-goal" style={{ left: '84%', top: '46%' }} />
      </div>

      <div className="playtest-hud">
        <div>
          <strong>Controls</strong>
          <p>Move: ← → or A / D · Jump: ↑ / W / Z / Space</p>
        </div>
        <div>
          <strong>Read target</strong>
          <p>Quick acceleration, crisp stop, gentle air control, forgiving jump timing.</p>
        </div>
      </div>
    </div>
  );
}

function PlayerChrome({ children, note }) {
  return (
    <div className="player-host">
      {children}
      {note ? <p className="player-note">{note}</p> : null}
    </div>
  );
}

function LocalExportPlayer({ gameTitle, player, note }) {
  const frameRef = useRef(null);

  useEffect(() => {
    const frame = frameRef.current;
    let cleanup = () => {};
    const onLoad = () => {
      cleanup();
      cleanup = installPico8KeyboardNavigation(frame, gameTitle, () => {
        frame.closest('.selector-grid')?.querySelector('.game-list-item.active')?.focus();
      });
    };
    frame.addEventListener('load', onLoad);
    onLoad();
    return () => {
      frame.removeEventListener('load', onLoad);
      cleanup();
    };
  }, [gameTitle, player.src]);

  return (
    <PlayerChrome note={note ? <><code>{player.src}</code></> : null}>
      <div className="embed-frame">
        <iframe
          ref={frameRef}
          key={`${gameTitle}-${player.src}-${__CARTPORT_BUILD_ID__}`}
          src={withCacheBust(player.src)}
          title={gameTitle}
          loading="eager"
          allowFullScreen
        />
      </div>
      <p className="player-keyboard-hint">Press Enter or Space on Play to start. Tab returns to the cartridge shelf.</p>
    </PlayerChrome>
  );
}

function EmbeddedVmStubPlayer({ gameTitle, player, note }) {
  return (
    <PlayerChrome note={note}>
      <div className="player-empty runtime-stub">
        <strong>Runtime host stub</strong>
        <p>
          This is where an inline canvas-based VM host would mount instead of an iframe export.
        </p>
        <ul className="runtime-stub-list">
          <li>Cart asset: <code>{player.cartAsset}</code></li>
          <li>Canvas target: <code>{player.canvasTarget}</code></li>
          <li>Input bridge: planned</li>
          <li>Focus / pause lifecycle: planned</li>
        </ul>
      </div>
    </PlayerChrome>
  );
}

function PlaceholderPlayer() {
  return (
    <div className="player-empty">
      <strong>Empty cartridge slot.</strong>
      <p>This spot is reserved for a future game.</p>
    </div>
  );
}

function UnknownPlayer({ kind }) {
  return <div className="player-empty">No player configured for player kind: {kind}.</div>;
}

function renderPlayerByKind({ gameTitle, player, note }) {
  switch (player?.kind) {
    case PLAYER_KIND.waveformMatch:
      return (
        <PlayerChrome note={note}>
          <OscillariumModeOne />
        </PlayerChrome>
      );

    case PLAYER_KIND.movementPlaytest:
      return (
        <PlayerChrome note={note}>
          <MovementPlaytest />
        </PlayerChrome>
      );

    case PLAYER_KIND.localExport:
      return <LocalExportPlayer gameTitle={gameTitle} player={player} note={note} />;

    case PLAYER_KIND.embeddedVm:
      return <EmbeddedVmStubPlayer gameTitle={gameTitle} player={player} note={note} />;

    case PLAYER_KIND.placeholder:
      return <PlaceholderPlayer />;

    default:
      return <UnknownPlayer kind={player?.kind ?? 'unknown'} />;
  }
}

function CartridgeImage({ game }) {
  if (!game?.cartridgeImage) {
    return null;
  }

  const download = game.cartridgeDownload;
  const downloadHref = download?.href ? withBase(download.href) : null;

  return (
    <figure className="cartridge-preview">
      <div className="cartridge-image-wrap">
        <img
          src={withCacheBust(game.cartridgeImage)}
          alt={`${game.title} PICO-8 cartridge`}
          loading="eager"
        />
        {downloadHref ? (
          <a
            className="cartridge-download"
            href={downloadHref}
            download={download.filename ?? ''}
            aria-label={`Download ${game.title} cartridge`}
            title="Download cartridge"
          >
            {download.label ?? '⬇'}
          </a>
        ) : null}
      </div>
      {game.cartridgeBlurb ? <p className="cartridge-blurb">{game.cartridgeBlurb}</p> : null}
    </figure>
  );
}

function GamePlayer({ game, variation, onSelectVariation }) {
  const activeVariation = variation ?? game?.variations?.[0] ?? null;
  const player = activeVariation?.player ?? game?.player;

  return (
    <>
      {game?.variations?.length ? (
        <div className="variation-picker" aria-label={`${game.title} variations`}>
          {game.variations.map((option) => {
            const isActive = option.id === activeVariation?.id;

            return (
              <button
                key={option.id}
                type="button"
                className={`variation-chip${isActive ? ' active' : ''}`}
                onClick={() => onSelectVariation?.(option.id)}
              >
                {option.label}
              </button>
            );
          })}
        </div>
      ) : null}

      {activeVariation?.description ? (
        <p className="variation-description">{activeVariation.description}</p>
      ) : null}

      {renderPlayerByKind({
        gameTitle: game?.title ?? 'Unknown game',
        player,
        note: activeVariation?.note
      })}
    </>
  );
}

function App() {
  const [selectedGameId, setSelectedGameId] = useState(games[0].id);
  const [selectedVariations, setSelectedVariations] = useState(() =>
    Object.fromEntries(
      games.filter((game) => game.variations?.length).map((game) => [game.id, game.variations[0].id])
    )
  );

  const selectedGame = useMemo(
    () => games.find((game) => game.id === selectedGameId) ?? games[0],
    [selectedGameId]
  );

  const selectedVariation = useMemo(() => {
    if (!selectedGame?.variations?.length) {
      return null;
    }

    return (
      selectedGame.variations.find(
        (variation) => variation.id === selectedVariations[selectedGame.id]
      ) ?? selectedGame.variations[0]
    );
  }, [selectedGame, selectedVariations]);

  return (
    <div className="app-shell">
      <header className="hero">
        <p className="eyebrow">PICO-8 GAME PORTAL</p>
        <h1>Cartport</h1>
        <p className="hero-copy">Browser-playable PICO-8 carts, sketches, and exports.</p>
      </header>

      <main className="content">
        <section>
          <div className="selector-grid">
            <aside className="game-list card" aria-label="Cartridge list">
              {games.map((game) => {
                const isActive = game.id === selectedGame.id;

                return (
                  <button
                    key={game.id}
                    type="button"
                    className={`game-list-item${isActive ? ' active' : ''}`}
                    aria-pressed={isActive}
                    onClick={() => setSelectedGameId(game.id)}
                  >
                    <span className="genre">{game.genre}</span>
                    <strong>{game.title}</strong>
                    <span className="author">{game.author}</span>
                    <span className={`status-badge ${game.status.replace(/\s+/g, '-')}`}>
                      {game.status}
                    </span>
                  </button>
                );
              })}
            </aside>

            <article key={selectedGame.id} className="game-card card">
              <div className="game-meta">
                <div>
                  <p className="genre">{selectedGame.genre}</p>
                  <h3>{selectedGame.title}</h3>
                  <p className="author">{selectedGame.author}</p>
                </div>
                {selectedGame.sourceUrl !== '#' ? (
                  <a href={selectedGame.sourceUrl} target="_blank" rel="noreferrer">
                    Design notes
                  </a>
                ) : null}
              </div>

              <div className="selected-game-stage">
                <CartridgeImage game={selectedGame} />

                <GamePlayer
                  game={selectedGame}
                  variation={selectedVariation}
                  onSelectVariation={(variationId) =>
                    setSelectedVariations((current) => ({
                      ...current,
                      [selectedGame.id]: variationId
                    }))
                  }
                />
              </div>
            </article>
          </div>
        </section>
      </main>
    </div>
  );
}

export default App;
