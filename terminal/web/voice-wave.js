'use strict';
// A short, in-memory level history; no audio or transcript is stored here.
function voiceWave(samples, pauses, now) {
  const x = time => Math.max(0, Math.min(1000, (time - now + 20000) / 20));
  const recent = samples.filter(sample => Number.isFinite(sample.at) && Number.isFinite(sample.level) && sample.at >= now - 20000 && sample.at <= now);
  const points = recent.map(sample => ({x: x(sample.at), height: Math.max(0, Math.min(1, sample.level)) * 27}));
  const last = recent.at(-1);
  if (last && now - last.at > 400) points.push({x: x(last.at + 400), height: 0});
  const first = points[0]?.x ?? 1000;
  const upper = [`0,32`, `${first},32`, ...points.map(p => `${p.x},${32 - p.height}`), '1000,32'];
  const lower = [...points].reverse().map(p => `${p.x},${32 + p.height}`);
  const bands = pauses.filter(p => Number.isFinite(p.start) && Number.isFinite(p.end ?? now) && (p.end ?? now) >= p.start && (p.end ?? now) >= now - 20000 && p.start <= now)
    .map(p => ({x: x(p.start), width: x(p.end ?? now) - x(p.start)}));
  return {path: `M${upper.join(' L')} L${lower.length ? lower.join(' L') : '1000,32'} L${first},32 Z`, bands};
}
if (typeof module !== 'undefined') module.exports = voiceWave;
