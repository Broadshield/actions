#!/usr/bin/env node
const environmentNameList = new Set(['dev', 'development', 'test', 'qa', 'testing', 'staging', 'prod', 'production']);
const rawApplicationName = process.argv[2];

const applicationName = rawApplicationName
  .split('-')
  .filter((word) => !environmentNameList.has(word.toLowerCase()))
  .join('-');
// eslint-disable-next-line no-console
console.log(applicationName);
