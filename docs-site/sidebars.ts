import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  developerGuideSidebar: [
    {
      type: 'category',
      label: 'Developer Guide',
      link: {type: 'doc', id: 'developer-guide/overview'},
      items: [
        'developer-guide/overview',
        'developer-guide/database-schema',
        'developer-guide/edge-functions',
        'developer-guide/web-admin',
      ],
    },
  ],
  userGuideSidebar: [
    {
      type: 'category',
      label: 'User Guide',
      link: {type: 'doc', id: 'user-guide/overview'},
      items: [
        'user-guide/overview',
        'user-guide/admin-dashboard',
      ],
    },
  ],
};

export default sidebars;
