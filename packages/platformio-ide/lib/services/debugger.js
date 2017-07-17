/** @babel */

/**
 * Copyright (c) 2016-present PlatformIO <contact@platformio.org>
 * All rights reserved.
 *
 * This source code is licensed under the license found in the LICENSE file in
 * the root directory of this source tree.
 */

import { DEFAULT_PIO_ARGS } from '../config';

import { Disposable } from 'atom';

import Telemetry from '../telemetry';


let debuggerService = null;
let lastProjectDebug = null;

export function DebuggerConsumer(service) {
  debuggerService = service;
  debuggerService.on('stop', () => terminateProjectDebug());
  return new Disposable(() => {
    terminateProjectDebug();
    debuggerService = null;
  });
}

export function debugProject(projectDir, environment=undefined) {
  if (lastProjectDebug) {
    lastProjectDebug.terminate();
  }
  lastProjectDebug = new ProjectDebug(projectDir, environment);
  return lastProjectDebug.start();
}

function terminateProjectDebug() {
  if (!lastProjectDebug) {
    return;
  }
  lastProjectDebug.terminate();
  lastProjectDebug = null;
}


export class ProjectDebug {

  constructor(projectDir, environment=undefined) {
    this.projectDir = projectDir;
    this.environment = environment;
  }

  start() {
    Telemetry.hitEvent('Debug', 'launch', `${this.environment}`);
    const clientArgs = DEFAULT_PIO_ARGS.slice(0);
    clientArgs.push('debug');
    clientArgs.push('--project-dir');
    clientArgs.push(this.projectDir);
    if (this.environment) {
      clientArgs.push('--environment');
      clientArgs.push(this.environment);
    }
    clientArgs.push('--interface=gdb');
    debuggerService.debug({
      clientExecutable: 'platformio',
      clientArgs,
      projectDir: this.projectDir,
      initCommands: ['source .pioinit'],
      env: process.env
    });
  }

  terminate() {
    debuggerService.stop();
  }

}
