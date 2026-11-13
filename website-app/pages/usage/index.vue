<script setup lang="ts">
useHead({
  title: 'Usage guide | syncenv',
  meta: [
    { name: 'description', content: 'Complete syncenv usage reference: manage modes, peers, secrets, sync, backups, cron, and service lifecycle from the CLI.' },
    { property: 'og:title', content: 'Usage guide | syncenv CLI reference' },
    { property: 'og:description', content: 'Complete syncenv CLI reference: manage modes, peers, secrets, sync, backups, cron, and service lifecycle.' },
    { property: 'og:type', content: 'article' },
    { property: 'og:url', content: 'https://syncenv.yuvrajthapa.com/usage' },
    { property: 'og:image', content: 'https://syncenv.yuvrajthapa.com/assets/cover.png' },
    { name: 'twitter:card', content: 'summary_large_image' },
    { name: 'twitter:title', content: 'Usage guide | syncenv CLI reference' },
    { name: 'twitter:description', content: 'Complete syncenv CLI reference: manage modes, peers, secrets, sync, backups, cron, and service lifecycle.' },
    { name: 'twitter:image', content: 'https://syncenv.yuvrajthapa.com/assets/cover.png' },
    { name: 'keywords', content: 'syncenv usage, syncenv CLI, secrets sync commands, peer management, dotenv sync guide' },
  ],
  link: [
    { rel: 'canonical', href: 'https://syncenv.yuvrajthapa.com/usage' },
  ],
})
</script>

<template>
  <div class="subpage-hero">
    <h1>Usage guide</h1>
    <p>Everything you can do with syncenv — from adding your first secret to managing peer access across machines.</p>
  </div>

  <section class="panel">
    <h2>Quick commands</h2>
    <p>The most common commands you will use day to day:</p>
    <pre><code>syncenv              # sync secrets from peers
syncenv status       # show current mode, host, peer count
syncenv discover     # list discovered peers on the network
syncenv --help       # full command reference</code></pre>
  </section>

  <section class="panel">
    <h2>Desktop GUI</h2>
    <p>Prefer a visual workflow? Install <code>syncenv-gui</code> with <code>--all</code> or <code>--gui-only</code> and launch the desktop app alongside the CLI.</p>
    <p>The GUI works on the same <code>~/.config/syncenv/</code> state as the CLI, so secrets, peers, keys, backups, and mode changes stay in sync whichever interface you use.</p>
    <p>Inside the app, the dashboard gives you status at a glance, while dedicated views handle secrets, sync, peers, keys, settings, and logs. For the complete GUI guide, see <a href="https://github.com/yuvraj1107thapa/syncenv/blob/main/docs/GUI.md">GUI.md</a>.</p>
  </section>

  <section class="panel">
    <h2>Mode management</h2>
    <p>Switch between security modes at any time. Mode switching is non-destructive by default.</p>
    <pre><code>syncenv mode get
syncenv mode set trusted-owner-ssh
syncenv mode set secure-peer
syncenv mode set dev-plaintext-http
syncenv mode set secure-peer --yes
syncenv mode set trusted-owner-ssh --prune-old-material --yes</code></pre>
  </section>

  <section class="panel">
    <h2>Peer management</h2>
    <p><strong>secure-peer mode</strong> — invitation-based access with explicit approval:</p>
    <pre><code>syncenv peer invite --expires 1h
syncenv peer request alice@hostname.local &lt;token&gt;
syncenv peer list --pending
syncenv peer approve bob@new-host.local
syncenv peer revoke mallory@compromised-host.local
syncenv peer trust show alice@hostname.local</code></pre>
    <p>Peer IDs are per-user (<code>user@host</code>). Endpoints also accept an explicit port: <code>alice@hostname.local:5740</code>.</p>
    <p><strong>trusted-owner mode</strong> — any SSH-reachable peer can sync without approval.</p>
  </section>

  <section class="panel">
    <h2>Secret &amp; sync operations</h2>
    <pre><code># manage secrets
syncenv add KEY="value"
syncenv remove KEY
syncenv list
syncenv show KEY
eval "$(syncenv load 2>/dev/null)"

# sync with peers
syncenv sync
syncenv sync alice@hostname.local
syncenv sync --force-pull alice@hostname.local
syncenv sync --dry-run</code></pre>
    <p><code>--force-pull</code> fully overwrites local secrets from the selected host. A backup is created first.</p>
  </section>

  <section class="panel">
    <h2>Service, cron &amp; backups</h2>
    <pre><code># background service
syncenv serve -d
syncenv service stop
syncenv service restart
syncenv service uninstall

# automatic sync via cron
syncenv cron --install --interval 30
syncenv cron --show
syncenv cron --remove

# restore from backup
syncenv restore       # list available backups
syncenv restore 1     # restore specific backup</code></pre>
  </section>

  <section class="panel">
    <h2>Troubleshooting</h2>
    <pre><code># check the log file
tail -f ~/.config/syncenv/logs/syncenv.log

# verbose output
syncenv sync --verbose

# verify connectivity
syncenv discover

syncenv status   # shows user@host peer IDs
# each OS user has their own server port (~/.config/syncenv/port)</code></pre>
  </section>

  <section class="cta-banner">
    <h2>Need help choosing a mode?</h2>
    <p>Learn about the three security models and when to use each one.</p>
    <div class="cta-row" style="justify-content:center;">
      <NuxtLink class="btn btn-primary" to="/modes">Mode comparison →</NuxtLink>
      <NuxtLink class="btn btn-secondary" to="/security">Security details</NuxtLink>
    </div>
  </section>
</template>
