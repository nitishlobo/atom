{bufferedProcess, cstr} = require './utils'
{Emitter} = require 'atom'
{Parser} = require './gdbmi.js'
Exec = require './exec'
Breaks = require './breaks'
VarObj = require './varobj'

# Public: A class to control an instance of GDB running as a child process.
# The child is not spawned on construction, but only when calling `.connect`
class GDB
    # A {BreakpointManager} instance.
    breaks: null
    # An {ExecState} instance.
    exec: null
    # A {VariableManager} instance.  API not finalised.
    vars: null
    command: 'gdb'

    constructor: (command) ->
        if command? then @command = command
        @next_token = 0
        @cmdq = []
        @parser = new Parser
        @emitter = new Emitter
        @exec = new Exec(this)
        @breaks = new Breaks(this)
        @vars = new VarObj(this)

    onConsoleOutput: (cb) ->
        @emitter.on 'console-output', cb
    # @private
    onGdbmiRaw: (cb) ->
        @emitter.on 'gdbmi-raw', cb

    # @private Invoke callback on received async exec records.
    onAsyncExec: (cb) ->
        @emitter.on 'async-exec', cb

    # @private Invoke callback on received async notify records.
    onAsyncNotify: (cb) ->
        @emitter.on 'async-notify', cb

    # @private Invoke callback on received async status records.
    onAsyncStatus: (cb) ->
        @emitter.on 'async-status', cb

    # Invoke the given function when GDB starts.
    onConnect: (cb) ->
        @emitter.on 'connected', cb

    # Invoke the given function when GDB exits.
    onDisconnect: (cb) ->
        @emitter.on 'disconnected', cb

    # Spawn the GDB child process, and set up with our config.
    #
    # @return [Promise] resolves when GDB is running.
    connect: (command, args) ->
        if command? then @command = command
        if not args then args = []
        args = args.concat(['--interpreter=mi', '-nx'])
        (@child?.kill() or Promise.resolve())
        .then =>
            bufferedProcess
                command: @command
                args: args
                stdout: @_line_output_handler.bind(this)
                exit: @_child_exited.bind(this)
        .then (@child) =>
            @send_mi '-gdb-set target-async on'
        .then =>
            @emitter.emit 'connected'

    # Politely request the GDB child process to exit
    disconnect: ->
        # First interrupt the target if it's running
        if not @child? then return
        if @exec.state == 'RUNNING'
            @exec.interrupt()
        @send_mi '-gdb-exit'

    terminate: ->
        if not @child? then return
        @child.stdin '-gdb-exit'
        setTimeout (-> @child?.kill()), 1000

    # @private
    _line_output_handler: (line) ->
        # Handle line buffered output from GDB child process
        @emitter.emit 'gdbmi-raw', line
        try
            r = @parser.parse line
        catch err
            @emitter.emit 'console-output', ['CONSOLE', line + '\n']
        if not r? then return
        @emitter.emit 'gdbmi-ast', r
        switch r.type
            when 'OUTPUT' then @emitter.emit 'console-output', [r.cls, r.cstring]
            when 'ASYNC' then @_async_record_handler r.cls, r.rcls, r.results
            when 'RESULT' then @_result_record_handler r.cls, r.results

    # @private
    _async_record_handler: (cls, rcls, results) ->
        signal = 'async-' + cls.toLowerCase()
        @emitter.emit signal, [rcls, results]
    # @private
    _result_record_handler: (cls, results) ->
        c = @cmdq.shift()
        if cls == 'error'
            c?.reject new Error results.msg
            @_flush_queue()
            return
        c?.resolve results
        @_drain_queue()
    # @private
    _child_exited: () ->
        # Clean up state if/when GDB child process exits
        @emitter.emit 'disconnected'
        @_flush_queue()
        delete @child

    # Send a gdb/mi command.  This is used internally by sub-modules.
    #
    # @return [Promise] resolves to the results part of the result record
    # reply or rejected in the case of an error reply.
    send_mi: (cmd, quiet) ->
        # Send an MI command to GDB
        if not @child?
            return Promise.reject new Error('Not connected')
        new Promise (resolve, reject) =>
            cmd = @next_token + cmd
            @next_token += 1
            @cmdq.push {quiet: quiet, cmd: cmd, resolve:resolve, reject: reject}
            if @cmdq.length == 1
                @_drain_queue()
    # @private
    _drain_queue: ->
        c = @cmdq[0]
        if not c? then return
        @emitter.emit 'gdbmi-raw', c.cmd
        @child.stdin c.cmd
    # @private
    _flush_queue: ->
        for c in @cmdq
            c.reject new Error('Flushed due to previous errors')
        @cmdq = []

    # Send a gdb/cli command.  This may be used to implement a CLI
    # window in a GUI frontend tool, or to send monitor or other commands for
    # which no equivalent MI commands exist.
    #
    # @return [Promise] resolves on success.
    send_cli: (cmd) ->
        cmd = cmd.trim()
        if cmd.startsWith '#'
            return Promise.resolve()
        @send_mi "-interpreter-exec console #{cstr(cmd)}"

    set: (name, value) ->
        @send_mi "-gdb-set #{name} #{value}"

    show: (name) ->
        @send_mi "-gdb-show #{name}"
            .then ({value}) -> value

    # Set current working directory.
    setCwd: (path) ->
        @send_mi "-environment-cd #{cstr(path)}"

    # Set current file for target execution and symbols.
    setFile: (path) ->
        @send_mi "-file-exec-and-symbols #{cstr(path)}"

    # Tear down the object and free associated resources.
    destroy: ->
        @terminate()
        @breaks.destroy()
        @exec.destroy()
        @vars.destroy()
        @emitter.dispose()

module.exports = GDB
