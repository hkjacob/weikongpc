using System.Diagnostics;
using System.Runtime.InteropServices;
using System.ServiceProcess;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

// ============================================================================
// WeikongPC Client (WeikongPC.exe)
// Single file: INI parse + Windows service self-register + status collect +
//              beat report + shutdown execute
// ----------------------------------------------------------------------------
// Design: README.md (2026-08-10)
//   - beat: POST {ServerUrl} (default https://weikongpc.com/beat)
//   - Auth: HTTP Header X-Uid / X-Uid-Key
//   - Body: os / cpu_usage / mem_usage / processes[]
//   - Response: HTTP status code only (no body)
//       200 -> wait 180s, repeat
//       201 -> shutdown immediately
//       401 -> auth fail, exit
//       429 -> too frequent, reset 180s timer
//   - Interval: 180s (hardcode)
//   - Service register: built-in (install/uninstall args)
// ----------------------------------------------------------------------------

// ----- Entry: detect run mode -----
if (Environment.UserInteractive)
{
    var arg = args.Length > 0 ? args[0].ToLowerInvariant() : "";
    switch (arg)
    {
        case "install":
            ServiceSelfInstaller.Install();
            return;
        case "uninstall":
            ServiceSelfInstaller.Uninstall();
            return;
        case "rebind":
            RebindHelper.OpenBindPage();
            return;
        default:
        {
            // Interactive mode: run main loop directly (for testing)
            using var cts = new CancellationTokenSource();
            Console.CancelKeyPress += (_, e) => { e.Cancel = true; cts.Cancel(); };
            var svc = new WeikongService();
            svc.RunMainLoopAsync(cts.Token).GetAwaiter().GetResult();
            return;
        }
    }
}
else
{
    // Service mode: launched by SCM
    ServiceBase.Run(new WeikongService());
}

// ============================================================================
// Windows Service class
// ============================================================================
public class WeikongService : ServiceBase
{
    private const int BeatIntervalSeconds = 180;

    private CancellationTokenSource? _cts;
    private Task? _loopTask;

    public WeikongService()
    {
        ServiceName = "WeikongPC";
        CanStop = true;
        CanPauseAndContinue = false;
        AutoLog = true;
    }

    protected override void OnStart(string[] args)
    {
        _cts = new CancellationTokenSource();
        _loopTask = RunMainLoopAsync(_cts.Token);
    }

    protected override void OnStop()
    {
        _cts?.Cancel();
        try { _loopTask?.Wait(TimeSpan.FromSeconds(10)); } catch { }
    }

    public async Task RunMainLoopAsync(CancellationToken token)
    {
        var exeDir = AppContext.BaseDirectory;
        var iniPath = Path.Combine(exeDir, "WeikongPC.ini");

        if (!File.Exists(iniPath))
        {
            Logger.Error($"Config file not found: {iniPath}, exit.");
            return;
        }

        var config = IniConfig.Load(iniPath);
        if (!config.Valid)
        {
            Logger.Error($"Config invalid: {iniPath}, exit.");
            return;
        }

        Logger.Info($"Started. uid={config.Uid.Substring(0, 8)}..., beat={config.ServerUrl}, interval={BeatIntervalSeconds}s");

        using var http = new HttpClient { Timeout = TimeSpan.FromSeconds(15) };

        while (!token.IsCancellationRequested)
        {
            int waitSeconds = BeatIntervalSeconds;
            try
            {
                waitSeconds = await BeatOnceAsync(http, config, token);
            }
            catch (OperationCanceledException) { break; }
            catch (HttpRequestException ex)
            {
                Logger.Error($"[BEAT] Network error: {ex.Message}");
                waitSeconds = BeatIntervalSeconds;
            }
            catch (Exception ex)
            {
                Logger.Error($"[BEAT] Unhandled: {ex.Message}");
                waitSeconds = BeatIntervalSeconds;
            }

            if (waitSeconds < 0) break;  // 401: exit
            if (token.IsCancellationRequested) break;

            try
            {
                Logger.Info($"Next beat in {waitSeconds}s");
                await Task.Delay(TimeSpan.FromSeconds(waitSeconds), token);
            }
            catch (OperationCanceledException) { break; }
        }

        Logger.Info("Stopped.");
    }

