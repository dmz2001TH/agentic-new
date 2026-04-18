#!/usr/bin/env node
/**
 * Oracle Vault Report Generator
 * Scans your ψ/ memory structure across ghq repos → OLED dashboard
 *
 * Works for any Oracle subscriber with ψ/ dirs in their repos.
 *
 * Usage:
 *   node generate.mjs              # generate index.html + data.json
 *   node generate.mjs --push       # generate + git commit + push (GitHub Pages)
 *
 * Vault detection (in order):
 *   1. $ORACLE_VAULT_PATH env var
 *   2. ghq repo matching *oracle-vault (not *-report)
 *   3. No vault = skip vault-specific stats, still show ψ/ scan
 *
 * No secrets — only repo names, file counts, sizes, skill names.
 */

import { writeFileSync, readFileSync, readdirSync, existsSync, lstatSync, readlinkSync, statSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';
import { execSync } from 'child_process';

// ── Config (auto-detect everything) ──────────────────────────────────────────

// Color palette for auto-assigning org colors
const PALETTE = ['violet','emerald','amber','blue','rose','teal','indigo','orange','cyan','fuchsia','lime','sky'];
const _orgCache = {};
function orgColor(org) {
  if (!_orgCache[org]) {
    const hash = [...org].reduce((h, c) => ((h << 5) - h + c.charCodeAt(0)) | 0, 0);
    _orgCache[org] = PALETTE[Math.abs(hash) % PALETTE.length];
  }
  return _orgCache[org];
}

const GHQ_ROOT = tryExec('ghq root');
if (!GHQ_ROOT) { console.error('ERROR: ghq not found. Install: https://github.com/x-motemen/ghq'); process.exit(1); }

const VAULT = process.env.ORACLE_VAULT_PATH
  || tryExec('ghq list -p')?.split('\n').find(p => /oracle-vault$/.test(p) && !p.includes('-report'))
  || null;

const OUT_DIR = process.cwd();
const SKILLS_DIR = join(homedir(), '.claude', 'skills');
const HAS_VAULT = VAULT && existsSync(VAULT);

if (HAS_VAULT) console.log(`📦 Vault: ${VAULT}`);
else console.log('📦 No central vault detected (showing ψ/ scan only)');

// ── Scan ghq repos ───────────────────────────────────────────────────────────

console.log('📊 Scanning ghq repos...');
const allRepos = tryExec('ghq list -p')?.split('\n').filter(Boolean) || [];
const repos = { symlinked: [], realRepos: [], realWorktrees: [] };

for (const repo of allRepos) {
  const rel = repo.replace(GHQ_ROOT + '/', '');
  const psiPath = join(repo, 'ψ');

  try {
    const stat = lstatSync(psiPath, { throwIfNoEntry: false });
    if (!stat) continue;

    if (stat.isSymbolicLink()) {
      const target = readlinkSync(psiPath);
      const vaultRel = HAS_VAULT ? target.replace(VAULT + '/', '') : target;
      repos.symlinked.push({ rel, target: vaultRel, mdCount: countMd(target) });
    } else if (stat.isDirectory()) {
      // Skip the vault repo itself
      if (rel.match(/oracle-vault$/)) continue;
      const mdCount = countMd(psiPath);
      const size = dirSize(psiPath);
      const isWt = /\.wt[-/]/.test(rel);
      const entry = { rel, mdCount, size, parentRel: isWt ? rel.replace(/\.wt[-/]\d+$/, '') : null };
      if (isWt) repos.realWorktrees.push(entry); else repos.realRepos.push(entry);
    }
  } catch { /* skip unreadable */ }
}

// ── Scan vault (if present) ──────────────────────────────────────────────────

let totalMdInVault = 0;
let vaultSize = 0;
const vaultProjects = [];
const vaultOrgs = [];

if (HAS_VAULT) {
  console.log('📂 Scanning vault...');
  const vaultGithub = join(VAULT, 'github.com');
  if (existsSync(vaultGithub)) {
    for (const org of readdirSync(vaultGithub)) {
      const orgDir = join(vaultGithub, org);
      if (!statSync(orgDir).isDirectory()) continue;
      vaultOrgs.push(org);
      for (const project of readdirSync(orgDir)) {
        const projDir = join(orgDir, project);
        if (!statSync(projDir).isDirectory()) continue;
        const mdCount = countMd(projDir);
        vaultProjects.push({ org, project, mdCount, size: dirSize(projDir) });
        totalMdInVault += mdCount;
      }
    }
    vaultProjects.sort((a, b) => b.mdCount - a.mdCount);
    vaultSize = dirSize(vaultGithub);
  }
}

// ── Scan skills ──────────────────────────────────────────────────────────────

console.log('🔧 Scanning skills...');
const skills = [];
if (existsSync(SKILLS_DIR)) {
  for (const name of readdirSync(SKILLS_DIR)) {
    const skillFile = join(SKILLS_DIR, name, 'SKILL.md');
    if (!existsSync(skillFile)) continue;
    const content = readFileSync(skillFile, 'utf-8');
    const descMatch = content.match(/description:\s*(.+)/);
    skills.push({ name, description: descMatch ? descMatch[1].trim() : '' });
  }
}
skills.sort((a, b) => a.name.localeCompare(b.name));
const skillsVersion = existsSync(join(SKILLS_DIR, 'VERSION.md'))
  ? (readFileSync(join(SKILLS_DIR, 'VERSION.md'), 'utf-8').match(/v[\d.]+/) || [''])[0]
  : '';

// ── Metrics ──────────────────────────────────────────────────────────────────

const totalRepos = allRepos.length;
const totalWithPsi = repos.symlinked.length + repos.realRepos.length + repos.realWorktrees.length;
const totalSymlinked = repos.symlinked.length;
const totalReal = repos.realRepos.length;
const totalWorktrees = repos.realWorktrees.length;
const totalNeedSync = totalReal + totalWorktrees;
const totalVaultProjects = vaultProjects.length;
const totalVaultOrgs = vaultOrgs.length;

// If no vault, count .md from all ψ/ dirs
if (!HAS_VAULT && totalMdInVault === 0) {
  for (const r of [...repos.symlinked, ...repos.realRepos, ...repos.realWorktrees]) {
    totalMdInVault += r.mdCount;
  }
}

const orgStats = {};
for (const p of vaultProjects) {
  if (!orgStats[p.org]) orgStats[p.org] = { org: p.org, projects: 0, mdCount: 0 };
  orgStats[p.org].projects++;
  orgStats[p.org].mdCount += p.mdCount;
}
const orgList = Object.values(orgStats).sort((a, b) => b.mdCount - a.mdCount);

const now = new Date();
const generated = now.toISOString();
const generatedDisplay = now.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' });

// ── Generate ─────────────────────────────────────────────────────────────────

console.log('🎨 Generating...');
writeFileSync(join(OUT_DIR, 'index.html'), generateHTML());
console.log('✅ index.html');

writeFileSync(join(OUT_DIR, 'data.json'), JSON.stringify({
  generated, totalRepos, totalWithPsi, totalSymlinked, totalReal, totalWorktrees,
  totalNeedSync, totalMdInVault, totalVaultProjects, totalVaultOrgs,
  vaultSize: HAS_VAULT ? vaultSize : null,
  skills: skills.map(s => s.name), skillsVersion,
  vaultProjects: vaultProjects.map(p => ({ org: p.org, project: p.project, mdCount: p.mdCount })),
  orgList,
}, null, 2));
console.log('✅ data.json');

if (process.argv.includes('--push')) {
  console.log('🚀 Pushing...');
  execSync('git add -A && git commit -m "update: ' + now.toISOString().split('T')[0] + '" && git push', { stdio: 'inherit' });
  console.log('✅ Pushed!');
}

// ── Helpers ──────────────────────────────────────────────────────────────────

function tryExec(cmd) { try { return execSync(cmd, { encoding: 'utf-8' }).trim(); } catch { return null; } }
function countMd(dir) { try { return parseInt(execSync(`find "${dir}" -name '*.md' 2>/dev/null | wc -l`, { encoding: 'utf-8' }).trim()) || 0; } catch { return 0; } }
function dirSize(dir) { try { return (parseInt(execSync(`du -sk "${dir}" 2>/dev/null`, { encoding: 'utf-8' }).trim().split('\t')[0]) || 0) * 1024; } catch { return 0; } }
function fmt(n) { if (n >= 1e9) return (n/1e9).toFixed(2)+'B'; if (n >= 1e6) return (n/1e6).toFixed(1)+'M'; if (n >= 1e3) return (n/1e3).toFixed(1)+'K'; return n.toString(); }
function fmtSize(b) { if (b >= 1e9) return (b/1e9).toFixed(1)+' GB'; if (b >= 1e6) return (b/1e6).toFixed(1)+' MB'; if (b >= 1e3) return (b/1e3).toFixed(1)+' KB'; return b+' B'; }
function pct(p, w) { return w ? ((p/w)*100).toFixed(1) : '0'; }
function esc(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }


// ── HTML ─────────────────────────────────────────────────────────────────────

function generateHTML() {
  const hero = [
    { label: '.md Files', value: fmt(totalMdInVault), color: 'text-blue-400' },
    { label: 'Projects', value: HAS_VAULT ? totalVaultProjects.toString() : totalWithPsi.toString(), color: 'text-emerald-400' },
    ...(HAS_VAULT ? [{ label: 'Orgs', value: totalVaultOrgs.toString(), color: 'text-violet-400' }] : []),
    { label: 'Skills', value: skills.length.toString(), color: 'text-amber-400' },
    { label: HAS_VAULT ? 'Vault Size' : 'ψ/ Repos', value: HAS_VAULT ? fmtSize(vaultSize) : totalWithPsi.toString(), color: 'text-rose-400' },
  ];

  const heroCards = hero.map(s => `<div class="glass rounded-xl p-3">
    <div class="text-[10px] text-gray-500 uppercase tracking-wider mb-1">${s.label}</div>
    <div class="text-xl font-bold font-mono ${s.color}">${s.value}</div>
  </div>`).join('\n');

  // Connection breakdown
  const breakdownBars = [
    { label: 'Symlinked → vault', count: totalSymlinked, color: 'emerald' },
    { label: 'Real ψ/ (repos)', count: totalReal, color: 'violet' },
    { label: 'Real ψ/ (worktrees)', count: totalWorktrees, color: 'amber' },
  ].filter(b => b.count > 0).map(b => { const p = pct(b.count, totalWithPsi); return `<div>
    <div class="flex justify-between items-center mb-1">
      <span class="text-xs text-gray-400">${b.label}</span>
      <span class="font-mono text-xs text-${b.color}-400">${b.count} <span class="text-gray-600">(${p}%)</span></span>
    </div>
    <div class="h-1.5 bg-surface-3 rounded-full overflow-hidden">
      <div class="h-full bg-gradient-to-r from-${b.color}-600 to-${b.color}-400 rounded-full" style="width: ${p}%"></div>
    </div>
  </div>`; }).join('\n');

  // Org distribution (vault only)
  const orgRows = orgList.map(o => { const c = orgColor(o.org); const p = pct(o.mdCount, totalMdInVault); return `<div>
    <div class="flex justify-between items-center mb-1">
      <div class="flex items-center gap-1.5"><span class="w-1.5 h-1.5 rounded-full bg-${c}-500"></span><span class="text-xs text-gray-300">${o.org}</span></div>
      <span class="font-mono text-xs text-${c}-400">${fmt(o.mdCount)} <span class="text-gray-600">(${o.projects})</span></span>
    </div>
    <div class="h-1 bg-surface-3 rounded-full overflow-hidden"><div class="h-full bg-${c}-500 rounded-full" style="width: ${p}%"></div></div>
  </div>`; }).join('\n');

  // Top projects chart
  const topProjects = HAS_VAULT ? vaultProjects.slice(0, 20) : [...repos.realRepos, ...repos.realWorktrees].sort((a,b) => b.mdCount - a.mdCount).slice(0, 20);
  const maxMd = Math.max(...topProjects.map(p => p.mdCount || 0), 1);
  const projectBars = topProjects.map((p, i) => {
    const name = p.project || p.rel?.split('/').pop() || '?';
    const org = p.org || p.rel?.split('/').slice(-2, -1)[0] || '';
    const w = Math.max(((p.mdCount || 0)/maxMd)*100, 1);
    const c = orgColor(org || name);
    return `<div class="flex items-center gap-2">
      <span class="w-4 text-[10px] text-gray-600 text-right font-mono">${i+1}</span>
      <span class="w-[180px] text-[11px] text-gray-400 truncate">${esc(name)}</span>
      <div class="flex-1 h-3 bg-surface-3 rounded-full overflow-hidden"><div class="h-full bg-gradient-to-r from-${c}-600 to-${c}-400 rounded-full" style="width: ${w.toFixed(1)}%"></div></div>
      <span class="w-12 text-[10px] font-mono text-gray-500 text-right">${fmt(p.mdCount)}</span>
    </div>`;
  }).join('\n');

  // Rsync eligible
  const rsyncList = [...repos.realRepos, ...repos.realWorktrees].sort((a,b) => b.mdCount - a.mdCount);
  const rsyncRows = rsyncList.map(r => {
    const isWt = !!r.parentRel;
    const tag = isWt ? `<span class="px-1 py-0.5 text-[9px] bg-amber-500/20 text-amber-400 rounded">wt</span>` : `<span class="px-1 py-0.5 text-[9px] bg-violet-500/20 text-violet-400 rounded">repo</span>`;
    return `<tr class="border-b border-white/5 hover:bg-white/[0.02]">
      <td class="py-1 px-2 text-xs text-gray-300 font-mono truncate max-w-[280px]">${esc(r.rel)}</td>
      <td class="py-1 px-2">${tag}</td>
      <td class="py-1 px-2 text-xs text-gray-400 font-mono text-right">${r.mdCount}</td>
      <td class="py-1 px-2 text-xs text-gray-500 font-mono text-right">${fmtSize(r.size)}</td>
    </tr>`;
  }).join('\n');

  // Skills
  const skillRows = skills.map(s => {
    const desc = s.description.replace(/^v[\d.]+ G-SKLL \| /, '');
    return `<div class="flex items-start gap-2 py-1">
      <span class="text-xs text-violet-400 font-mono w-[140px] shrink-0">/${esc(s.name)}</span>
      <span class="text-[11px] text-gray-500 leading-tight">${esc(desc)}</span>
    </div>`;
  }).join('\n');

  // Conditional sections
  const hasVaultSection = HAS_VAULT && orgList.length > 0;
  const hasRsync = rsyncList.length > 0;
  const hasSkills = skills.length > 0;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Oracle Vault Report</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script>tailwind.config={theme:{extend:{colors:{surface:'#0a0a0f','surface-2':'#111118','surface-3':'#1a1a24'},fontFamily:{sans:['Inter','system-ui','sans-serif'],mono:['JetBrains Mono','Fira Code','monospace']}}}}</script>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap');
    body { font-family: 'Inter', system-ui, sans-serif; background: #000; }
    .font-mono { font-family: 'JetBrains Mono', monospace; }
    .oled-bg { background: radial-gradient(ellipse at top, #0d1117 0%, #000 50%); }
    .glass { background: rgba(17, 17, 24, 0.8); backdrop-filter: blur(20px); border: 1px solid rgba(255,255,255,0.06); }
    ::-webkit-scrollbar { width: 6px; } ::-webkit-scrollbar-track { background: transparent; } ::-webkit-scrollbar-thumb { background: #333; border-radius: 3px; }
  </style>
</head>
<body class="oled-bg min-h-screen text-white antialiased">
  <div class="max-w-6xl mx-auto px-4 py-6">

    <header class="text-center mb-6">
      <h1 class="text-2xl font-semibold tracking-tight mb-1">Oracle Vault Report</h1>
      <p class="text-gray-500 text-xs font-mono">${totalWithPsi} repos with ψ/${HAS_VAULT ? ` &middot; ${totalVaultProjects} vault projects` : ''} &middot; ${skills.length} skills &middot; ${generatedDisplay}</p>
      <div class="mt-2"><a href="data.json" class="text-xs text-gray-500 hover:text-gray-300">JSON</a></div>
    </header>

    <div class="grid grid-cols-${hero.length} gap-2 mb-4">${heroCards}</div>

    <div class="grid lg:grid-cols-2 gap-3 mb-4">
      <div class="glass rounded-xl p-4">
        <h2 class="text-sm font-semibold mb-3">ψ/ Connection Breakdown <span class="text-[10px] text-gray-600 font-normal">(${totalWithPsi} repos)</span></h2>
        <div class="space-y-3">${breakdownBars}</div>
        ${totalNeedSync > 0 ? `<div class="mt-3 p-2.5 bg-surface-3/50 rounded-lg border border-white/5 flex items-center justify-between">
          <div><div class="text-[10px] text-gray-500 uppercase">Needs rsync</div><div class="text-lg font-bold font-mono text-white">${totalNeedSync}</div></div>
          <div class="text-[10px] text-gray-600">${totalReal} repos + ${totalWorktrees} wt</div>
        </div>` : ''}
      </div>
      ${hasVaultSection ? `<div class="glass rounded-xl p-4">
        <h2 class="text-sm font-semibold mb-3">Org Distribution</h2>
        <div class="space-y-2.5">${orgRows}</div>
      </div>` : `<div class="glass rounded-xl p-4">
        <h2 class="text-sm font-semibold mb-3">ghq Overview</h2>
        <div class="text-xs text-gray-400 space-y-2">
          <div class="flex justify-between"><span>Total ghq repos</span><span class="font-mono text-gray-300">${totalRepos}</span></div>
          <div class="flex justify-between"><span>Repos with ψ/</span><span class="font-mono text-emerald-400">${totalWithPsi}</span></div>
          <div class="flex justify-between"><span>Total .md files</span><span class="font-mono text-blue-400">${fmt(totalMdInVault)}</span></div>
        </div>
      </div>`}
    </div>

    ${topProjects.length > 0 ? `<div class="glass rounded-xl p-4 mb-4">
      <h2 class="text-sm font-semibold mb-3">Top ${Math.min(topProjects.length, 20)} Projects <span class="text-[10px] text-gray-600 font-normal">(.md files)</span></h2>
      <div class="space-y-1">${projectBars}</div>
    </div>` : ''}

    <div class="grid lg:grid-cols-2 gap-3 mb-4">
      ${hasRsync ? `<div class="glass rounded-xl p-4">
        <h2 class="text-sm font-semibold mb-3">Rsync Eligible <span class="text-[10px] text-gray-600 font-normal">(${totalNeedSync})</span></h2>
        <table class="w-full text-left">
          <thead class="text-[10px] text-gray-500 uppercase tracking-wider border-b border-white/10">
            <tr><th class="py-1 px-2">Repo</th><th class="py-1 px-2">Type</th><th class="py-1 px-2 text-right">.md</th><th class="py-1 px-2 text-right">Size</th></tr>
          </thead>
          <tbody>${rsyncRows}</tbody>
        </table>
      </div>` : ''}
      ${hasSkills ? `<div class="glass rounded-xl p-4">
        <h2 class="text-sm font-semibold mb-3">Oracle Skills <span class="text-[10px] text-gray-600 font-normal">(${skills.length}${skillsVersion ? ' &middot; ' + skillsVersion : ''})</span></h2>
        <div class="divide-y divide-white/5">${skillRows}</div>
      </div>` : ''}
    </div>

    <footer class="text-center text-gray-600 text-[10px] py-3 border-t border-white/5">
      <a href="https://github.com/Soul-Brews-Studio/oracle-vault-report" class="text-gray-500 hover:text-gray-300">oracle-vault-report</a> &middot; <span class="font-mono">${generated}</span>
    </footer>
  </div>
</body>
</html>`;
}
