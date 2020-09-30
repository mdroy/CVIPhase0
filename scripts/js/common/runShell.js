//##################################################################
//Script Name	: runShell.js                                                                                             
//Description	: This script run bash scripts and return response                                                                               
//Args          :                                                                                           
//Author       	: Mithun D Roy                                               
//DateTime      : 10-APR-2020 21:04:00
//##################################################################
var shell = require('shelljs');

shell.cd('/u01/app/cm/scripts/bash/administration/networking');
const { stdout, stderr, code } = shell.exec('./displayWallet.sh', { silent: true });
if (code !== 0) {
  shell.echo('Error: Git commit failed');
  shell.exit(1);
} else {
  shell.echo(stdout);
}

