import { Application, Graphics } from "https://cdn.jsdelivr.net/npm/pixi.js@8.23.0/dist/pixi.min.mjs";

const host = document.querySelector(".enemy-stage");
const fallback = document.getElementById("enemy-art");
if (host) {
  const app = new Application();
  try {
    await app.init({
      resizeTo: host,
      backgroundAlpha: 0,
      antialias: true,
      autoDensity: true,
      resolution: Math.min(window.devicePixelRatio || 1, 1.5),
      preference: "webgl"
    });
    app.canvas.className = "enemy-canvas";
    app.canvas.setAttribute("aria-hidden", "true");
    host.prepend(app.canvas);
    if (fallback) fallback.classList.add("pixi-ready");

    const art = new Graphics();
    const embers = new Graphics();
    app.stage.addChild(art, embers);
    const motes = Array.from({ length: 34 }, (_, i) => ({
      x: ((i * 73) % 997) / 997,
      y: ((i * 193) % 991) / 991,
      speed: 0.18 + (i % 5) * 0.075,
      drift: Math.sin(i * 4.2) * 0.12,
      size: 0.7 + (i % 4) * 0.45,
      phase: i * 1.7
    }));
    let elapsed = 0;
    let boss = false;

    function draw() {
      const w = app.renderer.width / app.renderer.resolution;
      const h = app.renderer.height / app.renderer.resolution;
      const cx = w * 0.5, cy = h * 0.53;
      const scale = Math.min(w / 280, h / 170, 1.2);
      art.clear();
      embers.clear();

      // A layered occult seal behind the creature.
      for (let ring = 0; ring < 3; ring++) {
        art.circle(cx, cy + 3, (39 + ring * 15) * scale)
          .stroke({ color: ring === 0 ? 0xc99a62 : 0x9b6461, width: ring === 0 ? 1.2 : 0.65, alpha: 0.25 - ring * 0.055 });
      }
      art.circle(cx, cy + 3, 22 * scale)
        .stroke({ color: 0xd7ad72, width: 0.7, alpha: 0.35 });
      for (let i = 0; i < 8; i++) {
        const a = i * Math.PI / 4 + elapsed * 0.035;
        const r1 = 53 * scale, r2 = 61 * scale;
        art.moveTo(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1)
          .lineTo(cx + Math.cos(a) * r2, cy + Math.sin(a) * r2)
          .stroke({ color: 0xc99a62, width: 1, alpha: 0.4 });
      }

      // Shadow, ragged mantle and a mask-like head.
      art.ellipse(cx, cy + 48 * scale, 39 * scale, 7 * scale).fill({ color: 0x08070b, alpha: 0.62 });
      const mantle = boss ? 0x39242e : 0x30252f;
      art.moveTo(cx - 12 * scale, cy - 24 * scale)
        .lineTo(cx - 32 * scale, cy + 9 * scale)
        .lineTo(cx - 39 * scale, cy + 43 * scale)
        .lineTo(cx - 17 * scale, cy + 34 * scale)
        .lineTo(cx, cy + 48 * scale)
        .lineTo(cx + 17 * scale, cy + 34 * scale)
        .lineTo(cx + 39 * scale, cy + 43 * scale)
        .lineTo(cx + 32 * scale, cy + 9 * scale)
        .lineTo(cx + 12 * scale, cy - 24 * scale)
        .closePath().fill({ color: mantle, alpha: 0.98 })
        .stroke({ color: 0x9d6b63, width: 1.1 * scale, alpha: 0.65 });
      art.moveTo(cx - 18 * scale, cy - 8 * scale)
        .lineTo(cx - 9 * scale, cy - 32 * scale)
        .lineTo(cx, cy - 43 * scale)
        .lineTo(cx + 9 * scale, cy - 32 * scale)
        .lineTo(cx + 18 * scale, cy - 8 * scale)
        .lineTo(cx + 13 * scale, cy + 18 * scale)
        .lineTo(cx, cy + 29 * scale)
        .lineTo(cx - 13 * scale, cy + 18 * scale)
        .closePath().fill({ color: boss ? 0x171116 : 0x1d1820 })
        .stroke({ color: 0xb58a68, width: 1.15 * scale, alpha: 0.85 });
      // Crown-like horns and burning eyes.
      art.moveTo(cx - 12 * scale, cy - 28 * scale)
        .lineTo(cx - 22 * scale, cy - 48 * scale)
        .lineTo(cx - 5 * scale, cy - 37 * scale)
        .moveTo(cx + 12 * scale, cy - 28 * scale)
        .lineTo(cx + 22 * scale, cy - 48 * scale)
        .lineTo(cx + 5 * scale, cy - 37 * scale)
        .stroke({ color: boss ? 0xe0a85f : 0x9b7772, width: 2 * scale, alpha: 0.9 });
      art.ellipse(cx - 7 * scale, cy - 8 * scale, 2.8 * scale, 1.4 * scale)
        .fill({ color: 0xf2bd72, alpha: 0.95 });
      art.ellipse(cx + 7 * scale, cy - 8 * scale, 2.8 * scale, 1.4 * scale)
        .fill({ color: 0xf2bd72, alpha: 0.95 });
      art.moveTo(cx - 11 * scale, cy + 3 * scale)
        .lineTo(cx, cy + 8 * scale)
        .lineTo(cx + 11 * scale, cy + 3 * scale)
        .stroke({ color: 0x8b565c, width: 1.2 * scale, alpha: 0.75 });

      for (const mote of motes) {
        const y = ((mote.y + elapsed * 0.00022 * mote.speed) % 1) * h;
        const x = mote.x * w + Math.sin(elapsed * 0.018 + mote.phase) * 8 + mote.drift * 12;
        const pulse = 0.45 + (Math.sin(elapsed * 0.045 + mote.phase) + 1) * 0.25;
        embers.circle(x, y, mote.size * scale).fill({ color: mote.phase % 2 > 1 ? 0xe0a45e : 0xb96958, alpha: pulse });
      }
    }
    app.ticker.add((ticker) => { elapsed += ticker.deltaTime; draw(); });
    draw();

    window.AshenBattleScene = {
      setEnemy(name) {
        boss = /король|босс/i.test(name || "");
        draw();
      }
    };
  } catch (error) {
    console.warn("ASHEN DECKS: PixiJS scene unavailable; using static fallback.", error);
    app.destroy(true);
    if (fallback) fallback.classList.remove("pixi-ready");
  }
}
