// docmd.config.js
export default defineConfig({
  title: 'fire-skills',
  url: 'https://variableway.github.io/fire-skills',

  src: 'docs',
  out: 'site',

  layout: {
    spa: true,
    header: { enabled: true },
    sidebar: { collapsible: true, defaultCollapsed: false },
    optionsMenu: {
      position: 'sidebar-top',
      components: { search: true, themeSwitch: true, sponsor: null },
    },
    footer: {
      style: 'minimal',
      content: '© ' + new Date().getFullYear() + ' fire-skills',
      branding: true,
    },
  },

  theme: {
    name: 'sky',
    appearance: 'system',
    codeHighlight: true,
    customCss: [],
  },

  minify: true,
  autoTitleFromH1: true,
  copyCode: true,
  pageNavigation: true,

  navigation: [
    { title: 'Home', path: '/', icon: 'home' },
  ],

  plugins: {
    seo: {
      defaultDescription: 'fire-skills documentation',
      openGraph: { defaultImage: '' },
      twitter: { cardType: 'summary_large_image' },
    },
    sitemap: { defaultChangefreq: 'weekly' },
    search: {},
    mermaid: {},
    llms: { fullContext: true },
  },
});
