#!/usr/bin/env node
const environment_name_list = ["dev", "development", "test", "qa", "testing", "staging", "prod", "production"];
const raw_application_name = process.argv[2];

const application_name = raw_application_name
  .split("-")
  .filter((word) => !environment_name_list.includes(word.toLowerCase()))
    .join("-");
  console.log(application_name);