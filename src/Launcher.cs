using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Threading;

[assembly: AssemblyTitle("MultiPrint")]
[assembly: AssemblyDescription("MultiPrint - print to several printers at once")]
[assembly: AssemblyCompany("MultiPrint")]
[assembly: AssemblyProduct("MultiPrint")]
[assembly: AssemblyCopyright("MultiPrint")]
[assembly: AssemblyVersion("2.2.5.0")]
[assembly: AssemblyFileVersion("2.2.5.0")]

static class Program
{
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern int MessageBoxW(IntPtr h, string text, string caption, uint type);

    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    static extern int SetCurrentProcessExplicitAppUserModelID(string appID);

    const BindingFlags PubAll = BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static;

    // Picks the exact method (non-generic, with the same parameter types) to avoid an Ambiguous match
    static MethodInfo M(Type t, string name, params Type[] p)
    {
        foreach (MethodInfo m in t.GetMethods(PubAll))
        {
            if (m.Name != name || m.IsGenericMethodDefinition) continue;
            ParameterInfo[] ps = m.GetParameters();
            if (ps.Length != p.Length) continue;
            bool ok = true;
            for (int i = 0; i < ps.Length; i++) if (ps[i].ParameterType != p[i]) { ok = false; break; }
            if (ok) return m;
        }
        throw new MissingMethodException(t.FullName, name);
    }

    static PropertyInfo P(Type t, string name)
    {
        for (Type cur = t; cur != null; cur = cur.BaseType)
        {
            PropertyInfo pi = cur.GetProperty(name, BindingFlags.Public | BindingFlags.Instance | BindingFlags.DeclaredOnly);
            if (pi != null) return pi;
        }
        throw new MissingMemberException(t.FullName, name);
    }

    [STAThread]
    static int Main(string[] args)
    {
        bool watch = args.Length > 0 && args[0].Equals("--watch", StringComparison.OrdinalIgnoreCase);
        string exe = Assembly.GetExecutingAssembly().Location;
        object runspace = null;
        try
        {
            try { SetCurrentProcessExplicitAppUserModelID("MultiPrint.App"); } catch { }

            if (!watch)
            {
                bool admin = new WindowsPrincipal(WindowsIdentity.GetCurrent())
                    .IsInRole(WindowsBuiltInRole.Administrator);
                if (!admin)
                {
                    var self = new ProcessStartInfo(exe) { UseShellExecute = true, Verb = "runas" };
                    try { Process.Start(self); } catch (System.ComponentModel.Win32Exception) { }
                    return 0;
                }
            }

            string script;
            using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream("MultiPrint.ps1"))
            using (var r = new StreamReader(s, System.Text.Encoding.UTF8)) { script = r.ReadToEnd(); }

            Assembly sma = Assembly.Load("System.Management.Automation, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35");
            Type issT = sma.GetType("System.Management.Automation.Runspaces.InitialSessionState", true);
            object iss = M(issT, "CreateDefault").Invoke(null, null);

            Type rfT = sma.GetType("System.Management.Automation.Runspaces.RunspaceFactory", true);
            runspace = M(rfT, "CreateRunspace", issT).Invoke(null, new[] { iss });
            Type rsT = sma.GetType("System.Management.Automation.Runspaces.Runspace", true);
            P(rsT, "ApartmentState").SetValue(runspace, ApartmentState.STA, null);
            Type optT = sma.GetType("System.Management.Automation.Runspaces.PSThreadOptions", true);
            P(rsT, "ThreadOptions").SetValue(runspace, Enum.Parse(optT, "UseCurrentThread"), null);
            M(rsT, "Open").Invoke(runspace, null);

            object proxy = P(rsT, "SessionStateProxy").GetValue(runspace, null);
            Type proxyT = sma.GetType("System.Management.Automation.Runspaces.SessionStateProxy", true);
            M(proxyT, "SetVariable", typeof(string), typeof(object))
                 .Invoke(proxy, new object[] { "AppExe", exe });

            Type psT = sma.GetType("System.Management.Automation.PowerShell", true);
            object ps = M(psT, "Create").Invoke(null, null);
            P(psT, "Runspace").SetValue(ps, runspace, null);
            M(psT, "AddScript", typeof(string)).Invoke(ps, new object[] { script });
            if (watch)
                M(psT, "AddParameter", typeof(string), typeof(object)).Invoke(ps, new object[] { "Watch", true });

            if (watch)
            {
                // Service: if the code crashes or exits for any reason, it restarts after 3 seconds (unless another instance is running)
                while (true)
                {
                    try { M(psT, "Invoke").Invoke(ps, null); } catch { }
                    object already = M(proxyT, "GetVariable", typeof(string)).Invoke(proxy, new object[] { "WatcherAlreadyRunning" });
                    if (already is bool && (bool)already) return 0;
                    Thread.Sleep(3000);
                    try { M(psT, "Stop").Invoke(ps, null); } catch { }
                    ps = M(psT, "Create").Invoke(null, null);
                    P(psT, "Runspace").SetValue(ps, runspace, null);
                    M(psT, "AddScript", typeof(string)).Invoke(ps, new object[] { script });
                    M(psT, "AddParameter", typeof(string), typeof(object)).Invoke(ps, new object[] { "Watch", true });
                }
            }
            try
            {
                M(psT, "Invoke").Invoke(ps, null);
            }
            catch (TargetInvocationException tie)
            {
                object shown = M(proxyT, "GetVariable", typeof(string))
                                    .Invoke(proxy, new object[] { "MPErrorShown" });
                if (!watch && !(shown is bool && (bool)shown))
                    MessageBoxW(IntPtr.Zero, (tie.InnerException ?? tie).Message, "MultiPrint", 0x10);
                return 1;
            }
            return 0;
        }
        catch (Exception ex)
        {
            if (!watch)
                MessageBoxW(IntPtr.Zero, (ex is TargetInvocationException && ex.InnerException != null ? ex.InnerException : ex).Message,
                            "MultiPrint", 0x10);
            return 1;
        }
        finally
        {
            try { if (runspace != null) ((IDisposable)runspace).Dispose(); } catch { }
        }
    }
}
