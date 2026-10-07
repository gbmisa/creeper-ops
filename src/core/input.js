// Centralised keyboard / mouse state. Modes read from this instead of attaching their own listeners.

export class Input {
  constructor(canvas) {
    this.canvas = canvas;
    this.keys = new Set();
    this.pressed = new Set();      // keys pressed since last endFrame()
    this.mouse = { x: 0, y: 0, dx: 0, dy: 0, left: false, clicked: false, released: false, rightClicked: false, wheel: 0, downX: 0, downY: 0 };
    this.pointerLocked = false;

    addEventListener('keydown', (e) => {
      if (e.code === 'Tab' || e.code === 'Space') e.preventDefault();
      if (!this.keys.has(e.code)) this.pressed.add(e.code);
      this.keys.add(e.code);
      this.onKeyDown?.(e);         // hook used for gesture-gated actions (pointer lock)
    });
    addEventListener('keyup', (e) => this.keys.delete(e.code));
    addEventListener('blur', () => this.keys.clear());

    canvas.addEventListener('mousemove', (e) => {
      this.mouse.x = e.clientX;
      this.mouse.y = e.clientY;
      if (this.pointerLocked) {
        this.mouse.dx += e.movementX;
        this.mouse.dy += e.movementY;
      }
    });
    canvas.addEventListener('mousedown', (e) => {
      if (e.button === 0) { this.mouse.left = true; this.mouse.clicked = true; this.mouse.downX = e.clientX; this.mouse.downY = e.clientY; }
      if (e.button === 2) this.mouse.rightClicked = true;
    });
    addEventListener('mouseup', (e) => { if (e.button === 0 && this.mouse.left) { this.mouse.left = false; this.mouse.released = true; } });
    canvas.addEventListener('contextmenu', (e) => e.preventDefault());
    canvas.addEventListener('wheel', (e) => { this.mouse.wheel += Math.sign(e.deltaY); e.preventDefault(); }, { passive: false });

    document.addEventListener('pointerlockchange', () => {
      this.pointerLocked = document.pointerLockElement === canvas;
      this.onPointerLockChange?.(this.pointerLocked);
    });
    // A refused lock leaves us unlocked; surface it the same way so the player gets a Resume button.
    document.addEventListener('pointerlockerror', () => this.onPointerLockChange?.(false));
  }

  down(code) { return this.keys.has(code); }
  get shift() { return this.keys.has('ShiftLeft') || this.keys.has('ShiftRight'); }
  wasPressed(code) { return this.pressed.has(code); }

  lockPointer() {
    // Newer browsers return a promise; a refusal is reported like pointerlockerror.
    this.canvas.requestPointerLock?.()?.catch?.(() => this.onPointerLockChange?.(false));
  }
  unlockPointer() { if (document.pointerLockElement) document.exitPointerLock(); }

  /** Call once at the end of every frame to clear edge-triggered state. */
  endFrame() {
    this.pressed.clear();
    this.mouse.dx = this.mouse.dy = 0;
    this.mouse.clicked = this.mouse.released = this.mouse.rightClicked = false;
    this.mouse.wheel = 0;
  }
}
