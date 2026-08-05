import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: 'Bonding Love Garden',
  tagline: 'Play Park Management Platform — Documentation',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  // Not deployed anywhere yet — placeholder until a real docs host is chosen.
  url: 'https://docs.bondinglovegarden.example',
  baseUrl: '/',

  organizationName: 'bonding-love-garden',
  projectName: 'docs-site',

  onBrokenLinks: 'warn',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    colorMode: {
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'Bonding Love Garden',
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'developerGuideSidebar',
          position: 'left',
          label: 'Developer Guide',
        },
        {
          type: 'docSidebar',
          sidebarId: 'userGuideSidebar',
          position: 'left',
          label: 'User Guide',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {label: 'Developer Guide', to: '/docs/developer-guide/overview'},
            {label: 'User Guide', to: '/docs/user-guide/overview'},
          ],
        },
      ],
      copyright: `Bonding Love Garden — internal documentation.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