    private async Task<int> BeatOnceAsync(HttpClient http, IniConfig config, CancellationToken token)
    {
        var (cpuUsage, memUsage) = SystemMonitor.GetUsage();
        var processes = SystemMonitor.GetProcesses();

        var beatReq = new BeatRequest
        {
            Os = config.Os,
            CpuUsage = cpuUsage,
            MemUsage = memUsage,
            Processes = processes
        };

        var json = JsonSerializer.Serialize(beatReq, BeatJsonContext.Default.BeatRequest);
        Logger.Info($"[BEAT] cpu={cpuUsage:F1}% mem={memUsage:F1}% procs={processes.Count} -> {config.ServerUrl}");

        using var req = new HttpRequestMessage(HttpMethod.Post, config.ServerUrl);
        req.Headers.Add("X-Uid", config.Uid);
        req.Headers.Add("X-Uid-Key", config.UidKey);
        req.Content = new StringContent(json, Encoding.UTF8, "application/json");

        var resp = await http.SendAsync(req, token);

        switch ((int)resp.StatusCode)
        {
            case 200:
                Logger.Info($"[BEAT] 200 OK, {BeatIntervalSeconds}s until next");
                return BeatIntervalSeconds;
            case 201:
                Logger.Info("[BEAT] 201 shutdown command received");
                ExecuteShutdown();
                return int.MaxValue;
            case 401:
                Logger.Error("[BEAT] 401 auth failed, exit");
                return -1;
            case 429:
                Logger.Info($"[BEAT] 429 too frequent, reset {BeatIntervalSeconds}s");
                return BeatIntervalSeconds;
            default:
                Logger.Error($"[BEAT] Unexpected: {(int)resp.StatusCode}");
                return BeatIntervalSeconds;
        }
    }

    private static void ExecuteShutdown()
    {
        try
        {
            var psi = new ProcessStartInfo
            {
                FileName = "shutdown.exe",
                Arguments = "-s -t 0",
                UseShellExecute = false,
                CreateNoWindow = true
            };
            using var p = Process.Start(psi);
            Logger.Info("[SHUTDOWN] shutdown -s -t 0 issued");
        }
        catch (Exception ex)
        {
            Logger.Error($"[SHUTDOWN] shutdown.exe failed: {ex.Message}, fallback to Win32 API");
            try
            {
                NativeMethods.InitiateSystemShutdown(null, null, 0, false, false);
                Logger.Info("[SHUTDOWN] Win32 API called");
            }
            catch (Exception ex2)
            {
                Logger.Error($"[SHUTDOWN] Win32 API also failed: {ex2.Message}");
            }
        }
    }
}

// ============================================================================
// INI config: [server] url, [device] uid/uid_key/os
// ============================================================================
public class IniConfig
{
    public string ServerUrl { get; set; } = "https://weikongpc.com/beat";
    public string Uid { get; set; } = "";
    public string UidKey { get; set; } = "";
    public string Os { get; set; } = "";
    public bool Valid { get; set; } = true;

    public static IniConfig Load(string path)
    {
        var cfg = new IniConfig();
        try
        {
            var lines = File.ReadAllLines(path);
            string currentSection = "";
            foreach (var rawLine in lines)
            {
                var line = rawLine.Trim();
                if (string.IsNullOrEmpty(line) || line.StartsWith(";") || line.StartsWith("#"))
                    continue;
                if (line.StartsWith("[") && line.EndsWith("]"))
                {
                    currentSection = line[1..^1].ToLowerInvariant();
                    continue;
                }
                var eq = line.IndexOf('=');
                if (eq <= 0) continue;
                var key = line[..eq].Trim().ToLowerInvariant();
                var val = line[(eq + 1)..].Trim();

                switch (currentSection, key)
                {
                    case ("server", "url"): cfg.ServerUrl = val; break;
                    case ("device", "uid"): cfg.Uid = val; break;
                    case ("device", "uid_key"): cfg.UidKey = val; break;
                    case ("device", "os"): cfg.Os = val; break;
                }
            }

            if (string.IsNullOrEmpty(cfg.Uid) || cfg.Uid.Length != 32) cfg.Valid = false;
            if (string.IsNullOrEmpty(cfg.UidKey) || cfg.UidKey.Length != 16) cfg.Valid = false;
            if (string.IsNullOrEmpty(cfg.Os)) cfg.Os = RuntimeInformation.OSDescription;
        }
        catch (Exception)
        {
            cfg.Valid = false;
        }
        return cfg;
    }
}

