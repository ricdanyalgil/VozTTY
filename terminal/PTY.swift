import Foundation
import Darwin

@MainActor
final class ShellSession {
    private var master: FileHandle?
    private(set) var pid: pid_t = 0
    private let writer = DispatchQueue(label: "com.danyalgil.voztty.pty-input")
    var output: ((Data) -> Void)?
    var ended: (() -> Void)?

    func start(executable: String, arguments: [String], directory: String) throws {
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        env["TERM_PROGRAM"] = "VozTTY"
        let args = ([executable] + arguments).map { strdup($0) }
        let vars = env.map { strdup("\($0.key)=\($0.value)") }
        let cwd = strdup(directory)
        defer { for p in args + vars { free(p) }; free(cwd) }
        var argv = args + [nil]
        var envp = vars + [nil]
        var fd: Int32 = -1
        var size = winsize(ws_row: 30, ws_col: 100, ws_xpixel: 0, ws_ypixel: 0)
        let child = argv.withUnsafeMutableBufferPointer { a in
            envp.withUnsafeMutableBufferPointer { e in
                let child = forkpty(&fd, nil, nil, &size)
                if child == 0 {
                    if chdir(cwd!) != 0 { _exit(126) }
                    execve(a[0]!, a.baseAddress!, e.baseAddress!)
                    _exit(127)
                }
                return child
            }
        }
        guard child > 0 else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
        pid = child
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        master = handle
        handle.readabilityHandler = { [weak self] file in
            var bytes = [UInt8](repeating: 0, count: 65536)
            let count = Darwin.read(file.fileDescriptor, &bytes, bytes.count)
            let data = count > 0 ? Data(bytes.prefix(count)) : Data()
            if !data.isEmpty { Task { @MainActor in self?.output?(data) } }
            else { file.readabilityHandler = nil }
        }
        DispatchQueue.global().async { [weak self] in
            var status: Int32 = 0
            while waitpid(child, &status, 0) < 0 && errno == EINTR {}
            Task { @MainActor in
                guard let self, self.pid == child else { return }
                self.pid = 0
                self.ended?()
            }
        }
    }

    func write(_ text: String) {
        guard pid > 0, let master else { return }
        let copy = dup(master.fileDescriptor)
        guard copy >= 0 else { return }
        let data = Data(text.utf8)
        // Keep PTY backpressure off the UI thread; the duplicate prevents descriptor reuse races.
        writer.async {
            defer { Darwin.close(copy) }
            data.withUnsafeBytes { bytes in
                var offset = 0
                while offset < bytes.count {
                    let count = Darwin.write(copy, bytes.baseAddress!.advanced(by: offset), bytes.count - offset)
                    if count > 0 { offset += count }
                    else if count < 0 && errno == EINTR { continue }
                    else { break }
                }
            }
        }
    }

    func resize(columns: Int, rows: Int) {
        guard let master, (2...1000).contains(columns), (2...500).contains(rows) else { return }
        var size = winsize(ws_row: UInt16(rows), ws_col: UInt16(columns), ws_xpixel: 0, ws_ypixel: 0)
        _ = ioctl(master.fileDescriptor, TIOCSWINSZ, &size)
    }

    func close() {
        if pid > 0 { _ = kill(-pid, SIGHUP); _ = kill(pid, SIGHUP) }
        master?.readabilityHandler = nil
        try? master?.close()
        master = nil
    }
}
