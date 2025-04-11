/*
 * testflows.js
 * Author: Kim McKinley <kim@lrunit.net> (http://github.com/potofcoffee2go)
 * License: MIT
 *
 * This file creates a node-red site in ./test/flotsam under-which
 *  a node-red sitedir containing the new test flows.
 * Note! - the existing test flows JSON will be overwritten with the ones
 *  from this release!
 *
 * A files directory is also created which is the default location of the in/out
 *  files used by the test flows. If it already exists remains unchanged.
 *
 * This script normally started by npm install as a 'postinstall' directive
 *  within the project package.json.
 *
 */

'use strict';

const fs = require('fs-extra');
const resolve = require('path').resolve;
var pkg = require('../package.json');

console.log('');
console.log('Create Alasql Test Suite');
var userDir = resolve(__dirname,'./flotsam/userdir');
var flowFile = resolve(__dirname,'./flotsam/userdir/alafiletests.json');
var filesDir = resolve(__dirname,'./flotsam/files');

// Create/the test flows
console.log('Create directories for node-red settings, test flows, and files');

// Overwrite existing alafiletests.json with the one from this release
fs.copySync(resolve(__dirname,'../flows/alafiletests.json'), flowFile);
// Ensure we got a default place to put files in/out
fs.ensureDirSync(resolve(__dirname,'./flotsam/files'));

// Inform of the paths to various stuff
console.log('Node-red user directory: ' + userDir);
console.log('Test flows copied into: ' + flowFile);
console.log('Test files directory: ' + filesDir);

// Symlink
console.log('');
console.log('Create symlink - all instances of node-red will now include' +
            ' alasql nodes in the palette.');
console.log('After testing can do a \'npm unlink\' from this directory' +
            ' to remove the symlink.');
require('child_process').spawnSync('npm', ['link'], { env: process.env, stdio: 'inherit'});

// Directions for starting up the Test Suite
console.log('');
console.log('To start the Test Suite in node-red:');
console.log('npm test');