// ============================================================================
// System monitor (CPU / memory / processes)
// ============================================================================
public static class SystemMonitor
{
    private static PerformanceCounter? _cpuCounter;

    public static (double cpuUsage, double memUsage) GetUsage()
    {
        double cpu = 0;
        double mem = 0;
        try
        {
            if (_cpuCounter == null)
            {
                _cpuCounter = new PerformanceCounter("Processor", "% Processor Time", "_Total");
                _cpuCounter.NextValue();
                Thread.Sleep(100);
            }
            cpu = _cpuCounter.NextValue();

            var memStatus = new MEMORYSTATUSEX { dwLength = (uint)Marshal.SizeOf<MEMORYSTATUSEX>() };
            if (NativeMethods.GlobalMemoryStatusEx(ref memStatus))
                mem = memStatus.dwMemoryLoad;
        }
        catch (Exception ex)
        {
            Logger.Error($"[MONITOR] {ex.Message}");
        }
        return (cpu, mem);
    }

    public static List<ProcessInfo> GetProcesses()
    {
        var list = new List<ProcessInfo>();
        try
        {
            var procs = Process.GetProcesses();
            foreach (var p in procs)
            {
                try
                {
                    list.Add(new ProcessInfo
                    {
                        Name = p.ProcessName + ".exe",
                        Pid = p.Id,
                        Mem = p.WorkingSet64 / 1024.0 / 1024.0,
                        Cpu = 0
                    });
                }
                catch { }
            }
        }
        catch (Exception ex)
        {
            Logger.Error($"[MONITOR] procs: {ex.Message}");
        }
        return list;
    }
}

// ============================================================================
// Logger (WeikongPC.log in same dir as exe)
// ============================================================================
public static class Logger
{
    private static readonly object _lock = new();
    private static readonly string _logFile = Path.Combine(AppContext.BaseDirectory, "WeikongPC.log");

    public static void Info(string msg) => Write("INFO", msg);
    public static void Error(string msg) => Write("ERROR", msg);

    private static void Write(string level, string msg)
    {
        try
        {
            lock (_lock)
            {
                var line = $"{DateTime.Now:yyyy-MM-dd HH:mm:ss} [{level}] {msg}{Environment.NewLine}";
                File.AppendAllText(_logFile, line);
            }
        }
        catch { }
    }
}

// ============================================================================
// Service self-installer (install/uninstall commands)
// ============================================================================
public static class ServiceSelfInstaller
{
    private const string ServiceName = "WeikongPC";
    private const string DisplayName = "WeikongPC Report Service";
    private const string Description = "WeikongPC PC client - process reporting and command execution";

    public static void Install()
    {
        var exePath = Environment.ProcessPath ?? AppContext.BaseDirectory;
        var binPath = $"\"{exePath}\"";

        // Check if already exists
        var existing = ServiceController.GetServices().FirstOrDefault(s => s.ServiceName == ServiceName);
        if (existing != null)
        {
            Console.WriteLine($"Service {ServiceName} already exists, removing first...");
            Uninstall();
            Thread.Sleep(1000);
        }

        RunSc($"create {ServiceName} binPath= {binPath} start= auto");
        RunSc($"description {ServiceName} \"{Description}\"");
        RunSc($"config {ServiceName} DisplayName= \"{DisplayName}\"");
        // Failure recovery: 24h reset, 60s restart on each failure
        RunSc($"failure {ServiceName} reset= 86400 actions= restart/60000/restart/60000/restart/60000");

        try
        {
            using var sc = new ServiceController(ServiceName);
            sc.Start();
            sc.WaitForStatus(ServiceControllerStatus.Running, TimeSpan.FromSeconds(10));
            Console.WriteLine($"OK: Service {ServiceName} installed and started");
            Console.WriteLine($"  Path: {exePath}");
            Console.WriteLine($"  StartType: Automatic");
            Console.WriteLine($"  Recovery: restart after 60s");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Service registered but start failed: {ex.Message}");
            Console.WriteLine("You can start it manually in services.msc");
        }
    }

