// Tiny pub/sub bus so systems (HUD, objectives, audio later) stay decoupled.

const handlers = new Map();

export const bus = {
  on(name, fn) {
    if (!handlers.has(name)) handlers.set(name, new Set());
    handlers.get(name).add(fn);
    return () => handlers.get(name).delete(fn);
  },
  emit(name, data) {
    const set = handlers.get(name);
    if (set) for (const fn of set) fn(data);
  },
};

/** Convenience: push a line to the event log. kind = info | warn | bad | good | radio */
export function log(text, kind = 'info') {
  bus.emit('log', { text, kind });
}
