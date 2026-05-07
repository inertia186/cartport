import { useEffect, useMemo, useRef, useState } from 'react';

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
  embeddedVm: 'embedded-vm'
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
    id: 'slot-02',
    title: 'Placeholder Cart 02',
    author: 'Coming later',
    genre: 'Placeholder',
    description:
      'Reserved slot for a future cart. The navigation stays in place so the portal already feels like a shelf instead of a one-off page.',
    player: {
      kind: PLAYER_KIND.placeholder
    },
    sourceUrl: '#',
    status: 'placeholder'
  },
  {
    id: 'slot-03',
    title: 'Placeholder Cart 03',
    author: 'Coming later',
    genre: 'Placeholder',
    description:
      'Another future slot for the catalog. Once there are more carts, this can become a real game entry without changing the structure.',
    player: {
      kind: PLAYER_KIND.placeholder
    },
    sourceUrl: '#',
    status: 'placeholder'
  }
];

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
  return (
    <PlayerChrome note={note ? <><code>{player.src}</code></> : null}>
      <div className="embed-frame">
        <iframe
          key={`${gameTitle}-${player.src}-${__CARTPORT_BUILD_ID__}`}
          src={withCacheBust(player.src)}
          title={gameTitle}
          loading="eager"
          allowFullScreen
        />
      </div>
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