    public static void Uninstall()
    {
        try
        {
            using var sc = new ServiceController(ServiceName);
            if (sc.Status != ServiceControllerStatus.Stopped)
            {
                sc.Stop();
                sc.WaitForStatus(ServiceControllerStatus.Stopped, TimeSpan.FromSeconds(10));
            }
        }
        catch { }

        RunSc($"delete {ServiceName}");
        Console.WriteLine($"OK: Service {ServiceName} removed");
    }

    private static void RunSc(string arguments)
    {
        var psi = new ProcessStartInfo
        {
            FileName = "sc.exe",
            Arguments = arguments,
            UseShellExecute = false,
            CreateNoWindow = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true
        };
        using var p = Process.Start(psi);
        if (p != null)
        {
            p.WaitForExit(10000);
            var stdout = p.StandardOutput.ReadToEnd().Trim();
            var stderr = p.StandardError.ReadToEnd().Trim();
            if (!string.IsNullOrEmpty(stdout)) Console.WriteLine(stdout);
            if (p.ExitCode != 0 && !string.IsNullOrEmpty(stderr)) Console.WriteLine($"[err] {stderr}");
        }
    }
}

// ============================================================================
// Rebind helper (rebind command: open browser with bind URL)
// ============================================================================
public static class RebindHelper
{
    public static void OpenBindPage()
    {
        var iniPath = Path.Combine(AppContext.BaseDirectory, "WeikongPC.ini");
        if (!File.Exists(iniPath))
        {
            Console.WriteLine($"Error: {iniPath} not found. Please run installer first.");
            return;
        }

        var config = IniConfig.Load(iniPath);
        if (!config.Valid)
        {
            Console.WriteLine("Error: WeikongPC.ini is invalid.");
            return;
        }

        var ts = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var url = $"https://weikongpc.com/bind?uid={config.Uid}&uid_key={config.UidKey}&ts={ts}";

        Console.WriteLine($"Opening bind page: {url}");
        try
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = url,
                UseShellExecute = true
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Failed to open browser: {ex.Message}");
            Console.WriteLine($"Please manually visit: {url}");
        }
    }
}

// ============================================================================
// Win32 API
// ============================================================================
internal static class NativeMethods
{
    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GlobalMemoryStatusEx(ref MEMORYSTATUSEX lpBuffer);

    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool InitiateSystemShutdown(
        string? lpMachineName,
        string? lpMessage,
        uint dwTimeout,
        [MarshalAs(UnmanagedType.Bool)] bool bForceAppsClosed,
        [MarshalAs(UnmanagedType.Bool)] bool bRebootAfterShutdown);
}

[StructLayout(LayoutKind.Sequential)]
internal struct MEMORYSTATUSEX
{
    public uint dwLength;
    public uint dwMemoryLoad;
    public ulong ullTotalPhys;
    public ulong ullAvailPhys;
    public ulong ullTotalPageFile;
    public ulong ullAvailPageFile;
    public ulong ullTotalVirtual;
    public ulong ullAvailVirtual;
    public ulong ullAvailExtendedVirtual;
}

// ============================================================================
// JSON models (AOT friendly)
// ============================================================================
public class BeatRequest
{
    [JsonPropertyName("os")] public string Os { get; set; } = "";
    [JsonPropertyName("cpu_usage")] public double CpuUsage { get; set; }
    [JsonPropertyName("mem_usage")] public double MemUsage { get; set; }
    [JsonPropertyName("processes")] public List<ProcessInfo> Processes { get; set; } = new();
}

public class ProcessInfo
{
    [JsonPropertyName("name")] public string Name { get; set; } = "";
    [JsonPropertyName("pid")] public int Pid { get; set; }
    [JsonPropertyName("cpu")] public double Cpu { get; set; }
    [JsonPropertyName("mem")] public double Mem { get; set; }
}

[JsonSourceGenerationOptions(WriteIndented = false)]
[JsonSerializable(typeof(BeatRequest))]
internal partial class BeatJsonContext : JsonSerializerContext { }
